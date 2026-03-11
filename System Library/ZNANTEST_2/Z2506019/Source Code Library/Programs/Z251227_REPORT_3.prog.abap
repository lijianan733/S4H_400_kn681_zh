*&---------------------------------------------------------------------*
*& Report z251227_report_3
*&---------------------------------------------------------------------*
*& DN发货过账的冲销

* WS_REVERSE_GOODS_ISSUE

*用这个bapi过账，当用vl09冲销的时候就会报错：
*
*不能取消来自分散系统的货物移动
*
*
*   交货单对应的 LIKP-VLSTK 字段 清空。


*&---------------------------------------------------------------------*
report z251227_report_3.
tables likp.
parameters p_dn type vbeln_vl obligatory. " 交货单号
parameters P_date type sy-datlo default sy-datlo. " 实际货物移动日期


at selection-screen on value-request for p_dn. " 通过代码写F4筛选逻辑
  perform frm_f4_konnr.


start-of-selection.
  data mblnr type mblnr.      " 冲销凭证
  data mjahr type mjahr.      " 物料凭证的年份
  data mseg type bapi_msg.   " 返回消息
  data ztype type bapi_mtype. " 消息类型: S 成功,E 错误,W 警告,I 信息,A 中断d

  perform zmom_sd003_00002
          using
            p_dn
            P_date
          changing
            mblnr
            mjahr
            mseg
            ztype.
  write: / '物料凭证号:', mblnr,
          / '物料凭证年份:', mjahr,
          / '消息类型:', ztype,
          / '消息内容:', mseg.


form frm_f4_konnr.
  select vbeln,erdat, ternr,wbstk
    from likp
    into table @data(tab1)
    where ernam = @sy-uname
      and wbstk = 'C' " 状态为发货过账
    order by erdat descending,
             erzet descending.
  call function 'F4IF_INT_TABLE_VALUE_REQUEST'
    exporting
      retfield        = 'VBELN'            " 这个参数为帮助表中返回到选择屏幕的字段的参数
      dynpprog        = sy-repid           " 当前程序，不写会有问题
      dynpnr          = sy-dynnr           " 当前屏幕，不写会有问题
      dynprofield     = 'P_DN'       " 选择屏幕上需要加F4帮助的字段
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

form zmom_sd003_00002
    using    i_vbeln     type vbeln_vl " dN
           i_wadat_ist type wadat_ist " 实际货物移动日期
  changing mblnr       type mblnr " 冲销凭证
           mjahr       type mjahr " 物料凭证的年份
           mseg        type bapi_msg " 返回消息
           ztype       type bapi_mtype. " 消息类型: S 成功,E 错误,W 警告,I 信息,A 中断

  check i_vbeln is not initial and i_wadat_ist is not initial.

  " TODO: variable is never used (ABAP cleaner)
  data lt_vbfa  like table of vbfa.
  " TODO: variable is never used (ABAP cleaner)
  data ls_vbfa  type vbfa.
  data lv_vgbel type vbeln.
  data lv_vbeln type vbeln.


  "清除交货的的标识，以便冲销
  field-symbols: <obj1> type likp.
  select single * from likp where vbeln = @i_vbeln into @data(obj1).
  assign obj1 to <obj1>.

  <obj1>-vlstk = ''."分配状态(分散仓库处理)
  modify likp from <obj1>.
  commit work and wait.





  clear:lv_vbeln,
         lv_vgbel.

  lv_vbeln = i_vbeln.

  call function 'CONVERSION_EXIT_ALPHA_INPUT'
    exporting
      input  = lv_vbeln
    importing
      output = lv_vbeln.
*&检查交货单是否过账
  select single vgbel into lv_vgbel from lips where vbeln = lv_vbeln.
  if lv_vgbel is initial.
    mseg = '交货单不存在'.
    ztype = 'E'.
    return.
  endif.
*&
*&* Data Define
  data ls_emkpf  type emkpf.
  data lt_return type table of mesg with header line.
  clear: lt_return[],
         ls_emkpf.
  call function 'WS_REVERSE_GOODS_ISSUE'
    exporting
      i_vbeln                   = lv_vbeln
      i_budat                   = i_wadat_ist
      i_tcode                   = 'VL09'
      i_vbtyp                   = 'J'
    importing
      es_emkpf                  = ls_emkpf
    tables
      t_mesg                    = lt_return
    exceptions
      error_reverse_goods_issue = 1
      error_message             = 99
      others                    = 2.
  if ls_emkpf-mblnr is not initial.
    commit work and wait.
    mblnr = ls_emkpf-mblnr.
    mjahr = ls_emkpf-mjahr.
    mseg = '冲销成功'.
    ztype = 'S'.
  else.
    loop at lt_return.
      concatenate lt_return-text mseg into mseg.
    endloop.
    concatenate '冲销失败' mseg into mseg.
  endif.
endform.
