*&---------------------------------------------------------------------*
*& Include z250615_report_1_frm
*&---------------------------------------------------------------------*
*& Form create_ub_order
*&---------------------------------------------------------------------*
*& 创建转储订单 BAPI_PO_CREATE1
*&---------------------------------------------------------------------*
*&      --> INPUT_DATA
*&      <-- OUTPUT_DATA
*&---------------------------------------------------------------------*
form create_po.
  data wa_poheader type bapimepoheader.  " 所要增加的内容
  data wa_poheaderx type bapimepoheaderx. " 针对要增加的内容做一个标记,其实标记过了才可以被修改的
  data wa_poitem type bapimepoitem.    " po中item的内容,工作区
  data itab_poitem like table of wa_poitem.                    " PO中ITEM的内容,内表

  data wa_poitemx type bapimepoitemx.   " po中item增加内容的标记 工作区
  data itab_poitemx like table of wa_poitemx.                    " po中item增加内容的标记 内表
  data wa_return type bapiret2.        " 消息 返回 ,工作区
  " data itab_return  like table of wa_return with header line .                    " 消息返回, 内表

  data itab_return  type standard table of bapiret2 with header line.

  data expheader    type bapimepoheader.

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
  wa_poheader-suppl_plnt = p_reswk.

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
  wa_poitem-material                   = p_matnr.
  wa_poitem-plant                      = p_plant.
  wa_poitem-stge_loc                   = p_loct.
  wa_poitem-quantity                   = p_quanti.
  wa_poitem-net_price                  = '10.00'.
  " WA_POITEM-PRICE_UNIT                 = P_PRICEU .
  wa_poitem-preq_name                  = p_rename.
  wa_poitem-period_ind_expiration_date = p_prdate.
  append wa_poitem to itab_poitem.

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
  append wa_poitemx to itab_poitemx.

  " call bapi
  call function 'BAPI_PO_CREATE1'
    exporting
      poheader         = wa_poheader
      poheaderx        = wa_poheaderx
    importing
      exppurchaseorder = gv_po_num
      expheader        = expheader
    tables
      return           = itab_return
      poitem           = itab_poitem
      poitemx          = itab_poitemx.

  data error_log type c length 1.
  loop at itab_return into wa_return.
    if wa_return-type = 'E'.
      error_log = 'X'.
      exit.
    endif.
    clear wa_return.
  endloop.
  if error_log = 'X'.
    call function 'BAPI_TRANSACTION_ROLLBACK'.
    write 'MESSAGE ERROR'.

  else.
    call function 'BAPI_TRANSACTION_COMMIT'
      exporting
        wait = 'X'.

  endif.
  perform deal_message using itab_return[].
endform.

*& Form valid_input_data
*&---------------------------------------------------------------------*
*& 校验传入的数据
*&---------------------------------------------------------------------*
*&      --> INPUT_DATA
*&      <-- OUTPUT_DATA
*&---------------------------------------------------------------------*
form valid_input_data.
endform.

*& Form check_material_storage
*&---------------------------------------------------------------------*
*& 检查物料库存
*&---------------------------------------------------------------------*
*&      --> INPUT_DATA
*&      <-- OUTPUT_DATA
*&---------------------------------------------------------------------*
form check_material_storage.
endform.

*& Form create_delivery_order
*&---------------------------------------------------------------------*
*& 创建交货单 BAPI_OUTB_DELIVERY_CREATE_SLS 参照销售订单创建交货单BAPI
*          BAPI_OUTB_DELIVERY_CREATE_STO 参照公司间采购订单/工厂件转储单创建交货单BAPI
*3.交货单修改ABPI:BAPI_OUTB_DELIVERY_CHANGE
*
*4.交货单拣配ABAP：WS_DELIVERY_UPDATE
*
*5.交货单过账ABPI：BAPI_OUTB_DELIVERY_CONFIRM_DEC
*&---------------------------------------------------------------------*
*&      --> INPUT_DATA
*&      <-- OUTPUT_DATA
*&---------------------------------------------------------------------*
form create_delivery_order
    using    gv_po_num
           p_vdatu
           p_posnr
           p_vstel
  changing gv_vbeln.

  data lt_stock_trans_items type standard table of bapidlvreftosto with header line.
  data lt_return1           type standard table of bapiret2 with header line.
  data itab_return like table of bapiret2. " 消息返回, 内表

  data ls_sto_item          like bapidlvreftosto.

  ls_sto_item-ref_doc  = gv_po_num.
  ls_sto_item-ref_item = p_posnr.
  append ls_sto_item to lt_stock_trans_items.
  call function 'BAPI_OUTB_DELIVERY_CREATE_STO'
    exporting
      ship_point        = p_vstel " 装运点/收货点
      due_date          = p_vdatu " 交货日期
*     debug_flg         =
*     no_dequeue        = ' '
    importing
      delivery          = gv_vbeln " 交货单号
*     num_deliveries    =
    tables
      stock_trans_items = lt_stock_trans_items
*     serial_numbers    =
*     extension_in      =
*     deliveries        =
*     created_items     =
*     extension_out     =
      return            = lt_return1[].

  data error_log type c length 1.
  loop at itab_return into data(wa_return).
    if wa_return-type = 'E'.
      error_log = 'X'.
      exit.
    endif.
    clear wa_return.
  endloop.
  if error_log = 'X'.
    call function 'BAPI_TRANSACTION_ROLLBACK'.
  else.
    call function 'BAPI_TRANSACTION_COMMIT'
      exporting
        wait = 'X'.
  endif.
  perform deal_message using lt_return1[].
endform.

