# AGENTS.md - Copilot Agent Customization Template

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

``` 

