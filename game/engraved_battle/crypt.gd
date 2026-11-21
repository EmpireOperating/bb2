extends "res://burial_ruins/terrain.gd"
const Finish = preload("res://engraved_battle/finish.gd")
const Stone = preload("res://engraved_battle/stone/chamber.gdshader")
const Ledgers = preload("res://engraved_battle/stone/ledger-stones.png")
const Limestone = preload("res://engraved_battle/stone/cut-limestone.png")

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
