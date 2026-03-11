# ABAP Keyword Documentation 学习指南（离线版）

面向 ABAP 7.54 的离线关键字文档，涵盖语法、运行时、数据字典、CDS、GUI 事件与最佳实践。本文提供学习路径与常用入口，帮助你高效查阅与系统学习。

## 快速入口

- 打开总目录树： [abap_docu_tree.htm](abap_docu_tree.htm)
- 站点地图（外链索引）： [abap_docu_sitemap.xml](abap_docu_sitemap.xml)
- 参考入口（示例）：
    - 赋值与字段符号： [abapassign.htm](abapassign.htm)
    - 内表追加与排名： [abapappend.htm](abapappend.htm)
    - 函数模块调用： [abapcall_function_general.htm](abapcall_function_general.htm)
    - 选择屏事件： [abapat_selection-screen.htm](abapat_selection-screen.htm)
    - 数据库表与属性： [abenddic_database_tables.htm](abenddic_database_tables.htm)
    - CDS 语法总览： [abencds_syntax.htm](abencds_syntax.htm)

## 学习路径（从入门到进阶）

1) 入门与运行环境
- 语言概览与语句总览：从目录树进入“ABAP - Overview”。
- 会话与内存：用户会话、内部会话、内存区域概念。

2) 数据字典（ABAP Dictionary）
- 数据元素、域、结构、表类型的技术/语义属性。
- 数据库表：键、客户端依赖、索引、缓冲、交付类、维护与转换。
- 经典视图与外部视图、增强与替换对象。

3) 处理内部数据与内表
- 字段符号与 `ASSIGN`：理解 `mem_area`、`CASTING`、`RANGE` 与 `IS ASSIGNED` 检查。
- 内表处理：`APPEND`、主/次键、`SORTED BY` 排名、`INITIAL SIZE` 行为与性能影响。

4) 过程调用与异常
- 函数模块 `CALL FUNCTION`：参数表与动态调用，安全校验（动态名称必须白名单/校验）。
- 异常模型：各关键字页列出可处理/不可处理异常与典型运行时错误码。

5) SAP GUI 选择屏
- 事件块 `AT SELECTION-SCREEN` 与事件顺序；子屏触发两次事件的特性；事件块中的声明产生局部数据。

6) ABAP CDS（进阶）
- 语法、注解、作用域；数据定义、视图、表函数；客户端处理与缓冲策略。
- 避免使用过时客户端处理模式，遵循最新注解与框架规范。

7) 巩固与练习
- 跟随每页“Example/Executable Example”动手实现；用“Exceptions”部分刻意演练错误复现与定位。

## 常见要点与易错提醒

- `ASSIGN` 对齐与深类型：`CASTING` 时长度与对齐必须匹配；深结构的组件布局需完全一致，否则抛异常。
- 动态调用安全：外部传入名称必须严格校验；动态评估在运行期发生，错误多为运行时而非语法时。
- 内表键与排序：唯一次键的重复将抛出异常；排序表需保持序；`SORTED BY` 仅标准表且指定工作区适用。
- 系统字段：`APPEND` 更新 `sy-tabix`；`ASSIGN` 的动态/表表达式更新 `sy-subrc`。

## 本地使用建议

- 入口建议从 [abap_docu_tree.htm](abap_docu_tree.htm) 打开，跟随左侧树导航浏览。
- 页内搜索：浏览器 `Ctrl+F`；跨页搜索：文档内的搜索输入框与 `search.htm`。
- 直达某关键字页：使用 `index.htm?file=<文件名>`（例如 `index.htm?file=abapassign.htm`）。

## 物理目录结构与兼容性

- 新的分类目录：
    - [docs/core](docs/core) — `abap*.htm`
    - [docs/advanced](docs/advanced) — `aben*.htm`
    - [docs/ui](docs/ui) — `dynp*.htm`
- 链接兼容：
    - 所有页内链接仍以原始文件名（如 `abapassign.htm`）传递，框架脚本会自动解析到新目录。
    - 导航树与搜索保持可用；`file` 查询参数继续使用原始文件名。
- 资源可用性：为确保相对路径引用，必要资源（`abap_docu.css`、`functions.js`、`ABAPIcon.ico`、`exa.gif`）已在各目录内复制。
 - 图片集中存放：所有图片已集中至 [assets/images](assets/images)，并通过脚本自动重写页内图片与图标链接；同时为兼容旧相对引用保留必要资源副本。

## 术语与文件命名速查

- `*_shortref`：快速参考；`*_abexa`：示例；`*_guidl`：指南；`*_glosry`：术语；`*_obsolete`：过时。
- 前缀约定：`abap*`（关键字）、`aben*`（扩展专题/总览）、`dynp*`（屏幕编程）。

## 版权与使用

- 文档内容来源于 SAP 官方 ABAP 关键字文档，仅供学习与参考。
- 如需最新版本或商业使用，请以 SAP 官方门户为准（https://help.sap.com）。

---

如需我为特定主题制作速查卡或练习题，请提出你的关注点（例如 CDS、内表性能、选择屏事件等），我会补充到本指南并链接到对应页面。
