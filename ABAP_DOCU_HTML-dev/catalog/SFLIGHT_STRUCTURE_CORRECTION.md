# SFLIGHT 表结构修正说明

## 问题识别

通过对比 SAP 标准数据字典（https://www.sapdatasheet.org/abap/），发现 `ABAP_ALV_Example.abap` 中的 SFLIGHT 表结构定义存在以下错误：

### 错误字段

以下字段在 SFLIGHT 表中**不存在**：

| 字段名 | 原因 | 正确做法 |
|--------|------|---------|
| `BOOKID` | SFLIGHT 是航班主表，预订信息在 SBOOK 表中 | 删除此字段 |
| `CUSTNAME` | 客户名称不在 SFLIGHT 中，应关联 SBOOK 或客户主表 | 删除此字段 |
| `STATUS` | SFLIGHT 没有状态字段（A/C）| 删除此字段 |

## 修正内容

### SFLIGHT 正确字段清单（核心字段）

根据 SAP 数据字典标准，SFLIGHT 表包含以下关键字段：

```
MANDT       - 客户端 (type CLNT)
CARRID      - 航空公司代码 (type CHAR4) [KEY]
CONNID      - 航班号 (type CHAR4) [KEY]
FLDATE      - 航班日期 (type DATE) [KEY]
PRICE       - 价格 (type CURR)
CURRENCY    - 货币代码 (type CUKY)
PLANETYPE   - 飞机型号 (type CHAR8)
SEATSMAX    - 最大座位数 (type INT4)
SEATSOCC    - 已占座位数 (type INT4)
PAYMENTSUM  - 支付总额 (type CURR)
TAXYFARE    - 税费 (type CURR)
```

### 修正的 TY_FLIGHT 结构

```abap
TYPES: BEGIN OF ty_flight,
         fldate    TYPE sflight-fldate,      "航班日期
         carrid    TYPE sflight-carrid,      "航空公司
         connid    TYPE sflight-connid,      "航班号
         planetype TYPE sflight-planetype,   "飞机型号
         seatsmax  TYPE sflight-seatsmax,    "最大座位数
         seatsocc  TYPE sflight-seatsocc,    "占座数
         price     TYPE sflight-price,       "价格
         currency  TYPE sflight-currency,    "货币
       END OF ty_flight.
```

### 修正的 SELECT 语句

**之前（错误）：**
```abap
SELECT fldate carrid connid
       '        ' as bookid
       'Passenger' as custname
       seatsocc price currency
       'A' as status
  FROM sflight ...
```

**之后（正确）：**
```abap
SELECT fldate carrid connid planetype seatsmax seatsocc price currency
  FROM sflight ...
```

### 修正的示例数据

**字段目录（pf_build_fieldcat）：**
- 删除：CUSTNAME 字段
- 删除：STATUS 字段
- 新增：PLANETYPE 字段
- 新增：SEATSMAX 字段

**新增行数据（ADD_ROW）：**
```abap
ls_flight-planetype = '320'.    "飞机型号
ls_flight-seatsmax  = 180.      "最大座位数
```

**保存验证（pf_save_changes）：**
- 添加验证：`seatsocc` 不能超过 `seatsmax`
- 改进必填字段检查

## 影响范围

修正涉及以下子程序（FORM）：

| 子程序名 | 修改项 | 说明 |
|---------|--------|------|
| pf_load_data | SELECT 语句 | 调整查询字段列表 |
| pf_load_data | 示例数据 | 更新 VALUE 构造函数中的字段值 |
| pf_build_fieldcat | 字段目录定义 | 调整为 8 个字段（删除 2 个，新增 2 个） |
| pf_on_toolbar | ADD_ROW 逻辑 | 更新示例数据为正确字段 |
| pf_on_data_changed | 验证逻辑 | 添加座位数上限检查说明 |
| pf_save_changes | 必填字段校验 | 添加座位数与最大座位数关系验证 |

## 设计考虑

### SFLIGHT vs SBOOK 关系

- **SFLIGHT**：航班信息主表（航班日期、路线、飞机类型、可用座位）
- **SBOOK**：预订信息表（客户、预订号、座位分配）

本示例仅演示 SFLIGHT 表的 CRUD 操作。如需完整的客户-航班-预订关系，应：

```abap
SELECT f~* b~custtype b~smoker
  FROM sflight AS f
  LEFT JOIN sbook AS b ON f~carrid = b~carrid
                      AND f~connid = b~connid
                      AND f~fldate = b~fldate ...
```

### 字段选择说明

选定的 8 个字段用于：

| 字段 | 用途 | 编辑 |
|-----|------|------|
| FLDATE | 航班日期唯一标识 | 否（主键） |
| CARRID | 航空公司唯一标识 | 否（主键） |
| CONNID | 航班号唯一标识 | 否（主键） |
| PLANETYPE | 展示飞机信息 | 否 |
| SEATSMAX | 座位限制约束 | 否 |
| SEATSOCC | 实时座位占用 | **是** |
| PRICE | 票价信息 | **是** |
| CURRENCY | 货币单位 | 否 |

可编辑字段：SEATSOCC（实际座位变化）、PRICE（价格调整）

## 学习要点

### ABAP 类型安全

此修正突出了 ABAP 的**强类型特性**：

```abap
"类型检查在编译时进行
custname  TYPE char30,    "定义不存在的字段会在编译时报错
            ↓
bookid    TYPE sflight-bookid.  "参考不存在的字段也会报错
```

### SAP 数据字典的重要性

- 永远参考标准数据字典（https://www.sapdatasheet.org 或 ABAP 开发环境中的 SE11 事务码）
- 不应凭记忆编写表结构
- 使用 `TYPES: ... TYPE <table>-<field>` 确保字段定义的一致性

### 版本兼容性

本修正基于 SAP ECC 6.0+ 及 S/4HANA 的标准 SFLIGHT 表结构，适用于：

- ABAP 7.40+
- SAP NetWeaver 7.4+
- S/4HANA 2020+

## 验证方法

### 方法 1：在 SAP 系统中验证

```abap
DATA: ls_flight TYPE sflight.
SELECT SINGLE *
  FROM sflight
  INTO ls_flight
  WHERE carrid = 'LH'
  AND   connid = '0400'
  AND   fldate = sy-datlo.
```

### 方法 2：检查数据字典（SE11）

SAP 事务码 → SE11 → 输入 "SFLIGHT" → 点击 "Display"

显示的字段列表应与本文档一致。

### 方法 3：使用 DDIC 函数

```abap
CALL FUNCTION 'DDIF_TABL_GET'
  EXPORTING
    name          = 'SFLIGHT'
    langu         = sy-langu
    withtext      = 'X'
  IMPORTING
    dd04v_tab     = lt_fields.
```

## 提交日志

- **提交哈希**：5257ed7
- **分支**：dev
- **日期**：2025-12-23
- **更改文件**：ABAP_ALV_Example.abap
- **插入**：33 行
- **删除**：29 行

## 后续改进建议

1. **多表关联示例**：创建 SFLIGHT + SBOOK 关联查询示例
2. **RTTI 动态验证**：使用 Runtime Type Information 验证字段有效性
3. **数据字典缓存**：实现本地元数据缓存，减少对系统 DDIC 的调用
4. **国际化支持**：添加语言相关字段（LANGU）的处理

---

*本文档维护：GitHub Copilot | 最后更新：2025-12-23*
