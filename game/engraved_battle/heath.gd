extends "res://grassland_visuals/terrain.gd"

const FortArt = preload("res://engraved_battle/procedural_fort_art.gd")
const WorkArt = preload("res://engraved_battle/terrain_work_art.gd")
var _work_known_walls := {}
var _work_wall_objects := {}
var _work_pending_joins := {}

func _init() -> void:
 _draw_terrain_work=true

func build(battle) -> void:
 _work_known_walls.clear();_work_wall_objects.clear();_work_pending_joins.clear()
 super.build(battle)
 for object:Dictionary in occluders:
  if object.kind=="wall":_work_wall_objects[object.tile]=object

func _work_remnant(key:String,kind:String) -> Node3D:
 var tree:=kind=="wood"
 var timber:=kind=="plank"
 var fort:bool=_presentation.get("landmark") in [FortArt.TIMBER,FortArt.RIDGE]
 var remnant:=_obstacle_root(key,"WorkStump" if tree else "WorkTimberDebris" if timber else "WorkRubble")
 var cell:=_cell(key)
 var art=WorkArt.stump(cell) if tree else FortArt.debris(cell,timber) if fort else WorkArt.rubble(cell)
 var body:=_mesh(remnant,"CutTimber" if tree else "SnappedTimber" if timber else "FallenMasonry",art,_scenic_material("earth" if tree or timber else "rock",.37))
 body.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 return remnant

func _terrain_work_retired(battle,row:Dictionary) -> void:
 if row.object.kind!="wall":return
 var key:String=row.object.tile
 if _work_known_walls.is_empty():_work_known_walls=_descriptor.tiles.duplicate()
 _work_known_walls.erase(key)
 _work_wall_objects.erase(key)
 _work_pending_joins.erase(key)
 for cell:Vector2i in battle.neighbors(row.cell):
  var neighbor:String=battle.key(cell)
  if _work_wall_objects.has(neighbor):_work_pending_joins[neighbor]=true

func refresh_terrain_work(battle) -> void:
 super.refresh_terrain_work(battle)
 var landmark:String=_presentation.get("landmark","")
 for key:String in _work_pending_joins.keys():
  var cell:=_cell(key)
  if not battle.tile_visible(0,cell):continue
  var neighbor:Dictionary=_work_wall_objects[key]
  var body:MeshInstance3D
  if landmark in [FortArt.TIMBER,FortArt.RIDGE]:
   body=neighbor.meshes[0]
   body.mesh=FortArt.build(cell,_work_known_walls,landmark==FortArt.TIMBER,key in _presentation.keep,key==_presentation.work_cell).finish()
  elif landmark=="forest_broken_gate":
   body=neighbor.meshes[1]
   body.mesh=_broken_gate_masonry(key,_work_known_walls).finish()
  _work_pending_joins.erase(key)
  if body==null:continue
  neighbor.bounds=body.transform*body.mesh.get_aabb()
  for mesh:MeshInstance3D in neighbor.meshes:
   neighbor.bounds=neighbor.bounds.merge(mesh.transform*mesh.mesh.get_aabb())
  var shadow:=body.get_node_or_null("FogKnownShadow") as MeshInstance3D
  if shadow!=null:shadow.mesh=body.mesh

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

# Each authored wall borrows the stock material, fog and occluder pipeline.
func _authored_ruin(key: String) -> void:
 var landmark: String = _presentation.get("landmark","")
 if landmark in [FortArt.TIMBER,FortArt.RIDGE]:
  var timber := landmark == FortArt.TIMBER
  var post: bool = key in _presentation.get("keep",[])
  var weak: bool = key == _presentation.get("work_cell","")
  var root := _obstacle_root(key,"TimberStockade" if timber else "RidgeOutpost")
  var art := FortArt.build(_cell(key),_tiles,timber,post,weak)
  var body := _mesh(root,"StockadeTimber" if timber else "RidgeMasonry",art,_scenic_material("earth" if timber else "rock",.37))
  _register_occluder("wall",key,root,[body])
  return
 if landmark!="forest_broken_gate":
  super._authored_ruin(key)
  return
 var ruin := _obstacle_root(key,"RuinedCurtain")
 var foundation := Builder.new()
 foundation.stone(Vector3.UP*.10,Vector3(1.35,.2,1.03),PI/6.0,Color("8a8b75"))
 var base := _mesh(ruin,"Foundation",foundation,_scenic_material("rock",.55))
 var masonry := _mesh(ruin,"BrokenCorners",_broken_gate_masonry(key,_tiles),_scenic_material("rock",.50))
 _register_occluder("wall",key,ruin,[base,masonry])

func _broken_gate_masonry(key:String,joins:Dictionary) -> RefCounted:
 var origin := _cell(key)
 var stones := Builder.new()
 var yaw := PI/6.0
 var face := Vector3(cos(yaw),0,-sin(yaw))
 var pier: bool = key in _presentation.keep
 var limestone := Color("bcb29b")

 var courses := 7 if pier else 2+int(_sample(origin,471)*3.0)
 for row in courses:
  var level := .33+float(row)*.236
  var width := 1.12-float(row)*.023 if pier else .78
  var depth := 1.02-float(row)*.019 if pier else .65
  var tone := limestone.darkened(_sample(origin,row+41)*.14)
  if row%2==0:
   stones.stone(Vector3.UP*level,Vector3(width,.232,depth),yaw,tone)
  else:
   for side: float in [-1.0,1.0]:
    stones.stone(Vector3.UP*level+face*side*width*.25,Vector3(width*.485,.23,depth),yaw,tone.lightened(.04*side))
 if pier:
  var north: bool = key==_presentation.keep[0]
  stones.stone(Vector3.UP*1.96,Vector3(1.13,.19,1.0),yaw,limestone.lightened(.10))
  stones.stone(Vector3.UP*2.17+face*(.15 if north else -.22),Vector3(.67 if north else .46,.28,.70),yaw,limestone)
  if north:stones.stone(Vector3.UP*2.35+face*.25,Vector3(.37,.15,.48),yaw,limestone.darkened(.08))
 # A pair of inset half-arms meets at each actual neighboring wall edge.
 # Gate and walkable yard never get a lintel or false collision geometry.
 var odd := origin.y&1
 for step: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i(odd-1,-1),Vector2i(odd,-1),Vector2i(odd-1,1),Vector2i(odd,1)]:
  var next := origin+step
  if joins.get("%d,%d"%[next.x,next.y],{}).get("obstacle")!="wall":continue
  var direction := (Layout.world(next)-Layout.world(origin)).normalized()
  var bearing := -atan2(direction.z,direction.x)
  for row in (3 if pier else mini(courses,3)):
   stones.stone(direction*.57+Vector3.UP*(.33+row*.236),Vector3(.58,.23,.59-row*.045),bearing,limestone.darkened(.10+row*.024))
 # At stock camera azimuth the front pier overlaps the low return behind it.
 # Only the designated segment has an exposed, battered flank to read work on.
 if _work.get(key,{}).get("kind")=="stone":WorkArt.wall_flank(stones,courses,yaw,limestone)
 return stones

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
  "FallenMasonry": moss = .16
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
