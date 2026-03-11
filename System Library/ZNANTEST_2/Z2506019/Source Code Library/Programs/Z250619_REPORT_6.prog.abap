*&---------------------------------------------------------------------*
*& Report z250619_report_5
*发货单拣配
" &----------------------------------------------------------------------
report z250619_report_6.
selection-screen begin of block b02 with frame title text-002.
  parameters: p_del_no type likp-vbeln default '0080004497', " 交货单号
              p_wadat  type likp-wadat default sy-datlo, " 交货日期
              p_posnr  type lips-posnr default '000010', " 交货单项目
              p_matnr  type lips-matnr default '000000000000011680', " 物料编号
              p_werks  type lips-werks default '8701', " 工厂
              p_lgort  type lips-lgort default '0001', " 库位
              p_pikmg  type lips-lfimg default '100.000'. " 拣配数量

selection-screen end of block b02.
data(util) = new znantest_util( ).

start-of-selection.
  data header_data    type bapiobdlvhdrchg.
  data header_control type bapiobdlvhdrctrlchg.
  data delivery       type vbeln_vl.
  data techn_control  type bapidlvcontrol.
  data item_data      type standard table of bapiobdlvitemchg with header line.
  data item_control   type standard table of bapiobdlvitemctrlchg with header line.
  data itab_return    type standard table of bapiret2.
  data item_data_spl  type standard table of /spe/bapiobdlvitemchg with header line.

  header_data-deliv_numb = p_del_no.
  header_control-deliv_numb = p_del_no.
  techn_control-upd_ind = 'U'.

  item_data = value #( deliv_numb = p_del_no
                       deliv_item = p_posnr
                       material   = p_matnr
                       dlv_qty    = p_pikmg ).
  select single meins umvkz umvkn
    into ( item_data-sales_unit,item_data-fact_unit_nom,item_data-fact_unit_denom )
    from lips
    where vbeln = p_del_no
      and posnr = p_posnr.

  append item_data.

  item_control = value #( deliv_numb = p_del_no
                          deliv_item = p_posnr
                          chg_delqty = abap_true ).
  append item_control.

  item_data_spl = value #( deliv_numb = p_del_no
                           deliv_item = p_posnr
                           stge_loc   = p_lgort ).
  append item_data_spl.
  call function 'BAPI_OUTB_DELIVERY_CHANGE'
    exporting
      header_data    = header_data
      header_control = header_control
      delivery       = p_del_no
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
  endif.

  util->show_message( itab_return = itab_return ).
