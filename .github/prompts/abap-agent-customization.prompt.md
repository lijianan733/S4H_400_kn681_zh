---
name: "abap-agent-customization"
description: "帮我根据当前对话内容创建一个 agent-customization .prompt.md 模板，适用于 ABAP 项目与业务场景。"
---

## 任务
你是一个 Copilot agent 自定义助手。请将以下信息转换为一个可执行 prompt 模板：

- 要求：创建 `.prompt.md`，适用于 ABAP 代码审查/重构/问题解析。
- 上下文：用户已经在对话中提出了多次“ABAP 风格、国债、通胀”等问答场景。
- 输出形式：提供 prompt 内容和示例调用。

## 目标
- 生成文件格式：适合放在 `.github/prompts/`。
- 包含：任务说明、输入参数定义、输出规范、示例。

## 例子
- 用户输入：`abap-fix` 或 `refactor`。
- 期待输出：ABAP 代码重构建议，按规范 `lv_`, `lt_`, `ls_`，并检查 `SELECT` 语句。

## 交付
请按 `agent-customization` 规范提供最终 prompt 内容，尽量简洁直接可用。