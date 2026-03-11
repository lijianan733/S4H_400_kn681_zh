*&---------------------------------------------------------------------*
*& Report z251226_report_1
*&---------------------------------------------------------------------*
*&  migo的冲销
*  BAPI_GOODSMVT_CANCEL
*&---------------------------------------------------------------------*
report z251226_report_1.
tables matdoc.

parameters: p_vbeln type vbeln_vl obligatory,
            p_wadat type gjahr obligatory default sy-datum.


at selection-screen on value-request for p_vbeln.
  " F4帮助：可调用标准交货单F4 发货单号，创建日期 ，时间，删除标志,移动状态，发票状态等字段
  perform do_f4.




start-of-selection.


form do_f4.
  select mblnr,record_type,matbf,ebeln,xblnr,vbeln_im,bldat,cputm
    from matdoc
    into table @data(tab1)
    up to 100 rows
    where usnam = @sy-uname
    order by bldat descending,
             cputm descending.

  " cl_demo_output=>display( tab1 ).

  call function 'F4IF_INT_TABLE_VALUE_REQUEST'
    exporting
      retfield        = 'MBLNR'
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
endform.
