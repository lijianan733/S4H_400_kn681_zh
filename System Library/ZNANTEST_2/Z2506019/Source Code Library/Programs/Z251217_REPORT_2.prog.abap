*&---------------------------------------------------------------------*
*& Report z251217_report_1
*&---------------------------------------------------------------------*
*&   输入一个交货单，校验其有没后续凭证，没有的话标记为删除
*   条件：LIKP-WBSTK ≠ 'C'（C = 已过账，空 / 其他 = 未过账）
*    无后续发票凭证（VBFA表中无VBTYP_N='M'的记录）

" dn的删除和冲销不一样

" 抬头  WBSTK   LIKP    空 = 未过账；C = 已过账；A = 部分过账；*= 冲销过账（VL09 冲销发货后，该字段标记为*）
" 抬头  FKSTK   LIKP    空 = 未开票；C = 完全开票；A = 部分开票；*= 冲销开票（VF11 冲销发票后，该字段标记为*）

*WS_DELIVERY_DELETE
*&---------------------------------------------------------------------*
report z251217_report_2.
tables: vbfa,lips,likp,vbrk,bkpf,matdoc,ekko, ekpo,vbap,vbak. " BKPF会计凭证,matdoc物料凭证





types: begin of ty_billing_doc, " 发票凭证列表结构
         vbelv         type vbelv,
         dn_vbeln      type vbeln_vl, " 发货单编号
         billing_vbeln type vbeln_vf, " 发票凭证号
         billing_type  type fkart,    " 发票类型（如F2=标准发票）
         billing_date  type fkdat,    " 开票日期
         netwr         type netwr,    " 发票金额
         fksto         type fksto.    " 冲销标识（X=已冲销）
types  end of ty_billing_doc.

data billing_tab type standard table of vbfa with header line.

types : begin of type1, " 发货单结构
          vbeln     type vbeln_vl,
          erdat     type erdat,
          erzet     type erzet,
          spe_loekz type loekz_bk,
          wbstk     type wbstk,
          fkstk     type fkstk.
types   end of type1.

data tab1 type table of type1.


*&---------------------------------------------------------------------*
*& 输入参数：DN编号（支持单/批量）
*&---------------------------------------------------------------------*
parameters p_vbeln type likp-vbeln obligatory default '0080005235'.  " 单DN编号





at selection-screen output.


at selection-screen on value-request for p_vbeln.
  " F4帮助：可调用标准交货单F4 发货单号，创建日期 ，时间，删除标志,移动状态，发票状态等字段
  select vbeln, erdat,erzet,spe_loekz,wbstk,fkstk
    from likp
    into table @tab1
    where ernam = @sy-uname
      and wbstk = 'C'
    order by bldat descending,
             erzet descending.

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
  data ev_okay    type abap_bool value abap_true.
  data et_message type bapiret2_t.

  " perform judge_status.
  " perform get_dn_followup_billing_list.
  " perform is_valid.

  perform zmm002_dn_delete_check using p_vbeln
                                       ev_okay
                                       et_message.

  cl_demo_output=>display( et_message ).

*&---------------------------------------------------------------------*
*& 获取DN的后续开票凭证列表
*&---------------------------------------------------------------------*
form get_dn_followup_billing_list.
  " 获取发票凭证为 5 M 的后续凭证列表
  " TODO: variable is assigned but never used (ABAP cleaner)
  data carrid_range type range of spfli-carrid.

  carrid_range = value #( ( sign = 'I' option = 'EQ' low = '5' high = 'M' ) ).

  select * from vbfa
    into corresponding fields of table @billing_tab
    where vbelv = @p_vbeln.
endform.

