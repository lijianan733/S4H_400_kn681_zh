# Webview 示例（VS Code 扩展）

本目录提供一个最小的 Webview 使用示例，用于演示如何在 VS Code 扩展中：

1. 创建一个 `WebviewPanel`
2. 在 Webview 中显示 HTML/CSS 页面
3. 通过 `postMessage` 来回传递消息

## 关键文件

- `webviewExample.ts`：Webview 创建逻辑（在扩展中调用这个函数即可弹出 Webview）。
- `../media/main.js`：Webview 内部的 JavaScript，负责发送消息给扩展主程序（位于扩展根目录的 `media/`）。
- `../media/styles.css`：Webview 页面样式。

## EPUB 阅读器

本扩展还提供一个 EPUB 电子书阅读器：

- `epubCore.ts`：纯解析/渲染逻辑（不依赖 VS Code API，便于测试）——解析 EPUB 的 OPF 包与 NCX 目录，并将章节渲染为可在 Webview 中显示的 HTML（图片内联为 data URI，样式内联为 `<style>`）。
- `epubReader.ts`：VS Code 集成（选择文件、创建 Webview 面板、消息桥接）。
- `../media/epub.js` / `../media/epub.css`：阅读器界面（目录侧栏、上一章/下一章、键盘左右翻页）。

运行命令 **Open EPUB Reader**（命令面板）或右键点击 `.epub` 文件即可打开。若工作区内仅有一本 EPUB，会自动打开它。

## 用法示例

如果你已经有一个 VS Code 扩展，可以在 `extension.ts` 中这样调用：

```ts
import * as vscode from 'vscode';
import { showSimpleWebview } from './webviewExample';

export function activate(context: vscode.ExtensionContext) {
  const disposable = vscode.commands.registerCommand('myExtension.showWebview', () => {
    showSimpleWebview(context);
  });
  context.subscriptions.push(disposable);
}
```

然后在 `package.json` 中注册命令：

```json
"contributes": {
  "commands": [
    {
      "command": "myExtension.showWebview",
      "title": "Show Simple Webview"
    }
  ]
}
```

启动扩展后执行命令即可打开示例 Webview 面板。

## 运行步骤（完整）

1. 安装依赖：

```bash
npm install
```

2. 编译 TypeScript：

```bash
npm run compile
```

3. 启动扩展开发主机：
   - 在 VS Code 中按 `F5`。

4. 在打开的扩展开发主机窗口中按 `Ctrl+Shift+P`，执行命令 `Show Webview Example`。

点击按钮会在主窗口中弹出 “Hello from the Webview!” 提示。
