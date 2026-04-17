# ABAP Cleaner 标准与 abaplint 规则映射（精要版）

目标：在 VS Code 中用 abaplint 近似复刻 ABAP Cleaner「Essential」风格（对齐 Clean ABAP）。

## 覆盖面与策略

- 关键词大小写与缩进：统一基本排版（abaplint 负责）。
- 空白/空行/标点：约束空格、空行、句点/冒号前空格等（abaplint 负责）。
- 常用“语义等价替换”：RECEIVING/EXPORTING 可省略、CALL METHOD→ 函数式、RAISE EXCEPTION NEW、NEW 构造、IS NOT（abaplint 负责）。
- 其余 ABAP Cleaner 增强（如大量对齐/美化、DDL 对齐等）目前由 ABAP Cleaner 处理，abaplint 不做重排，仅做静态检查和快速修复。

## 规则映射（核心项）

- 关键字大小写 → abaplint: `keyword_case`
- 缩进/对齐（语句/语句内） → `indentation`、`in_statement_indentation`
- 结尾空白、Tab、双空格 → `whitespace_end`、`contains_tab`、`double_space`
- 标点/链式语句空格 → `space_before_dot`、`space_before_colon`、`colon_missing_space`
- 空行规范 → `empty_line_in_statement`、`sequential_blank`
- 一行一语句 → `max_one_statement`
- 行长限制 → `line_length`
- 方法之间空行 → `newline_between_methods`
- 仅标点行 → `line_only_punc`
- 功能等价重写（Clean ABAP） → `exporting`、`omit_receiving`、`functional_writing`、`prefer_raise_exception_new`、`use_new`、`prefer_is_not`
- 结构化与健壮性 → `exit_or_check`、`empty_statement`、`unused_variables`、`nesting`

## abaplint 配置

项目根已新增文件：`abaplint.json`

```json
{
  "global": { "files": ["catalog/**/*.abap"] },
  "syntax": { "version": "v754" },
  "rules": {
    "keyword_case": true,
    "indentation": true,
    "whitespace_end": true,
    "contains_tab": true,
    "space_before_dot": true,
    "space_before_colon": true,
    "colon_missing_space": true,
    "double_space": true,
    "empty_line_in_statement": true,
    "sequential_blank": true,
    "max_one_statement": true,
    "line_length": { "enabled": true, "length": 120 },
    "in_statement_indentation": true,
    "newline_between_methods": true,
    "line_only_punc": true,
    "exporting": true,
    "omit_receiving": true,
    "prefer_is_not": true,
    "prefer_raise_exception_new": true,
    "functional_writing": true,
    "use_new": true,
    "exit_or_check": true,
    "empty_statement": true,
    "unused_variables": true,
    "nesting": true
  }
}
```

说明：上述规则多为 ABAP Cleaner Essential 所涵盖或 Clean ABAP 明确推荐的做法。个别需要精细阈值的规则，此处采用 abaplint 默认值，足以覆盖一致性需求。

## VS Code 使用建议

- 扩展：`larshp.vscode-abaplint`（诊断与 Quick Fix）；需要“自动排版”的话，仍以 ABAP Cleaner（Eclipse/Standalone）为主。
- 保存时自动修复：在问题列表对 abaplint 规则使用 Quick Fix；或结合 Git 钩子/CI 运行 `@abaplint/cli`。
- 建议 settings（可选）：

```json
{
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "editor.tabSize": 2,
  "editor.insertSpaces": true
}
```

## 不同点与注意

- ABAP Cleaner 会重排对齐（如 SELECT 列、参数对齐），abaplint 仅检查/建议，不强制重排布局。
- 复杂 DDL 规则（对齐/缩进/空行）目前建议继续通过 ABAP Cleaner 处理。
- 若需 100% 版式统一（尤其对齐类规则），建议团队在 ADT 中使用 ABAP Cleaner 作为最终“排版器”，abaplint 作为“风格/安全/可读性”守门人。

## 后续规划（可选）

- 扩展更多 Clean ABAP/ABAP Cleaner 可落地到 abaplint 的规则（如更多 obsolete/use-NEW 系列）。
- 在 `catalog/ABAP_CODE_QUALITY_GUIDE.md` 中加入“ABAP Cleaner 标准”章，统一工作流描述。
