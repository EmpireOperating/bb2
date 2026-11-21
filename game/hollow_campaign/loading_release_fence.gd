extends Node
## Temporary release fence for gestures that started before the field was active.
var host: Node
var holds: Dictionary = {}
func _input(event: InputEvent) -> void:
 if event is InputEventMouseMotion:
  for id in holds:
   if id.begins_with("m:") and event.button_mask & (1 << (int(id.substr(2)) - 1)):
    get_viewport().set_input_as_handled();return
 var id: String = host._loading_input_id(event)
 if id.is_empty() or not holds.has(id):return
 # A new non-repeat press implies the earlier release was lost (e.g. focus
 # changed). Retire stale ownership and let this distinct gesture through.
 if event.pressed and (not event is InputEventKey or not event.echo):
  holds.erase(id);host._held_inputs.erase(id)
  if holds.is_empty():queue_free()
  return
 if not event.pressed:
  holds.erase(id);host._held_inputs.erase(id)
 get_viewport().set_input_as_handled()
 if holds.is_empty():queue_free()
