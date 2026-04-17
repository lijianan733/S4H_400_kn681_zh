*&---------------------------------------------------------------------*
*& Include z250615_report_1_top
*  @EndUserText.label : '出库单号'
*  zckdh      : abap.string(0);
*  @EndUserText.label : '外围系统订单号'
*  bstkd      : abap.string(0);
*  @EndUserText.label : '公司代码'
*  bukrs      : abap.string(0);
*  @EndUserText.label : '供应商编码'
*  lifnr      : abap.string(0);
*  @EndUserText.label : '采购组织'
*  ekorg      : abap.string(0);
*  @EndUserText.label : '采购组'
*  ekgrp      : abap.string(0);
*  @EndUserText.label : '订单类型'
*  bsart      : abap.string(0);
*  @EndUserText.label : '创建日期'
*  aedat      : abap.string(0);
*  @EndUserText.label : '出库日期'
*  wadat_ist  : abap.string(0);
*  @EndUserText.label : '接收工厂'
*  in_werks   : abap.string(0);
*  @EndUserText.label : '币种'
*  waers      : abap.string(0);
*  @EndUserText.label : '付款条件'
*  zterm      : abap.string(0);
*  @EndUserText.label : '伙伴利润中心'
*  pprctr     : abap.string(0);
*  @EndUserText.label : '退货标识'
*  retpo      : abap.string(0);
*&---------------------------------------------------------------------*

tables ekko. " 采购抬头
tables ekpo. " 采购行项目
tables eina. " 采购信息记录
tables likp. " SD凭证:交货抬头数据
tables lips. " 交货单行项目
tables matdoc. " 物料凭证
tables mkpf. " 抬头：物料凭证
tables mseg. " 凭证段：物料

types: begin of input_param,
         zckdh     type string,        " 出库单号
         wadat_ist type sy-datum,      " 出库日期
         bstkd     type string,        " 外围系统订单号
         bukrs     type ekko-bukrs,    " 公司代码
         lifnr     type ekko-lifnr,    " 供应商编码
         ekorg     type ekko-ekorg,    " 采购组织
         ekgrp     type ekko-ekgrp,    " 采购组
         bsart     type ekko-bsart,    " 订单类型
         aedat     type ekko-aedat,    " 创建日期
         in_werks  type ekko-eq_werks, " 接收工厂，工厂表头：全部项目具有相同的接收工厂
         waers     type ekko-waers,    " 币种
         zterm     type ekko-zterm,    " 付款条件
         pprctr    type string,        " 伙伴利润中心
         retpo     type string,        " 退货标识

       end of input_param.
types: begin of input_param_item,
         vbeln type vbeln_va,
         posnr type posnr_va,
         matnr type Matnr,
       end of input_param_item.

types itab_return type standard table of bapiret2.

data gv_po_num      type ekko-ebeln.          " 生成的采购凭证号
data gv_delivery_no type vbeln_vl.            " 生成的交货单号
data picked         type c length 1 value ''. " 拣配完成标识

define mcr_message_add.
  if     sy-msgid is not initial
     and sy-msgty is not initial
     and sy-msgty ca 'AEXISW'
     and sy-msgno is not initial.

    if sy-msgty ca 'AEX'.
      &2 = abap_false.
    endif.

    call function 'HRIQ_APPEND_SYS_MESSAGE_TABLE'
      changing
        ct_return = &1.
  endif.
end-of-definition.

