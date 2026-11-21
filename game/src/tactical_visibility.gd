extends RefCounted
## BB2 daytime approximation, NOT native BB LOS: fixed hex radius, terrain-only
## intermediate ray, hard flagged obstacles and a ground ridge above the eye ray
## occlude. Eye endpoints = ground height + 1; blocking endpoint remains visible.
## Bodies never occlude, high ground adds no invented radius, no helmet/night rules.
static func observer_cells(battle, observer: Dictionary, radius: int) -> Dictionary:
	var cells = {}
	if not battle.living(observer): return cells
	var origin: Vector2i = battle.pos(observer)
	var eye = float(battle.tiles.get(battle.key(origin),{}).get("height",0))+1.0
	for r in range(maxi(0,origin.y-radius),mini(battle.height(),origin.y+radius+1)):
		for q in range(maxi(0,origin.x-radius),mini(battle.width(),origin.x+radius+1)):
			var cell = Vector2i(q,r)
			var k: String = battle.key(cell)
			if not battle.tiles.has(k): continue
			var length: int = battle.distance(origin,cell)
			if length > radius: continue
			var target_eye = float(battle.tiles[k].get("height",0))+1.0
			var clear = true
			for i in range(1,length):
				var t = float(i)/length
				var tile: Dictionary = battle.tiles.get(battle.key(battle.line_hex(origin,cell,t)),{})
				if tile.is_empty() or tile.get("vision_blocking",not battle.terrain_rules_enabled and tile.get("terrain","") in ["forest","wall"]) or float(tile.get("height",0)) >= lerpf(eye,target_eye,t):
					clear=false; break
			if clear: cells[k] = true
	return cells
