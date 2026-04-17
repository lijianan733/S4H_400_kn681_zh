*&---------------------------------------------------------------------*
*& Report z2506019_report_1
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
report z2506019_report_1.

" &光伏生活与SAP的STO创建
" 光伏公司开展光伏产品的销售业务，由启明公司代发货，光伏公司接到客户订单后，
" 光伏生活平台推送STO订单给SAP系统，SAP进行STO发货过账。
" 如果发生客户退货业务，光伏生活平台推送退货STO给SAP系统，SAP进行STO退货过账。
" 公司内STO 分为有无交货单
" 无交货单，则在创建完转储订单Ub单后，到MIGO进行发货和收货操作
" 业务逻辑
" 4.1 创建STO采购订单
" 1)  接收接口传入字段，首先检查必填项是否都有传值，如没有则报错“XX值未传入，传输内容不完整”。
" 2)  检查接口传入字段采购订单类型、供应商代码是否为STO，
" 采购订单类型=Z004、且通过供应商代码取LFA1-WERKS不为空的为STO，如果不是STO报错“传入数据非STO订单，不能通过该接口处理”。
" 3)  接收接口传入字段，检查出库号ZCKDH在EKKO-VERKF中是否存在，如果存在，报错：“采购订单已经创建,
" 不能重复创建，凭证号为：”。如果该EKPO的所有行项目loekz = 'L'，视同采购订单已删除，不需要报错，程序正常执行。
" 4)  直接复制函数ZIF030_YXMP_280的frm_zif030_yxmp_280_check，这个已经包含了步骤1~3。需要检查一下新增，减少和替换了的字段检查。
" 5)  按物料编码对MENGE进行汇总，然后在MARD表中检查库存是否足够。MARD-MATNR=ITEM-MATNR；MARD-WERKS=LFA1-WERKS（第二步的）；
" MARD-LGORT=HEADER-LGORT。如果MARD-LABST< ITEM-MENGE，报错“物料&工厂&仓位库存不足”。
" 6)  如以上检查都OK，接下来进行STO订单的创建：出库单号写在EKKO-VERKF字段、外围系统订单号写在EKKO-ZCONTRACTNO，
" 出库单行号写在EKPO-ZZPOSNR1。根据传入的字段创建STO采购订单，把价格输入到条件类型ZP00中。
" 7)  如果接口传入的“退货”标识=X，则创建退货STO单、即退货标识RETPO=“X”。
" 8)  具体的代码可以参考函数ZIF030_YXMP_280。
" 9)  调用BAPI生成STO发货单，调用BAPI对发货单进行过账。
" 10) 如果STO生成成功并且发货单也过账成功，返回状态S，消息：过账成功。如果STO生成失败就返回状态E，消息：STO生成失败。如果STO成功生成，但发货单或发货单过账失败，返回状态N，消息：STO生成成功，发货失败。
" 11) 返回参数：ZCKDH=出库单号；EBELN=STO编码；VBELN=发货单号。
*参考代码zif046_gfsh_200

" 前台操作 me21n vl10b
" 参考采购订单 4500006239


*谁向谁采购哪些东西 供应商提供货物，采购组织负责采购，采购组实施具体的采购活动，工厂接收货物，公司代码负责财务核算
*一个供应商可以和有很多采购组织合作，一个采购组织可以有多个采购组，一个采购组可以负责多个工厂的采购业务

" 测试
" 采购订单
" 4500006842
" 外向交货单
" 80004458

*&---------------------------------------------------------------------*

load-of-program.

top-of-page. " 在页首输出时触发。
include z250615_report_1_top.
include z250615_report_1_scr.
include z250615_report_1_frm.

