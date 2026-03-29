已读取文档内容如下：

# 功能说明书：发货清单查询报表

## 1. 功能说明概览
- **需求名称**：发货清单查询报表
- **所属模块**：MM, PP, SD, FI, CO, CA
- **开发类型**：报表 (ALV)
- **开发难度**：中
- **业务背景**：查询系统中的交货单清单以 ALV 展现，并支持导出等标准功能。

## 2. 处理逻辑
### 表关联关系
- **LIKP-VBELN = LIPS-VBELN**
- **VBAK-VBELN = VBAP-VBELN**
- **通过销售订单找交货单**：LIPS-VGBEL = VBAK-VBELN
- **通过交货单找SAP发票**：VBRP-VGBEL = LIPS-VBELN

## 3. 选择屏幕字段
- **组织数据**：
    - 销售组织 (VBAK-VKORG) - 必输
    - 分销渠道 (VBAK-VTWEG) - 必输
- **销售相关**：
    - 订单类型 (VBAK-AUART)
    - 送达方 (LIKP-KUNNR)
    - 销售订单号 (LIPS-VGBEL)
    - 客户单号 (VBAK-BSTNK)
    - 物料编码 (LIPS-MATNR)
- **交货单相关**：
    - 发货工厂 (LIPS-WERKS)
    - 库存地点 (LIPS-LGORT)
    - 交货单号码 (LIKP-VBELN)
    - 发货状态 (LIKP-WBSTA)

## 4. ALV 输出字段 (部分摘录)
- **交货单号** (LIKP-VBELN)
- **销售组织/描述** (LIKP-VKORG)
- **售达方/送达方及描述** (LIKP-KUNAG, LIKP-KUNNR)
- **物料/描述/物料组** (LIPS-MATNR, LIPS-ARKTX, MARA-MATKL)
- **交货数量** (LIPS-LFIMG)
- **交货金额** (计算逻辑：交货单数量 * (VBAP-KZWI1 / VBAP-KWMENG))
- **是否发货/发货日期** (LIKP-WBSTK, LIKP-WADAT_IST)
- **发票号码/发票行** (VBRP-VBELN, VBRP-POSNR)
- **业务员名称** (通过 VBPA-PARVW = 'SA' 关联 KNA1-NAME1)

## 5. 特殊逻辑
- **交货单备注**：通过 `READ_TEXT` 函数读取，文本对象 `VBBK`，文本 ID `0001`。
- **地址信息**：通过 `VBPA-ADRNR` 关联 `ADRC` 表获取街道、省份、城市等。
- **双击跳转**：支持双击订单、交货单跳转显示单据。
