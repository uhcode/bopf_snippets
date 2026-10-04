*----------------------------------------------------------------------*
* Snippet: Determine the processing mode (edit / display)
*----------------------------------------------------------------------*
* Two independent ways to find out whether an instance can be edited:
*   1) ask the FPM for the edit mode of a UIBB
*   2) probe the BOPF lock of the instance
*----------------------------------------------------------------------*

*----------------------------------------------------------------------*
* 1) Via FPM: read the edit mode of a UIBB
*----------------------------------------------------------------------*
" Replace [CONFIG_ID] and the window name with the values of the
" FPM application configuration
DATA(ls_uibb_instance_key) = VALUE fpm_s_uibb_instance_key(
  component = 'FPM_LIST_UIBB'
  config_id = '[CONFIG_ID]' ).

DATA(lv_edit_mode) = cl_fpm_factory=>get_instance( )->get_uibb_edit_mode(
  is_uibb_instance_key = ls_uibb_instance_key
  iv_window_name       = 'LIST_WINDOW' ).

IF lv_edit_mode = if_fpm_constants=>gc_edit_mode-read_only.
  " UIBB is in display mode - react here
ENDIF.

*----------------------------------------------------------------------*
* 2) Via lock: try to lock the instance and release it again
*----------------------------------------------------------------------*
" Scope must match the "Lock Behavior" setting of BO /IAM/ISSUE
CONSTANTS lc_scope TYPE c LENGTH 1 VALUE '1'.

" Request an exclusive lock on the instance. If another user already
" holds it, the instance can only be displayed.
CALL FUNCTION 'ENQUEUE_/BOBF/E_LIB_1'
  EXPORTING
    mode_/bobf/s_lib_enqueue_node = 'E'
    mandt                         = sy-mandt
    bo_name                       = /iam/if_i_issue_c=>sc_bo_name
    key                           = iv_key
    x_bo_name                     = abap_true
    x_key                         = abap_true
    _scope                        = lc_scope
    _wait                         = abap_false
    _collect                      = abap_false
  EXCEPTIONS
    foreign_lock                  = 1
    system_failure                = 2
    OTHERS                        = 3.
IF sy-subrc <> 0.
  cv_processing_mode = /iam/cl_fpm_wiring_model_uibb=>gc_display.
  RETURN.
ENDIF.

" The lock was only a probe - release it right away so that the
" regular BOPF locking can take over
CALL FUNCTION 'DEQUEUE_/BOBF/E_LIB_1'
  EXPORTING
    mode_/bobf/s_lib_enqueue_node = 'E'
    mandt                         = sy-mandt
    bo_name                       = /iam/if_i_issue_c=>sc_bo_name
    key                           = iv_key
    x_bo_name                     = abap_true
    x_key                         = abap_true
    _scope                        = lc_scope.