*&---------------------------------------------------------------------*
*    物料拣配
*&      --> INPUT_DATA
*&      <-- OUTPUT_DATA
*&---------------------------------------------------------------------*
form pick_goods using    gv_delivery_no like likp-vbeln
                changing picked         type c.

  data(util) = new znantest_util( ).
  data header_data    type bapiobdlvhdrchg.
  data header_control type bapiobdlvhdrctrlchg.
  data delivery       type vbeln_vl.
  data techn_control  type bapidlvcontrol.
  data item_data      type standard table of bapiobdlvitemchg with header line.
  data item_control   type standard table of bapiobdlvitemctrlchg with header line.
  data itab_return    type standard table of bapiret2 with header line.
  data item_data_spl  type standard table of /spe/bapiobdlvitemchg with header line.

  header_data-deliv_numb = gv_delivery_no.
  header_control-deliv_numb = gv_delivery_no.
  techn_control-upd_ind = 'U'.

  item_data = value #( deliv_numb = gv_delivery_no
                       deliv_item = p_posnr
                       material   = p_matnr
                       dlv_qty    = p_quanti ).
  select single meins umvkz umvkn
    into ( item_data-sales_unit,item_data-fact_unit_nom,item_data-fact_unit_denom )
    from lips
    where vbeln = gv_delivery_no
      and posnr = p_posnr.

  append item_data.

  item_control = value #( deliv_numb = gv_delivery_no
                          deliv_item = p_posnr
                          chg_delqty = abap_true
                          volume_flg = abap_true ). " 量的确认
  append item_control.

  item_data_spl = value #( deliv_numb = gv_delivery_no
                           deliv_item = p_posnr
                           stge_loc   = p_loct ).
  append item_data_spl.
  call function 'BAPI_OUTB_DELIVERY_CHANGE'
    exporting
      header_data    = header_data
      header_control = header_control
      delivery       = gv_delivery_no
      techn_control  = techn_control
    tables
      item_data      = item_data
      item_control   = item_control
      return         = itab_return
      item_data_spl  = item_data_spl.

  if sy-subrc <> 0.
    call function 'BAPI_TRANSACTION_ROLLBACK'.
    write 'MESSAGE ERROR'.

  else.
    call function 'BAPI_TRANSACTION_COMMIT'
      exporting
        wait = 'X'.
    picked = 'X'.
    itab_return = value #( message    = '拣配完成'
                           message_v1 = '拣配完成'
                           type       = 'W'
                           parameter  = 'POHEADER'
                           row        = '1'
                           system     = 'S4HCLNT400' ).
    append itab_return.
  endif.

  data ls_vbkok       type vbkok.
  data lt_prott       type standard table of prott.
  data ls_prott       type prott.
  data lt_vbpok       type standard table of vbpok.
  data ls_vbpok       type vbpok.
  data lv_message     type string.
  data lv_all_message type string.
  data lv_flag        type char01.

  ls_vbkok-vbeln_vl = gv_delivery_no.
  ls_vbkok-komue    = 'X'.      " 交货数量 = 捡配数量
  ls_vbkok-kzkodat  = 'X'.      " Picking date
  ls_vbkok-kodat    = sy-datum. " Picking date
  clear:ls_vbpok,
         lv_flag,
         lv_message,
         lv_all_message,
         lt_prott.
  ls_vbpok-vbeln_vl = gv_delivery_no.
  ls_vbpok-posnr_vl = p_posnr.
  ls_vbpok-vbeln    = gv_delivery_no.
  ls_vbpok-posnn    = p_posnr.
  ls_vbpok-pikmg    = p_quanti.
  ls_vbpok-lgort    = p_loct.

  append ls_vbpok to lt_vbpok.
  call function 'WS_DELIVERY_UPDATE'
    exporting
      vbkok_wa       = ls_vbkok
*     COMMIT         = CON
      delivery       = gv_delivery_no
      update_picking = 'X'
      synchron       = 'X'
*     if_database_update = 'X'         "L.S Commentd out
      nicht_sperren  = 'X'         " L.S Inserted
    tables
      vbpok_tab      = lt_vbpok
      prot           = lt_prott
    exceptions
      error_message  = 1
      others         = 2.
  if sy-subrc = 0.
    loop at lt_prott into ls_prott where msgty ca 'EAX'.
      call function 'MESSAGE_TEXT_BUILD'
        exporting
          msgid               = ls_prott-msgid
          msgnr               = ls_prott-msgno
          msgv1               = ls_prott-msgv1
          msgv2               = ls_prott-msgv2
          msgv3               = ls_prott-msgv3
          msgv4               = ls_prott-msgv4
        importing
          message_text_output = lv_message.
      concatenate  lv_all_message lv_message into lv_all_message.
      lv_message = lv_all_message.
      lv_flag = 'X'.
      clear ls_prott.
    endloop.
  else.
    clear lv_message.
    call function 'MESSAGE_TEXT_BUILD'
      exporting
        msgid               = sy-msgid
        msgnr               = sy-msgno
        msgv1               = sy-msgv1
        msgv2               = sy-msgv2
        msgv3               = sy-msgv3
        msgv4               = sy-msgv4
      importing
        message_text_output = lv_all_message.
    lv_message = lv_all_message.
  endif.

  if lv_flag is initial.
    call function 'BAPI_TRANSACTION_COMMIT'
      exporting
        wait = 'X'.

  else.
    call function 'BAPI_TRANSACTION_ROLLBACK'.

  endif.
  clear itab_return.
  itab_return = value #( message    = lv_message
                         message_v1 = lv_message
                         type       = 'W'
                         parameter  = 'POHEADER'
                         row        = '1'
                         system     = 'S4HCLNT400' ).
  append itab_return.

  util->show_message( itab_return = itab_return[] ).
endform.

*&---------------------------------------------------------------------*
*    发货过账
*&      --> INPUT_DATA
*&      <-- OUTPUT_DATA
*&---------------------------------------------------------------------*
form release_delivery_order using gv_delivery_no.
  data header_data type bapiobdlvhdrcon.     " 外向交货提货数据标题级别验证
  data header_control type bapiobdlvhdrctrlcon. " 外向交货标题级别控制数据
  data itab_return like table of bapiret2 with header line.   " 消息返回, 内表

  header_data-deliv_numb = gv_delivery_no.
  header_control-deliv_numb  = gv_delivery_no.
  header_control-post_gi_flg = 'X'.
  header_control-volume_flg  = 'X'.

  " 外向交货单发货过账
  call function 'BAPI_OUTB_DELIVERY_CONFIRM_DEC'
    exporting
      header_data    = header_data
      header_control = header_control
      delivery       = gv_delivery_no
    tables
      return         = itab_return.

  if sy-subrc <> 0.
    " Implement suitable error handling here
  endif.
  data error_log type string.
  loop at itab_return into data(wa_return).
    if wa_return-type = 'E'.
      error_log = 'X'.
      exit.
    endif.
    clear wa_return.
  endloop.
  if error_log = 'X'.
    call function 'BAPI_TRANSACTION_ROLLBACK'.
  else.
    call function 'BAPI_TRANSACTION_COMMIT'
      exporting
        wait = 'X'.
    clear itab_return.
    itab_return = value #( id         = '06' " 消息ID
                           message    = '发货过账完成'
                           type       = 'S' " 消息类型
                           parameter  = 'POHEADER' " 消息参数
                           row        = '1' "    行号
                           log_no     = '0000000000000000'
                           log_msg_no = '000000'
                           message_v1 = '发货过账完成'
                           message_v2 = '发货过账完成'
                           message_v3 = '发货过账完成'
                           message_v4 = '发货过账完成'
                           number     = '017'
                           system     = 'S4HCLNT400' ).
    append itab_return.

  endif.
  perform deal_message using itab_return[].
endform.

