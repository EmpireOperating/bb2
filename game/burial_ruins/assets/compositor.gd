extends "res://company_loop/compositor.gd"
## Finite foundation derivatives; equipment is still the accepted compositor.
func _image(asset: String) -> Image:
 if not asset.begins_with("burial_foundation"): return super._image(asset)
 if not _images.has(asset):
  var path := "res://burial_ruins/assets/"+asset+".png"
  if not FileAccess.file_exists(path): return null
  var image := Image.new()
  if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK: return null
  image.convert(Image.FORMAT_RGBA8)
  _images[asset] = image
 return _images[asset]