initialization. " 在程序开始执行时初始化数据时触发。
  tables sscrfields.
  selection-screen function key 1.           " 第一个按
  sscrfields-functxt_01 = '创建销售订单PO单'.      " 定义第一个按钮文本
  sscrfields-from_text  = '创建销售订单PO单'.
  sscrfields-to_text    = '创建销售订单PO单'.

  selection-screen function key 2.           " 第一个按
  sscrfields-functxt_02 = '创建外向交货单'.      " 定义第一个按钮文本
  sscrfields-from_text  = '创建外向交货单'.
  sscrfields-to_text    = '创建外向交货单'.

  selection-screen function key 3.           " 第一个按
  sscrfields-functxt_03 = '交货单拣配'.      " 定义第一个按钮文本
  sscrfields-from_text  = '交货单拣配'.
  sscrfields-to_text    = '创建外向交货单'.

  selection-screen function key 4.           " 第一个按
  sscrfields-functxt_04 = '交货单过账'.      " 定义第一个按钮文本
  sscrfields-from_text  = '交货单过账'.
  sscrfields-to_text    = '创建外向交货单'.

  selection-screen function key 5.           " 第一个按
  sscrfields-functxt_05 = '删除PO,PN'.      " 定义第一个按钮文本
  sscrfields-from_text  = '删除PO,PN'.
  sscrfields-to_text    = '删除PO,PN'.




at selection-screen output. " 在屏幕选择数据输出时触发。PBO
  " perform insert_into_excl(rsdbrunt) using 'ONLI'.

  " 这个事件里声明的变量都是局部变量。
  " 数据选择和处理事件."

at selection-screen. " 在屏幕选择执行的时候,点击执行PAI
  " 按钮命令事件处理  按钮功能

  case sscrfields-ucomm.
    when 'FC01'.
      perform create_po.
    when 'FC02'.
      if gv_po_num is not initial.
        perform create_delivery_order
          using    gv_po_num
                   p_vdatu
                   p_posnr
                   p_vstel
          changing gv_delivery_no.
      else.
        message |请先创建采购订单| type 'W'.
      endif.

    when 'FC03'.
      if gv_delivery_no is not initial.
        perform pick_goods using    gv_delivery_no
                           changing picked.
      else.
        message |请先创建外向交货单| type 'W'.
      endif.
    when 'FC04'.
      if picked = 'X'.
        perform release_delivery_order using gv_delivery_no.
      else.
        message |请先完成拣配| type 'W'.
      endif.
    when 'FC05'.
      line_1 = value #( p_dotype = p_dotype " 采购凭证类型
                        p_number = gv_po_num " 采购凭证号
                        p_dn_no  = gv_delivery_no " 采购凭证号

                        p_docdat = sy-datum " 采购凭证日期
                        p_crdate = sy-datum " 采购凭证创建日期
                        p_crdaby = sy-uname " 采购凭证创建人
                        p_vendor = p_vendor " 供应商
                        p_reswk  = p_reswk " 供应商工厂
                        p_status = p_status " 采购凭证状态
                        p_purch  = p_purch  " 采购组织
                        p_purgr  = p_purgr " 采购组
                        p_cocode = p_cocode " 公司代码
                        p_vatcn  = p_vatcn " 税务国家
                        p_POSNR  = p_POSNR " 采购凭证行项目
                        p_matnr  = p_matnr " 物料编号
                        p_plant  = p_plant " 工厂
                        p_loct   = p_loct " 库存地点
                        p_quanti = p_quanti " 采购数量
                        p_rename = sy-uname " 采购凭证修改人
                        p_prdate = 'D' " 采购凭证计划交货日期
                        p_netpri = '100.00'
                        p_vstel  = p_vstel " 交货地点
                        p_vdatu  = p_vdatu ). " 交货日期; 采购凭证净价'
      append line_1 to tab1[].
      assign tab1[ 1 ] to <line_1>.
      perform delete_dn.
      perform delete_po.

  endcase.

start-of-selection.
  perform frm_get_sql_data.
  perform frm_display_alv.

  end-of-page. " 在页尾输出时触发。
