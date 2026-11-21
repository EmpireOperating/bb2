extends RefCounted
const Press=preload("res://engraved_ui/press.gd")
static func mount(field) -> void:
 if not field.built or not is_instance_valid(field.combat_initiative):return
 var title: Label=field.hud.get_node("CombatBrand")
 title.text="FIRST MUSTER";title.add_theme_color_override("font_color",Press.BRASS)
 title.add_theme_stylebox_override("normal",Press.box("binding",6,0))
 field.help_panel.add_theme_stylebox_override("panel",Press.box("binding",12,12))
 field.combat_help_heading.add_theme_color_override("font_color",Press.BRASS)
 field.action_buttons.retreat.add_theme_color_override("font_color",Press.VERMILION)
 # Let longer skill names and their hotkeys wrap together inside the existing
 # action rail. Godot gives the icon the space left above its actual text.
 for key in ["basic","special"]:
  var skill: Button=field.action_buttons[key]
  skill.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  skill.add_theme_font_size_override("font_size",15)
 # Each published initiative card owns one tiny printer's device. The retained
 # portrait supplies its live, sight-filtered side/active state at redraw.
 for button in field.combat_initiative.get_children():watch(button)
 field.combat_initiative.child_entered_tree.connect(watch)
static func watch(button: Node) -> void:
 if not button is Button:return
 if button.has_node("FighterPortrait"):attach(button.get_node("FighterPortrait"))
 else:button.child_entered_tree.connect(func(node):
  if node.name=="FighterPortrait":attach(node))
static func attach(face: Control) -> void:
 # CanvasItem emits draw before the portrait's _draw paints its opaque well.
 # A passive child paints afterwards; it shares the already sight-filtered card's lifetime.
 var badge:=Control.new();badge.name="Allegiance";badge.size=Vector2(15,16)
 badge.mouse_filter=Control.MOUSE_FILTER_IGNORE;badge.focus_mode=Control.FOCUS_NONE
 face.add_child(badge);badge.draw.connect(mark.bind(badge,face));face.draw.connect(badge.queue_redraw)
static func mark(badge:Control, face) -> void:
 if face.get_meta("fighter_id",-1)<0:return
 # A swallowtail standard for company, a descending spear point for hostiles;
 # identical size, different silhouette even without color or underneath focus.
 var points:=PackedVector2Array([Vector2(0,0),Vector2(14,0),Vector2(14,12),Vector2(7,8),Vector2(0,12)] if not face.enemy else [Vector2(0,0),Vector2(14,0),Vector2(14,7),Vector2(7,15),Vector2(0,7)])
 badge.draw_colored_polygon(points,Press.GREEN if not face.enemy else Press.VERMILION)
 points.append(points[0]);badge.draw_polyline(points,Press.INK,1,true)
 badge.draw_line(Vector2(3,4),Vector2(10,4),Press.INK,1,true)
 if face.enemy:badge.draw_line(Vector2(7,4),Vector2(7,10),Press.INK,1,true)
