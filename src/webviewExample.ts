// Simple VS Code Webview example (TypeScript)
// This file shows how to create a WebviewPanel and communicate
// between the extension host and the webview content.

import * as vscode from 'vscode'

export function showSimpleWebview(context: vscode.ExtensionContext) {
    const panel = vscode.window.createWebviewPanel(
        'simpleWebview', // internal view type
        'Simple Webview', // title
        vscode.ViewColumn.One, // show in first editor column
        {
            enableScripts: true,
            localResourceRoots: [vscode.Uri.joinPath(context.extensionUri, 'media')],
        }
    )

    const scriptUri = panel.webview.asWebviewUri(
        vscode.Uri.joinPath(context.extensionUri, 'media', 'main.js')
    )

    const styleUri = panel.webview.asWebviewUri(
        vscode.Uri.joinPath(context.extensionUri, 'media', 'styles.css')
    )

    panel.webview.html = getHtmlForWebview(panel.webview, scriptUri, styleUri)

    // 1) 监听来自 webview 的消息
    panel.webview.onDidReceiveMessage(
        (message: any) => {
            switch (message.command) {
                case 'alert':
                    vscode.window.showInformationMessage(message.text)
                    return
            }
        },
        undefined,
        context.subscriptions
    )
}

function getHtmlForWebview(webview: vscode.Webview, scriptUri: vscode.Uri, styleUri: vscode.Uri) {
    // Content Security Policy (CSP) to enforce safe script/style sources
    const nonce = getNonce()

    return `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src ${webview.cspSource}; script-src 'nonce-${nonce}';">
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link href="${styleUri}" rel="stylesheet" />
    <title>Simple Webview</title>
  </head>
  <body>
    <h1>Webview Example</h1>
    <p>This is a simple Webview panel. Click the button below to send a message to the extension host.</p>
    <button id="sendButton">Send Message</button>

    <script nonce="${nonce}" src="${scriptUri}"></script>
  </body>
</html>`
}

function getNonce() {
    let text = ''
    const possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    for (let i = 0; i < 32; i++) {
        text += possible.charAt(Math.floor(Math.random() * possible.length))
    }
    return text
}
