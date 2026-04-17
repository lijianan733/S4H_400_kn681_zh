*&---------------------------------------------------------------------*
*& Report  ZFI_FLIGHT_ALV
*& 航班信息 OOALV 报表示例 - 支持增删改
*&---------------------------------------------------------------------*

REPORT zfi_flight_alv.
TYPE-POOLS: icon.

*----------------------------------------------------------------------*
* 数据结构定义
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_flight,
         fldate    TYPE sflight-fldate,      "航班日期
         carrid    TYPE sflight-carrid,      "航空公司
         connid    TYPE sflight-connid,      "航班号
         planetype TYPE sflight-planetype,   "飞机型号
         seatsmax  TYPE sflight-seatsmax,    "最大座位数
         seatsocc  TYPE sflight-seatsocc,    "占座数
         price     TYPE sflight-price,       "价格
         currency  TYPE sflight-currency,    "货币
       END OF ty_flight.

TYPES: ty_flight_tab TYPE STANDARD TABLE OF ty_flight WITH KEY fldate carrid connid.

*----------------------------------------------------------------------*
* 事件处理类
*----------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    METHODS:
      on_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object e_interactive,
      on_user_command FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm,
      on_data_changed FOR EVENT data_changed OF cl_gui_alv_grid
        IMPORTING er_data_changed.
ENDCLASS.

CLASS lcl_event_handler IMPLEMENTATION.
  METHOD on_toolbar.
    " 在工具栏事件中添加自定义按钮
    APPEND VALUE stb_button(
      function  = 'ADD_ROW',
      icon      = icon_create,
      text      = '新增行',
      quickinfo = 'Add new flight record'
    ) TO e_object->mt_toolbar.

    APPEND VALUE stb_button(
      function  = 'DELETE_ROW',
      icon      = icon_delete,
      text      = '删除行',
      quickinfo = 'Delete selected rows'
    ) TO e_object->mt_toolbar.

    APPEND VALUE stb_button(
      function  = 'SAVE_DATA',
      icon      = icon_save,
      text      = '保存',
      quickinfo = 'Save changes'
    ) TO e_object->mt_toolbar.

    APPEND VALUE stb_button(
      function  = 'CANCEL_EDIT',
      icon      = icon_cancel,
      text      = '取消',
      quickinfo = 'Discard changes'
    ) TO e_object->mt_toolbar.
  ENDMETHOD.

  METHOD on_user_command.
    DATA: ls_flight TYPE ty_flight,
          lt_rows   TYPE lvc_t_row,
          ls_row    TYPE lvc_s_row.

    CASE e_ucomm.
      WHEN 'ADD_ROW'.
        ls_flight-fldate    = sy-datlo + 3.
        ls_flight-carrid    = p_carrid.
        ls_flight-connid    = '9999'.
        ls_flight-planetype = '320'.
        ls_flight-seatsmax  = 180.
        ls_flight-seatsocc  = 0.
        ls_flight-price     = 0.
        ls_flight-currency  = 'EUR'.

        INSERT ls_flight INTO g_flight_tab INDEX 1.
        IF g_alv IS BOUND.
          CALL METHOD g_alv->refresh_table_display.
        ENDIF.
        MESSAGE 'Row added successfully' TYPE 'S'.

      WHEN 'DELETE_ROW'.
        IF g_alv IS BOUND.
          CALL METHOD g_alv->get_selected_rows
            IMPORTING et_index_rows = lt_rows.
        ENDIF.
        SORT lt_rows BY index DESCENDING.
        LOOP AT lt_rows INTO ls_row.
          DELETE g_flight_tab INDEX ls_row-index.
        ENDLOOP.
        IF g_alv IS BOUND.
          CALL METHOD g_alv->refresh_table_display.
        ENDIF.
        MESSAGE 'Rows deleted successfully' TYPE 'S'.

      WHEN 'SAVE_DATA'.
        PERFORM pf_save_changes.

      WHEN 'CANCEL_EDIT'.
        g_flight_tab = g_flight_backup.
        IF g_alv IS BOUND.
          CALL METHOD g_alv->refresh_table_display.
        ENDIF.
        MESSAGE 'Changes discarded' TYPE 'S'.
    ENDCASE.
  ENDMETHOD.

  METHOD on_data_changed.
    " 处理数据修改后的验证逻辑
    DATA: ls_flight TYPE ty_flight.
    LOOP AT g_flight_tab INTO ls_flight.
      " 验证座位数不能超过最大座位数
      IF ls_flight-seatsocc > ls_flight-seatsmax.
        MESSAGE 'Occupied seats cannot exceed max seats' TYPE 'E'.
        EXIT.
      ENDIF.
      " 验证座位数不能为负
      IF ls_flight-seatsocc < 0.
        MESSAGE 'Seats cannot be negative' TYPE 'E'.
        EXIT.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* 全局变量
