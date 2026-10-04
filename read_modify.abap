*----------------------------------------------------------------------*
* Snippet: Read and update node data inside an action
*----------------------------------------------------------------------*
* Context : Action implementation (/BOBF/IF_FRW_ACTION~EXECUTE) on the
*           ROOT node of BO /IAM/ISSUE
* Purpose : When the action APPROVE_MOC is executed, the change number
*           is written to all related object references of the issue.
*
* Shows how to
*   - read the instances the action was called for (RETRIEVE)
*   - navigate to a subnode (RETRIEVE_BY_ASSOCIATION)
*   - change single attributes of a subnode (UPDATE)
*----------------------------------------------------------------------*
METHOD /bobf/if_frw_action~execute.

  " Placeholder - determine the real change number here
  CONSTANTS lc_change_number TYPE aennr VALUE 'test'.

  DATA lt_root   TYPE /iam/t_i_root.
  DATA lt_objref TYPE /iam/t_i_obj_ref.

  CASE is_ctx-act_key.
    WHEN /iam/if_i_issue_c=>sc_action-root-approve_moc.

      " Read the root instances the action is executed for
      io_read->retrieve(
        EXPORTING
          iv_node      = is_ctx-node_key
          it_key       = it_key
          iv_fill_data = abap_true
        IMPORTING
          et_data      = lt_root ).

      " Follow the association to the related object references
      io_read->retrieve_by_association(
        EXPORTING
          iv_node        = /iam/if_i_issue_c=>sc_node-root
          it_key         = VALUE #( FOR ls_root IN lt_root ( key = ls_root-key ) )
          iv_association = /iam/if_i_issue_c=>sc_association-root-objref_related_objects
          iv_fill_data   = abap_true
        IMPORTING
          et_data        = lt_objref ).

      " Only the attributes named in IT_CHANGED_FIELDS are updated,
      " all other attributes of the node keep their current value
      LOOP AT lt_objref REFERENCE INTO DATA(lr_objref).
        lr_objref->aennr = lc_change_number.

        io_modify->update(
          iv_node           = /iam/if_i_issue_c=>sc_node-object_reference
          iv_key            = lr_objref->key
          is_data           = lr_objref
          it_changed_fields = VALUE #( ( /iam/if_i_issue_c=>sc_node_attribute-object_reference-aennr ) ) ).
      ENDLOOP.

  ENDCASE.

ENDMETHOD.
