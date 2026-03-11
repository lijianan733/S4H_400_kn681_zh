*&---------------------------------------------------------------------*
*& Report z250619_report_5
*发货单拣配，过账

" 前面说过，可以使用  WS_DELIVERY_UPDATE
" 进行外向交货单的发货过账，当然，这个可实现的很多，过账，冲销，删除都可以
"
" 但是这个不是bapi，是个函数，则会缺少bapi自带的那些校验
"
" 为了更安全，其实建议是使用 BAPI_OUTB_DELIVERY_CONFIRM_DEC
"
" 但同时遇到一个问题，就是使用BAPI_OUTB_DELIVERY_CONFIRM_DEC发货过账，不能冲销
"
" 提示啥我忘记了，好像是什么分散啥啥的
"
" 解决办法，目前知道是在增强里去清空一个字段
" 增强BADI：LE_SHP_DELIVERY_PROC
" 方法：CHANGE_DELIVERY_HEADER
" 清空值：CS_LIKP -VLSTK .“分配状态(分散仓库处理)
"
" 然后再调用bapi就不会冲销不掉了
" &----------------------------------------------------------------------
report z250619_report_5.
selection-screen begin of block b02 with frame title text-002.
parameters p_del_no type likp-vbeln. " 维护视图
selection-screen end of block b02.
data header_data    type bapiobdlvhdrcon.     " 外向交货提货数据标题级别验证
data header_control type bapiobdlvhdrctrlcon. " 外向交货标题级别控制数据
data lt_return      type standard table of bapiret2 with header line.


at selection-screen on value-request for p_del_no. " 通过代码写F4筛选逻辑
  perform frm_f4_p_del_no.

start-of-selection.
  header_data-deliv_numb = p_del_no.
  header_control-deliv_numb  = p_del_no.
  header_control-post_gi_flg = 'X'.
  header_control-volume_flg  = 'X'.

  " 外向交货单发货过账
  call function 'BAPI_OUTB_DELIVERY_CONFIRM_DEC'
    exporting
      header_data    = header_data
      header_control = header_control
      delivery       = p_del_no
    tables
      return         = lt_return.

  if sy-subrc <> 0.
    " Implement suitable error handling here
  endif.
  data error_log type string.
  LOOP AT lt_return INTO data(wa_return).
    IF wa_return-type = 'E'.
      error_log = 'X'.
      EXIT.
    ENDIF.
    CLEAR wa_return.
  ENDLOOP.
  IF error_log = 'X'.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    WRITE 'MESSAGE ERROR'.
    LOOP AT lt_return INTO wa_return.
      WRITE: / wa_return-type, wa_return-message.
      CLEAR wa_return.
    ENDLOOP.
  ELSE.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = 'X'.
    LOOP AT lt_return INTO wa_return.
      WRITE: / wa_return-type,wa_return-message.
      CLEAR wa_return.
    ENDLOOP.
  ENDIF.


form frm_f4_p_del_no.
  data lt_return1 type standard table of ddshretval with header line.

  select vbeln,erdat,erzet, lfart,xblnr,gbstk from likp into table @data(tab1)
    where ernam = 'KN681'
   order by erdat descending.
  call function 'F4IF_INT_TABLE_VALUE_REQUEST'
    exporting
*      DDIC_STRUCTURE  = ' '
      retfield        = 'VBELN'            " 这个参数为帮助表中返回到选择屏幕的字段的参数
*      PVALKEY         = ' '
      dynpprog        = sy-repid           " 当前程序，不写会有问题
      dynpnr          = sy-dynnr           " 当前屏幕，不写会有问题
      dynprofield     = 'P_DEL_NO'       " 选择屏幕上需要加F4帮助的字段
*      STEPL           = 0
*      WINDOW_TITLE    =
*      VALUE           = ' '
      value_org       = 'S'                " 默认为C但是此处不用S不行
*      MULTIPLE_CHOICE = ' '
*      DISPLAY         = ' '
*      CALLBACK_PROGRAM = ' '
*      CALLBACK_FORM   = ' '
*      CALLBACK_METHOD =
*      MARK_TAB        =
*  IMPORTING
*      USER_RESET      =
    tables
      value_tab       = tab1           " F4帮助值的表
*      FIELD_TAB       =
      RETURN_TAB      = lt_return1
*      DYNPFLD_MAPPING =
    exceptions
      parameter_error = 1
      no_values_found = 2
      others          = 3.
endform.
