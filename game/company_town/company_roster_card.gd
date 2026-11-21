extends "res://iron_oath/inventory_card.gd"
## Keep the approved composed portrait, but give assignment its own readable line.
var assignment: Label
var level_up_badge: Control
var vitals: Control
var _portrait_source: Texture2D
var _portrait: AtlasTexture
const InjuryStatus = preload("res://stat_clarity/injuries.gd")
var injury_badge: Label
var _injury_tooltip := ""
func present_injuries(person: Dictionary) -> void:
 var status: Dictionary = InjuryStatus.describe(person)
 _injury_tooltip = status.tooltip if status.active else ""
 injury_badge.visible = status.active
 injury_badge.text = "+" if status.temporary == "Deep wound" else "!"
 injury_badge.add_theme_color_override("font_color",Color("ef8f78") if status.temporary == "Deep wound" else Color("c5ad78"))
 _layout()
func _get_tooltip(at: Vector2) -> String:
 if injury_badge != null and injury_badge.visible and Rect2(injury_badge.position,injury_badge.size).has_point(at):return _injury_tooltip
 return tooltip_text
func _make_custom_tooltip(for_text: String) -> Object:
 var label := Label.new();label.text = for_text;label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.custom_minimum_size.x = 440;label.add_theme_font_size_override("font_size",14)
 return label
func present(title: String, detail: String, texture: Texture2D, uid: String = "", tier: String = "", condition: float = 0, maximum: float = 0) -> void:
 if texture!=_portrait_source:
  _portrait_source=texture;_portrait=null
  if texture is AtlasTexture and texture.has_meta("protected_head"):
   # Each card owns its crop. Never mutate the shared cached portrait/actor.
   _portrait=AtlasTexture.new();_portrait.atlas=texture.atlas;_portrait.region=texture.region
 super.present(title,detail,_portrait if _portrait!=null else texture,uid,tier,condition,maximum)
func _fit_head() -> void:
 if _portrait==null or not art.size.x>0 or not art.size.y>0:return
 var bounds:=Rect2(Vector2.ZERO,_portrait.atlas.get_size())
 var protected:Rect2=_portrait_source.get_meta("protected_head")
 var safe:=protected.grow(6).intersection(bounds)
 var preferred:Rect2=_portrait_source.region
 var top:=minf(preferred.position.y,safe.position.y)
 var ratio:=art.size.x/art.size.y
 var height:=maxf(preferred.size.y,maxf(safe.end.y-top,safe.size.x/ratio))
 var width:=height*ratio
 if width>bounds.size.x or height>bounds.size.y:
  # An impossible aspect gets safe letterboxing, never a cut-off head.
  _portrait.region=safe
  return
 var x:=clampf(safe.get_center().x-width/2,0,bounds.size.x-width)
 var y:=clampf(top,0,bounds.size.y-height)
 _portrait.region=Rect2(Vector2(x,y),Vector2(width,height))
func _init() -> void:
 super()
 art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 assignment = _label(12);assignment.add_theme_color_override("font_color",Color("c5ad78"))
 vitals=preload("res://iron_oath/vitals.gd").new();add_child(vitals)
 level_up_badge=preload("res://ui_polish/level_up_badge.gd").new();art.add_child(level_up_badge)
 injury_badge = _label(17);injury_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;injury_badge.hide()
 var plate := StyleBoxFlat.new();plate.bg_color = Color("241a19");plate.border_color = Color("bd8465");plate.set_border_width_all(1);plate.set_corner_radius_all(3)
 injury_badge.add_theme_stylebox_override("normal",plate)
func present_progression(person: Dictionary) -> void:
 level_up_badge.present(person);_layout()
func present_vitals(unit: Dictionary) -> void:
 caption.hide();meter.hide();vitals.present(unit);_layout()
func set_assignment(text_value: String) -> void:
 assignment.text = text_value;_layout()
func _layout() -> void:
 super._layout()
 if assignment == null:return
 var icon_width := minf(size.y-14,size.x*.30)
 var x := icon_width+15;var width := maxf(1,size.x-x-10)
 art.size = Vector2(icon_width,maxf(8,size.y-14))
 _fit_head()
 if level_up_badge != null:
  level_up_badge.position=Vector2(maxf(0,art.size.x-22),0);level_up_badge.size=Vector2(22,22)
 if injury_badge != null:
  injury_badge.position = Vector2(11,maxf(9,size.y-30));injury_badge.size = Vector2(22,22)
 heading.position = Vector2(x,7);heading.size = Vector2(width,23)
 _clear_badge_title()
 assignment.position = Vector2(x,30);assignment.size = Vector2(width,17)
 if vitals!=null:
  vitals.position=Vector2(x,49);vitals.size=Vector2(width,maxf(40,size.y-55))
