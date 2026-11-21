extends RefCounted
const Text = preload("res://src/traffic_view.gd")

static func detail(app, id: String) -> void:
	var c = app.campaign; var ow = c.overworld
	app.label_at("ROAMING PARTY",Vector2(1030,214),12,app.GOLD)
	app.label_at(c.enemy_label(ow.scouts[c.bandits.bands[id].get("lineage",id)].site,c.bandits.bands[id].threat,"scout") if c.bandits.enabled and ow.scouts.has(id) else "Bandits",Vector2(1030,254),28,app.PAPER,true)
	if not c.bandits.enabled or not ow.scouts.has(id): return
	var s: Dictionary = ow.scouts[id]
	if s.defeated:
		Text.paragraph(app,"This party is gone. Its home camp may still have defenders.",315)
		return
	if s.position.distance_to(ow.position) > ow.sight():
		Text.paragraph(app,"The band has left your sight. Its current activity and position are unknown. Pursuit stops when contact is lost.",315)
		return
	var b: Dictionary = c.bandits.bands[id]
	app.label_at(c.bandits.caption(id),Vector2(1030,310),18,app.RED)
	var descriptions = {
		"scouting":"Scouting the roads and wilderness for opportunities.",
		"hunting":"Closing on your company. They think they can take you.",
		"raiding":"Heading for a caravan or breaking its defences.",
		"hauling":"Carrying stolen freight back to camp.",
		"fleeing":"Breaking away from a stronger force. Catch them before they disappear.",
		"fighting_patrol":"Engaged with town guards. Intervening commits your company while the guards withdraw to recover.",
		"returning":"Heading back to their camp after a sortie, pursuit or setback.",
		"recovering":"Resting at camp. Wounded survivors recover; dead members are not replaced."
	}
	if c.camp_life.enabled: descriptions.recovering = "Survivors recover at their camp when supplies pay for care. Trained recruits can join them; fallen bandits stay dead."
	if c.raiders.enabled and c.raiders.displaced(c,id):
		descriptions.recovering = "Sheltering in woodland and gathering what food they can. Their old camp is gone; wounds and losses remain."
		descriptions.returning = "Regrouping after a setback. Their old camp can no longer supply them."
	descriptions["foraging"] = "Gathering food in the woods. It takes time; they remain vulnerable while working."
	descriptions["founding"] = "Travelling with provisions to establish a camp. Intercept them before they settle."
	descriptions["building"] = "Setting up camp here. Construction takes time, and the builders can be attacked."
	Text.paragraph(app,descriptions.get(b.mode,"Moving through the region."),355)
	Text.paragraph(app,c.raiders.description(c,id) if c.raiders.enabled else "Following keeps your course on this party while it remains visible. Terrain affects both your speed and theirs.",450)
	app.button("scout_"+id,"PURSUE BAND",Rect2(1030,565,364,45),not c.over(),true)
	app.button("world_stop","STOP & PAUSE",Rect2(1030,621,364,40))
	app._draw_job_reminder(1030,720)