*&---------------------------------------------------------------------*
*   显示message
*&      --> INPUT_DATA
*&      <-- OUTPUT_DATA
*&---------------------------------------------------------------------*
form deal_message using itab_return type itab_return.
  call function 'MESSAGES_INITIALIZE'.
  loop at itab_return into data(lt_return).
    call function 'MESSAGE_STORE'
      exporting
        arbgb = lt_return-id
        msgty = lt_return-type
        txtnr = lt_return-number
        msgv1 = lt_return-message
        msgv2 = lt_return-message_v1
        msgv3 = lt_return-message_v2
        msgv4 = lt_return-message_v3
        zeile = lt_return-row.
  endloop.
  call function 'MESSAGES_SHOW'
    exporting
      i_use_grid         = abap_true
      show_linno         = abap_true
    exceptions
      inconsistent_range = 1
      no_messages        = 2
      others             = 3.
endform.

*&---------------------------------------------------------------------*
*& Form frm_get_sql_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
form frm_get_sql_data.
  clear line_1.
  clear tab1.

  line_1 = value #( p_dotype = p_dotype " 采购凭证类型
                    p_number = '' " 采购凭证号
                    p_docdat = sy-datum " 采购凭证日期
                    p_crdate = sy-datum " 采购凭证创建日期
                    p_crdaby = sy-uname " 采购凭证创建人
                    p_vendor = p_vendor " 供应商
                    p_reswk  = p_reswk " 拣配的工厂
                    p_loct_2 = p_loct_2 " 拣配的库位
                    p_status = p_status " 采购凭证状态
                    p_purch  = p_purch  " 采购组织
                    p_purgr  = p_purgr " 采购组
                    p_cocode = p_cocode " 公司代码
                    p_vatcn  = p_vatcn " 税务国家
                    p_POSNR  = p_POSNR " 采购凭证行项目
                    p_matnr  = p_matnr " 物料编号
                    p_plant  = p_plant " 收货工厂
                    p_loct   = p_loct " 库存地点
                    p_quanti = p_quanti " 采购数量
                    p_rename = sy-uname " 采购凭证修改人
                    p_prdate = 'D' " 采购凭证计划交货日期
                    p_netpri = '100.00'
                    p_vstel  = p_vstel " 交货地点
                    p_vdatu  = p_vdatu ). " 交货日期; 采购凭证净价'
  select single maktx from makt into @line_1-maktx where matnr = @line_1-p_matnr.

  append line_1 to tab1[].
endform.

*&---------------------------------------------------------------------*
*& Form frm_get_fieldcat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
form frm_get_fieldcat.
  data rd_open type char1.

  if rd_open is not initial.
    data(lv_eidt) = 'X'.
  else.
    lv_eidt = ''.
  endif.

  perform frm_add_fieldcat
          using    'CICON'
                   ''
                   ''
                   '状态图标'
                   space
                   'X'
                   space
                   space
                   space
                   20
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'MESSAGE'
                   ''
                   ''
                   '消息'
                   space
                   space
                   space
                   'X'
                   space
                   20
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'P_NUMBER'
                   'EKPO'
                   'EBELN'
                   'STO单号'
                   space
                   space
                   space
                   'X'
                   space
                   20
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'P_DOTYPE'
                   'EKPO'
                   'ESART'
                   '凭证类型'
                   space
                   space
                   space
                   space
                   space
                   20
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'P_DN_NO'
                   'LIKP'
                   'VBELN'
                   '交货单号'
                   space
                   space
                   space
                   'X'
                   space
                   20
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'MBLNR'
                   'SMBLN'
                   'MSEG'
                   '发货过账物料凭证'
                   space
                   space
                   space
                   'X'
                   space
                   40
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'MBLNR_2'
                   'SMBLN'
                   'MSEG'
                   '收货的物料凭证'
                   space
                   space
                   space
                   'X'
                   space
                   20
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'P_BILL_DOC'
                   ''
                   ''
                   '发票凭证号'
                   space
                   space
                   space
                   'X'
                   space
                   20
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'P_POSNR'
                   'LIPS'
                   'POSNR'
                   '行号'
                   space
                   space
                   space
                   space
                   space
                   20
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'P_VENDOR'
                   'EKKO'
                   'LPONR'
                   '供应商'
                   space
                   space
                   space
                   space
                   space
                   20
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'NAME1'
                   'KNA1'
                   'NAME1'
                   '售达方名称'
                   space
                   space
                   space
                   space
                   space
                   20
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'KUNNR'
                   'LIKP'
                   'KUNNR'
                   '收货方'
                   space
                   space
                   space
                   space
                   space
                   20
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'P_PURCH'
                   'EKKO'
                   'EKORG'
                   '采购组织'
                   space
                   space
                   space
                   space
                   space
                   20
          changing gt_fcat.
  perform frm_add_fieldcat
          using    'P_PURGR'
                   'EKKO'
                   'EKGRP'
                   '采购组'
                   space
                   space
                   space
                   space
                   space
                   20
          changing gt_fcat.
  perform frm_add_fieldcat
          using    'P_COCODE'
                   'EKKO'
                   'BUKRS'
                   '采购公司代码'
                   space
                   space
                   space
                   space
                   space
                   20
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'P_MATNR'
                   'LIPS'
                   'MATNR'
                   '物料编号'
                   space
                   space
                   space
                   space
                   space
                   20
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'MAKTX'
                   'MAKT'
                   'MAKTX'
                   '物料描述'
                   space
                   space
                   space
                   space
                   space
                   20
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'P_QUANTI'
                   'LIPS'
                   'LFIMG'
                   '交货数量'
                   lv_eidt
                   space
                   space
                   space
                   space
                   20
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'P_NETPRI'
                   'VBAP'
                   'NETPR'
                   '净价'
                   space
                   space
                   space
                   space
                   space
                   20
          changing gt_fcat.
  perform frm_add_fieldcat
          using    'P_PLANT'
                   'LIPS'
                   'WERKS'
                   '收货工厂'
                   space
                   space
                   space
                   space
                   space
                   20
          changing gt_fcat.
  perform frm_add_fieldcat
          using    'P_LOCT'
                   'LIPS'
                   'LGORT'
                   '库存地点'
                   lv_eidt
                   space
                   space
                   space
                   space
                   20
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'P_RESWK'
                   'LIPS'
                   'WERKS'
                   '拣配工厂'
                   space
                   space
                   space
                   space
                   space
                   20
          changing gt_fcat.
  perform frm_add_fieldcat
          using    'P_LOCT_2'
                   'LIPS'
                   'LGORT'
                   '拣配库位'
                   lv_eidt
                   space
                   space
                   space
                   space
                   20
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'VGBEL'
                   'LIPS'
                   'VGBEL'
                   '参考单据号'
                   space
                   space
                   space
                   'X'
                   space
                   20
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'VGPOS'
                   'LIPS'
                   'VGPOS'
                   '参考单据行号'
                   space
                   space
                   space
                   space
                   space
                   20
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'P_CRDATE'
                   'LIKP'
                   'ERDAT'
                   '创建日期'
                   space
                   space
                   space
                   space
                   space
                   20
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'VKORG'
                   'LIKP'
                   'VKORG'
                   '销售组织'
                   space
                   space
                   space
                   space
                   space
                   20
          changing gt_fcat.

  perform frm_add_fieldcat
          using    'P_PRICEU'
                   'LIPS'
                   'VRKME'
                   '销售单位'
                   space
                   space
                   space
                   space
                   space
                   20
          changing gt_fcat.
