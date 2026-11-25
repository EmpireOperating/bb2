extends RefCounted
## Fort prop geometry only: no scene, HP, gameplay, RNG or fog state.
const Builder = preload("res://prototype/terrain_assets/mesh_builder.gd")
const Hex = preload("res://prototype/hex_layout.gd")
const TIMBER := "timber_stockade"
const RIDGE := "ridge_outpost"
const SLATE := Color("909a94")
const HEARTWOOD := Color("c88949")
const CAMERA_SIDE := Vector3(.5,0,.8660254)
const ACROSS := Vector3(.8660254,0,-.5)

static func build(cell: Vector2i, tiles: Dictionary, timber: bool, post: bool, weak: bool) -> RefCounted:
	var mesh := Builder.new()
	var odd := cell.y & 1
	var floor_height: int = tiles["%d,%d" % [cell.x,cell.y]].height
	var arms: Array[Vector3] = []
	var edge: Array[float] = []
	for step: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i(odd-1,-1),Vector2i(odd,-1),Vector2i(odd-1,1),Vector2i(odd,1)]:
		var next := cell + step
		var tile: Dictionary = tiles.get("%d,%d" % [next.x,next.y],{})
		if not tile.get("blocked",false) or tile.get("obstacle","") != "wall": continue
		arms.append((Hex.world(next)-Hex.world(cell)).normalized())
		# Stop against the rise instead of pretending the two levels are a ramp.
		edge.append(.859 if tile.height == floor_height else .79)
	if timber: _stockade(mesh,cell,arms,edge,post,weak)
	else: _outpost(mesh,cell,arms,edge,post,weak)
	return mesh

static func _variation(cell: Vector2i, salt: int) -> float:
	return float(posmod(cell.x*13+cell.y*7+salt*11,19))/18.0

static func _stockade(mesh, cell: Vector2i, arms: Array[Vector3], edge: Array[float], post: bool, weak: bool) -> void:
	if arms.is_empty():
		# An isolated wall is still timber, but doesn't invent a connection.
		arms = [Vector3.LEFT,Vector3.RIGHT]
		edge = [.62,.62]
	var height := .91 if weak else 1.22
	var hub := height + (.22 if post and not weak else .04)
	_stake(mesh,Vector3.ZERO,hub,.221 if post else .181,_variation(cell,0),true)
	for i in arms.size():
		var d := arms[i]
		var face := Vector3(-d.z,0,d.x)
		var facing := face.dot(CAMERA_SIDE)
		if facing < -.001 or (absf(facing) <= .001 and face.x < 0): face = -face
		var yaw := -atan2(d.z,d.x)
		for j in 3:
			var grain := _variation(cell,4*i+j+1)
			# Inset the last stake by radius + lean; only the rails meet the edge.
			var spread := .069 if j%2 == 0 else -.045
			var at := d*(edge[i]-.19)*(.38+.31*j)+face*(spread+(grain-.5)*.044)
			_stake(mesh,at,height+(.29 if not weak else .13)*(grain-.55),.105+.021*grain,grain,false)
		# Rails reach only the common wall edge; never span the entrance.
		for y: float in [.37,.72]:
			mesh.stone(d*(edge[i]*.5)+face*.163+Vector3.UP*y,Vector3(edge[i],.134,.18),yaw,Color("765032"))
		if post and not weak:
			mesh.branch(d*.54+face*.25+Vector3.UP*.015,d*.14+face*.14+Vector3.UP*.83,.066,.054,Color("825f3b"))

static func _stake(mesh, at: Vector3, height: float, radius: float, grain: float, lashed: bool) -> void:
	var sides := PackedVector3Array()
	var tips := PackedVector3Array()
	var lean := Vector3(grain-.51,0,.35-grain)*.075
	for i in 6:
		var a := TAU*float(i)/6.0+grain*.58
		var ray := Vector3(cos(a),0,sin(a))*radius*(.93+.10*sin(a*3.0+grain))
		sides.append(at+ray-Vector3.UP*.012)
		tips.append(at+lean+ray*.86+Vector3.UP*(height-.18+ray.z*.20))
	var point := at+lean+Vector3.UP*height+Vector3(-.031,0,.022)
	var stain := HEARTWOOD.darkened(.31+grain*.21)
	for i in 6:
		var j: int = (i+1)%6
		var facet := stain.lightened(.035*float(i%3))
		mesh.quad(sides[i],tips[i],tips[j],sides[j],facet)
		mesh.triangle(tips[i],point,tips[j],HEARTWOOD.lightened(.07*float(i%3)))
		if not lashed: continue
		# Two dark wraps hug the hub above the rails, with some edge thickness.
		for y: float in [.394,.717]:
			var low := y/(height-.168)
			var high := (y+.045)/(height-.168)
			mesh.quad(sides[i].lerp(tips[i],low)+(sides[i]-at)*.06,
				sides[i].lerp(tips[i],high)+(sides[i]-at)*.06,
				sides[j].lerp(tips[j],high)+(sides[j]-at)*.06,
				sides[j].lerp(tips[j],low)+(sides[j]-at)*.06,Color("30251c"))

