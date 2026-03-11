*&---------------------------------------------------------------------*
*& Report z250619_report_4
*&---------------------------------------------------------------------*
*& 公司间STO的交货单属于内向交货单
*在判断交货单是内向还是外向时，唯一依据是交货当事人主体的对应关系，而非货物的流动方向。
*例如，顾客退货交货单（单据类型LR）不能通过create outbound delivery VL01N创建，因为这不符合交货当事人主体的对应关系。
*同样，供应商退货交货单（单据类型RLL）也只能归类为inbound delivery。
*
*外向交货可能表现为两种情况：
*a)企业向顾客交货，常见交货单据类型为LF；
*b)顾客向企业退货，常见交货单据类型为LR。无论是企业与顾客之间的货物流动是“流入”还是“流出”，都属于外向交货。
**
**内向交货则可以分为两种情况：
*a)供应商向企业交货，通常涉及MIGO 101收货或创建内向交货单据EL；
*b)企业向供应商退货，单据类型为RLL（有时RL也可用）。不论是企业与供应商之间的货物流动是“流入”还是“流出”，都归类为内向交货。
*
*理解交货单的方向对于正确使用BAPI创建交货单至关重要。错误地将内向交货视为外向交货，或反之，
*将导致交货单信息的错误记录，影响供应链管理的准确性和效率。因此，在创建交货单时，务必确保交货单的方向与实际的交货当事人主体对应关系一致。
**
**使用BAPI创建交货单时，首先需要确定交货单的方向。通过分析交货当事人主体的对应关系，
*可以正确选择合适的BAPI进行创建。例如，对于外向交货，可以使用VL01N创建出库交货单；对于内向交货，可以使用适当的BAPI创建入库交货单。
*调用该方法的人是作为供应商 外向交货单BAPI_OUTB_DELIVERY_CREATE_STO
*                  内向交货单BAPI_DELIVERYPROCESSING_EXEC
*&---------------------------------------------------------------------*
report z250619_report_4.
tables mska. " 销售订单库存
tables likp. " SD凭证:交货抬头数据
tables lips. " 交货： 项目数据
selection-screen begin of block b02 with frame title text-002.
  parameters: P_po_num type ekko-ebeln default '4500006874', " 采购凭证编号
           p_posnr type ekpo-ebelp default '00010', " 行号
           p_vstel like likp-vstel default '8701', " 装运点/收货点,
           p_vdatu type ledat default sy-datum.   " 交货日期

selection-screen end of block b02.

data lv_ship_point        type vstel.
data lv_due_date          type ledat.
data lt_stock_trans_items type standard table of bapidlvreftosto with header line.
data lt_item1             type standard table of bapidlvitemcreated with header line.
data lt_extension_in      type standard table of bapiparex with header line.
data lt_return1           type standard table of bapiret2 with header line.
data gt_return            type standard table of bapiret2 with header line.
data lv_vbeln             type vbeln_vl. " 交货单号
data ls_sto_item          like bapidlvreftosto.
clear lt_stock_trans_items.
ls_sto_item-ref_doc  = P_po_num.
ls_sto_item-ref_item = p_posnr.
append ls_sto_item to lt_stock_trans_items.
call function 'BAPI_OUTB_DELIVERY_CREATE_STO'
  exporting
    ship_point        = p_vstel " 装运点/收货点
    due_date          = p_vdatu " 交货日期
  importing
    delivery          = lv_vbeln " 交货单号
  tables
    stock_trans_items = lt_stock_trans_items
    return            = lt_return1.
data error_log type c length 1.
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