endform.

*&---------------------------------------------------------------------*
*& Form frm_display_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
form frm_display_alv.
  data ls_layout type lvc_s_layo.

  perform frm_get_fieldcat.

  ls_layout-cwidth_opt = abap_true. " 优化列宽度
  ls_layout-zebra      = 'X'. " 可选行颜色 (带)
  ls_layout-sel_mode   = 'A'. " 选择方式
  ls_layout-box_fname  = 'SEL'. " 内部表字段的字段名称

  call function 'REUSE_ALV_GRID_DISPLAY_LVC'
    exporting
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'FRM_STATUS'
      i_callback_user_command  = 'FRM_COMMAND'
      is_layout_lvc            = ls_layout " 布局
      it_fieldcat_lvc          = gt_fcat " 列配置
    tables
      t_outtab                 = tab1[]
    exceptions
      program_error            = 1
      others                   = 2.
endform.

*&---------------------------------------------------------------------*
*& Form frm_add_fieldcat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> P_
*&      --> P_
*&      --> TEXT_T31
*&      --> SPACE
*&      --> SPACE
*&      --> SPACE
*&      --> SPACE
*&      --> SPACE
*&      --> P_20
*&      <-- GT_FCAT
*&---------------------------------------------------------------------*
form frm_add_fieldcat
    using    pv_field     type fieldname
           pv_table     type tabnam
           pv_ref_field type lvc_s_fcat-ref_field
           pv_text      type lvc_txt
           pv_edit      type char1
           pv_icon      type char1
           pv_checkbox  type char1
           pv_hotspot   type char1
           pv_key       type char1
           pv_outputlen type lvc_s_fcat-outputlen
  changing ct_fieldcat  type lvc_t_fcat.

  data ls_fieldcat type lvc_s_fcat.

  ls_fieldcat-fieldname = pv_field. " ALV 控制: 内部表字段的字段名称
  ls_fieldcat-seltext   = pv_text. " " ALV 控制: 对话功能的列标识符
  ls_fieldcat-reptext   = pv_text. " 标题
  ls_fieldcat-scrtext_l = pv_text. " " ALV 控制: 内部表字段的长文本
  ls_fieldcat-scrtext_m = pv_text. " " ALV 控制: 内部表字段的中等文本
  ls_fieldcat-scrtext_s = pv_text. " " ALV 控制: 内部表字段的短文本

  ls_fieldcat-ref_field = pv_ref_field. " " ALV 控制: 内部表字段的参考字段
  ls_fieldcat-ref_table = pv_table. " " ALV 控制: 内部表字段的参考表
  ls_fieldcat-edit      = 'X'. " " ALV 控制: 内部表字段是否可编辑
  ls_fieldcat-icon      = pv_icon. " " ALV 控制: 内部表字段是否显示图标
  ls_fieldcat-checkbox  = pv_checkbox. " " ALV 控制: 内部表字段是否显示复选框
  ls_fieldcat-hotspot   = pv_hotspot. " " ALV 控制: 内部表字段是否显示热点
  ls_fieldcat-key       = pv_key. " " ALV 控制: 内部表字段是否为键字段
  ls_fieldcat-outputlen = pv_outputlen. " " ALV 控制: 内部表字段的输出长度

  append ls_fieldcat to ct_fieldcat.
endform.

form frm_status using it_extab type slis_t_extab.
  "
  " if rd_open is not initial.
  "   append 'CPOST' to lt_exclude.
  "   append 'DEL' to lt_exclude.
  "   append 'CDEL' to lt_exclude.
  "
  " elseif rd_done is not initial.
  "   append 'POST' to lt_exclude.
  "
  " elseif rd_list is not initial.
  "   append 'CPOST' to lt_exclude.
  "   append 'POST' to lt_exclude.
  "   append 'DEL' to lt_exclude.
  "   append 'CDEL' to lt_exclude.
  "   append 'DATE' to lt_exclude.
  " endif.

  set pf-status 'STANDARD'.
endform.

*&---------------------------------------------------------------------*
*&      Form  frm_command
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->R_UCOMM      text
*      -->RS_SELFIELD  text
*----------------------------------------------------------------------*
form frm_command using r_ucomm     like sy-ucomm
                       rs_selfield type slis_selfield.

  if gr_alv_grid is initial.

    call function 'GET_GLOBALS_FROM_SLVC_FULLSCR'
      importing
        e_grid = gr_alv_grid.

  endif.

  gr_alv_grid->check_changed_data( ).

  rs_selfield-refresh = abap_true.

  if r_ucomm = '&IC1'. " 行的点击事件
    read table tab1 into data(ls_itab) index rs_selfield-tabindex.
    " 交货单
    if rs_selfield-fieldname = 'P_DN_NO' and ls_itab-p_dn_no is not initial.
      set parameter id 'VL' field ls_itab-p_dn_no.
      call transaction 'VL03N' and skip first screen.
      " 采购订单
    elseif rs_selfield-fieldname = 'P_NUMBER' and ls_itab-p_number is not initial.
      call function 'ME_DISPLAY_PURCHASE_DOCUMENT'
        exporting
          i_ebeln      = ls_itab-p_number
"         i_ebelp      = itab-ebelp
 "        i_enjoy      = 'X'
