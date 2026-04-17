---
name: copilot-chat
description: "Skill for Copilot Chat command discovery and setup in this repository. Includes /init workflow, commands reference, and recommended practices."
---

# Copilot Chat Skill: 命令与初始化指导

## 目的
本技能用于帮助开发者在 `S4H_400_kn681_zh` 仓库中快速掌握 Copilot Chat 交互命令集、启动流程，以及与 ABAP 开发相关的 tool 命令。适用于团队新成员或复盘时快速执行。

## 触发条件
- 用户询问 “Copilot 命令有哪些”
- 用户使用 `/init`、`/help`、`/todo` 相关问题
- 用户要求“hook”或“agent自定义”指导

## 主要步骤
1. 请先执行 `/init`。
2. 读取仓库级配置：
   - `AGENTS.md`
   - `.github/copilot-instructions.md`
   - `workspace-instructions.md`
3. 确认可用命令（对话通用）：
   - `/init`, `/help`, `/reset`, `/feedback`, `/todo`, `/config`, `/run`, `/exec`。
4. 确认扩展命令（Agent/Workflow）：
   - `/create-prompt`, `/create-instructions`, `/create-skill`, `/create-agent`, `/create-hook`
   - `/summarize-github-issue-pr`, `/suggest-fix-issue`, `/form-github-search-query`, `/address-pr-comments`
   - `clean-abap`, `abap-code-writing`, `abap-performance-ecc`, `abap-performance-hana`, `abap-research`, `sap-system-personality-report`, `sap-customizing`
5. 当涉及 ABAP 开发验证：
   - `abap_activate`
   - `run_unit_tests`

## 输出模板（可直接拷贝）
```markdown
# Copilot Chat 常用命令与初始化说明

## 1. 关键命令
- /init: 启动助手并加载本仓库次级配置。
- /help, /?: 获取帮助和可用命令。
- /reset: 重置会话上下文。
- /feedback: 报告问题/改进建议。
- /todo: 任务拆分与管理。
- /config: 配置模式与偏好。
- /run, /exec: 执行命令/脚本（需授权）。

## 2. 典型流程
1. /init
2. /help
3. /todo / coding
4. abap_activate + run_unit_tests
5. /reset
```

## 参考资料
- `AGENTS.md`
- `.github/copilot-instructions.md`
- `workspace-instructions.md`
- `Copilot-Chat-Commands.md`

## 评估标准
- 命令完成率：至少覆盖 80% 的常用指令
- 验证点：`/help` 输出是否含关键词
- 产出：形成一份可直接给新人看的快速指南

## 后续扩展
- 增加对 `hooks` 的自动检测和写法示例
- 增加 `ABAP` 与 `CDHDR/CDPOS` 变更追踪在 skill 里的自动化查询模板
