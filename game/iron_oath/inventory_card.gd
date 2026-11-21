extends Button
## Passive painted card. The owning panel alone connects the canonical command.
const IronSkin = preload("res://iron_oath/skin.gd")
const ItemRarity = preload("res://hollow_systems/rarity.gd")
const Press = preload("res://engraved_ui/press.gd")
var art_mat: Panel
var art: TextureRect
var heading: Label
var caption: Label
var badge: TextureRect
var meter: ProgressBar
var mode := "slot"
var item_uid := ""
func _init() -> void:
 clip_text = true
 focus_mode = Control.FOCUS_ALL
 size_flags_horizontal = Control.SIZE_EXPAND_FILL
 art = TextureRect.new();art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 art.mouse_filter = Control.MOUSE_FILTER_IGNORE;add_child(art)
 art_mat=Press.mount_icon(art);art_mat.hide()
 heading = _label(17);heading.add_theme_font_override("font",load("res://assets/serif.ttf"))
 caption = _label(13);caption.add_theme_color_override("font_color",Color("d0c3a6"))
 badge = preload("res://iron_oath/rarity_badge.gd").new();add_child(badge)
 meter = ProgressBar.new();meter.show_percentage = false;meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var bg := StyleBoxFlat.new();bg.bg_color = Color("302c22");bg.set_corner_radius_all(2)
 var fill := bg.duplicate();fill.bg_color = Color("81934f")
 meter.add_theme_stylebox_override("background",bg);meter.add_theme_stylebox_override("fill",fill);add_child(meter)
 resized.connect(_layout)
 add_theme_color_override("font_color",Color.TRANSPARENT)
 add_theme_color_override("font_hover_color",Color.TRANSPARENT)
 add_theme_color_override("font_focus_color",Color.TRANSPARENT)
 add_theme_color_override("font_pressed_color",Color.TRANSPARENT)
 add_theme_color_override("font_disabled_color",Color.TRANSPARENT)
 add_theme_stylebox_override("focus",Press.focus())
 set_selected(false)
func _label(font_size: int) -> Label:
 var label := Label.new();label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",Color("eeddb8"))
 label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 label.max_lines_visible = 1;add_child(label);return label
func present(title: String, detail: String, texture: Texture2D, uid: String = "", tier: String = "", condition: float = 0, maximum: float = 0) -> void:
 heading.text = title;caption.text = detail;art.texture = texture;item_uid = uid
 # Companion rarity is not item craftsmanship; never paint an orange N on a person.
 badge.present("" if mode == "roster" and tier == "named" else tier)
 heading.add_theme_color_override("font_color",ItemRarity.tier_color("named") if tier == "named" and mode != "roster" else Press.TYPE)
 meter.visible = maximum > 0;meter.max_value = maxf(1,maximum);meter.value = condition
 art.material = null if mode == "roster" else Press.icon_ink()
 art_mat.visible = mode != "roster" and texture != null
 var fill := meter.get_theme_stylebox("fill") as StyleBoxFlat
 var bg := meter.get_theme_stylebox("background") as StyleBoxFlat
 var fraction := condition / maximum if maximum > 0 else 0.0
 fill.bg_color=Press.VERMILION if fraction <= 0.25 else Press.BRASS if fraction < 0.65 else Press.GREEN
 bg.bg_color=Color("873e30") if condition <= 0 and maximum > 0 else Color("172019")
 _layout()
func set_selected(selected: bool) -> void:
 add_theme_stylebox_override("normal",IronSkin.panel(5,selected))
 add_theme_stylebox_override("hover",IronSkin.panel(5,true))
 add_theme_stylebox_override("pressed",IronSkin.button(true,true))
 add_theme_stylebox_override("disabled",Press.box("shut",5,5))
func _layout() -> void:
 if art == null:return
 var grid := mode == "stash"
 var portrait := mode == "roster"
 var inset := 9.0
 var icon_width := size.x-18 if grid else minf(size.y-14,size.x*(.40 if portrait else .34))
 art.position = Vector2(inset,7);art.size = Vector2(icon_width,maxf(8,size.y-(52 if grid else 14)))
 var x := inset if grid else icon_width+15
 var width := maxf(1,size.x-x-10)
 heading.position = Vector2(x,size.y-43 if grid else 12);heading.size = Vector2(width,23)
 caption.position = Vector2(x,size.y-23 if grid else 37);caption.size = Vector2(width,18)
 if mode=="slot":
  var two_lines := size.y>=80 and not item_uid.is_empty()
  caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART if two_lines else TextServer.AUTOWRAP_OFF
  caption.max_lines_visible=2 if two_lines else 1
  if two_lines:
   caption.position.y=34;caption.size=Vector2(width,size.y-49)
 badge.position = Vector2(size.x-36,6);badge.size = Vector2(28,28)
 meter.position = Vector2(x,size.y-11);meter.size = Vector2(width,4)
 if grid:meter.position.y = size.y-5
 heading.add_theme_font_size_override("font_size",15 if size.x < 210 else 20 if portrait else 18)
 _clear_badge_title()
func _clear_badge_title() -> void:
 # Stash titles below the art retain their full width. Only a title sharing
 # the top corner needs clearance; portraits, stats and assignment never move.
 if badge.visible and heading.get_rect().intersects(badge.get_rect().grow(6)):
  heading.size.x = maxf(1,badge.position.x-heading.position.x-6)
