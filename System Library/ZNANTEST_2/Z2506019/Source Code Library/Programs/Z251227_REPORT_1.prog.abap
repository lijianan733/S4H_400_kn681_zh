*&---------------------------------------------------------------------*
*& Report z251227_report_1
*&---------------------------------------------------------------------*
*& 发票的冲销

" MR8M 发票冲销
"
" 采购发票冲销-输入:
"
" BAPI_INCOMINGINVOICE_CANCEL
"
*2. 销售发票冲销 (VF11)
*
*使用 BAPI_BILLINGDOC_CANCEL 函数模块来冲销销售发票。

" 采购发票冲销-确认:
"
" BAPI_TRANSACTION_COMMIT
" &----------------------------------------------------------------------
report z251227_report_1.
tables:vbrk,vbap,rbkp.
parameters: re_belnr type bill_doc obligatory,
            gjahr    type bf_datm1eb default sy-datum obligatory,
            stgrd    type bapi_incinv_fld-reason_rev default 'Z6' obligatory.


at selection-screen on value-request for re_belnr. " 通过代码写F4筛选逻辑
  perform frm_f4_konnr.


start-of-selection.
  data lt_return1 type standard table of bapiret2 with header line.
  data error_log  type char1.
  data    success type standard table of bapivbrksuccess with header line.

  call function 'BAPI_BILLINGDOC_CANCEL1'
    exporting
      billingdocument = re_belnr
      billingdate     = gjahr
    tables
      return          = lt_return1
      success         = success.

*  call function 'BAPI_INCOMINGINVOICE_CANCEL'
*    exporting
*      invoicedocnumber          =  rbkp
*      fiscalyear                =
*      reasonreversal            =
**      postingdate               =
**    importing
**      invoicedocnumber_reversal =
**      fiscalyear_reversal       =
*    tables
*      return                    =
*    .



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







form frm_f4_konnr.
  select vbeln, fkart,fktyp,vbtyp,waerk,erdat
    from vbrk
    into table @data(tab1)
    order by erdat descending.
  call function 'F4IF_INT_TABLE_VALUE_REQUEST'
    exporting
      retfield        = 'VBELN'            " 这个参数为帮助表中返回到选择屏幕的字段的参数
      dynpprog        = sy-repid           " 当前程序，不写会有问题
      dynpnr          = sy-dynnr           " 当前屏幕，不写会有问题
      dynprofield     = 'RE_BELNR'       " 选择屏幕上需要加F4帮助的字段
      value_org       = 'S'                " 默认为C但是此处不用S不行
    tables
      value_tab       = tab1           " F4帮助值的表
    exceptions
      parameter_error = 1
      no_values_found = 2
      others          = 3.
  if sy-subrc <> 0.
    " Implement suitable error handling here
  endif.
endform.
