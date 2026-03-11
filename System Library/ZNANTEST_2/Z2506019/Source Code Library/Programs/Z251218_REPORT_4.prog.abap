*&---------------------------------------------------------------------*
*& Report z251218_report_4
*&---------------------------------------------------------------------*
*& 根据发货单进行开票VF01
*BAPI_BILLINGDOC_CREATEMULTIPLE
*&---------------------------------------------------------------------*
report z251218_report_4.


type-pools slis. " ALV
tables:lips,vkdfs,vbrk,vbrp,vbfa.
" ----------------------------------------------------------------------
" &数据类型定义
" ----------------------------------------------------------------------
types:
  begin of tp_vkdfs,
    vbeln type vkdfs-vbeln,
    fkart type vkdfs-fkart,
  end of tp_vkdfs.

types:
  begin of tp_vbfa,
    vbelv type vbfa-vbelv,
    posnv type vbfa-posnv,
    vbeln type vbfa-vbeln,
    posnn type vbfa-posnn,
    vbtyp type vbfa-vbtyp_n,
    rfmng type vbfa-rfmng,
  end of tp_vbfa.

types:
  begin of tp_data,
    vbeln type lips-vbeln,
    posnr type lips-posnr,
    arktx type lips-arktx,
    matnr type lips-matnr,
    lfimg type lips-lfimg,
    vrkme type lips-vrkme,
    vkorg type likp-vkorg,
    fkdat type likp-fkdat,
    vbtyp type likp-vbtyp,
    rfmng type vbfa-rfmng,
    menge type lips-lfimg,
    fkimg type vbrp-fkimg,
    fp    type vbrp-vbeln,
    fkart type vkdfs-fkart,
    prsdt type prsdt,
    chk   type c length 1,
  end of tp_data.
" ----------------------------------------------------------------------
" &全局数据定义
" ----------------------------------------------------------------------
data gt_data     type table of tp_data.

data gs_fieldcat type lvc_s_fcat.

define editfieldcat.
  clear gs_fieldcat.
  gs_fieldcat-fieldname  = &1.
  gs_fieldcat-no_zero    = &2.
  gs_fieldcat-fix_column = &3.
  gs_fieldcat-icon       = &4.
  gs_fieldcat-ref_table  = &5.
  gs_fieldcat-ref_field  = &6.
  gs_fieldcat-coltext    = &8.
  gs_fieldcat-hotspot    = 'X'.
  if &1 = 'FKIMG' or &1 = 'FKDAT' or &1 = 'PRSDT'.
    gs_fieldcat-edit = 'X'.
  endif.

  append gs_fieldcat to &7.

end-of-definition.
" ----------------------------------------------------------------------
" &全局常量定义
" ----------------------------------------------------------------------

" ----------------------------------------------------------------------
" &选择画面定义
" ----------------------------------------------------------------------
selection-screen begin of block b1 with frame title text-b01.
parameters s_vbeln type lips-vbeln obligatory. " 交货单号
select-options s_matnr for lips-matnr  no-display.
select-options s_fkart for vkdfs-fkart no-display.
selection-screen end of block b1.
" ----------------------------------------------------------------------
" &初始化
" ----------------------------------------------------------------------

initialization.
  " ----------------------------------------------------------------------
  " &选择画面相应
  " ----------------------------------------------------------------------

at selection-screen on value-request for s_vbeln. " 通过代码写F4筛选逻辑
  perform frm_f4_konnr.




at selection-screen.
  " ----------------------------------------------------------------------
  " &程序运行
  " ----------------------------------------------------------------------

start-of-selection.
  perform fm_get_data.

  perform fm_out_alv.

  " ----------------------------------------------------------------------
  " &程序结果
  " ----------------------------------------------------------------------

