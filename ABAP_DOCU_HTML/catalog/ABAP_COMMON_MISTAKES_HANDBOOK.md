# ABAP 常见错误速查手册

**目的**：记录 ABAP_ALV_Example.abap 开发过程中暴露的所有错误，防止下次重复犯错。  
**范围**：包括语法、类型、事件、SQL、数据等层面的常见坑点。

---

## 错误分类与查表

### 1️⃣ **Open SQL 语法错误**

| 错误 | 症状 | 修复 | 检查清单 |
|------|------|------|--------|
| 旧式 ROWS 语法 | `ROWS 10` 报语法错误 | 改用 `UP TO 10 ROWS` | ✓ 禁止 `ROWS n.`；使用 `UP TO n ROWS` |
| 主机变量未转义 | 编译报变量识别错误 | 使用 `@lv_var` | ✓ 所有主机变量加 `@` |
| UP TO 无排序 | 结果行集不稳定 | 补充 `ORDER BY` | ✓ `UP TO n ROWS` 必配 `ORDER BY` |
| SELECT 语句顺序错 | 某些版本编译不过 | FROM → UP TO → INTO → WHERE → ORDER BY | ✓ 核对完整顺序链 |

**示例（错误 vs 正确）**
```abap
❌ SELECT * FROM sflight INTO TABLE @gt_flights WHERE carrid = lv_carrid ROWS 10.
✓  SELECT fldate carrid connid planetype seatsmax seatsocc price currency
     FROM sflight
     UP TO 10 ROWS
     INTO TABLE @g_flight_tab
     WHERE carrid = @p_carrid
       AND fldate >= @sy-datlo
     ORDER BY fldate, connid.
```

---

### 2️⃣ **OOALV 布局与字段定义错误**

| 错误 | 症状 | 修复 | 检查清单 |
|------|------|------|--------|
| 布局结构体类型错 | `lvc_s_glay` 中 `edit`/`sel_mode` 不存在 | 改用 `lvc_s_layo` | ✓ 只用 `lvc_s_layo`；避免 `lvc_s_glay` |
| 字段目录用 width | ADT 报 width 无效 | 改用 `outputlen` | ✓ `lvc_s_fcat` 使用 `outputlen` 而非 `width` |
| 货币字段未绑定 | 金额显示格式不对 | 设置 `cfieldname = 'CURRENCY'` | ✓ 每个金额字段都有对应的 `cfieldname` |

**示例（错误 vs 正确）**
```abap
❌ DATA ls_layo TYPE lvc_s_glay.
   ls_layo-edit = abap_true.

✓  DATA ls_layo TYPE lvc_s_layo.
   ls_layo-edit = abap_true.
   ls_layo-sel_mode = 'C'.

❌ APPEND VALUE lvc_s_fcat( fieldname = 'PRICE' width = 12 ) TO pt_fieldcat.
✓  APPEND VALUE lvc_s_fcat( fieldname = 'PRICE' outputlen = 12 cfieldname = 'CURRENCY' ) TO pt_fieldcat.
```

---

### 3️⃣ **事件处理与注册错误**

| 错误 | 症状 | 修复 | 检查清单 |
|------|------|------|--------|
| FORM 直接用 SET HANDLER | ADT 报 `@brief->method` 错误 | 创建本地类，用类方法 | ✓ 事件处理只用"本地类+方法"，不用 FORM |
| 事件未启用 | 工具栏/按钮/data_changed 不触发 | 三件套启用：`set_toolbar_interactive`、`set_ready_for_input`、`register_edit_event` | ✓ ALV 初始化后立即调用三件套 |
| 事件处理器注册不当 | 事件无法触发 | 创建实例 `CREATE OBJECT g_handler`，用 `SET HANDLER g_handler->method FOR g_alv` | ✓ 先创建实例，再绑定事件 |

**示例（错误 vs 正确）**
```abap
❌ FORM pf_on_toolbar FOR EVENT toolbar OF cl_gui_alv_grid USING e_object.
   ...
ENDFORM.
SET HANDLER pf_on_toolbar FOR g_alv.  " ❌ 不能直接用 FORM

✓  CLASS lcl_event_handler DEFINITION.
     METHODS: on_toolbar FOR EVENT toolbar OF cl_gui_alv_grid IMPORTING e_object.
   ENDCLASS.
   CREATE OBJECT g_handler.
   SET HANDLER g_handler->on_toolbar FOR g_alv.  " ✓ 用本地类

❌ CALL METHOD g_alv->set_table_for_first_display(...).
   " 未启用事件

✓  CALL METHOD g_alv->set_table_for_first_display(...).
   CALL METHOD g_alv->set_toolbar_interactive.
   CALL METHOD g_alv->set_ready_for_input( EXPORTING i_ready_for_input = 1 ).
   CALL METHOD g_alv->register_edit_event( EXPORTING i_event_id = cl_gui_alv_grid=>mc_evt_modified ).
```

