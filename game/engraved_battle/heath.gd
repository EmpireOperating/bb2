extends "res://grassland_visuals/terrain.gd"
# Low stepping-stones sit in actual walkable shallows, never in the hard channel.
# They join the existing fogged scenery; no debug markers or new blocking flags.
func _authored_landscape(keys:Array) -> void:
 super._authored_landscape(keys)
 if not _presentation.has("reach"):return
 var stones:=Organic.new()
 for k:String in keys:
  if _tiles[k].terrain!="shallow_water":continue
  var center:Vector3=world_anchors[k]
  for i in 5:
   var phase:=_sample(_cell(k),791+i)
   var point:=center+Vector3((i-2)*.30,.045,(phase-.5)*.47)
   stones.boulder(point,Vector3(.31,.11,.26),phase*TAU,Color("e1d1a7"))
 _mesh(_generated,"WadingStones",stones,_scenic_material("rock",.52))

const Finish = preload("res://engraved_battle/finish.gd")
const OutdoorCut = preload("res://engraved_battle/outdoor_cut.gdshader")
enum { SLATE, BARK, LEAF }

func _mesh(parent:Node3D,label:String,builder,material:Material) -> MeshInstance3D:
 return super._mesh(parent,label,builder,_coat_outdoor(label,material))

func _coat_outdoor(label:String,material:Material) -> Material:
 if not material is ShaderMaterial or material.shader != Finish.PROP:
  return Finish.coat(material)
 var family := SLATE
 var moss := 0.0
 var foot := 0.0
 match label:
  "RockMass":
   moss = .82
   foot = .48
  "LayeredOutcrops": moss = .92
  "Foundation", "BrokenCorners":
   moss = .50
   foot = .36
  "ArchMasonry": moss = .42
  "ExposedFaces", "BankAndRuinGravel", "WadingStones", "FloorPavers": pass
  "TrunkBranches":
   family = BARK
   foot = .55
  "LeafCards": family = LEAF
  _: return Finish.coat(material)
 # Retain the same resource so stock fog and the occluder's opacity writes
 # still address it. Contact height is only for props rooted at local y=0.
 var mat := material as ShaderMaterial
 var uniforms := {}
 for uniform in mat.shader.get_shader_uniform_list():
  var value = mat.get_shader_parameter(uniform.name)
  if value != null: uniforms[uniform.name] = value
 mat.shader = OutdoorCut
 for key in uniforms: mat.set_shader_parameter(key,uniforms[key])
 mat.set_shader_parameter("outdoor_family",family)
 mat.set_shader_parameter("shelf_moss",moss)
 mat.set_shader_parameter("contact_height",foot)
 return mat