end-of-selection.
*&---------------------------------------------------------------------*
*&      Form  FM_GET_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form fm_get_data.
  data lt_vkdfs    type table of tp_vkdfs.
  data ls_vkdfs    type tp_vkdfs.

  data lt_vbfa     type table of tp_vbfa.
  data lt_vbfa_sum type table of tp_vbfa.
  data lt_vbfa_ivs type table of tp_vbfa.
  data ls_vbfa     type tp_vbfa.

  data lt_data     type table of tp_data.
  data ls_data     type tp_data.

  " VKDFS是 SD 模块（开票）与 FI 模块（应收）的核心关联表，全称是Billing Document: Cash Flow（开票凭证现金流表）
  " 主要存储开票凭证（发票 / DN 关联的收款类凭证）的现金流计划（如分期付款、收款到期日、金额）
  " 是管理发票收款计划、SD-FI 对账的关键表

  select vbeln
         fkart
    into table lt_vkdfs
    from vkdfs
    where vbeln  = s_vbeln
      and vbtyp in ('J')
      and fkart in s_fkart.

  if lt_vkdfs is initial.
    message '没有数据可供显示' type 'S' display like 'E'.
    leave list-processing.
  endif.

  select lips~vbeln
         lips~posnr
         lips~arktx
         lips~matnr
         lips~lfimg
         lips~vrkme
         likp~vkorg
         likp~fkdat
         likp~vbtyp
    into table lt_data
    from lips
           inner join
             likp on likp~vbeln = lips~vbeln
    for all entries in lt_vkdfs
    where lips~vbeln  = lt_vkdfs-vbeln
      and lips~matnr in s_matnr.

  if lt_data is initial.
    message '没有数据可供显示' type 'S' display like 'E'.
    leave list-processing.
  endif.

  select vbfa~vbelv
         vbfa~posnv
         vbfa~vbeln
         vbfa~posnn
         vbfa~vbtyp_n
         vbfa~rfmng
    into table lt_vbfa
    from vbfa
    for all entries in lt_data
    where vbfa~vbelv    = lt_data-vbeln
      and vbfa~posnv    = lt_data-posnr
      and vbfa~vbtyp_n in ( 'M', 'N', 'O', 'S', '5', '6' ).

  loop at lt_vbfa into ls_vbfa where vbtyp = 'M' or vbtyp = 'N' or vbtyp = 'O' or vbtyp = 'S'.
    if ls_vbfa-vbtyp = 'N' or ls_vbfa-vbtyp = 'S'.
      ls_vbfa-rfmng = 0 - ls_vbfa-rfmng.
    endif.

    clear:ls_vbfa-vbeln,
           ls_vbfa-posnn,
           ls_vbfa-vbtyp.
    collect ls_vbfa into lt_vbfa_sum.
  endloop.

  loop at lt_vbfa into ls_vbfa where vbtyp = '5' or vbtyp = '6'.
    if ls_vbfa-vbtyp = '6'.
      ls_vbfa-rfmng = 0 - ls_vbfa-rfmng.
    endif.

    clear:ls_vbfa-vbeln,
           ls_vbfa-posnn,
           ls_vbfa-vbtyp.
    collect ls_vbfa into lt_vbfa_ivs.
  endloop.

  sort lt_vbfa_sum by vbelv
                      posnv.

  loop at lt_vkdfs into ls_vkdfs.
    clear ls_data.
    loop at lt_data into ls_data where vbeln = ls_vkdfs-vbeln.
      ls_data-fkart = ls_vkdfs-fkart.
      ls_data-prsdt = sy-datum.
      ls_data-fkdat = sy-datum.
      if ls_vkdfs-fkart <> 'IV'.
        read table lt_vbfa_sum into ls_vbfa with key vbelv = ls_data-vbeln
                                                     posnv = ls_data-posnr binary search.
        if sy-subrc = 0.
          ls_data-rfmng = ls_vbfa-rfmng.
          ls_data-fkimg = ls_data-lfimg - ls_data-rfmng.
          ls_data-menge = ls_data-lfimg - ls_data-rfmng.
        else.
          ls_data-fkimg = ls_data-lfimg.
          ls_data-menge = ls_data-lfimg.
        endif.
      else.
        read table lt_vbfa_ivs into ls_vbfa with key vbelv = ls_data-vbeln
                                                     posnv = ls_data-posnr binary search.
        if sy-subrc = 0.
          ls_data-rfmng = ls_vbfa-rfmng.
          ls_data-fkimg = ls_data-lfimg - ls_data-rfmng.
          ls_data-menge = ls_data-lfimg - ls_data-rfmng.
        else.
          ls_data-fkimg = ls_data-lfimg.
          ls_data-menge = ls_data-lfimg.
        endif.
      endif.
      append ls_data to gt_data.
    endloop.
  endloop.

  delete gt_data where fkimg <= 0.
