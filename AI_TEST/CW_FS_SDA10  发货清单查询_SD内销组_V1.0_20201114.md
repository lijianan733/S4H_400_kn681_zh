# CW_FS_SDA10 发货清单查询_SD内销组_V1.0_20201114

|创维集团企业信息化（一期）项目组SAP ERP系统实施子项目CW_FS_SDA10 发货清单查询功能开发说明书|
|---|

文档更改历史

|修改日期 | 版本 | 描述 | 更改者|
|--- | --- | --- | ---|
|2020-11-14 | V1.0 | 创建 | 李晓波|
| |  |  | |
| |  |  | |
| |  |  | |
| |  |  | |
| |  |  | |

|功能说明概览|
|---|
|需求名称 | 发货清单查询报表|
|所属模块 | MM PP SDFI   CO CA(跨模块) | 业务顾问 | |
| |  | 邮箱 | |
|运行频率 | 实时    随时    天     周      月     年|
|开发类型 | 报表    增强  接口   功能   表单   其他|
|优先级 | 高    中    低 | 预计使用时间 | |
| |  | 开发难度 | 中|

功能详细说明

业务背景及开发目的说明

[本章节说明业务背景及开发目的]

查询系统中的交货单清单以ALV 展现，并可以导出等ALV 基本功能

输入参数和所需外部数据及屏幕格式说明

[本章节说明报表或表单类开发项的程序查询界面。增强、功能和接口等类型的开发项，此章节留空，改为集中在第4点“处理逻辑、功能性详细说明”中予以说明]

输出参数说明及输出结果要求

[本章节说明报表或表单类的程序输出结果，可罗列字段、列式表格或嵌入Excel输出样张附件予以说明；增强、功能和接口等类型的开发项，此章节留空，改为集中在第4点“处理逻辑、功能性详细说明”中予以说明]

逻辑：

逻辑：

本报表主要应用交货单执行情况的统计分析，包含了交货对应的销售订单的所有基本数据主要包含的数据表有LIKP,LIPS VBAK,VBAP, VBRK,VBRP等，

1报表中相应的单据：订单、交货单双击进去可以进行显示

