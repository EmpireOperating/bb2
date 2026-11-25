extends Panel
## One passive, out-of-scroller card. Native picking owns the hovered Control;
## this view does not claim input, change selection, or store equipment data.
const UI = preload("res://ui_polish/style.gd")
const Card = preload("res://iron_oath/inventory_card.gd")
const Rarity = preload("res://hollow_systems/rarity.gd")
const Text = preload("res://ui_polish/item_hover_text.gd")
const VaultItems = preload("res://vault_key_items/presentation.gd")
const DELAY := 0.22
const WIDTH := 384.0
const INSET := 12.0
const GAP := 10.0

enum InputKind {NONE, POINTER, KEYBOARD}
var _input_kind := InputKind.NONE
var _workspace
var _source: Button
var _source_key: Array = []
var _age := 0.0
var _projection := {}
var _labels: Array[Label] = []
const FLOW: Array[float] = [0,1,6,7,1,6]

func _init() -> void:
 name = "ItemHover"
 z_index = 90
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 focus_mode = Control.FOCUS_NONE
 var border := UI.panel(Color("19231d"),Color("a88a55"),0)
 border.shadow_color = Color(0,0,0,.44);border.shadow_size = 4;border.shadow_offset = Vector2(0,2)
 add_theme_stylebox_override("panel",border)
 hide()

func _ready() -> void:
 _workspace = get_parent()
 _workspace.visibility_changed.connect(_workspace_visibility)
 get_window().mouse_exited.connect(_pointer_exited)
 get_window().focus_exited.connect(retire)
 _label(20,UI.TEXT).add_theme_font_override("font",preload("res://assets/serif.ttf"))
 _label(14,UI.MUTED)
 _label(15,UI.TEXT)
 _label(13,UI.GOLD)
 _label(14,UI.TEXT)
 _label(13,UI.MUTED)

func _label(font_size: int, ink: Color) -> Label:
 var label := Label.new()
 UI.label(label,font_size,ink)
 label.focus_mode = Control.FOCUS_NONE
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 add_child(label);_labels.append(label)
 return label

func retire() -> void:
 _input_kind = InputKind.NONE
 _clear_source()

func _clear_source() -> void:
 hide()
 _source = null
 _source_key.clear()
 _age = 0.0
 _projection.clear()

func _workspace_visibility() -> void:
 if not _workspace.is_visible_in_tree():retire()

func _pointer_exited() -> void:
 if _input_kind == InputKind.POINTER:retire()

func _input(event: InputEvent) -> void:
 if not is_inside_tree() or not _workspace.is_visible_in_tree():return
 if event is InputEventMouseMotion or event is InputEventMouseButton:
  if _input_kind == InputKind.KEYBOARD:_clear_source()
  _input_kind = InputKind.POINTER
  if event is InputEventMouseButton and event.pressed:_clear_source()
 elif event is InputEventKey and event.pressed and not event.echo:
  var code: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
  if code in [KEY_TAB,KEY_LEFT,KEY_UP,KEY_RIGHT,KEY_DOWN]:
   if _input_kind != InputKind.KEYBOARD:_clear_source()
   _input_kind = InputKind.KEYBOARD

func _process(delta: float) -> void:
 if _input_kind == InputKind.NONE:return
 var viewport := get_viewport()
 if _workspace.is_queued_for_deletion() or not _workspace.is_visible_in_tree() or _workspace.section != "equipment" or _workspace.session == null or not _workspace._browse_reason().is_empty():
  retire();return
 if viewport.gui_is_dragging() or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
  _clear_source();return
 var keyboard := _input_kind == InputKind.KEYBOARD
 var source := (viewport.gui_get_focus_owner() if keyboard else viewport.gui_get_hovered_control()) as Card
 if not is_instance_valid(source) or source.is_queued_for_deletion() or source.disabled or not _workspace.is_ancestor_of(source):
  _clear_source();return
 var key: String = source.get_meta("vault_key_id","")
 if source.item_uid.is_empty() and key.is_empty():
  _clear_source();return
 var hit: Dictionary = _workspace._target(source)
 var clipped := Rect2(hit.clipped_rect[0],hit.clipped_rect[1],hit.clipped_rect[2],hit.clipped_rect[3])
 if not hit.visible or (not keyboard and not clipped.has_point(viewport.get_mouse_position())):
  _clear_source();return
 var campaign = _workspace.session.campaign
 var stamp := [campaign.get_instance_id(),_workspace._revision,_workspace.selected_sid,source.item_uid,key]
 if _source != source or _source_key != stamp:
  _clear_source()
  _source = source;_source_key = stamp
 _age += delta
 if not keyboard and _age < DELAY:return
 if _projection.is_empty():
  _projection = _inspect(source,campaign,key)
  if _projection.is_empty():
   _clear_source();return
  _paint()
 _place_card(clipped)

