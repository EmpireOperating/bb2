extends "res://hollow_experiment/donor/approved_six_presentation.gd"
## Request-local color treatment only. All semantic ordering and source admission
## execute the pinned donor implementation. Never modify its immutable PNG cache.
var tints: Dictionary = {}

func _image(layer: Dictionary) -> Dictionary:
	var result: Dictionary = super._image(layer)
	if not result.get("ok",false): return result
	var tint: Color = tints.get(layer.get("owner_art_key",""),Color.WHITE)
	if tint == Color.WHITE: return result
	var source: Image = result.image
	var bytes := source.get_data()
	for i in range(0,bytes.size(),4):
		bytes[i] = int(roundf(bytes[i]*tint.r))
		bytes[i+1] = int(roundf(bytes[i+1]*tint.g))
		bytes[i+2] = int(roundf(bytes[i+2]*tint.b))
	return {"ok":true,"image":Image.create_from_data(source.get_width(),source.get_height(),false,Image.FORMAT_RGBA8,bytes)}
