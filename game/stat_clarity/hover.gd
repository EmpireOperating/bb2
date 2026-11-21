extends PanelContainer
## Passive child in the painter's virtual coordinate space. Never consumes input.
var body: Label
var world
var owner_key: Array = []
func _init() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE;focus_mode = Control.FOCUS_NONE;z_index = 90
 var style := StyleBoxFlat.new();style.bg_color = Color("171b1e");style.border_color = Color("bca06b");style.set_border_width_all(1)
 style.content_margin_left = 14;style.content_margin_right = 14;style.content_margin_top = 12;style.content_margin_bottom = 12
 add_theme_stylebox_override("panel",style)
 body = Label.new();body.mouse_filter = Control.MOUSE_FILTER_IGNORE;body.add_theme_font_size_override("font_size",14);body.add_theme_color_override("font_color",Color("eeddb8"))
 body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;body.custom_minimum_size.x = 470;add_child(body);hide()
func current_key() -> Array:
 if world == null or not world.is_visible_in_tree() or world.blocked() or world._surface() != "person":return []
 if world.person_offer.is_empty():
  if world.camp_selected < 0 or world.camp_selected >= world.campaign.soldiers.size():return []
  return [world.campaign,world.camp_selected,"",JSON.stringify(world.campaign.soldiers[world.camp_selected])]
 return [world.campaign,-1,world.person_offer]
func _process(_delta: float) -> void:
 if visible and current_key() != owner_key:retire()
func retire() -> void:
 hide();body.text = "";owner_key.clear()
func _input(event: InputEvent) -> void:
 if event is InputEventMouseMotion:
  inspect_at(world.get_global_transform_with_canvas().affine_inverse()*event.position)
func inspect_at(point: Vector2) -> void:
 var key := current_key()
 if key.is_empty():retire();return
 var person: Dictionary = {}
 var offer: bool = not world.person_offer.is_empty()
 if offer:
  var candidates: Array = world.campaign.recruits().filter(func(p):return p.id == world.person_offer)
  if not candidates.is_empty():person = candidates[0]
 else:person = world.campaign.soldiers[world.camp_selected]
 if person.is_empty():retire();return
 var content := ""
 for i in world.People.ATTRS.size():
  # Exclude talent/training controls and preserve all existing click ownership.
  if Rect2(600,252+i*47,350,43).has_point(point):
   content = world.stat_breakdown(person,world.People.ATTRS[i],offer).text;break
 if not offer and Rect2(158,255,394,46).has_point(point):content = world.injury_status(person).tooltip
 if content.is_empty():retire();return
 body.text = content;owner_key = key
 reset_size();position = Vector2(clampf(point.x-510,120,810),clampf(point.y+20,145,790-get_combined_minimum_size().y));show()