static func _outpost(mesh, cell: Vector2i, arms: Array[Vector3], edge: Array[float], post: bool, weak: bool) -> void:
	# Squat, broken ashlar on a broad foot. The true terrain supplies all rise.
	var yaw := PI/6.0 + (_variation(cell,0)-.5)*.24
	var face := Vector3(cos(yaw),0,-sin(yaw))
	var fore := Vector3(sin(yaw),0,cos(yaw))
	var footing := Color("737a70")
	mesh.stone(Vector3.UP*.13,Vector3(1.31,.27,1.02),yaw,footing)
	mesh.stone(Vector3.UP*.34-fore*.05,Vector3(1.10,.20,.81),yaw,SLATE.darkened(.15))
	var rows := 4 if post and not weak else 1 if weak else 2
	for row in rows:
		var y := .546 + row*.218
		var width := 1.03 - row*.057
		var split := (.40 if row%2 == 0 else .59) * width
		var depth := .74 - row*.045
		var back := -fore*(.068+row*.015)
		mesh.stone(back+Vector3.UP*y+face*((split-width)*.5),Vector3(split-.023,.212,depth),yaw,SLATE.darkened(_variation(cell,row+1)*.12))
		if row == rows-1 and not post:
			# The fallen shoulder exposes the broken course, not a new floor.
			mesh.stone(back+Vector3.UP*(y-.043)+face*(split*.5+.057),Vector3(width-split-.155,.127,depth*.92),yaw-.09,SLATE.darkened(.06))
		else:
			mesh.stone(back+Vector3.UP*y+face*(split*.5),Vector3(width-split-.023,.212,depth),yaw,SLATE.lightened(.085))
	var cap := .550+(rows-1)*.218+.161
	mesh.stone(Vector3.UP*cap-face*.217-fore*.045,Vector3(.43,.126,.61),yaw+.07,SLATE.lightened(.12))
	if post and not weak:
		mesh.stone(Vector3.UP*(cap-.024)+face*.27-fore*.20,Vector3(.32,.084,.37),yaw-.13,SLATE.lightened(.11))
	for i in arms.size():
		var d := arms[i]
		var bearing := -atan2(d.z,d.x)
		var span := edge[i]-.43
		mesh.stone(d*(edge[i]-span*.5)+Vector3.UP*.12,Vector3(span,.247,.48),bearing,footing)
		var outer := edge[i]-.09-(_variation(cell,10+i)*.12)
		mesh.stone(d*((outer+.40)*.5)+Vector3.UP*.304,Vector3(outer-.40,.14,.39),bearing,SLATE.darkened(.09))

static func debris(cell: Vector2i, timber: bool) -> RefCounted:
	var mesh := Builder.new()
	var grain := _variation(cell,15)
	# Keep the middle of the gap clear: material settles onto the two shoulders.
	for side: float in [-1.0,1.0]:
		var shoulder := CAMERA_SIDE*(.47*side)
		if timber:
			_snapped_stake(mesh,shoulder+ACROSS*.10,.19+.04*grain,side)
			_snapped_stake(mesh,shoulder-ACROSS*.14,.12+.04*grain,-side)
			mesh.stone(shoulder-ACROSS*.28+Vector3.UP*.069,Vector3(.32,.11,.11),side*.49,HEARTWOOD.darkened(.26))
		else:
			var yaw := PI/6.0+side*.31+grain*.29
			mesh.stone(shoulder+ACROSS*.10+Vector3.UP*.123,Vector3(.38,.218,.28),yaw,SLATE)
			mesh.stone(shoulder-ACROSS*.247+Vector3.UP*.077,Vector3(.26,.142,.23),yaw-.45,SLATE.lightened(.12))
			mesh.stone(shoulder*.76+ACROSS*.32+Vector3.UP*.050,Vector3(.14,.09,.13),yaw+.71,SLATE.darkened(.18))
	return mesh

static func _snapped_stake(mesh, at: Vector3, height: float, side: float) -> void:
	# Flat split faces and irregular splinters, not a circular tree cut.
	var corners := [Vector3(-.075,.014,-.071),Vector3(.071,.014,-.066),
		Vector3(.069,.014,.076),Vector3(-.079,.014,.062)]
	var top := PackedVector3Array()
	for i in 4:
		top.append(at+corners[i]+Vector3(side*.027,height-[.038,.089,.014,.060][i],side*.014))
	var torn := at+Vector3(-side*.023,height-.052,0)
	for i in 4:
		var j := (i+1)%4
		mesh.quad(top[i],at+corners[i],at+corners[j],top[j],HEARTWOOD.darkened(.20+.047*i))
		mesh.triangle(torn,top[i],top[j],HEARTWOOD.lightened(.15+.055*i))
