import * as vscode from 'vscode'
import { showSimpleWebview } from './webviewExample'

export function activate(context: vscode.ExtensionContext) {
    context.subscriptions.push(
        vscode.commands.registerCommand('webviewExample.show', () => {
            showSimpleWebview(context)
        })
    )
}

export function deactivate() { }
