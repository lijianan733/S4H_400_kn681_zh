# S4H_400_kn681_zh 工作区说明

本工作区是“远程 ABAP 项目为主，本地文档为辅”的混合工作区：

- 远程主项目：`adt://mysap/`（ABAP FS 远程系统对象）
- 本地辅助资料：`ABAP_DOCU_HTML-dev/`（离线文档与学习索引）

## 快速入口

- 离线文档主页：`ABAP_DOCU_HTML-dev/index.htm`
- 文档目录树：`ABAP_DOCU_HTML-dev/abap_docu_tree.htm`
- 学习指南：`ABAP_DOCU_HTML-dev/README.md`
- 分类目录索引：`ABAP_DOCU_HTML-dev/catalog/CATALOG.md`

## 目录说明

- `adt://mysap/`
	- 远程 ABAP 项目主目录（实际开发与维护对象所在位置）。
- `$TMP/`、`Source Code Library/`、`System Library/`
	- 远程系统内对象分类目录（包、程序、类、事务等）。
- `ABAP_DOCU_HTML-dev/`
	- ABAP 关键字离线文档、导航页面、搜索页面、资源文件。
- `ABAP_DOCU_HTML-dev/catalog/`
	- 按主题整理的指南、规范、示例与速查资料。
- `AI_test/`
	- AI 新生成代码暂存目录（用于隔离、评审与验证后再合并到正式对象）。

## 远程项目注意事项

1. 代码主修改目标应优先定位在 `adt://mysap/` 下的对象。
2. 本地目录 `ABAP_DOCU_HTML-dev/` 主要用于查文档，不代表远程系统真实源码。
3. 远程对象修改后需按 ABAP 开发流程进行激活与验证（如语法检查、单元测试）。

## 建议使用方式

1. 先在远程项目中确认要修改的对象（`adt://mysap/`）。
2. 再使用 `ABAP_DOCU_HTML-dev/index.htm` 与 `ABAP_DOCU_HTML-dev/README.md` 作为语法与规范参考。
3. 变更后执行必要验证，再进行提交与传输流程。

## 开发规范

- 规范 01：所有远程 ABAP 对象在提交前必须完成“激活 + 基础验证”（至少包含语法检查，若有单元测试则需执行并通过）。
- 规范 02：凡使用 AI 生成代码，必须逐一核对关联业务对象（如类、函数、表、CDS）的参数定义、业务作用与调用影响，确认后方可提交。

## 远程项目可访问范围（记录）

- 当前已连接系统：`mysap`
- 可执行操作：
	- 检索 ABAP 对象（类、程序、表、CDS、接口、函数组等）
	- 读取与修改对象源码（含类方法级别提取）
	- 查询对象元数据、版本历史与差异对比
	- 执行 where-used 引用分析
	- 运行单元测试与 ATC 检查
	- 查询传输请求及其对象清单
	- 分析运行时 dump 与性能 trace
	- 通过 ABAP SQL 查询业务数据

## 备注

如需，我可以继续把这个 README 扩展为团队版模板（包含开发规范、提交流程、检查清单、FAQ）。
