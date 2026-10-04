*----------------------------------------------------------------------*
* Snippet: Create new instances of a subnode
*----------------------------------------------------------------------*
* Context : Inside a determination or action, where the framework
*           provides the modify object IO_MODIFY
* Purpose : Creates one OBJECT_REFERENCE instance below the ROOT node
*           for every line of an upload table.
*
* Assumes the following objects from the surrounding method:
*   lt_ro_upload - uploaded lines, field names match the node structure
*   lr_ro        - existing object reference; its PARENT_KEY is the key
*                  of the ROOT instance the new nodes are attached to
*----------------------------------------------------------------------*
LOOP AT lt_ro_upload ASSIGNING FIELD-SYMBOL(<ls_ro_upload>).

  " The framework takes the node data as a data reference, so every
  " new instance needs its own data object
  DATA(lr_related_obj) = NEW /iam/s_i_obj_ref( ).
  lr_related_obj->* = CORRESPONDING #( <ls_ro_upload> ).

  " A subnode is always created via the association from its parent:
  " source node/key identify the parent, the association the target
  io_modify->create(
    EXPORTING
      iv_node            = /iam/if_i_issue_c=>sc_node-object_reference
      is_data            = lr_related_obj
      iv_assoc_key       = /iam/if_i_issue_c=>sc_association-root-objref
      iv_source_node_key = /iam/if_i_issue_c=>sc_node-root
      iv_source_key      = lr_ro->parent_key
    IMPORTING
      ev_key             = DATA(lv_new_key) ).  " key of the new instance

ENDLOOP.
