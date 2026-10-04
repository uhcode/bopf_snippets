# bopf_snippets

ABAP code snippets for the SAP Business Object Processing Framework (BOPF):
determinations, validations & actions.

The examples use the business objects `/IAM/ISSUE` and `/IAM/ACTIVITY`
(SAP Management of Change), but the patterns apply to any BOPF business object.

| File | Topic |
|------|-------|
| [read_modify.abap](read_modify.abap) | Read node data in an action and update attributes of a subnode |
| [create_instance.abap](create_instance.abap) | Create new subnode instances via `io_modify->create` |
| [validate_on_action.abap](validate_on_action.abap) | Action validation with a parameterized association, error message and failed keys |
| [copy_nodes.abap](copy_nodes.abap) | Copy data between two BO instances using the service manager and a modification table |
| [get_proc_mode.abap](get_proc_mode.abap) | Determine edit/display mode via FPM or by probing the BOPF lock |

The snippets are excerpts from real implementations and are not meant to be
activated as they are - adapt node, association and attribute names to your
own business object.
