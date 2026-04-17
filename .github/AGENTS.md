# AGENTS.md - Copilot Agent Customization Template

> **🤖 对于 Copilot 的作用（必读）**
> **机制**：作为系统架构拓扑和扩展（skills/prompts/agents/hooks）的“索引地图（Map）”。
> **效果**：它让 AI 在遇到复杂需求时，先拥有全局视野。它知道当前项目目前定义了多少可调用的指令和代码骨架，并依照第 7 节中的说明来重用已有的 ABAP 代码（比如现成的 ALV `REUSE_ALV_GRID_DISPLAY_LVC` 实现方案），避免从零瞎编或偏离技术路线。

> 说明：此文件是 workspace 级别 agent-cheat sheet，用于快速找到/创建自定义 agent/instructions/prompt/skill 资源。

## 1. 目标
- 为这个 repo 提供标准 agent 自定义模板（ABAP + 报告 + 业务咨询）。
- 让团队成员通过 `/` 命令快速调用常用流程。

## 2. 插件与目录结构
建议创建如下文件：
- `.github/copilot-instructions.md`（通用指南）
- `.github/prompts/abap-refactor.prompt.md`（按需提示）
- `.github/agents/abap-workflow.agent.md`（多阶段工作流）
- `.github/skills/abap-cleanup/SKILL.md`（封装动作）

## 3. 模板：Workspace Instructions（copilot-instructions.md）

```markdown
---
description: "ABAP 项目全局指令（代码风格、重构、业务约定）"
applyTo:
  - "**/*.abap"
  - "**/*.prog.abap"
  - "**/System Library/**"

# “用时”示例
# 1. 修复命名标准
# 2. 自动添加注释模板
# 3. 按 ABAP clean code 规则重写逻辑

sections:
  - title: "ABAP 风格"
    content: |
      1. 变量使用 `lv_`、内部表 `lt_`、结构 `ls_`
      2. 关键字大写，缩进 2 空格。

  - title: "常见审查"
    content: |
      - 不用 SELECT *，必须列字段
      - 所有 SELECT 单独逻辑分离为方法
      - 使用 `cl_abap_tstmp` 进行时间处理

---
```

## 4. 模板：自定义 agent（.github/agents/abap-workflow.agent.md）

```markdown
---
name: "abap-workflow"
description: "自动化 ABAP 代码质量和单测编写流程。"

steps:
  - name: "代码风格检查"
    run: "apply_instruction: abap-style"

  - name: "重构建议"
    run: "apply_prompt: abap-refactor"

  - name: "生成单测模板"
    run: "run_skill: abap-unit-test-generator"

---
```

## 5. 创建建议
1. 先把“要解决的问题”总结为一句话。
2. 选择 Primitive：`instruction` / `prompt` / `agent` / `skill`。
3. 按上述模板填好 `description` + `applyTo`。
4. 提交 PR 并写 README 说明用途。

## 6. 常用触发词
- ABAP
- refactor
- unit test
- RFC
- 数据字典
- 性能

## 7. 本仓库项目说明（已实现/待完善）
- ABAP 示例程序：`Z260403_REPORT_1.prog.abap`，实现了 OOP 航班查询 + `REUSE_ALV_GRID_DISPLAY_LVC`。
- 自动 fieldcat 生成：使用 RTTI 根据结果表动态创建 `lvc_t_fcat`。
- 文档资产：`Copilot-Chat-Commands.md`（命令及流程说明）、`AI_test/AI代码生成注意点.md`。
- 变更追踪提示：CDHDR/CDPOS 处理说明已写在 `Copilot-Chat-Commands.md`，推荐 SQL/事务监控。
- 现有命令集：`/init`, `/help`, `/reset`, `/feedback`, `/todo`, `/config`, `/run`, `/exec`; 以及`/create-prompt`, `/create-instructions`, `/create-skill`, `/create-agent`, `/create-hook`, `/summarize-github-issue-pr`, `/suggest-fix-issue`, `/form-github-search-query`, `/address-pr-comments`，和 ABAP-specific skills (clean-abap/abap-code-writing/abap-performance-ecc/hana/abap-research/sap-system-personality-report/sap-customizing)。
- 推荐流程：先 `/init`；后 `/todo` 拆任务；`abap_activate`/`run_unit_tests` 验证；最后 `/reset`。
- 增强建议：可以继续补充 `.github/prompts`、`.github/agents`、`.github/skills` 项目级最佳实践方案。

```

