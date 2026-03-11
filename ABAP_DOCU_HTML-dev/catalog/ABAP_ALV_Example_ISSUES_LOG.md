# ABAP 示例问题记录与避免指南

目的：记录本仓库 ABAP 示例（OO ALV CRUD / SFLIGHT）在实现过程中暴露的问题与修正方案，给出可落地的预防措施（规则、CI、检查点），避免后续重复犯错。

适用范围：示例文件 [catalog/ABAP_ALV_Example.abap](ABAP_ALV_Example.abap) 及相似模式的 ABAP 报表/ALV 程序。

---

## 1) Open SQL 现代语法与可重复性

- 症状：
- 前/后对比：

```abap
* 之前（错误）
SELECT * FROM sflight
  INTO TABLE @gt_flights
  WHERE carrid = lv_carrid

* 之后（正确）
SELECT * FROM sflight
  UP TO 10 ROWS.
```

- 预防：
  - Lint：`strict_sql`、`sql_escape_host_variables`、`check_syntax`。
  - 检查单：必须加 `ORDER BY` 配合 `UP TO`；禁止旧式 `ROWS n`。
  - CI：已在 `.github/workflows/abaplint.yml` 强制执行。

## 2) 选择屏幕标题应使用文本元素

- 症状：直接写死字符串标题，或在某些语法/编码设置下报错、不可翻译。
- 根因：未按规范使用文本元素（如 `text-001`）。
- 修正：块标题改为 `text-001`，并在 ADT / SE80 维护文本元素 001。

* 之前（不规范）
  SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE title.

- 预防：
  - Lint：`check_text_elements`。
  - 检查单：所有选择屏幕标题、消息文本必须走文本元素。

## 3) OOALV 布局结构体类型错误

- 症状：`l_alv_settings-edit`、`sel_mode` 等字段编译不识别。
- 根因：误用了 `lvc_s_glay` 而非 `lvc_s_layo`。
- 修正：布局用 `lvc_s_layo`，字段如 `edit`、`sel_mode` 才有效。
  DATA ls_layo TYPE lvc_s_glay.
  ls_layo-edit = abap_true.

ls_layo-edit = abap_true.
ls_layo-sel_mode = 'A'. " 根据需要设定选择模式

````

  - Lint：`check_syntax`、`parser_error`。
  - 检查单：ALV 布局使用 `lvc_s_layo`，全局布局 `lvc_s_glay` 不混用。

## 4) ALV 事件不触发（工具条 / 用户命令 / data_changed）

- 症状：自定义按钮不出现，点击无响应；编辑后不进入 `data_changed`。
- 根因：未启用交互工具条；未设置可输入；未注册编辑事件；或 `SET HANDLER` 未绑定到实例。
- 修正要点：
  - `go_grid->set_toolbar_interactive( abap_true ).`
  - `go_grid->set_ready_for_input( 1 ).`
  - `go_grid->register_edit_event( cl_gui_alv_grid=>mc_evt_modified ).`
  - 事件绑定：`SET HANDLER me->on_toolbar FOR go_grid.`（确保 FOR 实例）
  - 保存前调用：`go_grid->check_changed_data( ).`
- 示例（片段）：

```abap
SET HANDLER me->on_toolbar FOR go_grid.
SET HANDLER me->on_user_command FOR go_grid.
SET HANDLER me->on_data_changed FOR go_grid.

go_grid->set_toolbar_interactive( abap_true ).
go_grid->set_ready_for_input( 1 ).
go_grid->register_edit_event( cl_gui_alv_grid=>mc_evt_modified ).
* 可选：Enter 触发
go_grid->register_edit_event( cl_gui_alv_grid=>mc_evt_enter ).
````

- 预防：
  - 检查单：创建 GRID 后立即三件套（交互、可输入、编辑事件）+ 三个 `SET HANDLER`。

## 5) 货币字段未绑定导致金额显示异常

- 症状：价格列未按货币小数位显示或格式化不正确。
- 根因：字段目录未设置 `cfieldname`。
- 修正：价格列 `cfieldname = 'CURRENCY'` 与 SFLIGHT 的 `CURRENCY` 字段绑定。
- 示例：

```abap
ls_fcat-fieldname  = 'PRICE'.
ls_fcat-outputlen  = 15.
ls_fcat-decimals   = 2.
ls_fcat-cfieldname = 'CURRENCY'.
```

- 预防：
  - 检查单：金额/数量字段与币种/单位字段成对绑定。

## 6) 数值常量类型不当（字符串代替数值）

- 症状：`'599.00'` 等字符串被隐式转换，可能受小数位/区域设置影响。
- 根因：用字符字面量表示 DEC 类型数值。
- 修正：使用数值字面量（与字段小数位一致）。
- 示例：

```abap
* 之前（不规范）
ls_row-price = '599.00'.

* 之后（规范）
ls_row-price = 599.00.
```

- 预防：
  - 检查单：数值字段禁止字符字面量；必要时显式转换并校验小数位。

## 7) `UP TO` 未配排序导致结果不稳定

- 症状：相同输入数据在不同运行/系统上行集顺序不同。
- 修正：与 1) 一致，补充 `ORDER BY` 明确顺序键。
- 示例：见 1)。
- 预防：
  - 检查单：凡使用 `UP TO n ROWS` 必有 `ORDER BY`。

## 8) DDIC 字段与类型对齐

- 症状：字段名拼写/类型不匹配导致选择或赋值报错。
- 修正：本地类型 `TYPES` 基于 DDIC（如 `sflight`）或 `INCLUDE TYPE`；字段名与大小写按 DDIC 一致。
- 预防：
  - Lint：`check_syntax`、`unused_variables`（清理冗余自定义类型）。
  - 检查单：优先引用 DDIC 类型，避免手写镜像结构。

## 9) 事件保存前未收集变更

- 症状：保存或提交时未带上刚刚编辑的单元格变更。
- 修正：执行 `go_grid->check_changed_data( ).` 在保存/校验前收集。
- 预防：
  - 检查单：在保存路径第一步调用 `check_changed_data( )`。

## 10) 文本元素维护方法（提示）

- 在 ADT 中：打开程序 → Properties → Text Elements → Text Symbols → 维护 `001`（与 `text-001` 匹配）。
- 在经典 SE80：GOTO → Text Elements → Text Symbols。

---

## 关联文件

- 示例程序：[catalog/ABAP_ALV_Example.abap](ABAP_ALV_Example.abap)
- Lint 配置（若存在）：`abaplint.json`、`.abaplintrc.json`
- CI 工作流：`.github/workflows/abaplint.yml`
- 代码评审检查单：[catalog/ABAP_CODE_REVIEW_CHECKLIST.md](ABAP_CODE_REVIEW_CHECKLIST.md)
- 质量指南：[catalog/ABAP_CODE_QUALITY_GUIDE.md](ABAP_CODE_QUALITY_GUIDE.md)

---

## 使用建议（落地）

- 本文档中的“预防”条目应并入团队检查单与 PR 模板。
- 在本地 VS Code 安装/启用 abaplint，对应规则开启；CI 已强制执行以防回归。
- 对新建报表/ALV：创建骨架时即补齐 3× 事件启用（交互/可输入/编辑事件）与 `ORDER BY` 习惯用法。
