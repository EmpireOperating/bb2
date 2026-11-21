extends TextureRect
## Decorative only. Authority stays with each caller's existing tier projection.
func _init() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 focus_mode = Control.FOCUS_NONE
 expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
const TIERS := ["common","rare","legendary","named","invalid"]
static var _textures: Dictionary = {}
func present(tier: String) -> void:
 # Empty legacy/unrolled equipment and empty slots retain their absent badge.
 visible = not tier.is_empty()
 texture = null
 tooltip_text = ""
 if tier.is_empty():return
 var classification := tier if tier in TIERS else "invalid"
 tooltip_text = "Named craftsmanship" if classification == "named" else classification.capitalize()
 if not _textures.has(classification):
  # PNG bytes also work before editor import; export remaps use the resource.
  var path := "res://iron_oath/assets/rarity/"+classification+".png"
  var source: Texture2D = null
  if FileAccess.file_exists(path):
   var image := Image.new()
   if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK:
    source = ImageTexture.create_from_image(image)
  elif ResourceLoader.exists(path):
   source = ResourceLoader.load(path,"Texture2D") as Texture2D
  if source != null:_textures[classification] = source
 texture = _textures.get(classification)
