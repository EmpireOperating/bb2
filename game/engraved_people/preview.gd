extends Node3D
## Presentation seam used by the existing inventory panel. Never spawns a field actor.
const Art = preload("res://engraved_people/actors.gd")
var _diagnostics := {}
var _texture: Texture2D
func configure(unit: Dictionary, _catalog: Dictionary) -> void:
 _diagnostics=Art.describe(unit)
 _texture=Art.field(unit)
func preview_texture() -> Texture2D:return _texture
func render_diagnostics() -> Dictionary:return _diagnostics.duplicate(true)
func layer_signature() -> Dictionary:return _diagnostics.get("signature",{}).duplicate(true)