endform.

*&---------------------------------------------------------------------*
*&      Form  fm_out_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
form fm_out_alv.
  data ls_vari     type disvariant.
  data ls_layout   type lvc_s_layo.
  data lt_fieldcat type lvc_t_fcat.

  ls_layout-box_fname = 'CHK'.

  editfieldcat
     'VBELN' 'X' 'X' '' 'LIPS' 'VBELN' lt_fieldcat text-001.
  editfieldcat
     'POSNR' 'X' 'X' '' 'LIPS' 'POSNR' lt_fieldcat text-002.
  editfieldcat
     'FKART' 'X' '' '' 'LIKP' 'FKARV' lt_fieldcat text-020.
  editfieldcat
     'ARKTX' '' '' '' 'LIPS' 'ARKTX' lt_fieldcat text-003.
  editfieldcat
     'MATNR' 'X' '' '' 'LIPS' 'MATNR' lt_fieldcat text-004.
  editfieldcat
     'LFIMG' '' '' '' 'LIPS' 'LFIMG' lt_fieldcat text-005.
  editfieldcat
     'VRKME' '' '' '' 'LIPS' 'VRKME' lt_fieldcat text-006.
  editfieldcat
     'FKDAT' '' '' '' 'LIKP' 'FKDAT' lt_fieldcat text-007.
  editfieldcat
     'PRSDT' '' '' '' 'LIKP' 'FKDAT' lt_fieldcat text-012.
  editfieldcat
     'RFMNG' '' '' '' 'VBFA' 'RFMNG' lt_fieldcat text-008.
  editfieldcat
     'MENGE' '' '' '' 'LIPS' 'LFIMG' lt_fieldcat text-009.
  editfieldcat
     'FKIMG' '' '' '' 'VBRP' 'FKIMG' lt_fieldcat text-010.
  editfieldcat
     'FP' '' '' '' 'VBRP' 'VBELN' lt_fieldcat text-011.

  call function 'REUSE_ALV_GRID_DISPLAY_LVC'
    exporting
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'FM_PF_STATUS'
      i_callback_user_command  = 'FM_USER_COMMAND'
      is_layout_lvc            = ls_layout
      it_fieldcat_lvc          = lt_fieldcat
      i_default                = 'X'
      i_save                   = 'A'
      is_variant               = ls_vari
    tables
      t_outtab                 = gt_data.
endform.

*&---------------------------------------------------------------------*
*&      Form  fm_pf_status
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->RT_EXTAB   text
*----------------------------------------------------------------------*
form fm_pf_status using rt_extab type slis_t_extab.
  " TODO: variable is never used (ABAP cleaner)
  data ls_extab type slis_extab.

  " set pf-status 'PFSTATUS' excluding rt_extab.
endform.

*&---------------------------------------------------------------------*
*&      Form  fm_user_command
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->UCOMM        text
*      -->IS_SELFIELD  text
*----------------------------------------------------------------------*
form fm_user_command using ucomm       like sy-ucomm
                           is_selfield type slis_selfield.

  data lr_grid type ref to cl_gui_alv_grid.

  field-symbols <fs_data> type tp_data.

  call function 'GET_GLOBALS_FROM_SLVC_FULLSCR'
    importing
      e_grid = lr_grid.

  lr_grid->check_changed_data( ).
  message | { ucomm } | type 'I'.
  case ucomm.

    when '&IC1'. " 行的点击事件
      read table gt_data into data(ls_itab) index is_selfield-tabindex.
      if is_selfield-fieldname = 'VBELN' and ls_itab-vbeln is not initial.
        set parameter id 'VL' field ls_itab-vbeln.
        call transaction 'VL03N' and skip first screen.
      endif.

    when 'ONLI'.
      loop at gt_data assigning <fs_data> where chk = 'X' and fp = '' and fkimg > 0.
        if <fs_data>-fkimg > <fs_data>-menge.
          message '创建发票的数量超过未清数量'(040) type 'E'.
        endif.
      endloop.
      if sy-subrc <> 0.
        message '请选择创建发票的订单'(037) type 'E'.
      endif.

      perform fm_create_fp.

  endcase.

  " 重新加载数据
  is_selfield-refresh    = 'X'.
  is_selfield-col_stable = 'X'.
  is_selfield-row_stable = 'X'.
