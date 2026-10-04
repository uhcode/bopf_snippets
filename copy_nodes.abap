*----------------------------------------------------------------------*
* Snippet: Copy node data between two BO instances
*----------------------------------------------------------------------*
* Context : Implementation of /IAM/IF_CREATE_CHILD_CR~CHANGE_CHILD_CR
* Purpose : Copies the questionnaire answers from the activities of a
*           parent change request to the matching activities of its
*           child change request.
*
* Shows how to
*   - obtain service managers for two different business objects
*   - read dependent nodes with RETRIEVE_BY_ASSOCIATION
*   - collect several updates in a modification table and send them
*     to the BO with a single MODIFY call
*----------------------------------------------------------------------*
METHOD /iam/if_create_child_cr~change_child_cr.

  " Description type that holds the response of a code group question
  CONSTANTS lc_desc_type_response TYPE c LENGTH 5 VALUE 'ARESP'.

  DATA lt_activity     TYPE /iam/t_act_root.
  DATA lt_desc_parent  TYPE /iam/t_act_desc.
  DATA lt_desc_child   TYPE /iam/t_act_desc.
  DATA lt_modification TYPE /bobf/t_frw_modification.
  DATA lo_message      TYPE REF TO /bobf/if_frw_message.

  eo_message = /bobf/cl_frw_factory=>get_message( ).

  " One service manager per business object: the change request (issue)
  " owns the activities, the activity BO owns the data we want to change
  DATA(lo_svc_issue)    = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /iam/if_i_issue_c=>sc_bo_key ).
  DATA(lo_svc_activity) = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /iam/if_act_activity_c=>sc_bo_key ).

  " Read the activities of parent and child in one round trip
  lo_svc_issue->retrieve_by_association(
    EXPORTING
      iv_node_key    = /iam/if_i_issue_c=>sc_node-root
      it_key         = VALUE #( ( key = iv_parent_root_key )
                                ( key = iv_child_root_key ) )
      iv_association = /iam/if_i_issue_c=>sc_association-root-all_activities
      iv_fill_data   = abap_true
    IMPORTING
      et_data        = lt_activity
      eo_message     = lo_message ).
  IF lo_message IS BOUND.
    eo_message->add( lo_message ).
  ENDIF.

  LOOP AT lt_activity REFERENCE INTO DATA(lr_child_act)
       WHERE par_issue_uuid = iv_child_root_key.

    " Find the parent activity that was created from the same template
    READ TABLE lt_activity REFERENCE INTO DATA(lr_parent_act)
         WITH KEY par_issue_uuid = iv_parent_root_key
                  act_template   = lr_child_act->act_template
                  act_type       = lr_child_act->act_type
                  act_category   = lr_child_act->act_category.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    IF is_codegroup( CONV #( lr_child_act->act_template ) ) = abap_false.

      " Simple question: the answer is stored on the activity root node
      APPEND VALUE #(
        node           = /iam/if_act_activity_c=>sc_node-root
        change_mode    = /bobf/if_frw_c=>sc_modify_update
        key            = lr_child_act->key
        changed_fields = VALUE #( ( /iam/if_act_activity_c=>sc_node_attribute-root-sel_crit_cd )
                                  ( /iam/if_act_activity_c=>sc_node_attribute-root-resp_val_bool ) )
        data           = NEW /iam/s_act_root( sel_crit_cd   = lr_parent_act->sel_crit_cd
                                              resp_val_bool = lr_parent_act->resp_val_bool )
      ) TO lt_modification.
      CONTINUE.

    ENDIF.

    " Code group question: the answer is stored on the description node,
    " so the response description of both activities is needed
    lo_svc_activity->retrieve_by_association(
      EXPORTING
        iv_node_key    = /iam/if_act_activity_c=>sc_node-root
        it_key         = VALUE #( ( key = lr_parent_act->key ) )
        iv_association = /iam/if_act_activity_c=>sc_association-root-description
        iv_fill_data   = abap_true
      IMPORTING
        et_data        = lt_desc_parent
        eo_message     = lo_message ).
    IF lo_message IS BOUND.
      eo_message->add( lo_message ).
    ENDIF.

    READ TABLE lt_desc_parent REFERENCE INTO DATA(lr_desc_parent)
         WITH KEY desc_type = lc_desc_type_response.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    lo_svc_activity->retrieve_by_association(
      EXPORTING
        iv_node_key    = /iam/if_act_activity_c=>sc_node-root
        it_key         = VALUE #( ( key = lr_child_act->key ) )
        iv_association = /iam/if_act_activity_c=>sc_association-root-description
        iv_fill_data   = abap_true
      IMPORTING
        et_data        = lt_desc_child
        eo_message     = lo_message ).
    IF lo_message IS BOUND.
      eo_message->add( lo_message ).
    ENDIF.

    READ TABLE lt_desc_child REFERENCE INTO DATA(lr_desc_child)
         WITH KEY desc_type = lc_desc_type_response.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    " Only the fields listed in CHANGED_FIELDS are taken over from DATA
    APPEND VALUE #(
      node           = /iam/if_act_activity_c=>sc_node-description
      change_mode    = /bobf/if_frw_c=>sc_modify_update
      key            = lr_desc_child->key
      changed_fields = VALUE #( ( /iam/if_act_activity_c=>sc_node_attribute-description-code )
                                ( /iam/if_act_activity_c=>sc_node_attribute-description-code_txt ) )
      data           = NEW /iam/s_act_desc( code     = lr_desc_parent->code
                                            code_txt = lr_desc_parent->code_txt )
    ) TO lt_modification.

  ENDLOOP.

  IF lt_modification IS INITIAL.
    RETURN.
  ENDIF.

  " Send all collected changes to the activity BO at once.
  " Saving is left to the caller (transaction manager).
  lo_svc_activity->modify(
    EXPORTING
      it_modification = lt_modification
    IMPORTING
      eo_message      = lo_message ).
  IF lo_message IS BOUND.
    eo_message->add( lo_message ).
  ENDIF.

ENDMETHOD.
