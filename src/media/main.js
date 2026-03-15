(function () {
  const vscode = acquireVsCodeApi();

  document.getElementById('sendButton').addEventListener('click', () => {
    vscode.postMessage({
      command: 'alert',
      text: 'Hello from the Webview!'
    });
  });
})();
