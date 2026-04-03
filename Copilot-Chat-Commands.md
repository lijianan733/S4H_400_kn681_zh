# Copilot Chat 常用命令与初始化说明

> **🤖 对于 Copilot 的作用（必读）**
> **机制**：作为项目操作手册，参与 Copilot 对话交互的 RAG（检索增强生成）与上下文检索。
> **效果**：它既能供人类成员快速学习现有命令，也当用户不知道怎么操作并向 Copilot 请求`/help` 或 `有什么命令` 时，Copilot 能检索此文件内容，快速指导用户正确的提问与工具使用流程，充当项目的指令“说明书”。

本文档为本仓库 Copilot Chat 使用提供统一规范，包含 `/init` 命令以及常见控制指令、作用范围、推荐流程。

## 1. 关键命令（“前缀 /”）

- `/init`
  - 启动助手：加载仓库中 `AGENTS.md`、`.github/copilot-instructions.md`、`workspace-instructions.md` 等指令配置。
  - 目的：让 Copilot 进入项目专用模式，绑定本仓库约定。

- `/help` 或 `/?`
  - 获取可用命令列表与文档说明。

- `/reset`
  - 重置会话状态，清除上下文缓存。

- `/feedback`
  - 反馈当前对话结果质量、建议、错漏等。

- `/todo`
  - 代办任务管理（等价于 `manage_todo_list`）。

- `/config`
  - 查看/设置当前 Agent 模式或偏好（取决平台支持）。

- `/run`, `/exec`
  - 执行 shell 命令或脚本（需要运行环境授权）。

## 2. 启动后读取的文件优先级

1. `AGENTS.md`
2. `.github/copilot-instructions.md`
3. `workspace-instructions.md`
4. `copilot-instructions.md` / `AGENT.md` / `CLAUDE.md`
5. `.cursorrules`, `.windsurfrules`, `.clinerules` 等规则文件

对照：引导命令行发起 `/init` 时会聚合这些配置，决定引导策略、行为准则和工具使用范围。

## 3. 典型流程

1. 发送 `/init`
2. Copilot 报告初始化完成，说明读取规则与当前模式
3. 使用 `/todo` 拆任务 / 用代码工具修复 / 询问业务知识
4. `abap_activate` / `run_unit_tests` 等执行基本验证
5. 结束可定义 `/reset` 或 `/exit`（支持时）

## 4. 变更追踪相关（CDHDR/CDPOS）

- 所有启用变更文档对象（如物料、供应商、订单、信息记录等）
- 无论 GUI 或 标准 ABAP/BAPI 修改，都会写 `CDHDR` + `CDPOS`（除非直接 UPDATE 数据库表）

## 5. 推荐实践

- 写代码前先 `/init`，不确定点就 `/help`
- 复杂任务用 `/todo` 管理
- 变更测试后再执行 `abap_activate`
- 规范可在 `AGENTS.md` 增加本项目专用规则（现有规则已经存在）

---

文档已创建于 `\Copilot-Chat-Commands.md`。