*&---------------------------------------------------------------------*
*& CD              :                                                  *
*& Project Code/N  : Solution Manager Development                      *
*& Author / Company: I339142(Marianna Shcherbina)                      *
*& Date (DDMMMYYYY): 28-April-2021                                     *
*& Transport       : SODK908454                                        *
*& Obj Descriptions: Change document attributes                        *
*&---------------------------------------------------------------------*
report zsd_doc_att_copy_test.

parameters: p_file   type        rlgrap-filename,
            p_branch type        smud_guid22 no-display,
            p_desc   type        smud_root_occ_desc.

data:
  gv_soldoc_toolset type ref to zsd_cl_soldoc_toolset,
  gt_smud_rnode_t   type zsd_cl_soldoc_toolset=>tt_smud_rnode_t,
  gs_smud_rnode_t   like line of gt_smud_rnode_t,
  gt_table          type table of string,
  gt_doc_attr       type table of zsd_cl_soldoc_toolset=>ts_doc_attr,
  gv_doc_attr       type ref to data.

"gv_soldoc_toolset = zsd_cl_soldoc_toolset=>get_instance( ).
create object gv_soldoc_toolset.
*&--------------------------------------------------------------------------------------------------*
*& csv file upload {
*&--------------------------------------------------------------------------------------------------*
at selection-screen on value-request for p_file.

  if p_file is initial.
    call function 'KD_GET_FILENAME_ON_F4'
      changing
        file_name = p_file.
  endif.

at selection-screen on value-request for p_desc. "p_branch.

  if p_desc is initial.

    gt_smud_rnode_t = gv_soldoc_toolset->get_full_branches_list( ).

    if sy-subrc ne 0.
      message text-004 type 'I'.
    endif.

    call function 'F4IF_INT_TABLE_VALUE_REQUEST'
      exporting
        retfield        = gv_soldoc_toolset->co_retfield
        dynpprog        = sy-repid
        dynpnr          = sy-dynnr
        dynprofield     = gv_soldoc_toolset->co_dynprofield
        value_org       = gv_soldoc_toolset->co_value_org
      tables
        value_tab       = gt_smud_rnode_t
      exceptions
        parameter_error = 1
        no_values_found = 2.

    if sy-subrc ne 0.
      message text-005 type 'I'.
    endif.
  endif.

start-of-selection.

  if p_desc is initial.
    message text-014 type 'E'.
    return.
  else.
    if gt_smud_rnode_t is not initial.
      read table  gt_smud_rnode_t into gs_smud_rnode_t with key root_occ_desc = p_desc.
      if sy-subrc = 0.
        p_branch = gs_smud_rnode_t-root_occ.
      endif.
    else.
      select single root_occ from smud_rnode_t into p_branch where root_occ_desc = p_desc and
                                                                   lang          = sy-langu.
      if sy-subrc ne 0.
        message text-015 type 'E'.
        return.
      endif.
    endif.
  endif.

  call method cl_gui_frontend_services=>gui_upload
    exporting
      filename                = |{ p_file }|
      has_field_separator     = abap_true
    changing
      data_tab                = gt_table
    exceptions
      file_open_error         = 1
      file_read_error         = 2
      no_batch                = 3
      gui_refuse_filetransfer = 4
      invalid_type            = 5
      no_authority            = 6
      unknown_error           = 7
      bad_data_format         = 8
      header_not_allowed      = 9
      separator_not_allowed   = 10
      header_too_long         = 11
      unknown_dp_error        = 12
      access_denied           = 13
      dp_out_of_memory        = 14
      disk_full               = 15
      dp_timeout              = 16
      not_supported_by_gui    = 17
      error_no_gui            = 18
      others                  = 19.

  if sy-subrc ne 0.
    message text-001 type 'E'.
    return.
  endif.

  create data gv_doc_attr like line of gt_doc_attr.
  assign gv_doc_attr->* to field-symbol(<gv_doc_attr>).

  assign component 'TARGET_DOC_PATH' of structure <gv_doc_attr> to field-symbol(<gv_component_target_path>).
  assign component 'DOC_TYPE' of structure <gv_doc_attr> to field-symbol(<gv_component_doc_type>).
  assign component 'DESCRIPTION' of structure <gv_doc_attr> to field-symbol(<gv_component_description>).
  assign component 'JRS_RISK_LEVEL' of structure <gv_doc_attr> to field-symbol(<gv_component_jrs_risk_level>).
  assign component 'PERF' of structure <gv_doc_attr> to field-symbol(<gv_component_perf>).

  data(gv_zkey_count) = 1.
  loop at gt_table assigning field-symbol(<gv_table>).
    if <gv_table> is not initial.
      split <gv_table> at gv_soldoc_toolset->co_split into <gv_component_target_path> <gv_component_doc_type> <gv_component_description> <gv_component_jrs_risk_level> <gv_component_perf>.
      if sy-subrc <> 0.
        message text-002 type 'E'.
      else.
        append <gv_doc_attr> to gt_doc_attr.
        clear: <gv_doc_attr>, <gv_table>.
      endif.
      gv_zkey_count = gv_zkey_count + 1.
    endif.
  endloop.
  if sy-subrc <> 0.
    message text-013 type 'E'.
    return.
  endif.
*&--------------------------------------------------------------------------------------------------*
*& } file upload
*&--------------------------------------------------------------------------------------------------*
