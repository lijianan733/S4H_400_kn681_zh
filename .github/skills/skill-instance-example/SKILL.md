---
name: abap-alv-row-selection
description: "示例 Skill：解释 ABAP ALV 行选中实现，以及何时使用 REUSE_ALV_GRID_DISPLAY_LVC 与 CL_GUI_ALV_GRID。"
---

# ABAP ALV 行选中实现 Skill

## 目的

帮助开发者快速理解并选择适合的 ABAP ALV 行选中实现方式。这个 skill 以具体示例说明：

- `REUSE_ALV_GRID_DISPLAY_LVC` 的非 OO 行选择实现
- `CL_GUI_ALV_GRID` 的 OO 容器方式
- 何时需要自建屏幕/容器，何时不需要

## 触发条件

- 用户问“ABAP ALV 行选中有几种实现”
- 用户问“CL_GUI_ALV_GRID 是否需要自建屏幕”
- 用户在 `ABAP` 报表中使用 `REUSE_ALV_GRID_DISPLAY_LVC` 并希望理解 `SEL` 字段作用

## 主要步骤

1. 识别当前程序使用的 ALV 类型：函数模块式还是对象式。
2. 如果使用 `REUSE_ALV_GRID_DISPLAY_LVC`，解释 `SEL` 字段、`box_fname` 与 `sel_mode` 的配置。
3. 如果使用 `CL_GUI_ALV_GRID`，说明必须有容器控件：`CUSTOM_CONTAINER` 或 `DOCKING_CONTAINER`。
4. 对比两者的优缺点：实现简单性、交互能力、屏幕依赖、扩展性。
5. 给出适合改造的场景建议。

## 具体示例

### 1. 非 OO ALV：`REUSE_ALV_GRID_DISPLAY_LVC`

你的程序使用方式：

- `ty_result` 中定义 `sel type abap_bool`
- `ls_layo-box_fname = 'SEL'`
- `ls_layo-sel_mode = 'A'`
- 调用 `REUSE_ALV_GRID_DISPLAY_LVC`，并传入 `gt_alv`

这就表示：

- ALV 左侧会显示复选框
- 用户勾选后，ALV 会将选择写回 `gt_alv` 中的 `SEL` 字段
- 你可以在回调里通过 `where sel = abap_true` 读取选中行

这个实现不需要你自己建屏幕，直接在普通报表中使用即可。

### 2. OO ALV：`CL_GUI_ALV_GRID`

典型写法：

- 先创建容器：
  - `cl_gui_custom_container=>new( container_name = 'CC_AREA' )`
  - 或 `cl_gui_docking_container=>new( side = cl_gui_docking_container=>dock_at_left )`
- 再创建 ALV 对象：
  - `cl_gui_alv_grid=>new( i_parent = container )`
- 设置字段目录、布局、事件回调
- 调用 `set_table_for_first_display`

这个方式通常需要一个自建屏幕或一个容器区域，因为 OO ALV 不会自动占用报表标准列表区域。

### 3. 何时选哪个

| 场景 | 推荐方案 |
|------|----------|
| 只要显示列表、带选择框、少量交互 | `REUSE_ALV_GRID_DISPLAY_LVC` |
| 需要复杂事件、动态容器、控件布局 | `CL_GUI_ALV_GRID` |
| 希望面向对象、易扩展 | `CL_GUI_ALV_GRID` 或 `CL_SALV_TABLE` |

## 输出示例

当用户询问时，skill 应输出：

- 你当前是 `REUSE_ALV_GRID_DISPLAY_LVC` 非 OO 实现
- `SEL` 字段是 ALV 选择列的关键
- 你不需要自建屏幕
- `CL_GUI_ALV_GRID` 需要容器，通常要自建屏幕或 docking container
- 如果你想要更复杂交互，建议使用 OO ALV；如果只想简单选择行，继续用当前方式即可

## 示例提示

- 请帮我解释这段 ABAP ALV 代码中的 `SEL` 字段是什么意思。
- 现在我的程序用 `REUSE_ALV_GRID_DISPLAY_LVC`，要不要改成 `CL_GUI_ALV_GRID`？
- 我想在报表里加复选框选中行，该用哪个 ALV 实现？

## 评估标准

- 是否识别当前程序 ALV 类型为 `REUSE_ALV_GRID_DISPLAY_LVC`
- 是否解释 `SEL`、`box_fname`、`sel_mode` 的作用
- 是否明确回答 `CL_GUI_ALV_GRID` 是否需要屏幕/容器
- 是否给出实际改造建议

## 后续扩展

- 增加 `CL_SALV_TABLE` 与 `CL_GUI_ALV_GRID` 的对比
- 增加标准字段目录与 LVC 字段目录的区别
- 增加常见 ALV `user_command` 回调模板
