*&---------------------------------------------------------------------*
*& Report z250619
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
report z250619_report_2.
 selection-screen begin of block b02 with frame title text-002.
  PARAMETERS: p_number LIKE bapimepoheader-po_number,
            p_dotype LIKE bapimepoheader-doc_type DEFAULT 'ZIV',

            p_docdat LIKE bapimepoheader-doc_date DEFAULT sy-datum, " 文档日期,
            p_crdate LIKE bapimepoheader-creat_date DEFAULT sy-datum, " 创建日期,
            p_crdaby LIKE bapimepoheader-created_by DEFAULT sy-uname,
            p_itemin LIKE bapimepoheader-item_intvl DEFAULT '10', " 项目编号间隔
            p_vendor LIKE bapimepoheader-vendor     DEFAULT '0000000797', " 供应商代码
            p_reswk  LIKE bapimepoheader-suppl_plnt DEFAULT '8701', " 转储单的供应(发出)工厂
            p_status LIKE bapimepoheader-status DEFAULT '9', " 采购凭证的状态

*            P_LANGU  LIKE  BAPIMEPOHEADER-LANGU,
*            p_pmnttr like bapimepoheader-pmnttrms   default 'COD', " 收付条件代码
            p_purch  LIKE bapimepoheader-purch_org  DEFAULT '7801', " 采购组织代码
            p_purgr  LIKE bapimepoheader-pur_group  DEFAULT '781', " 采购组代码
            p_cocode LIKE bapimepoheader-comp_code DEFAULT '7788', " 公司代码
            p_vatcn  LIKE bapimepoheader-vat_cntry  DEFAULT 'CNY'.
  selection-screen end of block b02.

" ME21N-PO采购单创建（采购订单、转储订单）
