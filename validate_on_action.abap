*----------------------------------------------------------------------*
* Snippet: Action validation with error message
*----------------------------------------------------------------------*
* Context : Validation implementation (/BOBF/IF_FRW_VALIDATION~EXECUTE)
*           on the ROOT node of BO /IAM/ACTIVITY, assigned to the
*           action REJECT
* Purpose : A task may only be rejected if a reason text (description
*           of type NOTES) was entered. Otherwise an error message is
*           raised and the action is prevented.
*
* Shows how to
*   - use an association with parameters and filtered attributes
*   - attach a message to a node attribute, so the UI can highlight
*     the affected field
*   - stop an action by returning failed keys
*----------------------------------------------------------------------*
METHOD /bobf/if_frw_validation~execute.

  CONSTANTS lc_desc_type_notes TYPE c LENGTH 5 VALUE 'NOTES'.

  DATA lt_desc_key  TYPE /bobf/t_frw_key.
  DATA lt_desc_text TYPE /iam/t_act_desctxt.

  CLEAR: eo_message, et_failed_key.

  IF is_ctx-act_key <> /iam/if_act_activity_c=>sc_action-root-reject.
    RETURN.
  ENDIF.

  " Read the keys of the NOTES description. The association parameter
  " selects the description type, the filtered attributes tell the
  " framework which parameter fields are actually filled.
  io_read->retrieve_by_association(
    EXPORTING
      iv_node                = /iam/if_act_activity_c=>sc_node-root
      it_key                 = it_key
      iv_association         = /iam/if_act_activity_c=>sc_association-root-description_by_desc_type
      is_parameters          = NEW /iam/s_a_desc_assoc_param( desc_type = lc_desc_type_notes )
      it_filtered_attributes = VALUE #( ( /iam/if_act_activity_c=>sc_node_attribute-description-desc_type ) )
    IMPORTING
      et_target_key          = lt_desc_key ).

  " Read the text of the description in its current state
  " (not the before image)
  io_read->retrieve_by_association(
    EXPORTING
      iv_node         = /iam/if_act_activity_c=>sc_node-description
      it_key          = lt_desc_key
      iv_association  = /iam/if_act_activity_c=>sc_association-description-description_text_default
      iv_fill_data    = abap_true
      iv_before_image = abap_false
    IMPORTING
      et_data         = lt_desc_text ).

  " Reason text entered - validation passed
  DATA(lv_reason_text) = VALUE #( lt_desc_text[ 1 ]-long_text_formatted OPTIONAL ).
  IF lv_reason_text IS NOT INITIAL.
    RETURN.
  ENDIF.

  " Raise the error message with reference to the text attribute
  eo_message = /bobf/cl_frw_factory=>get_message( ).
  eo_message->add_message(
    is_msg       = VALUE #( msgid = '/XXX/MOC_MESSAGES'
                            msgno = '007'
                            msgty = 'E' )
    iv_node      = /iam/if_act_activity_c=>sc_node-description_text
    iv_key       = VALUE #( lt_desc_key[ 1 ]-key OPTIONAL )
    iv_attribute = /iam/if_act_activity_c=>sc_node_attribute-description_text-long_text_formatted ).

  " A failed key prevents the action from being executed for this
  " instance. Note: only the first instance is checked, as REJECT is
  " called for a single task.
  IF it_key IS NOT INITIAL.
    et_failed_key = VALUE #( ( key = it_key[ 1 ]-key ) ).
  ENDIF.

ENDMETHOD.
