extends "res://company_loop/character.gd"
## Painted hostiles reuse the existing strike clock. Anchors, material, portrait
## and item truth remain owned by their original renderer.
const HostileArms = preload("res://src/arsenal.gd")
const HostileCuts = preload("res://painted_merge/hostile_motion/cuts.gd")
var _cut_key := ""
var _cut_identity := ""
var _cut_elapsed := -1.0
var _cut_index := -1
var _cut_flip := true
var _cut_idle_flip := true
var _cut_spec: Dictionary = {}
var _cut_frames: Array = []

func _bind_hostile_attack(key:String, unit:Dictionary) -> void:
 var sprite:Sprite3D=_cut_sprite()
 if sprite!=null:_cut_idle_flip=sprite.flip_h
 var item:Dictionary=unit.get("arms",{}).get("weapon",{})
 var weapon:String=str(unit.get("weapon",""))
 var owned:String=str(item.get("id",""))
 var signature:String=str(_signature.get("weapon",{}).get("item",""))
 if weapon in HostileArms.RANGED or weapon.is_empty() or owned.is_empty() or owned!=signature:key=""
 var identity:String=JSON.stringify([key,unit.get("id",-1),owned,item.get("definition","")])
 if identity!=_cut_identity:
  cancel_motion()
  _cut_key=key;_cut_identity=identity
  _cut_spec=HostileCuts.FAMILIES.get(key,{})
  _cut_frames=HostileCuts.load_frames(key) if not _cut_spec.is_empty() else []
 if sprite==null:return
 if _cut_elapsed>=0.0:_paint_cut()

func _cut_sprite() -> Sprite3D:
 return _illustration.get_node_or_null("Composite") if is_instance_valid(_illustration) else null

func play_attack(direction:Vector3) -> void:
 if not _can_move() or not direction.is_finite() or Vector2(direction.x,direction.z).length_squared()<0.000001 or _cut_frames.is_empty():
  super.play_attack(direction);return
 var sprite:Sprite3D=_cut_sprite()
 if sprite==null or sprite.material_override==null or sprite.texture.get_size()!=_cut_frames[0].get_size():
  super.play_attack(direction);return
 cancel_motion()
 var camera:=get_viewport().get_camera_3d()
 _cut_flip=_cut_idle_flip if camera==null else camera.global_basis.x.dot(Vector3(direction.x,0,direction.z))<=0.05
 _cut_elapsed=0.0;_paint_cut()

func attack_contact_delay() -> float:
 return float(_cut_spec.contact) if _cut_elapsed>=0.0 else 0.0

func _process(delta:float) -> void:
 super._process(delta)
 if _cut_elapsed<0.0:return
 if not _can_move():cancel_motion();return
 if not is_finite(delta):return
 _cut_elapsed+=maxf(0.0,delta)
 if _cut_elapsed>=float(_cut_spec.ends.back()):cancel_motion()
 else:_paint_cut()

func cancel_motion() -> void:
 super.cancel_motion()
 if _cut_elapsed<0.0:return
 _cut_elapsed=-1.0;_cut_index=-1
 _set_cut(_preview,_cut_idle_flip)

func _paint_cut() -> void:
 var ends:Array=_cut_spec.ends
 for i in ends.size():
  if _cut_elapsed+0.0000001>=float(ends[i]):continue
  _cut_index=i
  # The terminal cut was certified exactly equal to the original body paint.
  _set_cut(_preview if i==ends.size()-1 else _cut_frames[i],_cut_idle_flip if i==ends.size()-1 else _cut_flip)
  return

func _set_cut(texture:Texture2D,flipped:bool) -> void:
 var sprite:Sprite3D=_cut_sprite()
 if sprite==null or texture==null:return
 if sprite.texture==texture and sprite.flip_h==flipped:return
 if sprite.flip_h!=flipped:sprite.offset.x=-sprite.offset.x
 sprite.texture=texture;sprite.flip_h=flipped
 sprite.material_override.set_shader_parameter("source_texture",texture)
 if sprite.has_meta("pick_alpha"):sprite.remove_meta("pick_alpha")

func _attack_diagnostics() -> Dictionary:
 return {"hostile_attack_style":_cut_key,"hostile_attack_frame":_cut_index,"hostile_attack_elapsed":_cut_elapsed}
