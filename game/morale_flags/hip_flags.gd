extends Node3D
## Read-only tactical pennants. A sibling of the figures, not part of Illustration
## (the field alpha-ray picker traverses that subtree), the HUD, or any snapshot.
const ART := {
 1:"res://morale_flags/confident.png",
 -1:"res://morale_flags/wavering.png",
 -2:"res://morale_flags/breaking.png",
 -3:"res://morale_flags/fleeing.png",
}
const HIP := Vector2(0.28,0.86) # Screen-facing world units from the planted plate origin.
const PEG := Vector2(8,29) # Shared authored cloth/pole attachment in the unflipped plate.
var _textures: Dictionary = {}
var _flags: Dictionary = {}

func _init() -> void:
 name = "MoraleFlags"
 process_priority = 20 # Observe after the field scheduler and the figures' pose updates.

func _process(_delta: float) -> void:
 var field := get_parent()
 var battle = field.battle
 var camera: Camera3D = field.camera
 var keep := {}
 if field.built and battle != null and battle.individual and battle.core_rules and is_instance_valid(camera):
  var axes := camera.global_basis.orthonormalized()
  var hold: bool = not field._impact_beats.is_empty()
  for unit: Dictionary in battle.units:
   var id: int = unit.id
   # Own-side unit_visible alone admits dead rows. Never use held vitals,
   # explored cells, private feedback, or the presence of corpse art for this.
   if not battle.living(unit) or not battle.unit_visible(0,id): continue
   if not unit.get("stat_rules",false) or unit.get("faction","") == "undead": continue
   var actor: Node3D = field.actors.get(id)
   if not is_instance_valid(actor) or not actor.is_visible_in_tree(): continue
   var plate := actor.get_node_or_null("Illustration/Composite") as Sprite3D
   if not is_instance_valid(plate) or not plate.is_visible_in_tree() or plate.texture == null: continue
   var flag: Sprite3D = _flags.get(id)
   if hold:
    # Don't announce a new living morale result before contact. The gates
    # above still retire fogged or dead actors during the hold itself.
    if flag == null or flag.get_meta("portrait_owner") != actor.get_instance_id(): continue
   else:
    var state: Variant = unit.get("morale_state")
    if not state is int or not ART.has(state) or (state == -3) != unit.get("routed",false): continue
    var texture := _texture(state)
    if texture == null: continue
    if flag == null:
     flag = _make_flag(id)
     _flags[id] = flag
    flag.set_meta("portrait_owner",actor.get_instance_id())
    if flag.texture != texture: flag.texture = texture
   var sign_x := 1.0 if plate.flip_h else -1.0
   flag.flip_h = sign_x < 0.0
   flag.offset = Vector2(sign_x*(0.5*flag.texture.get_width()-PEG.x),PEG.y-0.5*flag.texture.get_height())
   # Follow the rendered foot/illustration through tween, facing and recoil.
   # A small forward depth bias keeps the pin readable against its own plate;
   # ordinary world depth, including terrain and other actors, is still tested.
   flag.global_transform = Transform3D(axes,plate.global_position+axes.x*HIP.x*sign_x+axes.y*HIP.y+axes.z*0.045)
   keep[id] = true
 for id in _flags.keys():
  if keep.has(id): continue
  _flags[id].free()
  _flags.erase(id)

func _texture(state: int) -> Texture2D:
 if not _textures.has(state):
  # Raw authored PNG paths are also present in the mounted source ZIP.
  var image := Image.load_from_file(ART[state])
  _textures[state] = ImageTexture.create_from_image(image) if image != null else null
 return _textures[state]

func _make_flag(id: int) -> Sprite3D:
 var flag := Sprite3D.new()
 flag.name = "Flag%d" % id
 flag.pixel_size = 0.0105
 flag.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
 flag.alpha_scissor_threshold = 0.34
 flag.shaded = false
 flag.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 flag.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
 add_child(flag)
 return flag