*          IMPORTING
*         E_EKKO       =
        exceptions
          not_found    = 1
          no_authority = 2
          invalid_call = 3
          others       = 4.
      " 发票
    elseif rs_selfield-fieldname = 'P_BILL_DOC' and ls_itab-p_dn_no is not initial.
      set parameter id 'VF' field ls_itab-P_bill_doc.
      call transaction 'VF02' and skip first screen.
      " 物料凭证
    elseif rs_selfield-fieldname = 'MBLNR' and ls_itab-mblnr is not initial.
      call function 'MIGO_DIALOG'
        exporting
          i_action            = 'A04'
          i_refdoc            = 'R02'
          i_notree            = 'X'
          i_skip_first_screen = 'X'
          i_okcode            = 'OK_GO'
          i_mblnr             = <line_1>-mblnr
        " i_mjahr             = itab-gjahr
        exceptions
          illegal_combination = 1
          others              = 2.
      " 物料凭证
    elseif rs_selfield-fieldname = 'MBLNR_2' and ls_itab-mblnr_2 is not initial.
      call function 'MIGO_DIALOG'
        exporting
          i_action            = 'A04'
          i_refdoc            = 'R02'
          i_notree            = 'X'
          i_skip_first_screen = 'X'
          i_okcode            = 'OK_GO'
          i_mblnr             = <line_1>-mblnr_2
        " i_mjahr             = itab-gjahr
        exceptions
          illegal_combination = 1
          others              = 2.
      " 消息
    elseif rs_selfield-fieldname = 'MESSAGE' and ls_itab-message is not initial.
      data: begin of ls_text,
              ztext type c length 2048,
            end of ls_text.
      data lt_text like standard table of ls_text.
      append <line_1>-message to lt_text.
      call function 'ADA_POPUP_WITH_TABLE'
        exporting
          startpos_col = 1
          startpos_row = 1
          titletext    = '消息'    " 弹窗显示标题文本
        tables
          valuetab     = lt_text.
      " elseif rs_selfield-fieldname = 'VGBEL' and ls_itab-vgbel is not initial.
      "   set parameter id 'AUN' field ls_itab-vgbel.
      "   call transaction 'VA03' and skip first screen.

*    elseif rs_selfield-fieldname = 'DNNO' and ls_itab-dnno is not initial.
*      set parameter id 'VL' field ls_itab-dnno.
*      call transaction 'VL03N' and skip first screen.
*    elseif rs_selfield-fieldname = 'MTDOC' and ls_itab-mtdoc is not initial.
*      call function 'MIGO_DIALOG'
*        exporting
*          i_action            = 'A04'
*          i_refdoc            = 'R02'
*          i_notree            = 'X'
*          i_skip_first_screen = 'X'
*          i_okcode            = 'OK_GO'
*          i_mblnr             = ls_itab-mtdoc
*        " i_mjahr             = itab-gjahr
*        exceptions
*          illegal_combination = 1
*          others              = 2.
    endif.
  elseif r_ucomm = 'CPOST'.
    perform frm_create_sto_dataflow.
  elseif r_ucomm = 'POST'. " 新建PO,DN
    perform create_sto.
    if tab1[ 1 ]-p_number is not initial.
      perform create_dn.
    endif.
  elseif r_ucomm = 'ACTIVATE'. " 拣配，过账
    if tab1[ 1 ]-p_dn_no is not initial.
      perform pick_and_release.
    endif.
    " 删除
  elseif r_ucomm = 'DEL' or r_ucomm = 'CDEL'.
    perform frm_cancel_dataflow.
  elseif r_ucomm = 'DATE'.
    perform frm_set_post_date.
  elseif r_ucomm = 'RECEIVE'.
    perform receive_goods.

  elseif r_ucomm = 'BILLING'. " 开发票
    perform build_bill.

  elseif r_ucomm = 'DEL_DN'. " 删除DN
    data is_can_delete type abap_boolean.
    perform valid_dn_deletable
            changing
              is_can_delete.
    if is_can_delete = abap_true.
      perform delete_DN.
    endif.

  elseif r_ucomm = 'REVERSE_GOOD_DELIVER'. " 冲销发货过账
    perform reverse_good_delivery.
  elseif r_ucomm = 'REVERSE_GR'. " 冲销收货
    perform reverse_good_receive.
  elseif r_ucomm = 'REVERSE_BR'. " 冲销开票
    perform reverse_create_billing.
  elseif r_ucomm = 'CHANGE_RANGE'. " 调整账期 mmpv mmrv
    perform build_bill.
  endif.

  clear r_ucomm.
endform.

form create_sto.
  data wa_poheader type bapimepoheader.  " 所要增加的内容
  data wa_poheaderx type bapimepoheaderx. " 针对要增加的内容做一个标记,其实标记过了才可以被修改的
  data wa_poitem type bapimepoitem.    " po中item的内容,工作区
  data itab_poitem like table of wa_poitem.                    " PO中ITEM的内容,内表

  data wa_poitemx type bapimepoitemx.   " po中item增加内容的标记 工作区
  data itab_poitemx like table of wa_poitemx.                    " po中item增加内容的标记 内表
  data wa_return type bapiret2.        " 消息 返回 ,工作区
  " data itab_return  like table of wa_return with header line .                    " 消息返回, 内表

  data itab_return  type standard table of bapiret2 with header line.

  data expheader    type bapimepoheader.

  assign tab1[ 1 ] to <line_1>.

  " herader data
  wa_poheader-po_number  = <line_1>-p_number.
  wa_poheader-comp_code  = <line_1>-p_cocode.
  wa_poheader-doc_type   = <line_1>-p_dotype.
  wa_poheader-status     = <line_1>-p_status.
  wa_poheader-creat_date = <line_1>-p_crdate.
  wa_poheader-created_by = <line_1>-p_crdaby.
  wa_poheader-item_intvl = <line_1>-p_posnr.
  wa_poheader-vendor     = <line_1>-p_vendor.
  " WA_POHEADER-LANGU      = P_LANGU .
