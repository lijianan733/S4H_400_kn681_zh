import * as vscode from 'vscode'
import { showSimpleWebview } from './webviewExample'
import { openEpubReader } from './epubReader'

export function activate(context: vscode.ExtensionContext) {
    context.subscriptions.push(
        vscode.commands.registerCommand('webviewExample.show', () => {
            showSimpleWebview(context)
        }),
        vscode.commands.registerCommand('epubReader.open', (resource?: vscode.Uri) => {
            void openEpubReader(context, resource)
        })
    )
}

export function deactivate() { }
