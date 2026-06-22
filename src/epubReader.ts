// VS Code integration for the EPUB reader: file selection, Webview panel,
// and the message bridge to the webview UI. All EPUB parsing/rendering lives
// in the vscode-free ./epubCore module.

import * as vscode from 'vscode'
import { EpubBook, loadBook, renderChapter } from './epubCore'

function getNonce(): string {
    let text = ''
    const possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    for (let i = 0; i < 32; i++) {
        text += possible.charAt(Math.floor(Math.random() * possible.length))
    }
    return text
}

function getHtmlForWebview(webview: vscode.Webview, scriptUri: vscode.Uri, styleUri: vscode.Uri): string {
    const nonce = getNonce()
    return `<!DOCTYPE html>
<html lang="zh">
  <head>
    <meta charset="UTF-8" />
    <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src ${webview.cspSource} data:; style-src ${webview.cspSource} 'unsafe-inline'; font-src ${webview.cspSource} data:; script-src 'nonce-${nonce}';">
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link href="${styleUri}" rel="stylesheet" />
    <title>EPUB Reader</title>
  </head>
  <body>
    <div id="app">
      <aside id="sidebar">
        <div id="book-title"></div>
        <nav id="toc"></nav>
      </aside>
      <main id="reader">
        <div id="toolbar">
          <button id="prev">上一章</button>
          <span id="progress"></span>
          <button id="next">下一章</button>
        </div>
        <article id="content"></article>
      </main>
    </div>
    <script nonce="${nonce}" src="${scriptUri}"></script>
  </body>
</html>`
}

// Pick an .epub file to open: prefer an explicitly passed URI, otherwise look
// inside the workspace, and finally fall back to an open dialog.
async function pickEpubUri(resource?: vscode.Uri): Promise<vscode.Uri | undefined> {
    if (resource && resource.fsPath.toLowerCase().endsWith('.epub')) {
        return resource
    }

    const found = await vscode.workspace.findFiles('**/*.epub', '**/node_modules/**', 50)
    if (found.length === 1) {
        return found[0]
    }
    if (found.length > 1) {
        const picked = await vscode.window.showQuickPick(
            found.map((uri) => ({
                label: uri.path.slice(uri.path.lastIndexOf('/') + 1),
                description: vscode.workspace.asRelativePath(uri),
                uri,
            })),
            { placeHolder: '选择要打开的 EPUB 文件' }
        )
        return picked?.uri
    }

    const chosen = await vscode.window.showOpenDialog({
        canSelectMany: false,
        openLabel: '打开 EPUB',
        filters: { 'EPUB 电子书': ['epub'] },
    })
    return chosen?.[0]
}

export async function openEpubReader(context: vscode.ExtensionContext, resource?: vscode.Uri): Promise<void> {
    const uri = await pickEpubUri(resource)
    if (!uri) {
        return
    }

    let book: EpubBook
    try {
        const bytes = await vscode.workspace.fs.readFile(uri)
        book = await loadBook(bytes)
    } catch (err) {
        vscode.window.showErrorMessage(`无法打开 EPUB：${err instanceof Error ? err.message : String(err)}`)
        return
    }

    if (book.spine.length === 0) {
        vscode.window.showErrorMessage('该 EPUB 没有可阅读的内容。')
        return
    }

    const panel = vscode.window.createWebviewPanel(
        'epubReader',
        book.title,
        vscode.ViewColumn.One,
        {
            enableScripts: true,
            retainContextWhenHidden: true,
            localResourceRoots: [vscode.Uri.joinPath(context.extensionUri, 'media')],
        }
    )

    const scriptUri = panel.webview.asWebviewUri(
        vscode.Uri.joinPath(context.extensionUri, 'media', 'epub.js')
    )
    const styleUri = panel.webview.asWebviewUri(
        vscode.Uri.joinPath(context.extensionUri, 'media', 'epub.css')
    )
    panel.webview.html = getHtmlForWebview(panel.webview, scriptUri, styleUri)

    const sendChapter = async (index: number, anchor = '') => {
        const clamped = Math.max(0, Math.min(index, book.spine.length - 1))
        const html = await renderChapter(book, clamped)
        panel.webview.postMessage({
            type: 'chapter',
            index: clamped,
            total: book.spine.length,
            html,
            anchor,
        })
    }

    panel.webview.onDidReceiveMessage(
        async (message: { command: string; index?: number; anchor?: string }) => {
            switch (message.command) {
                case 'ready':
                    panel.webview.postMessage({
                        type: 'init',
                        title: book.title,
                        toc: book.toc,
                    })
                    await sendChapter(0)
                    return
                case 'goto':
                    await sendChapter(message.index ?? 0, message.anchor ?? '')
                    return
            }
        },
        undefined,
        context.subscriptions
    )
}
