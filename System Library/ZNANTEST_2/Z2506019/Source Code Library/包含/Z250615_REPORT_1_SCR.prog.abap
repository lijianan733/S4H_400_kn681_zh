*&---------------------------------------------------------------------*
*& Include z250615_report_1_scr
*&---------------------------------------------------------------------*
 selection-screen begin of block b01 with frame title text-001.
   selection-screen skip.

   parameters: p_number like bapimepoheader-po_number,
               p_dotype like bapimepoheader-doc_type default 'ZIV', " 采购凭证类型

               p_docdat like bapimepoheader-doc_date default sy-datum, " 文档日期,
               p_crdate like bapimepoheader-creat_date default sy-datum, " 创建日期,
               p_crdaby like bapimepoheader-created_by default sy-uname,
               p_itemin like bapimepoheader-item_intvl default '10', " 项目编号间隔
               p_vendor like bapimepoheader-vendor     default '0000000797', " 供应商代码
               p_reswk  like bapimepoheader-suppl_plnt default '8701', " 拣配工厂
               p_loct_2 like bapimepoitem-stge_loc default '0001', " 拣配的库位
               p_status like bapimepoheader-status default '9', " 采购凭证的状态

*            P_LANGU  LIKE  BAPIMEPOHEADER-LANGU,
*            p_pmnttr like bapimepoheader-pmnttrms   default 'COD', " 收付条件代码
               p_purch  like bapimepoheader-purch_org  default '7801', " 采购组织代码
               p_purgr  like bapimepoheader-pur_group  default '781', " 采购组代码
               p_cocode like bapimepoheader-comp_code default '7788', " 公司代码
               p_vatcn  like bapimepoheader-vat_cntry  default 'CNY'. " 税务国家代码
 selection-screen end of block b01.
 selection-screen begin of block b02 with frame title text-002.
   " ITEM
   selection-screen skip.
   parameters: p_poitem like bapimepoitem-po_item default '10',
               p_matnr  like bapimepoitem-material default '11680', " 物料
               p_plant  like bapimepoitem-plant default '7801', " 收货工厂
               p_loct   like bapimepoitem-stge_loc default '0001', " 收货库存地点
               p_quanti like bapimepoitem-quantity default '10.00', " 数量
*            P_NETPRI LIKE BAPIMEPOITEM-NET_PRICE,
*            P_PRICEU LIKE BAPIMEPOITEM-PRICE_UNIT,
               p_rename like bapimepoitem-preq_name default sy-uname,
               p_prdate like bapimepoitem-period_ind_expiration_date default 'D'. " 货架存放期过期日期的期间标识
 selection-screen end of block b02.

 selection-screen begin of block b03 with frame title text-003.
   selection-screen skip.
   parameters: p_posnr type ekpo-ebelp default '00010', " 行号
               p_vstel like likp-vstel default '8701', " 装运点/收货点,
               p_vdatu type ledat default sy-datum.   " 交货日期
 selection-screen end of block b03.
