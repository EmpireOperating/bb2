extends RefCounted
## First Muster print stock. No viewports, input, timers, domain reads or screen filters.
const INK := Color("202b23")
const TYPE := Color("f1e6c6")
const BRASS := Color("e5c180")
const GREEN := Color("9dc5ad")
const VERMILION := Color("f0a188")
const PAPER_INK := Color("253528")
const PAPER_NOTE := Color("43503b")
const PAPER_RED := Color("733728")
static var _stocks := {}
static func stock(name: String) -> Texture2D:
 if not _stocks.has(name):
  var path := "res://engraved_ui/print/"+name+".png"
  var image := Image.new()
  var tex: Texture2D
  if FileAccess.file_exists(path) and image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK:
   tex = ImageTexture.create_from_image(image)
  elif ResourceLoader.exists(path):tex=load(path)
  if tex == null:push_error("Missing First Muster stock: " + path);return null
  tex.resource_name="Muster/"+name;_stocks[name]=tex
 return _stocks[name]
static func box(kind: String, x: int, y: int) -> StyleBoxTexture:
 var sheet:=StyleBoxTexture.new();sheet.texture=stock(kind);sheet.set_texture_margin_all(16)
 sheet.axis_stretch_horizontal=StyleBoxTexture.AXIS_STRETCH_MODE_TILE
 sheet.axis_stretch_vertical=StyleBoxTexture.AXIS_STRETCH_MODE_TILE
 sheet.content_margin_left=x;sheet.content_margin_right=x
 sheet.content_margin_top=y;sheet.content_margin_bottom=y
 return sheet
static func focus() -> StyleBoxFlat:
 var ring:=StyleBoxFlat.new();ring.draw_center=false;ring.border_color=Color("ffdc91");ring.set_border_width_all(2)
 for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:ring.set_content_margin(side,0)
 return ring
static var _print_blocks: Dictionary={}
static func impression(host, rect: Rect2, kind: String) -> void:
 if host is CanvasItem and rect.has_area():
  if not _print_blocks.has(kind):_print_blocks[kind]=box(kind,0,0)
  host.draw_style_box(_print_blocks[kind],rect)
## Small icon register. Keep the original image, crop and aspect, even when worn.
static var _ink: ShaderMaterial
static func icon_ink() -> ShaderMaterial:
 if _ink==null:
  _ink=ShaderMaterial.new();_ink.shader=preload("res://engraved_ui/icon_ink.gdshader")
 return _ink
static func mount_icon(icon: TextureRect, resource: bool = false) -> Panel:
 icon.material=icon_ink()
 # Negative z would put this below the parent. A passive behind-parent child
 # draws just before this TextureRect and follows its existing rect exactly.
 var mat:=Panel.new();mat.name="Impression";mat.mouse_filter=Control.MOUSE_FILTER_IGNORE
 mat.focus_mode=Control.FOCUS_NONE;mat.show_behind_parent=true
 mat.add_theme_stylebox_override("panel",box("leaf" if resource else "well",0,0))
 icon.add_child(mat);mat.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var inset := 1 if resource else 2
 mat.offset_left=-inset;mat.offset_top=-inset;mat.offset_right=inset;mat.offset_bottom=inset
 return mat