endform.

*&---------------------------------------------------------------------*
*&      Form  FM_CREATE_FP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form fm_create_fp.
  data lt_billingdatain type table of bapivbrk. " 开票标题字段的通讯字段
  data ls_billingdatain type bapivbrk.
  data lt_return        type table of bapiret1.
  " TODO: variable is never used (ABAP cleaner)
  data ls_return        type bapiret1.
  data lt_success type table of bapivbrksuccess. " 有关成功处理记帐凭证项目的信息
  data ls_success       type bapivbrksuccess.

  data ls_data          type tp_data.

  field-symbols <fs_data> type tp_data.

  loop at gt_data into ls_data where chk = 'X' and fp = '' and fkimg > 0.
    ls_billingdatain-salesorg   = ls_data-vkorg."销售组织
    ls_billingdatain-ordbilltyp = ls_data-fkart."建议的发票类型

    ls_billingdatain-ref_doc    = ls_data-vbeln."参考单据号码
    ls_billingdatain-doc_number = ls_data-vbeln."参考单据号码
    ls_billingdatain-ref_item   = ls_data-posnr."参考单据项目

    ls_billingdatain-price_date = ls_data-prsdt."定价和汇率的日期
    ls_billingdatain-bill_date  = ls_data-fkdat."发票日期
    ls_billingdatain-ref_doc_ca = ls_data-vbtyp."先前凭证类型
    ls_billingdatain-material   = ls_data-matnr."物料编号
    ls_billingdatain-req_qty    = ls_data-fkimg."开票数量

    append ls_billingdatain to lt_billingdatain.
  endloop.

  call function 'BAPI_BILLINGDOC_CREATEMULTIPLE'
    tables
      billingdatain = lt_billingdatain
      return        = lt_return
      success       = lt_success.

  if lt_success is not initial.
  "提交事务并且等待完成
    call function 'BAPI_TRANSACTION_COMMIT'
      exporting
        wait = 'X'.
    loop at gt_data assigning <fs_data> where chk = 'X' and fp = '' and fkimg > 0.
      clear ls_success.
      read table lt_success into ls_success with key ref_doc      = <fs_data>-vbeln
                                                     ref_doc_item = <fs_data>-posnr.
      if sy-subrc = 0.
        <fs_data>-fp     = ls_success-bill_doc." 发票号码
        <fs_data>-menge -= <fs_data>-fkimg." 未清数量减少
        <fs_data>-rfmng += <fs_data>-fkimg." 已开数量增加

        <fs_data>-fkimg  = <fs_data>-lfimg - <fs_data>-rfmng." 开票数量重新计算
      endif.
    endloop.

    message '发票生成成功' type 'S'.
  else.
    call function 'BAPI_TRANSACTION_ROLLBACK'.

    message '发票生成错误' type 'S' display like 'E'.
  endif.
endform.

form frm_f4_konnr.
  " wbstk 查找出已过账，FKSTK 但是未开票的交货的
  select vbeln,erdat,wbstk,fkstk from likp
    into table @data(tab1)
    where ernam = @sy-uname and wbstk = 'C' and fkstk = ''
    order by erdat descending.
  call function 'F4IF_INT_TABLE_VALUE_REQUEST'
    exporting
      retfield        = 'VBELN'            " 这个参数为帮助表中返回到选择屏幕的字段的参数
      dynpprog        = sy-repid           " 当前程序，不写会有问题
      dynpnr          = sy-dynnr           " 当前屏幕，不写会有问题
      dynprofield     = 'S_VBELN'       " 选择屏幕上需要加F4帮助的字段
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
