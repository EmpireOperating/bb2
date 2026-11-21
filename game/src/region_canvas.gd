extends Node2D
const PAPER = Color("ded8bd")
const GOLD = Color("d7b66b")
const MUTED = Color("9a9c90")
const INK = Color("101716")
const BLUE = Color("78b7b2")
const RED = Color("c97860")
var host
var camera
var buttons: Dictionary = {}
var map_labels: Array = []
var label_rects: Array = []
var drawn_labels: Array = []
var campaign:
	get: return host.campaign
var world_selected:
	get: return host.world_selected
var font:
	get: return host.font
var serif:
	get: return host.serif
func label_at(text: String, at: Vector2, size: int, tint: Color, fancy: bool = false) -> void:
	centered(text,at+Vector2((serif if fancy else font).get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2,0),size,tint,fancy)
func centered(text: String, at: Vector2, size: int, tint: Color, fancy: bool = false) -> void:
	if text.length() <= 2:
		var f = serif if fancy else font
		draw_string(f,at-Vector2(f.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,tint)
		return
	# Secondary marker statuses live in the selected context, not under every name.
	if size <= 9: return
	map_labels.append({"text":text,"at":at,"size":maxi(12,size),"tint":tint,"fancy":fancy})
func draw_labels() -> void:
	draw_set_transform(Vector2.ZERO)
	label_rects.clear(); drawn_labels.clear()
	var landmark_names = campaign.news.navigation.visible(campaign).map(func(m):return m.name)
	map_labels.sort_custom(func(a,b):return (0 if a.text in landmark_names else 1 if a.size>=13 else 2) < (0 if b.text in landmark_names else 1 if b.size>=13 else 2))
	var icon_rects: Array = []
	for row in buttons.values():
		icon_rects.append(Rect2(camera.world_to_screen(row.rect.position)-camera.RECT.position,row.rect.size*camera.zoom).grow(3))
	for row in map_labels:
		var anchor: Vector2 = camera.world_to_screen(row.at)-camera.RECT.position
		var f = serif if row.fancy else font
		var width = f.get_string_size(row.text,HORIZONTAL_ALIGNMENT_LEFT,-1,row.size).x+12
		var rect = Rect2()
		var offsets = [Vector2.ZERO]
		for i in range(1,8):
			for dx in [0,-100,100]:
				offsets.append(Vector2(dx,i*23)); offsets.append(Vector2(dx,-i*23))
		for offset in offsets:
			var candidate = Rect2(anchor+offset-Vector2(width/2,15),Vector2(width,22))
			if not Rect2(Vector2(8,8),camera.RECT.size-Vector2(16,16)).encloses(candidate): continue
			if label_rects.any(func(r):return r.grow(3).intersects(candidate)) or icon_rects.any(func(r):return r.intersects(candidate)): continue
			rect = candidate; break
		if not rect.has_area(): continue
		label_rects.append(rect); drawn_labels.append(row.text)
		if rect.get_center().distance_to(anchor)>28: draw_line(anchor,rect.get_center(),Color(0.55,0.53,0.44,0.4),1,true)
		draw_rect(rect,Color(0.07,0.08,0.08,0.94))
		draw_string(f,rect.position+Vector2(6,16),row.text,HORIZONTAL_ALIGNMENT_LEFT,-1,row.size,row.tint)
func button(_id: String, _text: String, _rect: Rect2, _enabled: bool = true, _selected: bool = false) -> void:
	pass # Map helpers' report controls belong to the fixed interface.
func visible_cells() -> Rect2i:
	var half = camera.RECT.size/(camera.zoom*2)
	var start = Vector2i((camera.center-half-campaign.overworld.ORIGIN)/16)-Vector2i.ONE
	var end = Vector2i((camera.center+half-campaign.overworld.ORIGIN)/16)+Vector2i(2,2)
	return Rect2i(start,end-start).intersection(Rect2i(Vector2i.ZERO,campaign.overworld.SIZE))
func _draw() -> void:
	buttons.clear(); map_labels.clear()
	if campaign.region.get("generator") != 3: return
	draw_rect(Rect2(Vector2.ZERO,camera.RECT.size),Color("080e0b"))
	draw_set_transform(camera.RECT.size/2-camera.center*camera.zoom,0,Vector2.ONE*camera.zoom)
	preload("res://src/procedural_view.gd").draw_map(self)
	preload("res://src/footprint_view.gd").draw_map(self)
	preload("res://src/traffic_view.gd").draw_map(self)
	preload("res://src/farm_view.gd").draw_map(self)
	preload("res://src/guard_view.gd").draw_map(self)
	draw_parties()
	preload("res://src/dungeon_view.gd").draw_sites(self)
	preload("res://src/regional_news_view.gd").draw_landmarks(self)
	draw_labels()
func draw_parties() -> void:
	var ow = campaign.overworld
	for party in ow.friendly_parties(campaign.world,campaign.traffic):
		var p: Vector2 = party.position
		if p.distance_to(ow.position) > ow.sight(): continue
		var tint = GOLD if party.kind == "wagon" else BLUE
		if campaign.traffic.enabled and party.kind == "wagon" and campaign.traffic.wagons[party.id].carried: tint = RED
		draw_circle(p,10,INK)
		if party.kind == "wagon":
			draw_rect(Rect2(p-Vector2(7,5),Vector2(14,10)),tint,false,2)
			draw_circle(p+Vector2(-5,7),3,tint); draw_circle(p+Vector2(5,7),3,tint)
		else: draw_colored_polygon(PackedVector2Array([p+Vector2(0,-9),p+Vector2(7,0),p+Vector2(0,9),p+Vector2(-7,0)]),tint)
		centered(("RELIEF " if campaign.rebuilding.enabled and campaign.rebuilding.shipments.has(party.id) else "")+("Caravan" if party.kind == "wagon" else "Patrol"),p+Vector2(0,-15),10,tint)
		if party.kind == "wagon": buttons["convoy_"+party.id] = {"rect":Rect2(p-Vector2.ONE*11,Vector2.ONE*22),"enabled":true}
	for scout in ow.scouts.values():
		if scout.defeated or scout.position.distance_to(ow.position) > ow.sight(): continue
		var p: Vector2 = scout.position
		draw_circle(p,11,INK); draw_arc(p,11,0,TAU,24,RED,2,true)
		draw_line(p+Vector2(-4,-5),p+Vector2(4,5),RED,2,true)
		draw_line(p+Vector2(4,-5),p+Vector2(-4,5),RED,2,true)
		var scouts_name = campaign.enemy_label(scout.site,campaign.world.camps[scout.site].strength,"scout").to_upper()
		var caption = "PURSUING" if scout.mode == "pursuit" else "RAIDER SCOUTS"
		if campaign.traffic.enabled and campaign.traffic.missions.has(scout.id):
			caption = "HAULING LOOT" if campaign.traffic.wagons[campaign.traffic.missions[scout.id]].carried else "RAIDING PARTY"
		if campaign.bandits.enabled: caption = campaign.bandits.caption(scout.id)
		if not campaign.guards.engaged(scout.id): centered(caption.replace("RETURNING HOME","RETURNING").replace("HUNTING YOU","HUNTING") if campaign.bandits.enabled else scouts_name+" · "+str(campaign.enemy_count(scout.site,maxi(1,int(campaign.world.camps[scout.site].strength)-1),"scout")),p+Vector2(0,-18),10,RED)
		buttons["scout_"+scout.id] = {"rect":Rect2(p-Vector2.ONE*12,Vector2.ONE*24),"enabled":true}
	var p = ow.position
	draw_circle(p+Vector2(0,3),13,Color(0,0,0,0.5))
	draw_arc(p,14,0,TAU,36,BLUE,2,true)
	draw_line(p+Vector2(0,8),p+Vector2(0,-23),PAPER,2,true)
	draw_colored_polygon(PackedVector2Array([p+Vector2(0,-23),p+Vector2(21,-17),p+Vector2(0,-10)]),BLUE)