---

### 4️⃣ **选择屏与文本元素错误**

| 错误 | 症状 | 修复 | 检查清单 |
|------|------|------|--------|
| 标题直接写字符串 | 可能报错或无法翻译 | 改用 `text-nnn` | ✓ 选择屏标题/文本都走文本元素 |
| 文本元素不维护 | 运行时找不到符号 | 在 ADT Properties → Text Elements 中维护对应符号 | ✓ 源代码和文本元素保持一致 |

**示例（错误 vs 正确）**
```abap
❌ SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE 'Flight Selection'.
✓  SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
   " 需在文本元素中维护 001 = 'Flight Selection'（或中文）
```

---

### 5️⃣ **数值字面量与类型转换错误**

| 错误 | 症状 | 修复 | 检查清单 |
|------|------|------|--------|
| 小数字面量给 P 类型 | 浮点→十进制转换可能舍入 | 用整数（两位小数时 599 表示 599.00）或显式 CONV | ✓ P 目标不直接用 F 字面量 |
| 字符串赋值数值字段 | 隐式转换风险，受小数点设置影响 | 直接用数值，必要时显式转换 | ✓ 数值字段禁止字符字面量 |

**示例（错误 vs 正确）**
```abap
❌ ls_row-price = '599.00'.      " 字符串隐式转换
❌ ls_row-price = 599.00.        " F 字面量转 P 有舍入风险

✓  ls_row-price = 599.           " 整数（表示 599.00，P 带 2 位小数）
✓  ls_row-price = CONV p(10)( CONV decfloat34( '123.45' ) ).  " 显式转换
```

---

### 6️⃣ **默认值与验证冲突**

| 错误 | 症状 | 修复 | 检查清单 |
|------|------|------|--------|
| 新增默认 0 值，保存校验拒 0 | 新增行无法保存 | 改验证为 `< 0` 而非 `<= 0`，或给新增非 0 默认值 | ✓ 新增默认值与保存校验逻辑一致 |

**示例（错误 vs 正确）**
```abap
❌ ls_row-seatsocc = 0.      " 新增行默认
   IF ls_flight-seatsocc <= 0.  " 保存拒绝
     MESSAGE 'Invalid' TYPE 'E'.

✓  ls_row-seatsocc = 0.
   IF ls_flight-seatsocc < 0.   " 改为 <0，允许 0
     MESSAGE 'Invalid' TYPE 'E'.
```

---

### 7️⃣ **ALV 行选择与删除错误**

| 错误 | 症状 | 修复 | 检查清单 |
|------|------|------|--------|
| 调用 get_selected_rows 返回空 | DELETE_ROW 无法工作 | 确保 `sel_mode = 'D'` 或其他行选择模式 | ✓ DELETE 前验证 `sel_mode` 支持行选择 |

**示例（正确做法）**
```abap
l_alv_settings-sel_mode = 'D'.  " 或 'C' 等，取决于业务需要
```

---

### 8️⃣ **data_changed 事件处理错误**

| 错误 | 症状 | 修复 | 检查清单 |
|------|------|------|--------|
| 在 data_changed 里用 MESSAGE 弹窗 | 无法精确标注错误单元格，用户体验差 | 改用 `er_data_changed->add_protocol_entry(...)` | ✓ data_changed 中不用 MESSAGE，用 protocol API |

**示例（错误 vs 正确）**
```abap
❌ METHOD on_data_changed.
     IF ls_flight-seatsocc > ls_flight-seatsmax.
       MESSAGE 'Error' TYPE 'E'.  " ❌ 弹窗，无法标注单元格
     ENDIF.
   ENDMETHOD.

✓  METHOD on_data_changed.
     DATA(lo_protocol) = er_data_changed.
     lo_protocol->add_protocol_entry(
       i_msgid = 'ZMSG' i_msgno = '001' i_msgty = 'E'
       i_fieldname = 'SEATSOCC' i_row_id = lv_row ).
   ENDMETHOD.
```

---

