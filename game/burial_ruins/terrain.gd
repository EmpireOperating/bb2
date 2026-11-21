extends "res://map_visibility/terrain.gd"
## Contained stock crypt: local painted palette, actual cells only, no new rules.
## Inherited build creates anchors and registers walls before shared fog collection.
var _exit_battle
var exit_labels: Array[Label3D] = []
func build(battle) -> void:
 _exit_battle = battle
 exit_labels.clear()
 super.build(battle)
func update_occlusion(camera: Camera3D, unit_positions: Array) -> void:
 super.update_occlusion(camera,unit_positions)
 for label in exit_labels:
  label.visible = _exit_battle.tile_explored(0,label.get_meta("exit_cell"))
func _build_fields() -> void:
 var floor_mesh := Builder.new()
 var cutaway := Builder.new()
 for key: String in _tiles:
  var cell := _cell(key)
  var center: Vector3 = world_anchors[key]
  var ring := Layout.corners(cell,float(_tiles[key].height))
  var side: int = _tiles[key].get("escape_side",-1)
  var tint := Color("70b8b1") if side == 0 else Color("c58b68") if side == 1 else Color("9ca5a6")
  for i in 6:
   floor_mesh.triangle(center,ring[i],ring[(i+1)%6],tint)
   var a: Vector3 = ring[i]
   var b: Vector3 = ring[(i+1)%6]
   var midpoint := (a+b)*.5
   var neighbor := Layout.from_world(midpoint+(midpoint-center).normalized()*.05)
   if not _tiles.has("%d,%d" % [neighbor.x,neighbor.y]):
    # Presentation-only vertical exposed slab edge; never another tactical wall.
    cutaway.quad(a,a-Vector3.UP*.28,b-Vector3.UP*.28,b,Color("606b6e"))
 var floor_node := _mesh(_generated,"CryptPaving",floor_mesh,_scenic_material("paving",.88))
 floor_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 ground_batches.append(floor_node)
 _mesh(_generated,"CryptCutawaySlab",cutaway,_scenic_material("rock",.65))
 backdrop_bounds = floor_node.mesh.get_aabb()

func _authored_ruin(key: String) -> void:
 var cell := _cell(key)
 var wall := _obstacle_root(key,"CryptMasonry")
 var stones := Builder.new()
 # Actual wall cells only. Hexagonal ashlar courses are clipped inside the
 # blocker footprint, so no standing centre or lane is narrowed by decoration.
 for row in 7:
  var course_y := .12+float(row)*.235
  var color := Color("a5aaa6").darkened(_sample(cell,row+431)*.11)
  stones.stone(Vector3(0,course_y,0),Vector3(.78,.225,.78),float(row%2)*PI*.5,color)
  for side in 6:
   var angle := float(side)*TAU/6.0
   var offset := Vector3(cos(angle)*.53,course_y,sin(angle)*.53)
   stones.stone(offset,Vector3(.36,.225,.34),-angle,color)
 var masonry := _mesh(wall,"AshlarPillarCourses",stones,_scenic_material("rock",.62))
 _register_occluder("wall",key,wall,[masonry])

func _authored_landscape(_keys: Array) -> void:
 # Side bands are real floor; labels add no collision or escape authority.
 for key: String in _tiles:
  var side: int = _tiles[key].get("escape_side",-1)
  var cell := _cell(key)
  # Company retreat cells keep their colored paving; do not repeat text above them.
  if side != 1 or cell.y not in [2,6,10]: continue
  var label := Label3D.new()
  label.name = "CompanyExit" if side == 0 else "EnemyExit"
  label.text = "COMPANY EXIT" if side == 0 else "ENEMY EXIT"
  label.font_size = 40; label.pixel_size = .022; label.outline_size = 10
  label.modulate = Color("a7eee0") if side == 0 else Color("f2b98a")
  label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
  label.position = world_anchors[key]+Vector3.UP*.45
  label.set_meta("escape_side",side); label.set_meta("exit_cell",cell)
  label.visible = _exit_battle.tile_explored(0,cell)
  _generated.add_child(label); exit_labels.append(label)