func _inspect(source: Card, c, key: String) -> Dictionary:
 if not key.is_empty():
  if _workspace.key_buttons.get(key) != source:return {}
  var entry := VaultItems.row(c,key)
  return Text.key(entry) if not entry.is_empty() else {}
 var uid := source.item_uid
 var record: Dictionary = c.items.get(uid,{})
 if record.get("id") != uid:return {}
 var person: Dictionary = _workspace._person()
 var owner: int = c.owner(uid)
 var origin := "Owned stash"
 if source.mode == "stash":
  if _workspace.item_buttons.get(uid) != source or owner >= 0 or not c.parent_kit(uid).is_empty():return {}
 else:
  var cards: Dictionary = _workspace.carry_buttons if source.mode == "carry" else _workspace.slot_buttons
  var slot = cards.find_key(source)
  if not slot is String or person.is_empty() or owner != _workspace.selected_sid or c.slot_uid(person,slot) != uid:return {}
  origin = "%s · %s" % [person.name,source.heading.text]
 var ammo: Dictionary = c.items.get(c.slot_uid(person,"ammo"),{}) if not person.is_empty() else {}
 var data := Text.item(record,c.catalog,_workspace._unit,c.battle,ammo,origin)
 if source.mode == "stash" and data.tier != "invalid" and c.stored_repair_cost(uid) > 0:
  var queued: bool = uid in c.recovery.stored
  if queued:data.record += "\nQueued for repair"
  if not _workspace.battle_read_only:data.record += "\nShift-click to "+("cancel repair" if queued else "queue repair")
 if source.art.texture == null:data.record += "\nNo exact item paint"
 return data

func _paint() -> void:
 var data := _projection
 _labels[0].text = data.title
 _labels[1].text = data["class"]
 _labels[1].add_theme_color_override("font_color",UI.MUTED if data.tier.is_empty() else Rarity.tier_color(data.tier))
 _labels[2].text = data.stats
 _labels[3].text = "WEAPON SKILLS · IF EQUIPPED" if not data.skills.is_empty() else ""
 _labels[4].text = data.skills
 _labels[5].text = data.record

func _place_card(clipped: Rect2) -> void:
 var inverse: Transform2D = _workspace.get_global_transform_with_canvas().affine_inverse()
 var source: Rect2 = inverse * clipped
 var area: Rect2 = (inverse * get_viewport_rect()).intersection(Rect2(Vector2.ZERO,_workspace.size)).grow(-INSET)
 # Prefer the equipment body band; don't obscure the identity/header or stash actions.
 var content_top: Rect2 = inverse * _workspace._canvas_rect(_workspace.stash_scroll)
 var action_reason: Rect2 = inverse * _workspace._canvas_rect(_workspace.reason_label)
 var remove: Rect2 = inverse * _workspace._canvas_rect(_workspace.remove_button)
 var details: Rect2 = inverse * _workspace._canvas_rect(_workspace.details_button)
 area.position.y = maxf(area.position.y,content_top.position.y)
 area.end.y = minf((inverse * get_viewport_rect()).end.y-INSET,action_reason.position.y-GAP)
 var width := minf(WIDTH,area.size.x)
 if width <= INSET*2 or not area.has_area():hide();return
 var y := INSET
 for i in _labels.size():
  var label := _labels[i]
  label.visible = not label.text.is_empty()
  if not label.visible:continue
  y += FLOW[i]
  label.position = Vector2(INSET,y)
  label.size.x = width-INSET*2
  # No maximum lines/ellipsis: actual Godot text shaping sets the block height.
  label.size.y = label.get_minimum_size().y
  y += label.size.y
 var box := Vector2(width,y+INSET)
 if box.y > area.size.y:
  # At shorter heights allow the full client band, while keeping controls clear.
  area.position.y = (inverse * get_viewport_rect()).position.y+INSET
  area.end.y = minf((inverse * get_viewport_rect()).end.y-INSET,action_reason.position.y-GAP)
 if box.y > area.size.y:hide();return
 var left := source.position.x-GAP-box.x
 var right := source.end.x+GAP
 var aligned_y := clampf(source.position.y,area.position.y,area.end.y-box.y)
 var centered_x := clampf(source.get_center().x-box.x*.5,area.position.x,area.end.x-box.x)
 var sides := [left,right] if source.get_center().x > area.get_center().x else [right,left]
 var spots := [Vector2(sides[0],aligned_y),Vector2(sides[1],aligned_y),Vector2(centered_x,source.position.y-GAP-box.y),Vector2(centered_x,source.end.y+GAP)]
 for x: float in sides:
  spots.append(Vector2(x,minf(aligned_y,remove.position.y-GAP-box.y)))
  spots.append(Vector2(x,minf(aligned_y,details.position.y-GAP-box.y)))
  spots.append(Vector2(x,maxf(aligned_y,details.end.y+GAP)))
 for spot: Vector2 in spots:
  var proposed := Rect2(spot,box)
  if area.encloses(proposed) and not proposed.intersects(source) and not proposed.intersects(remove) and not proposed.intersects(details):
   position = spot;size = box;show();return
 hide()

func observation() -> Dictionary:
 return {"visible":true,"uid":_projection.uid,"key":_projection.key,"text":"\n".join(_labels.filter(func(label):return label.visible).map(func(label):return label.text))} if visible else {"visible":false}