*----------------------------------------------------------------------*
DATA: g_flight_tab    TYPE ty_flight_tab,
      g_flight_backup TYPE ty_flight_tab,
      g_alv           TYPE REF TO cl_gui_alv_grid,
      g_container     TYPE REF TO cl_gui_docking_container,
      g_handler       TYPE REF TO lcl_event_handler.

*----------------------------------------------------------------------*
* 初始化选择屏
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-001.
  PARAMETERS: p_carrid TYPE sflight-carrid DEFAULT 'LH'.
SELECTION-SCREEN END OF BLOCK blk1.

*----------------------------------------------------------------------*
* AT SELECTION-SCREEN 事件
*----------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.
  PERFORM pf_validate_input.

*----------------------------------------------------------------------*
* START-OF-SELECTION
*----------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM pf_load_data.
  PERFORM pf_display_alv.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*& Form pf_load_data - 加载航班数据
*&---------------------------------------------------------------------*
FORM pf_load_data.
  CLEAR g_flight_tab.

  "从SFLIGHT表读取示例数据（此处为演示，实际应该真实查询）
  SELECT fldate carrid connid planetype seatsmax seatsocc price currency
    FROM sflight
    UP TO 10 ROWS
    INTO TABLE @g_flight_tab
    WHERE carrid = @p_carrid
      AND fldate >= @sy-datlo
    ORDER BY fldate, connid.

  "如果无数据，插入示例数据
  IF g_flight_tab IS INITIAL.
    APPEND VALUE ty_flight(
      fldate    = sy-datlo + 1
      carrid    = 'LH'
      connid    = '0400'
      planetype = '747'
      seatsmax  = 400
      seatsocc  = 45
      price     = 599
      currency  = 'EUR'
    ) TO g_flight_tab.

    APPEND VALUE ty_flight(
      fldate    = sy-datlo + 2
      carrid    = 'LH'
      connid    = '0401'
      planetype = '737'
      seatsmax  = 180
      seatsocc  = 78
      price     = 699
      currency  = 'EUR'
    ) TO g_flight_tab.
  ENDIF.

  "备份原始数据
  g_flight_backup = g_flight_tab.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form pf_display_alv - 显示 OO ALV 表格
*&---------------------------------------------------------------------*
FORM pf_display_alv.
  DATA: l_alv_settings  TYPE lvc_s_layo,
        l_field_catalog TYPE lvc_t_fcat.

  "创建容器（Docking Container）
  IF g_container IS INITIAL.
    CREATE OBJECT g_container
      EXPORTING
        repid     = sy-repid
        dynnr     = sy-dynnr
        side      = cl_gui_docking_container=>dock_at_bottom
        ratio     = 75.
  ENDIF.

  "创建 ALV 网格
  IF g_alv IS INITIAL.
    CREATE OBJECT g_alv
      EXPORTING
        i_parent = g_container.

    "设置列表元数据
    PERFORM pf_build_fieldcat CHANGING l_field_catalog.

    "设置表格参数
    l_alv_settings-edit = abap_true.      "允许编辑
    l_alv_settings-sel_mode = 'C'.        "列选择模式

    "设置 ALV 表格
    CALL METHOD g_alv->set_table_for_first_display
      EXPORTING
        is_layout       = l_alv_settings
        i_save          = 'A'
        is_variant      = VALUE disvariant( report = sy-repid )
      CHANGING
        it_fieldcatalog = l_field_catalog
        it_outtab       = g_flight_tab.

    "启用交互式工具栏事件（触发 toolbar 事件）
    CALL METHOD g_alv->set_toolbar_interactive.

    "启用编辑与数据变更事件（触发 data_changed）
    CALL METHOD g_alv->set_ready_for_input
      EXPORTING
        i_ready_for_input = 1.
    CALL METHOD g_alv->register_edit_event
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_modified.

    "注册事件处理器
    CREATE OBJECT g_handler.
    SET HANDLER g_handler->on_toolbar FOR g_alv.
    SET HANDLER g_handler->on_data_changed FOR g_alv.
    SET HANDLER g_handler->on_user_command FOR g_alv.

  ELSE.
    "更新表格
    CALL METHOD g_alv->refresh_table_display.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form pf_build_fieldcat - 构建字段目录