*wa_poheader-pmnttrms   = p_pmnttr.
  wa_poheader-purch_org  = <line_1>-p_purch.
  wa_poheader-pur_group  = <line_1>-p_purgr.
  wa_poheader-doc_date   = <line_1>-p_docdat.
  wa_poheader-vat_cntry  = <line_1>-p_vatcn.
  wa_poheader-suppl_plnt = <line_1>-p_reswk.

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
  wa_poitem-po_item                    = <line_1>-p_posnr.
  wa_poitem-material                   = <line_1>-p_matnr.
  wa_poitem-plant                      = <line_1>-p_plant.
  wa_poitem-stge_loc                   = <line_1>-p_loct.
  wa_poitem-quantity                   = <line_1>-p_quanti.
  wa_poitem-net_price                  = '10.00'.
  " WA_POITEM-PRICE_UNIT                 = P_PRICEU .
  wa_poitem-preq_name                  = <line_1>-p_rename.
  wa_poitem-period_ind_expiration_date = <line_1>-p_prdate.
  append wa_poitem to itab_poitem.

  " po item flag
  wa_poitemx-po_item                    = <line_1>-p_posnr.
  wa_poitemx-po_itemx                   = 'X'.
  wa_poitemx-material                   = 'X'.
  wa_poitemx-plant                      = 'X'.
  wa_poitemx-stge_loc                   = 'X'.
  wa_poitemx-quantity                   = 'X'.
  wa_poitemx-net_price                  = 'X'.
  wa_poitemx-price_unit                 = 'X'.
  wa_poitemx-preq_name                  = 'X'.
  wa_poitemx-period_ind_expiration_date = 'X'.
  append wa_poitemx to itab_poitemx.

  " call bapi
  call function 'BAPI_PO_CREATE1'
    exporting
      poheader         = wa_poheader
      poheaderx        = wa_poheaderx
    importing
      exppurchaseorder = gv_po_num
      expheader        = expheader
    tables
      return           = itab_return
      poitem           = itab_poitem
      poitemx          = itab_poitemx.

  data error_log type c length 1.
  loop at itab_return into wa_return.
    if wa_return-type = 'E'.
      error_log = 'X'.
      exit.
    endif.
    clear wa_return.
  endloop.
  loop at itab_return into wa_return.
    msg = |{ msg } ;{ wa_return-message }|.
  endloop.
  if error_log = 'X'.
    call function 'BAPI_TRANSACTION_ROLLBACK'.
    write 'MESSAGE ERROR'.
    msg = | '创建STO失败;' { msg }|.
    tab1[ 1 ]-cicon = icon_led_red.
    tab1[ 1 ]-message = msg.
  else.
    call function 'BAPI_TRANSACTION_COMMIT'
      exporting
        wait = 'X'.
    msg = |'创建STO成功;' { msg }|.
    tab1[ 1 ]-p_number = gv_po_num.
    tab1[ 1 ]-cicon = icon_led_green.
    tab1[ 1 ]-message = msg.
  endif.
*  perform deal_message using itab_return[].
endform.

form create_dn.
  data lt_stock_trans_items type standard table of bapidlvreftosto with header line.
  data lt_return1           type standard table of bapiret2 with header line.
  data ls_sto_item like bapidlvreftosto. "

  ls_sto_item-ref_doc  = <line_1>-p_number. " STO订单号
  ls_sto_item-ref_item = <line_1>-p_posnr. " STO
  append ls_sto_item to lt_stock_trans_items.
  call function 'BAPI_OUTB_DELIVERY_CREATE_STO'
    exporting
      ship_point        = <line_1>-p_vstel " 装运点/收货点
      due_date          = <line_1>-p_vdatu " 交货日期
    importing
      delivery          = <line_1>-p_dn_no " 交货单号
    tables
      stock_trans_items = lt_stock_trans_items
      return            = lt_return1[].

  data error_log type c length 1.
  loop at lt_return1 into data(wa_return).
    msg = |{ msg } ;{ wa_return-message }|.
    if wa_return-type = 'E'.
      error_log = 'X'.
      exit.
    endif.
    clear wa_return.
  endloop.
  if error_log = 'X'.
    call function 'BAPI_TRANSACTION_ROLLBACK'.
    msg = | { msg } 创建DN失败!;|.
    tab1[ 1 ]-message = msg.
    tab1[ 1 ]-cicon = icon_led_red.
    perform delete_po.

  else.
    call function 'BAPI_TRANSACTION_COMMIT'
      exporting
        wait = 'X'.
    msg = | { msg } 创建DN成功!;|.

    tab1[ 1 ]-p_dn_no = <line_1>-p_dn_no.
    tab1[ 1 ]-message = msg.
    tab1[ 1 ]-cicon = icon_led_green.

  endif.
endform.

form pick_and_release.
  data header_data    type bapiobdlvhdrchg.
  data header_control type bapiobdlvhdrctrlchg.
  data delivery       type vbeln_vl.
  data techn_control  type bapidlvcontrol.
  data item_data type standard table of bapiobdlvitemchg with header line. " 更改外向交货拣配数据项目等级
  data item_control type standard table of bapiobdlvitemctrlchg with header line. " 外向交货项目级别控制数据
  data itab_return    type standard table of bapiret2 with header line.
  data item_data_spl type standard table of /spe/bapiobdlvitemchg with header line. " 更改向外交货拣配数据项目等级（SPE）

  " data collective_change_items type standard table of /spe/bapiobdlvcollchgir with header line.                        " 拣配行项目数量
  " data cwm_item_data           type standard table of /cwm/bapiobdlvitem with header line.
  header_data-deliv_numb = <line_1>-p_dn_no. "
  header_control-deliv_numb = <line_1>-p_dn_no.
  techn_control-upd_ind = 'X'. " 交货更改到后继
  " 该标识表明是否应该从用户对话（UPD_IND = 空）或者在数据保存时(UPD_IND = X )调用该模拟。
  " 若在数据保存时调用模拟，并且成功，则系统触发跨系统交货更改。

  item_data = value #( deliv_numb = <line_1>-p_dn_no " 交货单号
                       deliv_item = <line_1>-p_posnr " 交货行项目
                       material   = <line_1>-p_matnr " 物料编号
                       dlv_qty    = <line_1>-p_quanti ). " 交货数量

  select single meins umvkz umvkn
    into ( item_data-sales_unit,item_data-fact_unit_nom,item_data-fact_unit_denom )
    " 销售单位 销售数量转换成SKU的分子(因子)  销售数量转换为 SKU 的值（除数）
    from lips
    where vbeln = <line_1>-p_dn_no
      and posnr = <line_1>-p_posnr.

  append item_data.

  item_control = value #( deliv_numb = <line_1>-p_dn_no
                          deliv_item = <line_1>-p_posnr
                          chg_delqty = abap_true ). "  " chg_delqty = 'X' 表示交货数量已更改
  append item_control.

  item_data_spl = value #( deliv_numb = <line_1>-p_dn_no " 交货单号
                           deliv_item = <line_1>-p_posnr " 交货行项目
                           stge_loc   = <line_1>-p_loct_2 ). " 库存地点
  append item_data_spl.

*  collective_change_items = value /spe/bapiobdlvcollchgir( deliv_numb   = <line_1>-p_dn_no
*                                                           deliv_item   = <line_1>-p_posnr
*                                                           dlv_qty_from = <line_1>-p_quanti " 交货数量
*                                                           base_uom     = item_data-sales_unit " 捡配单位
*                                                           base_uom_iso = item_data-sales_unit ). " 捡配单位
*  cwm_item_data = value /cwm/bapiobdlvitem( deliv_numb      = <line_1>-p_dn_no
*                                            itm_number      = <line_1>-p_posnr
*                                            cum_btch_qty    = <line_1>-p_quanti
*                                            dlv_qty         = <line_1>-p_quanti
*                                            pick_qty        = <line_1>-p_quanti
*                                            pick_unit       = ''
*                                            pick_unit_iso   = ''
*                                            sales_unit      = ''
*                                            sales_unit_iso  = ''
*                                            target_qty      = <line_1>-p_quanti
*                                            target_unit     = ''
*                                            target_unit_iso = '' ). " 交货数量
  call function 'BAPI_OUTB_DELIVERY_CHANGE'
    exporting
      header_data    = header_data
      header_control = header_control
      delivery       = <line_1>-p_dn_no " 交货单号
      techn_control  = techn_control
    tables
      item_data      = item_data " 更改外向交货拣配数据项目等级
      item_control   = item_control " 更改外向交货拣配数据项目等级控制
      item_data_spl  = item_data_spl " 拣配行项目库存地点
