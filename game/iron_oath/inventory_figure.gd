extends TextureRect
## Keep the actual actor Texture2D identity; frame its nontransparent pixels.
## The transparent native TextureRect keeps the inherited inspection seam.
## Its child draws a source region of that SAME texture, never a new composite.
class Artwork extends Control:
 var source_texture: Texture2D
 var source_region := Rect2()
 var destination := Rect2()
 func _draw() -> void:
  if source_texture != null and source_region.has_area():
   draw_texture_rect_region(source_texture,destination,source_region)
var artwork: Artwork
func _init() -> void:
 self_modulate = Color(1,1,1,0) # self-only; the actual artwork child stays opaque.
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 artwork = Artwork.new();artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
 artwork.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
 add_child(artwork);resized.connect(_frame)
func present(value: Texture2D) -> void:
 if texture == value:return
 texture = value;artwork.source_texture = value
 if value == null:artwork.source_region = Rect2()
 else:
  var image := value.get_image();image.clear_mipmaps()
  artwork.source_region = Rect2(image.get_used_rect())
 _frame()
func _frame() -> void:
 artwork.size = size
 if not artwork.source_region.has_area():artwork.destination = Rect2()
 else:
  var scale_value := minf(size.x/artwork.source_region.size.x,size.y/artwork.source_region.size.y)
  var extent := artwork.source_region.size*scale_value
  artwork.destination = Rect2((size-extent)/2,extent)
 artwork.queue_redraw()
func painted_rect() -> Rect2:
 return artwork.destination
