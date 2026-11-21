extends Control
## Derived presentation only. No persisted notification or view-open acknowledgement.
const Progression = preload("res://src/progression.gd")
var status := {}
static func pending(person: Dictionary) -> Dictionary:
 if person.is_empty() or not person.get("alive",false):return {}
 var perks := maxi(0,Progression.points(person))
 var attributes := 0
 for i in range(Progression.level(person)-1):
  attributes += maxi(0,3-person.get("training",[])[i].size()) if person.get("growth_version",0) == 1 else 0
 if perks == 0 and attributes == 0:return {}
 return {"perks":perks,"attributes":attributes,"levels":Progression.training_levels(person)}
func _init() -> void:
 name = "LevelUpBadge";custom_minimum_size = Vector2(22,22)
 mouse_filter = Control.MOUSE_FILTER_PASS;focus_mode = Control.FOCUS_NONE
func present(person: Dictionary) -> void:
 status = pending(person);set_meta("soldier_id",person.get("id",-1))
 visible = not status.is_empty()
 tooltip_text = ""
 if visible:
  tooltip_text = "Level up available\n%d perk point%s · %d attribute choices remaining\nOpen Company → Perks to choose." % [status.perks,"" if status.perks == 1 else "s",status.attributes]
 queue_redraw()
func _draw() -> void:
 var center := size/2
 draw_circle(center,10,Color("253d2b"))
 draw_arc(center,10,0,TAU,32,Color("e2cf8c"),1.5,true)
 var ink := Color("b6ec91")
 draw_line(center+Vector2(0,6),center+Vector2(0,-5),ink,3,true)
 draw_polyline(PackedVector2Array([center+Vector2(-5,0),center+Vector2(0,-5),center+Vector2(5,0)]),ink,3,true)