*&---------------------------------------------------------------------*
FORM pf_build_fieldcat CHANGING pt_fieldcat TYPE lvc_t_fcat.
  CLEAR pt_fieldcat.

  APPEND VALUE lvc_s_fcat(
    fieldname = 'FLDATE'
    coltext   = 'Flight Date'
    edit      = abap_false
  ) TO pt_fieldcat.

  APPEND VALUE lvc_s_fcat(
    fieldname = 'CARRID'
    coltext   = 'Airline'
    edit      = abap_false
    outputlen = 10
  ) TO pt_fieldcat.

  APPEND VALUE lvc_s_fcat(
    fieldname = 'CONNID'
    coltext   = 'Flight No.'
    edit      = abap_false
    outputlen = 10
  ) TO pt_fieldcat.

  APPEND VALUE lvc_s_fcat(
    fieldname = 'PLANETYPE'
    coltext   = 'Aircraft Type'
    edit      = abap_false
    outputlen = 15
  ) TO pt_fieldcat.

  APPEND VALUE lvc_s_fcat(
    fieldname = 'SEATSMAX'
    coltext   = 'Max Seats'
    edit      = abap_false
    outputlen = 12
    datatype  = 'INT4'
  ) TO pt_fieldcat.

  APPEND VALUE lvc_s_fcat(
    fieldname = 'SEATSOCC'
    coltext   = 'Occupied'
    edit      = abap_true
    outputlen = 10
    datatype  = 'INT4'
  ) TO pt_fieldcat.

  APPEND VALUE lvc_s_fcat(
    fieldname = 'PRICE'
    coltext   = 'Price'
    edit      = abap_true
    outputlen = 12
    datatype  = 'CURR'
    cfieldname = 'CURRENCY'
  ) TO pt_fieldcat.

  APPEND VALUE lvc_s_fcat(
    fieldname = 'CURRENCY'
    coltext   = 'Currency'
    edit      = abap_false
    outputlen = 8
  ) TO pt_fieldcat.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form pf_validate_input - 输入校验
*&---------------------------------------------------------------------*
FORM pf_validate_input.
  IF p_carrid IS INITIAL.
    p_carrid = 'LH'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form pf_save_changes - 保存变更
*&---------------------------------------------------------------------*
FORM pf_save_changes.
  "此处为演示，实际应调用 MODIFY sflight 写入数据库
  LOOP AT g_flight_tab INTO DATA(ls_flight).
    "验证必填字段
    IF ls_flight-fldate IS INITIAL OR
       ls_flight-carrid IS INITIAL OR
       ls_flight-connid IS INITIAL OR
       ls_flight-seatsocc < 0 OR
       ls_flight-price < 0.
      MESSAGE 'Some required fields are empty or invalid' TYPE 'E'.
      RETURN.
    ENDIF.

    "验证座位数不超过最大座位数
    IF ls_flight-seatsocc > ls_flight-seatsmax.
      MESSAGE 'Occupied seats cannot exceed max seats' TYPE 'E'.
      RETURN.
    ENDIF.

    "此处可加入实际的数据库操作
    "*  MODIFY sflight FROM ls_flight.
  ENDLOOP.

  MESSAGE 'Data saved successfully' TYPE 'S'.
  COMMIT WORK AND WAIT.

ENDFORM.