### 9️⃣ **DDIC 一致性错误**

| 错误 | 症状 | 修复 | 检查清单 |
|------|------|------|--------|
| 字段名拼写/类型不匹配 | 编译或选择报错 | 基于 DDIC 定义，验证字段名大小写 | ✓ 优先引用 DDIC 类型；禁止手写镜像结构 |

**示例**
```abap
❌ TYPES: BEGIN OF ty_flight,
      bookid TYPE ...  " SFLIGHT 没有这个字段
    END OF ty_flight.

✓  TYPES: BEGIN OF ty_flight,
      fldate TYPE sflight-fldate,      " 从 DDIC 引用
      carrid TYPE sflight-carrid,
    END OF ty_flight.
```

---

## 🎯 **综合预防检查清单**

在提交代码前，必须逐项检查：

### SQL
- [ ] 使用 `UP TO n ROWS` 而非 `ROWS n`
- [ ] 所有主机变量用 `@` 转义
- [ ] `UP TO` 配有 `ORDER BY` 确保可重复
- [ ] 语句顺序：FROM → UP TO → INTO → WHERE → ORDER BY

### 选择屏与文本
- [ ] 标题用 `text-nnn` 而非字符串字面量
- [ ] 文本元素已在 ADT 中维护

### OOALV
- [ ] 布局用 `lvc_s_layo`，非 `lvc_s_glay`
- [ ] 字段目录用 `outputlen` 而非 `width`
- [ ] 金额字段链接 `cfieldname` 到币种字段
- [ ] ALV 初始化后立即调用：
  - `set_toolbar_interactive( abap_true )`
  - `set_ready_for_input( 1 )`
  - `register_edit_event( mc_evt_modified )`

### 事件处理
- [ ] 事件处理器在"本地类"中定义，不用 FORM
- [ ] 先创建处理器实例，再注册事件
- [ ] `SET HANDLER g_handler->method FOR g_alv`（含 FOR 语句）

### 数据与验证
- [ ] P 类型目标：整数赋值或显式 CONV decfloat
- [ ] 新增默认值与保存校验逻辑一致
- [ ] 删除操作前验证 `sel_mode` 支持行选择
- [ ] data_changed 中用 protocol 而非 MESSAGE

### DDIC
- [ ] 所有字段从 DDIC 引用，不手写镜像结构
- [ ] 字段名大小写与 DDIC 一致

### CI 与 Lint
- [ ] abaplint 启用：`check_syntax`、`strict_sql`、`sql_escape_host_variables`、`check_text_elements`
- [ ] 本地 VS Code 运行 abaplint，或依赖 CI 拦截

---

## 📋 **快速翻查表**

| 症状 | 可能原因 | 快速修复 |
|------|--------|--------|
| SQL 报语法错 | ROWS / 主机变量 / 顺序 | 见 1️⃣ Open SQL |
| ALV 字段不显示或报错 | width 或 outputlen | 改为 `outputlen` |
| 工具栏/按钮不出现 | 事件未启用 | 补三件套 enable 调用 |
| 点击按钮无反应 | 事件处理未注册 | 改用本地类 + SET HANDLER |
| 新增行无法保存 | 默认值与校验冲突 | 改校验为 `<0` |
| 新增行删除失败 | sel_mode 不支持行选 | 改为行选择模式 |
| data_changed 无效 | 未注册或只用 MESSAGE | 改用 protocol API |

---

## 🔗 **关联文档**

- [catalog/ABAP_ALV_Example_ISSUES_LOG.md](ABAP_ALV_Example_ISSUES_LOG.md) — 详细问题与修复
- [catalog/ABAP_CODE_REVIEW_CHECKLIST.md](ABAP_CODE_REVIEW_CHECKLIST.md) — 评审检查单
- [catalog/ABAP_ALV_Example.abap](ABAP_ALV_Example.abap) — 示例代码（已修正）

---

## 📌 **使用建议**

1. **新项目启动**：复制这个手册到项目文档目录。
2. **Code Review**：用快速翻查表进行 10 分钟快速扫描。
3. **错误排查**：遇到问题先查"症状"列，快速定位根因。
4. **CI/Lint**：配合 abaplint 规则，双重防护。
5. **团队培训**：新入职 ABAP 开发者必读，避免重复踩坑。

---

**版本历史**

| 版本 | 时间 | 变更 |
|------|------|------|
| 1.0 | 2025-12-23 | 初版，包含 9 大类错误与综合检查清单 |
