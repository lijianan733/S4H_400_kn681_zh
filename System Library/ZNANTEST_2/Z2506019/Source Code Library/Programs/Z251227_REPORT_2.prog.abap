*&---------------------------------------------------------------------*
*& Report z250813_report_1
*&---------------------------------------------------------------------*
*&  使用bapi BAPI_GOODSMVT_CREATE 来进行migo过账
*  最简单的101过账的吃你下
*&---------------------------------------------------------------------*
report z251227_report_2.
tables: ekko,ekpo.
parameters p_dn type ekko-ebeln.
parameters p_wadat type gjahr default sy-datlo.


at selection-screen on value-request for p_dn.
  " F4帮助：可调用标准交货单F4 发货单号，创建日期 ，时间，删除标志,移动状态，发票状态等字段 VGBEL参考的凭证
  select likp~vbeln,
         likp~erdat,
         likp~erzet,
         spe_loekz,
         wbstk,
         fkstk,
         vgbel
    from likp
           join
             lips on likp~vbeln = lips~vbeln
    into table @data(tab1)
    where likp~ernam = @sy-uname
      and wbstk      = 'C'
    order by bldat descending. " 发货过账后的DN

  " cl_demo_output=>display( tab1 ).

  call function 'F4IF_INT_TABLE_VALUE_REQUEST'
    exporting
      retfield        = 'VBELN'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = 'P_VBELN'
      value_org       = 'S'
    tables
      value_tab       = tab1
    exceptions
      parameter_error = 1
      no_values_found = 2
      others          = 3.

start-of-selection.
  " 获取采购订单数据
  perform reverse_good_reciver.


form reverse_good_reciver.





  data p_vbeln type mblnr.

  select single  vbeln from vbfa
    into  @p_vbeln
    where vbelv = @p_dn
      and vbtyp_n = 'i'.
  data lt_return1 type standard table of bapiret2 with header line.
  data error_log  type char1.
  call function 'BAPI_GOODSMVT_CANCEL'
    exporting
      materialdocument = p_vbeln
      matdocumentyear  = p_wadat
*     goodsmvt_pstng_date =
*     goodsmvt_pr_uname =
*     documentheader_text =
*    importing
*     goodsmvt_headret =
    tables
      return           = lt_return1.
*     goodsmvt_matdocitem =

  loop at lt_return1 into data(wa_return).
    if wa_return-type = 'E'.
      error_log = 'X'.
      exit.
    endif.
    clear wa_return.
  endloop.
  if error_log = 'X'.
    call function 'BAPI_TRANSACTION_ROLLBACK'.
    write 'MESSAGE ERROR'.
    loop at lt_return1 into wa_return.
      write: / wa_return-type, wa_return-message.
      clear wa_return.
    endloop.
  else.
    call function 'BAPI_TRANSACTION_COMMIT'
      exporting
        wait = 'X'.
    loop at lt_return1 into wa_return.
      write: / wa_return-type,wa_return-message.
      clear wa_return.
    endloop.
  endif.
endform.
