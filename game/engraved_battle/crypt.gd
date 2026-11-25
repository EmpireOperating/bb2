extends "res://burial_ruins/terrain.gd"
const Finish = preload("res://engraved_battle/finish.gd")
const Stone = preload("res://engraved_battle/stone/chamber.gdshader")
const Ledgers = preload("res://engraved_battle/stone/ledger-stones.png")
const Limestone = preload("res://engraved_battle/stone/cut-limestone.png")
const WorkArt = preload("res://engraved_battle/terrain_work_art.gd")

func _init() -> void:
 _draw_terrain_work=true

func _work_remnant(key:String,_kind:String) -> Node3D:
 var remnant:=_obstacle_root(key,"WorkCryptRubble")
 var mesh:=_mesh(remnant,"FallenMasonry",WorkArt.rubble(_cell(key)),_scenic_material("rock",.55))
 mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 return remnant

func _mesh(parent:Node3D,label:String,builder,material:Material) -> MeshInstance3D:
 if label not in ["CryptPaving", "CryptCutawaySlab", "AshlarPillarCourses"]:
  return super._mesh(parent,label,builder,Finish.coat(material))
 # Replace the paint here, before the native fog and occluder owners bind the
 # actual mesh material. No additional pass, geometry, lights or fog surface.
 var wall := label != "CryptPaving"
 var stone := ShaderMaterial.new()
 stone.shader=Stone
 stone.set_shader_parameter("paint",Limestone if wall else Ledgers)
 stone.set_shader_parameter("scale",.65 if wall else .16)
 stone.set_shader_parameter("masonry",wall)
 return super._mesh(parent,label,builder,stone)
