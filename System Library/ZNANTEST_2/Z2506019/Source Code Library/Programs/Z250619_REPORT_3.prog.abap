*&---------------------------------------------------------------------*
*& Report z250619_report_3
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z250619_report_3.

TABLES bapimepoheader.


DATA wa_poheader  TYPE bapimepoheader.  " 所要增加的内容
DATA wa_poheaderx TYPE bapimepoheaderx. " 针对要增加的内容做一个标记,其实标记过了才可以被修改的
DATA wa_poitem    TYPE bapimepoitem.    " po中item的内容,工作区
DATA itab_poitem  LIKE TABLE OF wa_poitem.                    " PO中ITEM的内容,内表

DATA wa_poitemx   TYPE bapimepoitemx.   " po中item增加内容的标记 工作区
DATA itab_poitemx LIKE TABLE OF wa_poitemx.                    " po中item增加内容的标记 内表
DATA wa_return    TYPE bapiret2.        " 消息 返回 ,工作区
DATA itab_return  LIKE TABLE OF wa_return.                    " 消息返回, 内表

*HEADER.
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
" ITEM
SELECTION-SCREEN SKIP.
PARAMETERS: p_poitem LIKE bapimepoitem-po_item DEFAULT '10',
            p_matner LIKE bapimepoitem-material DEFAULT '11680', " 物料
            p_plant  LIKE bapimepoitem-plant DEFAULT '7801', " 工厂
            p_loct   LIKE bapimepoitem-stge_loc DEFAULT '0001', " 库存地点
            p_quanti LIKE bapimepoitem-quantity DEFAULT '100.00', " 数量
*            P_NETPRI LIKE BAPIMEPOITEM-NET_PRICE,
*            P_PRICEU LIKE BAPIMEPOITEM-PRICE_UNIT,
            p_rename LIKE bapimepoitem-preq_name DEFAULT sy-uname,
            p_prdate LIKE bapimepoitem-period_ind_expiration_date DEFAULT 'D'. " 货架存放期过期日期的期间标识

" herader data
wa_poheader-po_number  = p_number.
wa_poheader-comp_code  = p_cocode.
wa_poheader-doc_type   = p_dotype.
wa_poheader-status     = p_status.
wa_poheader-creat_date = p_crdate.
wa_poheader-created_by = p_crdaby.
wa_poheader-item_intvl = p_itemin.
wa_poheader-vendor     = p_vendor.
" WA_POHEADER-LANGU      = P_LANGU .
*wa_poheader-pmnttrms   = p_pmnttr.
wa_poheader-purch_org  = p_purch.
wa_poheader-pur_group  = p_purgr.
wa_poheader-doc_date   = p_docdat.
wa_poheader-vat_cntry  = p_vatcn.
wa_poheader-suppl_plnt  = p_reswk.

" po header flag
wa_poheaderx-po_number  = 'X'.
wa_poheaderx-comp_code  = 'X'.
wa_poheaderx-doc_type   = 'X'.
wa_poheaderx-status     = 'X'.
wa_poheaderx-creat_date = 'X'.
wa_poheaderx-created_by = 'X'.
wa_poheaderx-item_intvl = 'X'.
wa_poheaderx-vendor     = 'X'.
wa_poheaderx-suppl_plnt = 'X'.

wa_poheaderx-langu      = 'X'.
wa_poheaderx-pmnttrms   = 'X'.
wa_poheaderx-purch_org  = 'X'.
wa_poheaderx-pur_group  = 'X'.
wa_poheaderx-doc_date   = 'X'.
wa_poheaderx-vat_cntry  = 'X'.

" po item data
wa_poitem-po_item                    = p_poitem.
wa_poitem-material                   = p_matner.
wa_poitem-plant                      = p_plant.
wa_poitem-stge_loc                   = p_loct.
wa_poitem-quantity                   = p_quanti.
" WA_POITEM-NET_PRICE                  = P_NETPRI .
" WA_POITEM-PRICE_UNIT                 = P_PRICEU .
wa_poitem-preq_name                  = p_rename.
wa_poitem-period_ind_expiration_date = p_prdate.
APPEND wa_poitem TO itab_poitem.

" po item flag
wa_poitemx-po_item                    = p_poitem.
wa_poitemx-po_itemx                   = 'X'.
wa_poitemx-material                   = 'X'.
wa_poitemx-plant                      = 'X'.
wa_poitemx-stge_loc                   = 'X'.
wa_poitemx-quantity                   = 'X'.
wa_poitemx-net_price                  = 'X'.
wa_poitemx-price_unit                 = 'X'.
wa_poitemx-preq_name                  = 'X'.
wa_poitemx-period_ind_expiration_date = 'X'.
APPEND wa_poitemx TO itab_poitemx.

" call bapi
CALL FUNCTION 'BAPI_PO_CREATE1'
  EXPORTING poheader  = wa_poheader
            poheaderx = wa_poheaderx
  TABLES    return    = itab_return
            poitem    = itab_poitem
            poitemx   = itab_poitemx.
" POACCOUNT   = I_PO_ACCOUNT
" POACCOUNTX  = I_PO_ACCOUNTX
" POSCHEDULE  = I_PO_SCHEDULE
" POSCHEDULEX = I_PO_SCHEDULEX.

DATA error_log TYPE c LENGTH 1.
LOOP AT itab_return INTO wa_return.
  IF wa_return-type = 'E'.
    error_log = 'X'.
    EXIT.
  ENDIF.
  CLEAR wa_return.
ENDLOOP.
IF error_log = 'X'.
  CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
  WRITE 'MESSAGE ERROR'.
  LOOP AT itab_return INTO wa_return.
    WRITE: / wa_return-type, wa_return-message.
    CLEAR wa_return.
  ENDLOOP.
ELSE.
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING wait = 'X'.
  LOOP AT itab_return INTO wa_return.
    WRITE: / wa_return-type,wa_return-message.
    CLEAR wa_return.
  ENDLOOP.
ENDIF.
