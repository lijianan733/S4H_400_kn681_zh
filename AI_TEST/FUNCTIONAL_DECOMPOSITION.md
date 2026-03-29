# 发货清单查询报表 - 功能分解列表 (Functional Decomposition)

根据需求文档 `CW_FS_SDA10  发货清单查询_SD内销组_V1.0_20201114.docx`，功能分解如下：

## 1. 选择屏幕 (Selection Screen)
### 1.1 组织数据 (必输项)
- [ ] **销售组织**：S_VKORG (VBAK-VKORG)，带权限控制。
- [ ] **分销渠道**：S_VTWEG (VBAK-VTWEG)。
### 1.2 销售单据相关
- [ ] **订单类型**：S_AUART (VBAK-AUART)。
- [ ] **送达方**：S_KUNNR (LIKP-KUNNR)。
- [ ] **销售订单号**：S_VGBEL (LIPS-VGBEL)。
- [ ] **客户单号**：S_BSTNK (VBAK-BSTNK)。
- [ ] **物料编码**：S_MATNR (LIPS-MATNR)。
### 1.3 交货单据相关
- [ ] **发货工厂**：S_WERKS (LIPS-WERKS)。
- [ ] **库存地点**：S_LGORT (LIPS-LGORT)。
- [ ] **交货单号**：S_VBELN (LIKP-VBELN)。
- [ ] **交货单创建日期**：S_ERDAT (LIKP-ERDAT)。
- [ ] **发货状态**：S_WBSTA (LIKP-WBSTA)。

## 2. 数据获取逻辑 (Data Retrieval)
### 2.1 核心关联
- [ ] 以 `LIPS`/`LIKP` 为核心，通过 `VBELN` 关联。
- [ ] 关联 `VBAK`/`VBAP` 获取销售订单信息（`LIPS-VGBEL` = `VBAK-VBELN`）。
- [ ] 关联 `VBRP`/`VBRK` 获取发票信息（`VBRP-VGBEL` = `LIPS-VBELN`）。
### 2.2 扩展信息获取
- [ ] **主数据描述**：获取销售组织描述、分销渠道描述、物料描述、工厂/库位描述。
- [ ] **客户地址**：通过 `VBPA-ADRNR` (WE/AG角色) 关联 `ADRC` 表获取省/市/街道。
- [ ] **交货备注**：调用 `READ_TEXT` (Object: `VBBK`, ID: `0001`)。
- [ ] **业务员获取**：通过 `VBPA-PARVW = 'SA'` 获取人员编号及其姓名。

## 3. 数据处理与计算 (Logic & Calculation)
- [ ] **交货金额计算**：`LIPS-LFIMG` * (`VBAP-KZWI1` / `VBAP-KWMENG`)。
- [ ] **发货状态转换**：将 `LIKP-WBSTK` 的 'A'/'C' 转换为中文描述。
- [ ] **差异数量**：从 `TVPOD` 表获取。

## 4. ALV 报表功能 (Presentation)
- [ ] **基础展示**：动态构建 Fieldcat，展示中文列标题。
- [ ] **工具栏功能**：启用 查找、过滤、求和、导出 (Excel/PDF)。
- [ ] **交互跳转 (Hotspot)**：
    - [ ] 点击 **销售订单号** 跳转 `VA03`。
    - [ ] 点击 **交货单号** 跳转 `VL03N`。
    - [ ] 点击 **发票号码** 跳转 `VF03`。

## 5. 其他约束 (Constraints)
- [ ] **权限检查**：需要对销售组织 (V_VBAK_VKO) 进行权限预检查。
- [ ] **性能优化**：对多重表关联和大批量 `READ_TEXT` 需注意性能处理。