基于LIKP、LIPS 关联其他表(先找LIKP，LIPS 表，通过这两张表找其他表

以交货单维度ALV展现

表关联：

LIKP-VBELN=LIPS-VBELN,

VBAK-VBELN=VBAP-VBELN

通过销售订单 找交货单：

LIPS- VBELN 交货单号

LIPS- POSNR 交货单行项目

LIPS- VGBEL 销售订单

LIPS- VGPOS  销售订单行项目

通过交货单找SAP发票：

VBRP- VBELN  SAP 发票号

VBRP- POSNR  SAP 发票行项目

VBRP- VGBEL 交货单号

VBRP- VGPOS 交货单行项目

选择界面

|组织数据 |  |  |  |  | |
|--- | --- | --- | --- | --- | ---|
| | 销售组织 | VBAK-VKORG | 到 | 必输（做权限控制） | |
| | 分销渠道 | VBAK-VTWEG | 到 | 必输 | |
| |  |  |  |  | |
| |  |  |  |  | |
|销售相关 |  |  |  |  | |
| | 订单类型 | VBAK-AUART | 到 |  | |
| | 送达方 | LIKP-KUNNR | 到 |  | |
| | 销售订单号 | LIPS-VGBEL | 到 |  | |
| | 客户单号 | VBAK-BSTNK | 到 |  | |
| | 订单创建日期 | VBAK-ERDAT | 到 |  | |
| | 创建者 | VBAK-ERNAM | 到 |  | |
| | 物料编码 | LIPS- MATNR | 到 |  | |
| |  |  |  |  | |
| |  |  |  |  | |
|交货单 |  |  |  |  | |
| | 发货工厂 | LIPS- WERKS | 到 |  | |
| | 仓库 | LIPS-LGORT |  |  | |
| | 交货单号码 | LIKP-VBELN |  |  | |
| | 交货单项目 | LIPS-POSNR | 到 |  | |
| | 交货单建立日期 | LIKP- ERDAT | 到 |  | |
| | 实际发货日期 |  |  |  | |
| | 发货状态 | LIKP- WBSTA |  |  | |
| | 发货日期 | LIKP- ADAT_IST |  |  | |
| | 签收状态 | LIKP- PDSTK |  |  | |
| | 签收日期 | LIKP-PODAT |  |  | |
| |  |  |  |  | |

ALV 报表中相应的单据：订单双击进去可以进行显示

|栏位 | 字段 | 逻辑|
|--- | --- | ---|
|交货单号 | LIKP- VBELN | 当 VBAK-VBELN =LIKP-VGBEL,AND VBAP- POSNR =LIKP- VGPOS 取  LIKP- VBELN|
|公司编码 | TVKO-BUKRS | 销售组织=TVKO-VKORG， 取TVKO-BUKRS为公司代码|
|公司描述 | T001-BUTXT | TVKO-BUKRS=T001 -BUKRS,取 T001-BUTXT|
|销售组织 | LIKP-VKORG | |
|销售组织描述 |  | LIKP-VKORG= TVKO- VKORG，取  TVKO- VTEXT|
|分销渠道 | LIKP-VTWEG | |
|分销渠道描述 |  | VBAK-VTWEG=TVTW-VTWEG  取  TVTW-VTEXT|
|销售区域 | LIKP-VKBUR | LIKP-VKBUR =TVBUR-VKBUR,取   TVBUR-BEZEI|
|交货类型 | TVLK-VTEXT | LIKP-LFART =TVLK-LFART，取 TVLK-VTEXT|
|自提/送货 | TVSAK - BEZEI | LIKP-SDABW =TVSAK -SDABW， 取 TVSAK - BEZEI|
|送货单号 | LIKP-BOLNR | |
|售达方 | LIKP- KUNAG | |
|售达方描述 | KAN1-NAME1+ KNA1-NAME2 | LIKP- KUNAG =KNA1-KUNNR,取 KAN1-NAME1+ KNA1-NAME2|
|送达方 | LIKP- KUNNR | |
|送达方描述 | KAN1-NAME1+ KNA1-NAME2 | lips-VBELN=VBPA-VBELN,AND   VBPA-PARVW=WE,取 VBPA-ADRNR=ADRC- ADDRNUMBER,取 ADRC-NAME1 & NAME2|
|交货单备注 | 通READTXT 函数读取文本对象 VBBK文本ID   0001 | |
|收货方地址 | ADRC- MC_STREET | 交货单地址界面街道门牌号LIKP-VBELN=VBPA- VBELN, 当VBPA- PARVW=”WE”,取VBPA-ADRNR= ADRC-ADDRNUMBER,取  ADRC- MC_STREET|
|交货单建立人 | LIKP-ERNAM | |
|交货单建立日期 | LIKP-ERDAT | |
|交货单行号 | LIPS- POSNR | |
|交货单物料 | Lips- MATNR | |
|物料描述 | Lips-ARKTX | |
|物料组 | MARA- MATKL | Lips- MATNR =MARA- MATNR,取MARA- MATKL|
|物料组描述 | V023-WGBEZ | MARA- MATKL=V023 -MATKL,取 V023-WGBEZ|
|交货单数量 | LIPS-LFIMG | |
|交货金额 |  | 【交货单数量】*【 VBAP- KZWI1除以 VBAP-KWMENG】|
|工厂 | LIPS- WERKS | |
|工厂描述 | T001W-NAME1 | LIPS- WERKS  =T001W-WERKS,取T001W-NAME1|
|仓库 | LIPS-LGORT | |
|仓库描述 | T001L-LGOBE | LIPS-LGORT= T001L- LGORT,and     LIPS- WERKS=  T001L -WERKS,取 T001L-LGOBE|
|是否发货 | LIKP- WBSTK | A ：显示“未发货”   C ：显示“已发货”|
|发货日期 | LIKP-WADAT_IST | 如果【是否发货】栏位为 C , 则取 LIKP-WADAT_IST|
|是否签收 | LIKP- PDSTK | A ：显示“未签收”   C ：显示“已签收”|
|签收日期 | LIKP-PODAT | |
|差异数量 | TVPOD – LFIMG_DIFF | LIKP- VBELN= TVPOD – VBELN，取 TVPOD – LFIMG_DIFF|
|发票号码 | VBRP-VBELN | LIPS-VBELN=VBRP-VGBEL,AND LIPS-POSNR = VBRP-VGPOS,取 VBRP-VBELN|
|发票行 | VBRP-POSNR | |
|发票数量 | VBRP - FKIMG | |
|是否开金税 |  | |
|销售订单号 | LIPS-VGBEL | |
|客户单号 | VBAK-BSTNK | |
|订单类型 | VBAK-AUART | |
|订单类型描述 | TVAK-BEZEI | |
|业务员编码 |  | VBAK-VBELN= VBPA- VBELN ,  VBPA- PARVW=SA， 取  VBPA- KUNNR|
|业务员名称 |  | VBPA- KUNNR =KNA1-KUNNR,取 KNA1-NAME1|
|凭证货币 | VBAK-WAERK | |
|付款方式 | VBKD-ZTERM | VBAK-VBELN=VBKD-VBELN取   VBKD-ZTERM|
|付款方式说明 | TVZBT-VTEXT | VBKD-ZTERM =TVZBT- ZTERM，且  TVZBT-SPRAS=ZH,取  TVZBT-VTEXT|
|订单创建日期 | VBAK-ERDAT | |
|创建者 | VBAK-ERNAM | |
|国家 | ADRC-LAND1 | lips-VBELN=VBPA-VBELN,AND   VBPA-PARVW=WE,取 VBPA-ADRNR=ADRC- ADDRNUMBER,取 ADRC-LAND1|
|省份 | ADRC-LAND1 | lips-VBELN=VBPA-VBELN,AND   VBPA-PARVW=WE,取 VBPA-ADRNR=ADRC- ADDRNUMBER,取 ADRC -BEZEI|
|城市 | ADRC-LAND1 | lips-VBELN=VBPA-VBELN,AND   VBPA-PARVW=WE,取 VBPA-ADRNR=ADRC- ADDRNUMBER,取 ADRC- ORT01|
|销售订单行号 | LIPS- VGPOS | |
|物料组 | MARA- MATKL | VBAP- MATNR=MARA- MATNR,取MARA- MATKL|
|物料组描述 | V023-WGBEZ | MARA- MATKL=V023 -MATKL,取 V023-WGBEZ|
|订单数量 | VBAP-KWMENG | |
|销售单位 | VBAP-VRKME | |
|销售单价 | VBAP- KZWI1除以 VBAP-KWMENG | |
|销售订单总价 | VBAP- KZWI1 | |
|税额 | VBAP-MWSBP | |
| |  | |
| |  | |

处理逻辑、功能性详细说明

[本章节说明开发项的处理逻辑、功能性详细说明]

PO接口字段详细说明

[本章节仅用于使用PO中间件的接口开发，按PO接口文档规范填写PO接口文档，并在此嵌入该文档]

相关权限及依赖

|权限对象 | 字段 | 值|
|--- | --- | ---|
| |  | |
| |  | |

参考事务代码

|事务代码 | 描述 | 备注|
|--- | --- | ---|
| |  | |
| |  | |
| |  | |
| |  | |

开发测试数据（说明已经在开发环境准备好的可供程序员测试的数据）

[本章节提供已经在开发环境准备好的可供程序员测试的数据，测试数据需涵盖典型测试案例，可通过嵌入Excel附件方式提供，确保开发人员在开发测试时能充分考虑这些测试案例]

|技术说明概览|
|---|
|程序名称 | |
|开发者 |  | 邮箱 | |
|开始开发时间 |  | 预计开发人天 | |
|权限控制 |  | T-CODE | |

技术详细说明

程序涉及数据库表说明

程序涉及方法 类/FUNCTION/增强点说明

关键逻辑说明