*     collective_change_items = collective_change_items " 拣配行项目数量
*     cwm_item_data  = cwm_item_data
      return         = itab_return.
  if itab_return is not initial.
    loop at itab_return into data(wa_return).
      msg = |{ msg } ;{ wa_return-message }|.
    endloop.
  endif.
  if sy-subrc <> 0.
    call function 'BAPI_TRANSACTION_ROLLBACK'.
    msg = |{ msg } 捡配单号 { <line_1>-p_dn_no } 捡配行项目 { <line_1>-p_posnr } 设置拣配地点 { <line_1>-p_purgr } 捡配失败!|.
    tab1[ 1 ]-cicon = icon_led_red.
    perform delete_po.
  else.
    call function 'BAPI_TRANSACTION_COMMIT'
      exporting
        wait = 'X'.
    msg = |{ msg } 捡配单号 { <line_1>-p_dn_no } 捡配行项目 { <line_1>-p_posnr } 设置拣配地点 { <line_1>-p_purgr } 捡配成功!|.
    tab1[ 1 ]-cicon = icon_led_green.
    tab1[ 1 ]-message = msg.

  endif.

  data ls_vbkok       type vbkok.
  data lt_prott       type standard table of prott.
  data ls_prott       type prott.
  data lt_vbpok       type standard table of vbpok.
  data ls_vbpok       type vbpok.
  data lv_message     type string.
  data lv_all_message type string.
  data lv_flag        type char01.

  ls_vbkok-vbeln_vl = <line_1>-p_dn_no.
  ls_vbkok-komue    = 'X'.      " 交货数量 = 捡配数量
  ls_vbkok-kzkodat  = 'X'.      " 标记: 复制拣配日期
  ls_vbkok-kodat    = sy-datum. " 拣配日期
  clear:ls_vbpok,
         lv_flag,
         lv_message,
         lv_all_message,
         lt_prott.
  ls_vbpok-vbeln_vl = <line_1>-p_dn_no. " 交货
  ls_vbpok-posnr_vl = <line_1>-p_posnr. " 行项目
  ls_vbpok-vbeln    = <line_1>-p_dn_no. "  " 交货单号
  ls_vbpok-posnn    = <line_1>-p_posnr. " " 交货行项目
  ls_vbpok-pikmg    = <line_1>-p_quanti. " " 捡配数量
  ls_vbpok-lgort    = <line_1>-p_loct_2. " 库存地点

  append ls_vbpok to lt_vbpok.
  call function 'WS_DELIVERY_UPDATE'
    exporting
      vbkok_wa       = ls_vbkok " " 交货拣配数据
*     COMMIT         = CON
      delivery       = <line_1>-p_dn_no
      update_picking = 'X' " " 更新拣配
      synchron       = 'X' " " 同步更新
*     if_database_update = 'X'         " " 数据库更新
      nicht_sperren  = 'X'         " " 不锁定
    tables
      vbpok_tab      = lt_vbpok " " 交货行项目数据
      prot           = lt_prott " " 交货更新日志
    exceptions
      error_message  = 1
      others         = 2.
  if sy-subrc = 0.
    lv_flag = 'X'.
    if lt_prott is not initial.
      loop at lt_prott into ls_prott where msgty ca 'EAX'.
        msg = |{ msg } ;{ wa_return-message }|.
        call function 'MESSAGE_TEXT_BUILD'
          exporting
            msgid               = ls_prott-msgid
            msgnr               = ls_prott-msgno
            msgv1               = ls_prott-msgv1
            msgv2               = ls_prott-msgv2
            msgv3               = ls_prott-msgv3
            msgv4               = ls_prott-msgv4
          importing
            message_text_output = lv_message.
        concatenate  lv_all_message lv_message into lv_all_message.
        lv_message = lv_all_message.
        clear ls_prott.
      endloop.
    endif.
  else.
    clear lv_message.
    call function 'MESSAGE_TEXT_BUILD'
      exporting
        msgid               = sy-msgid
        msgnr               = sy-msgno
        msgv1               = sy-msgv1
        msgv2               = sy-msgv2
        msgv3               = sy-msgv3
        msgv4               = sy-msgv4
      importing
        message_text_output = lv_all_message.
    lv_message = lv_all_message.
  endif.

  if lv_flag is not initial.
    call function 'BAPI_TRANSACTION_COMMIT'
      exporting
        wait = 'X'.
    msg = |{ msg } ;捡配单号 { <line_1>-p_dn_no } 捡配行项目 { <line_1>-p_posnr } 设置拣配数量 { <line_1>-p_quanti } 捡配成功!|.
    tab1[ 1 ]-cicon = icon_led_green.
    tab1[ 1 ]-message = msg.
  else.
    call function 'BAPI_TRANSACTION_ROLLBACK'.
    msg = |{ msg } ; { lv_all_message }|.
    msg = | { msg } ; 捡配单号 { <line_1>-p_dn_no } 捡配行项目 { <line_1>-p_posnr } 设置拣配数量 { <line_1>-p_quanti } 捡配失败!|.
    tab1[ 1 ]-message = msg.
    tab1[ 1 ]-cicon = icon_led_red.
    perform delete_dn.
    perform delete_po.
  endif.

  data bapiobdlvhdrcon type bapiobdlvhdrcon.     " 外向交货提货数据标题级别验证
  data bapiobdlvhdrctrlcon type bapiobdlvhdrctrlcon. " 外向交货标题级别控制数据

  bapiobdlvhdrcon-deliv_numb = <line_1>-p_dn_no.
  bapiobdlvhdrctrlcon-deliv_numb  = <line_1>-p_dn_no.
  bapiobdlvhdrctrlcon-post_gi_flg = 'X'.
  bapiobdlvhdrctrlcon-volume_flg  = 'X'.

  " 外向交货单发货过账
  call function 'BAPI_OUTB_DELIVERY_CONFIRM_DEC'
    exporting
      header_data    = bapiobdlvhdrcon " 外向交货提货数据标题级别验证
      header_control = bapiobdlvhdrctrlcon " 外向交货标题级别控制数据
      delivery       = <line_1>-p_dn_no " 交货单号
    tables
      return         = itab_return.

  data error_log type string.
  " TODO: variable is assigned but never used (ABAP cleaner)
  loop at itab_return into data(wa_return1).
    if wa_return-type = 'E'.
      error_log = 'X'.
      exit.
    endif.
    clear wa_return.
  endloop.
  if error_log = 'X'.
    call function 'BAPI_TRANSACTION_ROLLBACK'.
    msg = |{ msg } ;交货单号 { <line_1>-p_dn_no } 过账失败!|.
    tab1[ 1 ]-cicon = icon_led_red.
    tab1[ 1 ]-message = msg.
    perform delete_dn.
    perform delete_po.
  else.
    call function 'BAPI_TRANSACTION_COMMIT'
      exporting
        wait = 'X'.
    msg = |{ msg } ;交货单号 { <line_1>-p_dn_no } 过账成功!|.
    tab1[ 1 ]-cicon = icon_led_green.
    tab1[ 1 ]-message = msg.
    " 返回物料凭证
    " select single vbeln into @data(e_vbeln)
    "   from vbfa
    "   where     vbelv = @<line_1>-p_dn_no and vbtyp_n = 'R' and bwart <> '' and rfmng <> 0 " R 货物移动（过账物料凭证）
    "     and not exists
    "     ( select * from m_mbmps " 视图比mseg多条件
    "         where smbln = vbfa~vbeln or mblnr = vbfa~vbeln ). " 非冲销和被冲销
    data matdoc type c length 10.
    clear matdoc.
    import matdoc from memory id 'BORGR_MATDOC'.

    if matdoc is not initial.
      tab1[ 1 ]-mblnr = matdoc.
    endif.
  endif.
