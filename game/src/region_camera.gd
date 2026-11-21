extends RefCounted
## Presentation-only camera. Campaign positions and saved routes stay in world coordinates.
const RECT = Rect2(0,64,1440,788)
const ZOOMS = [0.5,0.75,1.0,1.25,1.5,2.0,2.5,3.0]
var center = Vector2.ZERO
var zoom = 1.0
var follow = true
var dragging = false
var region_seed = -1
var viewport: SubViewport
var canvas
func setup(app) -> void:
	viewport = SubViewport.new(); viewport.size = Vector2i(1440,788); viewport.world_2d = World2D.new(); viewport.disable_3d = true
	viewport.gui_disable_input = true; viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	app.add_child(viewport)
	canvas = preload("res://src/region_canvas.gd").new(); canvas.host = app; canvas.camera = self; viewport.add_child(canvas)
func reset(c) -> void:
	region_seed = c.region.seed; center = c.overworld.position; zoom = 1.0; follow = true; dragging = false; canvas.buttons.clear()
func world_to_screen(p: Vector2) -> Vector2:
	return RECT.get_center()+(p-center)*zoom
func screen_to_world(p: Vector2) -> Vector2:
	return center+(p-RECT.get_center())/zoom
func bound(c) -> void:
	# Let the company remain centred near region edges; unseen space stays fogged.
	var low: Vector2 = c.overworld.ORIGIN
	var high: Vector2 = c.overworld.ORIGIN+Vector2(c.overworld.SIZE)*c.overworld.CELL
	center = Vector2(clampf(center.x,low.x,high.x),clampf(center.y,low.y,high.y))
func zoom_at(c, amount: int, screen: Vector2) -> void:
	var anchor = screen_to_world(screen); var i = ZOOMS.find(zoom)
	zoom = ZOOMS[clampi(i+amount,0,ZOOMS.size()-1)]
	center = anchor-(screen-RECT.get_center())/zoom; follow = false; bound(c)
func input(app, event: InputEvent) -> bool:
	if not app.world_controls_available() or app.campaign.region.get("generator") != 3: dragging = false; return false
	if event is InputEventMouseButton:
		# UI panels own their pixels, including scroll and middle-drag input.
		if app.iron.blocks_map(app,event.position): return false
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed and RECT.has_point(event.position); follow = false; return true
		if event.pressed and RECT.has_point(event.position) and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_at(app.campaign,1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1,event.position); app.refresh(); return true
	if event is InputEventMouseMotion and dragging:
		center -= event.relative/zoom; bound(app.campaign); app.refresh(); return true
	if event is InputEventKey and event.pressed:
		var delta = {KEY_LEFT:Vector2.LEFT,KEY_A:Vector2.LEFT,KEY_RIGHT:Vector2.RIGHT,KEY_D:Vector2.RIGHT,KEY_UP:Vector2.UP,KEY_W:Vector2.UP,KEY_DOWN:Vector2.DOWN,KEY_S:Vector2.DOWN}.get(event.keycode,Vector2.ZERO)
		if delta != Vector2.ZERO:
			follow = false; center += delta*100/zoom; bound(app.campaign); app.refresh(); return true
		if event.keycode == KEY_HOME: follow = true; app.refresh(); return true
	return false
func action(app, id: String) -> bool:
	if not id.begins_with("camera_"): return false
	match id:
		"camera_in": zoom_at(app.campaign,1,RECT.get_center())
		"camera_out": zoom_at(app.campaign,-1,RECT.get_center())
		"camera_home": follow = true
		"camera_left": center.x -= 200/zoom; follow = false
		"camera_right": center.x += 200/zoom; follow = false
		"camera_up": center.y -= 200/zoom; follow = false
		"camera_down": center.y += 200/zoom; follow = false
	bound(app.campaign); app.refresh(); return true
func draw(app) -> void:
	var c = app.campaign
	if region_seed != c.region.seed: reset(c)
	if follow: center = c.overworld.position
	bound(c); viewport.render_target_update_mode = SubViewport.UPDATE_ONCE; canvas.queue_redraw()
	app.draw_texture_rect(viewport.get_texture(),RECT,false)
	for id in canvas.buttons:
		var row: Dictionary = canvas.buttons[id]; var r: Rect2 = row.rect
		var transformed = Rect2(world_to_screen(r.position),r.size*zoom).intersection(RECT)
		if transformed.has_area(): app.buttons[id] = {"rect":transformed,"enabled":row.enabled,"map_target":true,"map_kind":row.get("map_kind","")}

func marker_at(app, p: Vector2) -> String:
	# Use only rendered, clipped targets. A later panel button with the same ID
	# replaces map provenance, so INSPECT CONTROLLING CAMP stays a real control.
	if not app.world_controls_available() or not RECT.has_point(p) or app.iron.blocks_map(app,p): return ""
	var hits = app.buttons.keys().filter(func(id): return app.buttons[id].rect.has_point(p))
	if hits.any(func(id): return not app.buttons[id].get("map_target",false)): return ""
	hits.reverse()
	var moving = hits.filter(func(id): return id.begins_with("scout_") or id.begins_with("convoy_") or id.begins_with("trace_") or id.begins_with("guard_open_") or id.begins_with("footprint_"))
	if not moving.is_empty():
		moving.sort_custom(func(a,b):
			var da: float = app.buttons[a].rect.get_center().distance_squared_to(p); var db: float = app.buttons[b].rect.get_center().distance_squared_to(p)
			if not is_equal_approx(da,db): return da < db
			return (0 if a.begins_with("scout_") else 1 if a.begins_with("convoy_") else 2) < (0 if b.begins_with("scout_") else 1 if b.begins_with("convoy_") else 2))
		return moving[0]
	# The small camp glyph owns its pixels over a broad farm painting; exposed
	# farm pixels and all other overlap ordering retain the rendered fallback.
	if hits.any(func(id): return id == "farm_open" or id.begins_with("farm_open_")):
		for id in hits:
			if app.buttons[id].get("map_kind","") == "camp": return id
	return "" if hits.is_empty() else hits[0]