form is_valid.
  data dd07v_wa    type dd07v.
  data rc          type syst_subrc.
  data dd07v_tab_a type standard table of dd07v with header line.
  data dd07v_tab_n type standard table of dd07v with header line.

  call function 'DD_DOMA_GET'
    exporting
      domain_name   = 'VBTYPL'
      langu         = sy-langu
      withtext      = 'X'
    tables
      dd07v_tab_a   = dd07v_tab_a
      dd07v_tab_n   = dd07v_tab_n
    exceptions
      illegal_value = 1
      op_failure    = 2
      others        = 3.

  loop at billing_tab into data(wa_billing).

    data(record) = dd07v_tab_a[ domvalue_l = wa_billing-vbtyp_n ].
    " TODO: variable is assigned but never used (ABAP cleaner)
    data(record2) = dd07v_tab_a[ domvalue_l = wa_billing-vbtyp_v ].
    data msg_text type string.
    data(value) = ''.
    value = wa_billing-vbtyp_n.
    call function 'DD_DOMVALUE_TEXT_GET'
      exporting
        domname  = 'VBTYPL'
        value    = 'M'
        langu    = sy-langu
      importing
        dd07v_wa = dd07v_wa
        rc       = rc.
    " TODO: variable is assigned but never used (ABAP cleaner)
    data is_valid type abap_bool value abap_true.
    if wa_billing-vbtyp_n = '5' or wa_billing-vbtyp_n = '6' or wa_billing-vbtyp_n = 'M'.
      " 有后续发票凭证
      " BKPF会计凭证表  XBLNR 参考凭证号
      select single * from bkpf
        into @data(wa_bkpf)
        where xblnr = @wa_billing-vbeln.
      if wa_bkpf is initial.
        " 没有会计凭证，说明过程有问题，不能直接删除
        is_valid = abap_false.

        msg_text = |{ msg_text }交货单 { p_vbeln } 有后续开票凭证 { wa_billing-vbeln }，但无会计凭证，不能删除;|.
      endif.

    endif.

    write: / 'DN:', p_vbeln,
*        ' 先前凭证:', wa_billing-vbelv,
*          ' 类型:', wa_billing-vbtyp_v,
*             ' 类型描述:', record2-ddtext,
             ' 后续凭证:', wa_billing-vbeln,
             ' 类型:', wa_billing-vbtyp_n,
             ' 类型描述:', record-ddtext.

    " 判断有没会计凭证，如果没有会计凭证，说明过程有问题，不能直接删除

  endloop.
  write / |{ msg_text } |.
endform.

form judge_status.
  " F4帮助：可调用标准交货单F4 发货单号，创建日期 ，时间，删除标志,移动状态，发票状态等字段
  " wbstk
  " ' '   无关
  " 'A' 没有处理
  " 'B' 部分处理
  " 'C' 完全地处理
  select vbeln, erdat,erzet,spe_loekz,wbstk,fkstk from likp into table @tab1 where ernam = @sy-uname.
  " TODO: variable is assigned but never used (ABAP cleaner)
  data tab2 like tab1.
  loop at tab1 into data(wa_tab1).
    " 读取DN信息
    if wa_tab1-spe_loekz <> abap_true and wa_tab1-wbstk cn 'BC' and wa_tab1-fkstk cn 'BC'. " 未删除
      append wa_tab1 to tab2.
    endif.

  endloop.

  " cl_demo_output=>display( tab2 ).
endform.

form zmm002_dn_delete_check using    iv_vbeln   type vbeln_vl
                                     ev_okay    type abap_bool
                            changing et_message type bapiret2_t.

  check sy-uname = 'KN681'.

  data msg_text type string.

  " 根据交货单号，查找后续凭证中开票，如果开票没有生成会计凭证，则标识为不正常，不管后续凭证是否已经冲销，不允许删除交货单
  " 获取发票凭证为M N的后续凭证列表
  select vbfa~vbelv, " DN
         vbfa~vbeln, " 后续凭证
         vbfa~vbtyp_n, " 凭证类型
         bkpf~belnr " 会计凭证
    from vbfa
           left outer join
             bkpf on vbfa~vbeln = bkpf~awkey "BKPF会计凭证表  AWKEY 参考键
    into table @data(billing_tab)
    where vbfa~vbelv = @iv_vbeln and ( vbfa~vbtyp_n = '5' or vbfa~vbtyp_n = '6' or vbfa~vbtyp_n = 'M' or vbfa~vbtyp_n = 'N' ). " 如果后续凭证为发票类型,或者为发票的冲销
  loop at billing_tab into data(wa_billing).
    " 如果会计凭证为空，说明开票异常
    if wa_billing-belnr is initial.
      " 没有会计凭证，说明过程有问题，不能直接删除
      ev_okay = abap_false.
      msg_text = |交货单:{ iv_vbeln }有后续开票凭证{ wa_billing-vbeln }，但无会计凭证，不能删除;|.
    endif.
  endloop.

  if ev_okay = abap_false.
    append value #( type    = 'E'
                    id      = 'ZSD'
                    number  = '000'
                    message = cond #( when sy-langu = '1' then msg_text else msg_text  ) ) to et_message.
  endif.

  cl_demo_output=>display( billing_tab ).
endform.
