# ABAP 代码评审速查清单（精简版）

> 🚀 **快速避坑**：
> - [常见错误速查手册](ABAP_COMMON_MISTAKES_HANDBOOK.md) — 看症状快速查原因
> - [相关问题库](ABAP_ALV_Example_ISSUES_LOG.md) — 获取详细技术方案

- 选择屏标题：`SELECTION-SCREEN ... WITH FRAME TITLE text-001.` 不要使用字符串字面量。文本符号需在系统内维护。
- Open SQL：
  - 使用新语法 `@` 转义主机变量；限制行数用 `UP TO n ROWS`；需要稳定顺序时加 `ORDER BY`。
  - 避免旧式 `ROWS n.` 写法。
  - 语句顺序：FROM → UP TO → INTO → WHERE → ORDER BY。
- ALV：
  - `is_layout` 用 `lvc_s_layo`，`edit`/`sel_mode` 字段才可用。
  - 字段目录用 `outputlen` 而非 `width`。
  - 工具栏按钮在 `toolbar` 事件中向 `e_object->mt_toolbar` 追加 `stb_button`；动作在 `user_command` 事件处理。
  - 价格列设置 `cfieldname = 'CURRENCY'` 以便货币格式联动。
  - 事件处理在"本地类"中定义，先创建实例后注册（`SET HANDLER g_handler->method FOR g_alv`）。
  - 初始化后必须启用三件套：`set_toolbar_interactive( )`、`set_ready_for_input( 1 )`、`register_edit_event( mc_evt_modified )`。
- DDIC 一致性：
  - 仅使用真实字段（如 SFLIGHT: `fldate,carrid,connid,planetype,seatsmax,seatsocc,price,currency`）。
  - 必填字段与业务校验（如 `seatsocc < seatsmax`、数值非负）。
  - 新增默认值与保存校验逻辑一致。
- 数值类型：
  - P 类型目标：整数赋值（两位小数时 `599` 表示 599.00）或显式 `CONV decfloat34()`。
  - 禁止字符字面量给数值字段。
- 文本元素与消息：
  - 引用的 `text-xxx`、消息文本必须存在；优先 ABAP Doc/文本元素而非硬编码字符串。
- 质量工具：
  - VS Code abaplint 已启用：`check_syntax`、`strict_sql`、`sql_escape_host_variables`、`check_text_elements` 等。
  - PR 会自动跑 abaplint 工作流，问题会在合并前被阻断。
