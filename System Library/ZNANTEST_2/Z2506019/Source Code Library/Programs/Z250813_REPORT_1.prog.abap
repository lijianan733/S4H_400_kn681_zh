*&---------------------------------------------------------------------*
*& Report z250813_report_1
*&---------------------------------------------------------------------*
*&  使用bapi BAPI_GOODSMVT_CREATE 来进行migo过账
*当遇到移动类型不知道选择GOODSMVT_CODE对应的CODE时，可以通过移动类型查询T158B表和T158G，找到对应的CODE值
*&---------------------------------------------------------------------*
report z250813_report_1.

select * from z250813_view_1 into table @data(tab1) where mandt = @sy-mandt order by bwart.
data itab             type range of i.
*cl_demo_output=>display( tab1 ).

data goodsmvt_header  type bapi2017_gm_head_01. " 创建物料凭证抬头数据
data goodsmvt_code    type bapi2017_gm_code.    " 业务类型-收货
data goodsmvt_item_01 type standard table of bapi2017_gm_item_create with header line. " 创建物料凭证项目
data materialdocument type mblnr.               " 物料凭证
data lt_return        type standard table of bapiret2 with header line.

" 01 MB01 按采购订单的货物移动
" 02 MB31 按生产订单的货物移动
" 03 MB1A 货物提取（工单发料）
" 04 MB1B 转移过帐
" 05 MB1C 其他收货
" 06 MB11 货物移动
" 07 MB04 "物料供应"消耗的事后调整
data(po_no) = '4500007727'.
data(p_vbeln) = '0080004823'. " 交货单号

goodsmvt_code = '01'. " 业务是收货
goodsmvt_header-ref_doc_no    = p_vbeln. " 参考凭证编号
goodsmvt_header-gr_gi_slip_no = p_vbeln. " 收货/发货单编号
goodsmvt_header-bill_of_lading = p_vbeln. " 收货/发货单编号
goodsmvt_header-bill_of_lading_long = p_vbeln.
goodsmvt_header-doc_date      = sy-datum. " 文档日期
goodsmvt_header-pstng_date    = sy-datum. " 过账日期
goodsmvt_header-pr_uname      = sy-datum. " 用户名

select single * from lips into @data(deli_data) where lips~vbeln = @p_vbeln. " 获取交货单单数据
select single * from ekpo into @data(po_data) where ekpo~ebeln = @deli_data-vgbel. " 根据交货单获得对应的采购订单项数据
" ' ' 无参考的货物移动
" 'B' 按采购订单的货物移动
" 'F' 有关生产单的货物移动
" 'L' 有关交货通知的货物移动
" 'K' 看板需求的货物移动（WM－仅限内部）
" 'O' "提供物料"消耗的后续调整
" 'W' 比例的后续调整/产品单位物料
goodsmvt_item_01 = value #( deliv_numb = deli_data-vbeln " 交货单号
                            deliv_item = deli_data-posnr " 交货单行
                            po_number  = deli_data-vgbel " 采购订单号
                            po_item    = deli_data-vgpos " 采购订单行项目
                            stge_loc   = deli_data-lgort " 库位
                            entry_qnt  = deli_data-lfimg " 交货数量
                            entry_uom  = deli_data-vrkme " 交货单位
                            material   = po_data-matnr " 物料
                            plant      = po_data-werks " 工厂
                            move_type  = '101' " 移动类型
                            mvt_ind    = 'B' " 移动标识，根据交货单的收货
                            item_text  = 'nantestttttt'
                            move_reas  = 'testReson' ).

append goodsmvt_item_01.

data(out) = cl_demo_output=>new( ).
out->write_data( deli_data ).
out->write_data( po_data ).

*out->display( ).
data goodsmvt_headret type bapi2017_gm_head_ret.
data matdocumentyear  type mjahr.

call function 'BAPI_GOODSMVT_CREATE'
  exporting goodsmvt_header  = goodsmvt_header " 物料凭证抬头数据
            goodsmvt_code    = goodsmvt_code " 为 BAPI 货物移动分配事务代码
*            testrun          = 'X' " 切换到编写 BAPI 的模拟会话
*            goodsmvt_ref_ewm =
*            goodsmvt_print_ctrl =
  importing
    goodsmvt_headret = goodsmvt_headret
    materialdocument = materialdocument " 物料凭证
    matdocumentyear  = matdocumentyear
  tables    goodsmvt_item    = goodsmvt_item_01[] " 创建物料凭证项目
*            goodsmvt_serialnumber =
            return           = lt_return.
*   goodsmvt_serv_part_data =
*   extensionin      =
*   goodsmvt_item_cwm       =


if materialdocument is not initial.
  call function 'BAPI_TRANSACTION_COMMIT'
    exporting
      wait = 'X'.
  data(isValid) = 'X'.
  cl_demo_output=>display( goodsmvt_headret ).

else.
  call function 'BAPI_TRANSACTION_ROLLBACK'.
  loop at lt_return into data(line_1).
    if line_1-type co 'EA'. " 字符包含在EA里面
      isValid = ''.
    endif.
  endloop.
  data(util) = new znantest_util( ).
  util->show_message( itab_return = lt_return[] ).
endif.