endform.

form frm_cancel_dataflow.
endform.

form frm_create_sto_dataflow.
  perform create_sto.
  if tab1[ 1 ]-p_number is not initial.
    perform create_dn.
  endif.
  if tab1[ 1 ]-p_dn_no is not initial.
    perform pick_and_release.
  endif.
endform.

form frm_set_post_date.
endform.
*&---------------------------------------------------------------------*
*& Module STATUS_2000 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
module status_2000 output.
  set pf-status 'STANDARD'.
  set titlebar 'STO流程'.
endmodule.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_2000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module user_command_2000 input.




endmodule.

form delete_PO.
  data ls_header type bapimepoheader.  " 采购订单抬头数据
  data ls_headerx type bapimepoheaderx. " 采购订单抬头数据的标识符

  ls_header-po_number  = <line_1>-p_number.
  ls_header-delete_ind = 'X'.

  ls_headerx-po_number  = <line_1>-p_number.
  ls_headerx-delete_ind = 'X'.
  data lt_return type standard table of bapiret2 with header line.

  call function 'BAPI_PO_CHANGE'
    exporting
      purchaseorder = <line_1>-p_number
      poheader      = ls_header
      poheaderx     = ls_headerx
    tables
      return        = lt_return.
  if lt_return is not initial.
    loop at lt_return.
      msg = |{ msg } { lt_return-message }|.
    endloop.
  endif.
  if sy-subrc = 0.
    call function 'BAPI_TRANSACTION_COMMIT'
      exporting
        wait = 'X'.
    <line_1>-message  = |{ <line_1>-message } '删除PO:{ <line_1>-p_number }成功'|.
    <line_1>-p_number = space.
    <line_1>-cicon    = icon_led_red.

  else.
    call function 'BAPI_TRANSACTION_ROLLBACK'.
    <line_1>-message = |{ <line_1>-message } '删除PO:{ <line_1>-p_number }失败'|.
    <line_1>-cicon   = icon_led_red.
  endif.
endform.

*&---------------------------------------------------------------------*
*&      Form  校验DN是否可以删除 如果有开了发票，就不可以删了
*&---------------------------------------------------------------------*

form valid_DN_deletable changing isValid type abap_boolean.
  isValid = abap_true.

  types: begin of ty_billing,
           vbelv   type vbeln_von,
           posnv   type posnr_von,
           vbtyp_v type vbtypl_v,
           vbeln   type vbeln_nach,
           posnn   type posnr_nach,
           vbtyp_n type vbtypl_n,
         end of ty_billing.

  data(nd_no) = <line_1>-p_dn_no.
  data billing_tab type standard table of ty_billing.
  perform get_dn_followup_billing_list using nd_no
          changing billing_tab.

  if nd_no is initial. " 没有发票数据
    isValid = abap_true.
  else. " 判断是否为已经冲销

  endif.
endform.

*&---------------------------------------------------------------------*
*& 获取DN的后续开票凭证列表
*&---------------------------------------------------------------------*
form get_dn_followup_billing_list using    nd_no
                                  changing tab1  type standard table.

  " TODO: variable is assigned but never used (ABAP cleaner)
  data(bill_range) = '5M'.
  select vbelv,posnv,vbtyp_v,vbeln,posnn,vbtyp_n
    from vbfa
    into corresponding fields of table @tab1
    where vbtyp_v = 'J' and vbelv = @nd_no and ( vbtyp_n = '5' or vbtyp_n = 'M' ).

  cl_demo_output=>display( tab1 ).
endform.

form delete_DN.
  data ls_header_data type bapiobdlvhdrchg.
  data ls_header_ctrl type bapiobdlvhdrctrlchg.
  data lt_return      type standard table of bapiret2 with header line.

  ls_header_ctrl-dlv_del    = 'X'.
  ls_header_ctrl-deliv_numb = <line_1>-p_dn_no.
  ls_header_data-deliv_numb = <line_1>-p_dn_no.

  call function 'BAPI_OUTB_DELIVERY_CHANGE'
    exporting
      header_data    = ls_header_data
      header_control = ls_header_ctrl
      delivery       = <line_1>-p_dn_no " 交货单号
    tables
      return         = lt_return.
  if lt_return is initial.
    return.
  endif.
  data isValid type abap_bool value abap_true.
  loop at lt_return.
    msg = |{ lt_return-message }|.
    if lt_return-type co 'EA'. " 字符包含在EA里面
      <line_1>-message = |{ <line_1>-message } ; 删除DN失败:{ msg } |.
      <line_1>-cicon   = icon_led_red.
      isValid = abap_false.
    endif.
  endloop.
  if isValid = abap_true.
    call function 'BAPI_TRANSACTION_COMMIT'
      exporting
        wait = 'X'.
    <line_1>-p_dn_no = space.
    <line_1>-message = |{ <line_1>-message } ; 删除DN:{ <line_1>-p_dn_no }成功|.
    <line_1>-cicon   = icon_led_red.

  else.
    call function 'BAPI_TRANSACTION_ROLLBACK'.