data: begin of gs_itab,
        vbeln      like likp-vbeln,    " 交货单号
        kunag      like likp-kunag,    " 售达方
        kunnr      like likp-kunnr,    " 收货方
        vkorg      like likp-vkorg,    " 销售组织
        waerk      like likp-waerk,    " 货币
        lfdat      like likp-lfdat,    " 交货日期
        posnr      like lips-posnr,    " 行号
        matnr      like lips-matnr,    " 物料编号
        lgort      like lips-lgort,    " 库存地点
        lfimg      like lips-lfimg,    " 交货数量
        vrkme      like lips-vrkme,    " 销售单位
        vgbel      like lips-vgbel,    " 参考单据号
        vgpos      like lips-vgpos,    " 参考单据行号
        werks      like lips-werks,    " gs_itab
        maktx      like makt-maktx,    " 物料描述
        name1      like kna1-name1,    " 售达方名称
        knttp      like t459k-knttp,   " 客户类型
        bsart      like ekko-bsart,    " 文档类型 ziv
        netpr      like vbap-netpr,    " 净价
        kpein      like vbap-kpein,    " 价格单位
        prsfd      like tvap-prsfd,    " 价格条件类型
        sel        type char1,
        mtype      type char1,
        message    type string,
        cicon      type char4,
        status     type char4,
        mblnr      type mblnr,         " 物料凭证号
        mjahr      type mjahr,         " 物料凭证年份
        ebeln      type vbeln,         " 采购订单号
        dnno       type vbeln,         " 送货单号
        mtdoc      type mblnr,         " 物料凭证号
        inco1      type inco1,
        inco2_l    type inco2_l,
        bedar_lf   like lips-bedar_lf, " 需求交货数量
        invoice_no type c length 1,
      end of gs_itab.

data: begin of gs_itab_2,
        p_dotype   like bapimepoheader-doc_type,  " 采购凭证类型
        p_number   like likp-vbeln,               " 采购订单号
        p_docdat   type ebdat,                    " 文档日期
        p_crdate   type erdat,                    " 创建日期
        p_crdaby   type ernam,                    " 创建人
        p_vendor   type lifnr,                    " 供应商
        p_reswk    type werks_d,                  " 拣配的工厂
        p_loct_2   type bapimepoitem-stge_loc,    " 拣配的库位
        p_status   type estak,                    " 采购凭证的状态
        p_purch    type ekko-ekorg,               " 采购组织
        p_purgr    type ekko-ekgrp,               " 采购组
        p_cocode   like ekko-bukrs,               " 公司代码
        p_vatcn    like bapimepoheader-vat_cntry, " VAT国家代码
        P_bill_doc type bill_doc,                 " 发票凭证号
        p_POSNR    like bapimepoitem-po_item,     " 采购行项目号
        p_matnr    like bapimepoitem-material,    " 物料
        maktx      like makt-maktx,               " 物料描述
        p_plant    like bapimepoitem-plant,       " 收货工厂
        p_loct     like bapimepoitem-stge_loc,    " 收货库存地点
        p_quanti   like bapimepoitem-quantity,    " 数量
        p_netpri   like bapimepoitem-net_price,   " 净价
        p_priceu   like bapimepoitem-price_unit,  " " 价格单位
        p_rename   like bapimepoitem-preq_name,   " " 需求名称
        p_prdate   type dattp,                    " " 期限指示到期日期

        p_dn_no    type likp-vbeln,               " 交货单号
        p_vstel    type likp-vstel,               " 装运点/收货点
        p_vdatu    type likp-lfdat,               " 交货日期

        mblnr      type mblnr,                    " 物料凭证号
        mblnr_2    type mblnr,                    " 收货的物料凭证
        vkorg      type likp-vkorg,               " 销售组织
        kunnr      type likp-kunnr,               " 收货方
        sel        type char1,
        mtype      type char1,
        message    type string,
        cicon      type char4,
        status     type char4,
        inco1      type inco1,
        inco2_l    type inco2_l,
        invoice_no type c length 1,

      end of gs_itab_2.

types: begin of zmmt0335,
         mandt   type mandt,      " 集团
         vbeln   type likp-vbeln, " 交货单号
         posnr   type lips-posnr, " 交货行号
         zstep   type numc01,     " 单据流步骤
         docno   type vbeln,      " 销售订单号
         docit   type lips-posnr, " 销售订单行号
         mjahr   type mjahr,      " 销售订单年份
         redocno type vbeln,      " 冲销销售订单号
         zfdel   type char1,      " 冲销标识
       end of zmmt0335.
data gt_itab like table of gs_itab.
data tab1    like table of gs_itab_2 with header line.
data line_1  like line of tab1.
field-symbols <line_1> like line of tab1.



data gt_log       type table of zmmt0335.

data gv_post_date like sy-datum.
data msg          type string.

data gr_alv_grid  type ref to cl_gui_alv_grid.
data gt_fcat      type lvc_t_fcat. " 清单观察器控制的字段目录
