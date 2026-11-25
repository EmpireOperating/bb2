extends Node2D
const Iron = preload("res://src/iron_ui.gd")
var iron = Iron.new()
const ReconView = preload("res://src/camp_recon_view.gd")
const FootprintView = preload("res://src/footprint_view.gd")
const RecoveryView = preload("res://src/recovery_view.gd")
const TrafficView = preload("res://src/traffic_view.gd")
const BanditView = preload("res://src/bandit_view.gd")
const VaultJournal = preload("res://src/vault_journal_view.gd")
var vault_journal = false
var vault_page = 0
var expedition_view = {"site":"","tab":"notes","floor":0,"room":0,"keys_page":0,"days":2,"scouting":4,"town":""}
var dungeon_door = -1
const DungeonView = preload("res://src/dungeon_view.gd")
const Named = preload("res://src/named_equipment.gd")
const GuardView = preload("res://src/guard_view.gd")
const FarmView = preload("res://src/farm_view.gd")
const ProceduralView = preload("res://src/procedural_view.gd")
const Perks = preload("res://src/perks.gd")
const PerkProgression = preload("res://src/perk_progression.gd")
const PerkTrials = preload("res://src/perk_trials.gd")
const RangedTrials = preload("res://src/ranged_trials.gd")
var lineup = preload("res://src/company_formation_view.gd").new()
var queue_page = 0
var ranged_lab = false
var perk_lab_mode = false
var perks_view = false
var perk_choice = ""
var perk_filter = "All"
var perk_target_mode = ""
# Read-only paint observations for the perk-tree oracle; never command authority.
var _ui_perk_cards: Dictionary = {}

## Immediate-mode prototype presentation. Campaign, World and Battle own the game rules.

const Armor = preload("res://src/armor.gd")
const Arsenal = preload("res://src/arsenal.gd")
var salvage_view = false
var salvage_mode = "sell"
var salvage_filter = "all"
var salvage_choice = ""
var salvage_page = 0
var sale_confirmation = -1
var arms_view = false
var loot_view = false
var arms_slot = "weapon"
var arms_source = "stores"
var arms_choice = ""
var arms_page = 0
var loot_page = 0
var weapon_special = false
var weapon_target = 6
var armor_view = false
var armor_group = "body"
var armor_layer = "base"
var armor_mode = "parts"
var armor_source = "stores"
var armor_choice = ""
var armor_page = 0
const People = preload("res://src/people.gd")
const PersonStats = preload("res://hollow_campaign/person_stats.gd")
var growth_selection: Array = []
var person_view = false
var person_offer = ""
var seed_text = ""
var seed_replace = true
const Battle = preload("res://src/battle.gd")
const Progression = preload("res://src/progression.gd")
const Campaign = preload("res://src/campaign.gd")
const Playability = preload("res://src/playability.gd")
var guide = Playability.new()
var guide_view = false
var planner_view = false
var record_view = false
var record_page = 0
var planning_cache: Dictionary = {}
var feedback_popups: Array = []
var observed_commands = 0
const GOLD = Color("d7b66b")
const PAPER = Color("e5dcc6")
const MUTED = Color("9a9c90")
const INK = Color("131517")
const BLUE = Color("78b7b2")
const RED = Color("c97860")
const SAVE_PATH = "user://ashen-company-save.json"
const PERK_LAB_SAVE_PATH = "user://ashen-company-perks-lab-save.json"
var region_camera = preload("res://src/region_camera.gd").new()
const NewsView = preload("res://src/regional_news_view.gd")
var news_view = false
var news_tab = "reports"
var news_page = 0
var news_destination = ""
var report_towns_page = 0
var report_camps_page = 0
var campaign = Campaign.new()
var battle = Battle.new()
var font: Font
var serif: Font
var selected = 0
var inspected = -1
var inspection_view = false
var inspection_id = 0
var inspection_tab = "stats"
var inspection_page = 0
var observed_active = -99
var hovered = Vector2i(-1, -1)
var reachable: Dictionary = {}
var buttons: Dictionary = {}
var intro = false
var help = false
var withdraw_mode = false
var notice = ""
var notice_time = 0.0
var ai_clock = 0.0
var flash_id = -1
var flash_time = 0.0
var seed_number = 7391
var autosim = false
var camp_selected = 0
var gear_slot = "body"
var stash_page = 0
var confirmation = ""
var save_failed = false
var world_view = true
var world_selected = "ashwick"
var town_tab = "contracts"
var roll_page = 0
var job_page = 0
var trade_view = false
var politics_view = false
var bonds_view = false
var bond_partner = -1
var bond_page = 0
var bond_roll_page = 0
var service_view = false
var service_page = 0
var tactics_view = false
var tactics_tab = "orders"
var formation_selection: Array = []
var formation_direction = 0
var detail_target = 6
var trade_page = 0
var trade_selected = ""

func _ready() -> void:
	region_camera.setup(self)
	font = load("res://assets/sans.ttf")
	serif = load("res://assets/serif.ttf")
	seed_number = 7391 if "--smoke" in OS.get_cmdline_user_args() else fresh_seed()
	campaign.setup(seed_number,-1 if "--smoke" in OS.get_cmdline_user_args() else seed_number,"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),false,"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args())
	battle = campaign.battle
	bind_battle()
	refresh()
	if "--perk-lab" in OS.get_cmdline_user_args() or name == "PerkSandbox":
		perk_lab_mode = true; ranged_lab = true; RangedTrials.install(campaign); battle = campaign.battle; bind_battle()
		world_view = false; camp_selected = 0; person_offer = ""; perks_view = true
		refresh()
	elif "--smoke" in OS.get_cmdline_user_args():
		campaign.accept_job(campaign.offers()[0].id)
		campaign.travel("ford")
		campaign.deploy()
		battle = campaign.battle
		autosim = true
	elif FileAccess.file_exists(PERK_LAB_SAVE_PATH if perk_lab_mode else SAVE_PATH):
		action("load")
	else:
		campaign.enable_dungeons()
		write_save(false)

func fresh_seed() -> int:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var value = rng.randi_range(1,999999999)
	return value if value != seed_number else value%999999999+1

func refresh() -> void:
	sync_active()
	reachable = battle.movement_map(selected) if selected >= 0 and campaign.phase == "battle" else {}
	queue_redraw()

func _process(delta: float) -> void:
	if world_controls_available():
		if campaign.tick_overworld(delta):
			if (campaign.overworld.at_site(campaign.location) and not (world_selected.begins_with("band:") or world_selected.begins_with("wagon:") or world_selected.begins_with("trace:") or world_selected.begins_with("farm:") or world_selected.begins_with("guard:") or world_selected.begins_with("recovery:") or world_selected.begins_with("footprints:"))) or campaign.over(): world_selected = campaign.location
			write_save(false)
	for popup in feedback_popups: popup.life -= delta
	feedback_popups = feedback_popups.filter(func(p): return p.life > 0)
	observe_guide()
	notice_time = maxf(0.0, notice_time-delta)
	flash_time = maxf(0.0, flash_time-delta)
	if not intro and not help and confirmation.is_empty() and not tactics_view and not guide_view and not record_view and not vault_journal and not arms_view and not loot_view and not inspection_view and campaign.phase == "battle" and battle.result.is_empty() and (battle.side == 1 or autosim or (battle.individual and battle.active_id >= 0 and battle.units[battle.active_id].routed)):
		if battle.individual: battle.advance_if_spent(); sync_active()
		ai_clock += delta
		if ai_clock >= (0.01 if autosim else 0.3):
			ai_clock = 0
			battle.ai_step()
			if battle.side == 0 and (selected < 0 or not battle.fighting(battle.units[selected])): choose_next()
			refresh()
	if campaign.phase == "battle" and battle.individual and battle.result.is_empty() and not intro and not help and confirmation.is_empty():
		if battle.advance_if_spent(): refresh()
		sync_active()
	if campaign.phase == "battle" and not battle.result.is_empty():
		campaign.resolve_battle()
		arms_view = false; weapon_special = false
		write_save(false)
	if autosim and campaign.phase == "aftermath":
		print("UI_SMOKE_OK result=%s rounds=%d commands=%d" % [battle.result, battle.round_no, battle.commands.size()])
		get_tree().quit(0)
	queue_redraw()

func hex_center(p: Vector2i) -> Vector2:
	if battle.roster_rules: return Vector2(65+56.94*(p.x+0.5*(p.y&1)),218+45.63*p.y)
	return Vector2(80 + 73.0 * (p.x + 0.5 * (p.y & 1)), 218 + 58.5 * p.y if battle.individual else 178 + 63.2 * p.y)

func hex_points(p: Vector2, radius: float = 41.0) -> PackedVector2Array:
	if battle.individual and radius == 41.0: radius = 38.0
	if battle.roster_rules: radius *= 0.78
	var points = PackedVector2Array()
	for i in 6: points.append(p + Vector2(cos(deg_to_rad(i*60-30)), sin(deg_to_rad(i*60-30))) * radius)
	return points

func nearest_hex(p: Vector2) -> Vector2i:
	for r in battle.height():
		for q in battle.width():
			var h = Vector2i(q, r)
			if Geometry2D.is_point_in_polygon(p, hex_points(hex_center(h))): return h
	return Vector2i(-1, -1)

func label_at(s: String, p: Vector2, size: int = 16, color: Color = PAPER, display: bool = false) -> void:
	draw_string(serif if display else font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func fitted_text(s: String, width: float, size: int, display: bool = false) -> Dictionary:
	var f = serif if display else font
	while size > 10 and f.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x > width: size -= 1
	if f.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x > width:
		while not s.is_empty() and f.get_string_size(s+"…",HORIZONTAL_ALIGNMENT_LEFT,-1,size).x > width: s = s.left(-1)
		s += "…"
	return {"text":s,"size":size}

func label_fit(s: String, p: Vector2, width: float, size: int, color: Color, display: bool = false) -> void:
	var fitted = fitted_text(s,width,size,display)
	label_at(fitted.text,p,fitted.size,color,display)

func centered(s: String, p: Vector2, size: int = 16, color: Color = PAPER, display: bool = false) -> void:
	var f = serif if display else font
	draw_string(f, p-Vector2(f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x/2, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func wrapped_lines(message: String, width: float, size: int, limit: int) -> Array:
	var lines: Array = []
	var current = ""
	for word in message.split(" "):
		var candidate = word if current.is_empty() else current+" "+word
		if not current.is_empty() and font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
			lines.append(current)
			current = word
		else: current = candidate
	if not current.is_empty(): lines.append(current)
	if lines.size() > limit:
		lines.resize(limit)
		lines[limit-1] += "…"
	return lines

func panel(rect: Rect2, color: Color = Color("1c1f22"), border: Color = Color("494640")) -> void:
	# Neutral iron surfaces; preserve deliberately coloured warning borders.
	color = Color.from_hsv(color.h, minf(color.s, 0.12), color.v, color.a)
	draw_rect(rect, color)
	draw_rect(rect, border, false, 1)

func button(id: String, title: String, rect: Rect2, enabled: bool = true, primary: bool = false) -> void:
	buttons[id] = {"rect":rect, "enabled":enabled}
	var hot = rect.has_point(get_global_mouse_position()) and enabled
	panel(rect, Color("383632") if hot else (Color("302e29") if primary else Color("202326")), GOLD if primary and enabled else Color("4c4942"))
	var fitted = fitted_text(title,rect.size.x-14,14)
	centered(fitted.text, rect.position+Vector2(rect.size.x/2, rect.size.y/2+5), fitted.size, (GOLD if primary else PAPER) if enabled else Color("667064"))

func bar(p: Vector2, width: float, value: float, maximum: float, color: Color, height: float = 5) -> void:
	draw_rect(Rect2(p, Vector2(width, height)), Color("0a100f"))
	if maximum <= 0: return
	draw_rect(Rect2(p, Vector2(width*clampf(value/maximum, 0, 1), height)), color)

func _draw() -> void:
	if font == null: return
	buttons.clear()
	if campaign.phase == "camp":
		if world_view:
			if campaign.dungeons.active != "": DungeonView.draw(self)
			else: _draw_world()
		else: _draw_camp()
		if trade_view: _draw_trade()
		if politics_view: _draw_politics()
		if service_view: _draw_service()
		if bonds_view: _draw_bonds()
		if person_view: _draw_person()
		if armor_view: _draw_armor_editor()
		if arms_view: _draw_armory()
		_draw_playability_buttons()
		if planner_view: _draw_planner()
		if vault_journal: VaultJournal.draw(self)
		if guide_view: _draw_guide()
		if salvage_view: _draw_salvage()
		if perks_view: _draw_perk_tree()
		if news_view: NewsView.draw(self)
		if help: _draw_briefing()
		if not confirmation.is_empty(): _draw_confirmation()
		if lineup.opened: lineup.draw(self)
		if iron.sheet != "": iron.draw_sheet(self)
		return
	draw_rect(Rect2(0, 0, 1440, 900), Color("111917"))
	for i in 90:
		draw_line(Vector2(0, i*10), Vector2(1440, i*10), Color(0.9, 0.85, 0.7, 0.012))
	draw_rect(Rect2(0, 0, 1440, 107), Color("0d1312"))
	draw_line(Vector2(24, 106), Vector2(1416, 106), Color("635b3a"))
	draw_line(Vector2(38, 35), Vector2(65, 75), GOLD, 3, true)
	draw_line(Vector2(65, 35), Vector2(38, 75), GOLD, 3, true)
	draw_arc(Vector2(52, 54), 31, 0, TAU, 36, Color("756c48"), 1.2, true)
	label_at("THE ASHEN COMPANY", Vector2(102, 36), 13, GOLD)
	var battle_title: String = campaign.aftermath.title if campaign.phase == "aftermath" else campaign.battle_job().title
	var title_size = 32
	while title_size > 22 and serif.get_string_size(battle_title,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size).x > 560: title_size -= 1
	if serif.get_string_size(battle_title,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size).x > 560:
		while not battle_title.is_empty() and serif.get_string_size(battle_title+"…",HORIZONTAL_ALIGNMENT_LEFT,-1,title_size).x > 560: battle_title = battle_title.left(battle_title.length()-1)
		battle_title += "…"
	label_at(battle_title, Vector2(100, 76), title_size, PAPER, true)
	label_at("THE ASHEN COMPANY", Vector2(677, 36), 11, MUTED)
	label_at("ROUND %02d" % battle.round_no, Vector2(678, 70), 23, GOLD, true)
	label_at(("ALLY ACTS" if battle.side == 0 else "ENEMY ACTS") if battle.individual else ("YOUR TURN" if battle.side == 0 else "ENEMY TURN"), Vector2(852, 68), 14, BLUE if battle.side == 0 else RED)
	button("save", "F5  Save", Rect2(1110, 30, 92, 40), battle.result.is_empty())
	button("load", "F9  Load", Rect2(1210, 30, 92, 40), FileAccess.file_exists(PERK_LAB_SAVE_PATH if perk_lab_mode else SAVE_PATH))
	button("help", "?  Orders", Rect2(1310, 30, 106, 40))
	if battle.individual: _draw_turn_queue()
	else:
		label_at(battle.objective_name(), Vector2(34, 135), 12, GOLD)
		label_at(battle.objective_text(), Vector2(213, 135), 13, MUTED)
	_draw_board()
	_draw_sidebar()
	_draw_roster()
	_draw_feedback()
	if notice_time > 0:
		panel(Rect2(365, 661, 650, 36), Color("101815"), GOLD)
		centered(notice, Vector2(690, 685), 14, GOLD)
	button("formations","4  Formation orders",Rect2(30,859,216,30),campaign.phase == "battle" and battle.side == 0)
	button("weapon_actions","6  Weapons & active perks",Rect2(268,859,255,30),campaign.phase == "battle" and battle.side == 0 and selected >= 0)
	label_at("Click move / strike · Space wait · F end activation" if battle.individual else "Click move / strike · Space next · F end turn",Vector2(540,879),11,MUTED)
	button("retreat", "Retreat to entrance" if campaign.encounter.get("kind") == "dungeon" else "Retreat from contract", Rect2(1160, 861, 256, 28), campaign.phase == "battle" and battle.side == 0)
	_draw_playability_buttons()
	if intro or help: _draw_briefing()
	elif campaign.phase == "aftermath": _draw_result()
	if inspection_view: _draw_battle_inspection()
	if arms_view: _draw_weapon_actions()
	if loot_view: _draw_loot()
	if tactics_view: _draw_tactics()
	if record_view: _draw_record()
	if guide_view: _draw_guide()
	if not confirmation.is_empty(): _draw_confirmation()

func _draw_board() -> void:
	for r in battle.height():
		for q in battle.width():
			var p = Vector2i(q, r)
			var c = hex_center(p)
			var tile: Dictionary = battle.tiles[battle.key(p)]
			var shade = ((q*7+r*11) % 5) * 0.012
			var color = Color(0.245+shade, 0.277+shade, 0.205+shade)
			match tile.terrain:
				"water": color = Color("29484a")
				"ford": color = Color("596358")
				"mud": color = Color("494637")
				"forest": color = Color("2c3e2d")
				"hill": color = Color("65624b")
				"stone": color = Color("41473f")
				"rubble": color = Color("555346")
				"wall": color = Color("202724")
			draw_colored_polygon(hex_points(c+Vector2(0, 4)), Color("0b1411"))
			draw_colored_polygon(hex_points(c), color)
			draw_polyline(hex_points(c)+PackedVector2Array([hex_points(c)[0]]), Color("222d22"), 1, true)
			if tile.terrain == "wall":
				draw_rect(Rect2(c-Vector2(26,23),Vector2(52,46)),Color("777868"))
				for y in [-15,0,15]: draw_line(c+Vector2(-25,y),c+Vector2(25,y),Color("3a4239"),2)
			elif tile.terrain == "water":
				for y in [-13, 0, 13]:
					draw_line(c+Vector2(-22, y), c+Vector2(16, y-3), Color("527376"), 1, true)
			elif tile.terrain == "hill":
				draw_polyline(PackedVector2Array([c+Vector2(-23, 7), c+Vector2(-5, -13), c+Vector2(6, 2), c+Vector2(14, -5), c+Vector2(25, 11)]), Color("9c9675"), 2, true)
			elif tile.terrain == "forest":
				for dx in [-12, 12]:
					draw_colored_polygon(PackedVector2Array([c+Vector2(dx, -23), c+Vector2(dx-14, 9), c+Vector2(dx+14, 9)]), Color("172c20"))
					draw_line(c+Vector2(dx, 5), c+Vector2(dx, 18), Color("7c7150"), 3)
			elif tile.terrain in ["grass", "mud"]:
				for i in 3:
					var g = c+Vector2((q*11+r*7+i*17)%45-22, (q*3+r*13+i*23)%38-19)
					draw_line(g, g+Vector2(3, -5), Color(0.65, 0.66, 0.61, 0.20), 1, true)
			if battle.objective != "eliminate" and battle.distance(p, battle.goal()) <= 1:
				draw_polyline(hex_points(c, 37)+PackedVector2Array([hex_points(c, 37)[0]]), Color(0.84, 0.72, 0.62, 0.5), 1.5, true)
			if p == battle.goal() and battle.objective == "escort":
				draw_rect(Rect2(c+Vector2(-18,-10),Vector2(36,20)),Color("9c7c4e"))
				for dy in [-6,0,6]: draw_line(c+Vector2(-16,dy),c+Vector2(16,dy),Color("59462f"),2)
				for dx in [-13,13]:
					draw_circle(c+Vector2(dx,15),6,Color("2a2a1d"))
					draw_arc(c+Vector2(dx,15),6,0,TAU,16,GOLD,1,true)
			if reachable.has(battle.key(p)) and battle.side == 0 and not withdraw_mode:
				draw_colored_polygon(hex_points(c, 36), Color(0.65, 0.75, 0.71, 0.13))
				draw_circle(c, 3, BLUE)
			if p == hovered:
				draw_polyline(hex_points(c, 39)+PackedVector2Array([hex_points(c, 39)[0]]), PAPER, 2, true)
	# Connections use the same live adjacency rules as combat defence.
	for u in battle.units:
		if not battle.fighting(u) or not u.shield or (not u.guard if battle.core_rules else u.order != "line"): continue
		for id in battle.shield_neighbors(u,battle.pos(u)):
			if id > u.id and (battle.units[id].guard and absi(battle.tiles[battle.key(battle.pos(u))].height-battle.tiles[battle.key(battle.pos(battle.units[id]))].height) <= 1 if battle.core_rules else battle.units[id].order == "line"): draw_line(hex_center(battle.pos(u)),hex_center(battle.pos(battle.units[id])),BLUE if u.side == 0 else RED,5,true)
	# Ground marks and bodies first; living counters remain readable above them.
	for u in battle.units:
		if u.hp <= 0 and u.name != "Empty rank":
			var c = hex_center(battle.pos(u))
			draw_circle(c, 17, Color(0.25, 0.1, 0.07, 0.75))
			draw_line(c-Vector2(10, 6), c+Vector2(10, 6), Color("998773"), 4, true)
			draw_line(c-Vector2(-10, 6), c+Vector2(-10, 6), Color("998773"), 4, true)
	for u in battle.units:
		if not battle.living(u): continue
		var c = hex_center(battle.pos(u))
		if int(u.id) == selected:
			draw_arc(c, 33, 0, TAU, 48, GOLD, 3, true)
			if u.side == 0 and battle.side == 0: draw_arc(c, 36, 0, TAU, 48, Color(0.84, 0.71, 0.62, 0.3), 2, true)
		_draw_soldier(u, c-Vector2(0, 7), 0.71 if battle.roster_rules else 0.91)
		bar(c+Vector2(-22, 23), 44, u.hp, u.max_hp, Color("95a35c"), 4)
		bar(c+Vector2(-22, 29), 44, u.morale, 100, BLUE if not u.routed else RED, 3)
		if u.guard:
			centered("+", c+Vector2(-26, -17), 18, GOLD)
		if u.routed: centered("!", c+Vector2(27, -14), 22, RED)
		elif not battle.core_rules and u.order == "loose": centered("L" if battle.spaced(u,battle.pos(u)) else "L!",c+Vector2(27,-14),12,BLUE if battle.spaced(u,battle.pos(u)) else RED)
		elif not battle.core_rules and u.order == "line" and u.shield and battle.line_support(u) == 0: centered("GAP",c+Vector2(0,-38),10,RED)
		if u.side == 0 and battle.side == 0:
			for i in 3:
				draw_circle(c+Vector2(-6+i*6, 37), 1.7, GOLD if u.ap > i*3 else Color("3b4236"))
		if flash_time > 0 and flash_id == int(u.id): draw_arc(c, 32, 0, TAU, 40, RED, 4, true)

func _draw_soldier(u: Dictionary, p: Vector2, zoom: float) -> void:
	if u.has("appearance") or not u.get("armor_parts",[]).is_empty():
		_draw_equipped_soldier(u,p,zoom)
		return
	draw_set_transform(p, 0, Vector2.ONE*zoom)
	var cloth = Color("699992") if u.side == 0 else Color("a15f4e")
	var metal = Color("929b91") if u.armor > 0 else Color("726955")
	draw_circle(Vector2(2, 8), 25, Color(0, 0, 0, 0.32))
	draw_colored_polygon(PackedVector2Array([Vector2(-20, 3), Vector2(-12, -6), Vector2(13, -6), Vector2(22, 6), Vector2(17, 27), Vector2(-17, 27)]), Color("111a18"))
	draw_colored_polygon(PackedVector2Array([Vector2(-17, 3), Vector2(-10, -5), Vector2(11, -5), Vector2(19, 5), Vector2(14, 24), Vector2(-14, 24)]), cloth)
	draw_rect(Rect2(-11, 0, 23, 20), metal)
	for i in 4: draw_line(Vector2(-9, 4+i*4), Vector2(10, 4+i*4), Color("535f59"), 1)
	draw_line(Vector2(-12, 16), Vector2(13, 16), Color("53452f"), 4)
	draw_circle(Vector2(0, -13), 12, Color("161d1a"))
	draw_circle(Vector2(0, -13), 10, Color("c6ac87"))
	if u.helmet > 0:
		draw_arc(Vector2(0, -14), 10, PI, TAU, 16, Color("bbc0b0"), 5, true)
		draw_rect(Rect2(-11, -16, 22, 4), Color("777f74"))
		draw_line(Vector2(0, -20), Vector2(0, -8), Color("cbd0be"), 3)
	draw_line(Vector2(-7, -11), Vector2(-3, -11), Color("322e23"), 2)
	draw_line(Vector2(3, -11), Vector2(7, -11), Color("322e23"), 2)
	if u.shield:
		draw_colored_polygon(PackedVector2Array([Vector2(-29, 0), Vector2(-11, 0), Vector2(-11, 17), Vector2(-20, 27), Vector2(-29, 17)]), Color("c2b58e"))
		draw_colored_polygon(PackedVector2Array([Vector2(-27, 2), Vector2(-13, 2), Vector2(-13, 16), Vector2(-20, 23), Vector2(-27, 16)]), cloth.darkened(0.3))
		draw_line(Vector2(-20, 2), Vector2(-20, 21), Color("c2b58e"), 2)
		draw_circle(Vector2(-20, 10), 3.5, Color("e0d4b1"))
	var length = 1.3 if u.weapon in ["greatsword","greataxe","maul","glaive","warbow","heavy_crossbow","heavy_spear"] else 0.72 if u.weapon in ["shortsword","hatchet","knife","shortbow","militia_spear"] else 1.0
	match Arsenal.family(u.weapon):
		"throwing":
			if u.weapon == "bolas":
				for end in [Vector2(18,0),Vector2(35,5),Vector2(30,-14)]:
					draw_line(Vector2(24,26),end,Color("aa8659"),2)
					draw_circle(end,4,PAPER)
			else: draw_line(Vector2(24,26),Vector2(27,-26 if u.weapon == "javelins" else -10),Color("aa8659"),3)
			if u.weapon == "javelins": draw_colored_polygon(PackedVector2Array([Vector2(27,-35),Vector2(23,-24),Vector2(31,-24)]),PAPER)
			elif u.weapon != "bolas": draw_colored_polygon(PackedVector2Array([Vector2(25,-12),Vector2(36,-17),Vector2(37,-4),Vector2(26,-2)]),PAPER)
		"sword":
			draw_line(Vector2(23, 17), Vector2(29, -25), Color("d6d8c5"), 3, true)
			draw_line(Vector2(18, 9), Vector2(28, 11), GOLD, 3)
		"spear":
			draw_line(Vector2(23, 27), Vector2(25, -35), Color("aa8659"), 3, true)
			draw_colored_polygon(PackedVector2Array([Vector2(25, -43), Vector2(20, -30), Vector2(29, -30)]), Color("d1d3bd"))
		"axe":
			draw_line(Vector2(20, 22), Vector2(28, -27), Color("aa8659"), 4, true)
			draw_colored_polygon(PackedVector2Array([Vector2(25, -28), Vector2(37, -33), Vector2(40, -18), Vector2(26, -16)]), Color("c0c6b9"))
		"bow":
			draw_arc(Vector2(16, -2), 23, -1.3, 1.3, 20, Color("bc9962"), 3, true)
			draw_line(Vector2(22, -24), Vector2(22, 20), Color("d4cfae"), 1, true)
	draw_set_transform(Vector2.ZERO)

func _draw_sidebar() -> void:
	panel(Rect2(1080, 121, 336, 577))
	label_at(battle.objective_name(), Vector2(1100, 150), 12, GOLD)
	label_at(("Round %d / 8" % mini(battle.round_no, 8) if battle.objective in ["defend", "escort"] else "Company   %d / 3" % battle.held[0]) if battle.objective != "eliminate" else ("Destroy every undead" if battle.is_crypt() else "Break every raider"), Vector2(1100, 179), 16, BLUE)
	label_at("Enemy %d / 3" % battle.held[1] if battle.objective != "eliminate" else "", Vector2(1270, 179), 16, RED)
	draw_line(Vector2(1100, 195), Vector2(1396, 195), Color("404b3a"))
	var inspecting = battle.at(hovered)
	if inspecting < 0: inspecting = inspected if battle.individual and inspected >= 0 else selected
	if inspecting >= 0:
		var u: Dictionary = battle.units[inspecting]
		_draw_soldier(u, Vector2(1140, 256), 1.35)
		label_at(u.name, Vector2(1193, 239), 25, PAPER, true)
		label_at(("ACTING NOW" if inspecting == battle.active_id else "ACTIVATION FINISHED" if inspecting in battle.finished else "INSPECTING · ACTS LATER") if battle.individual else u.title, Vector2(1193,260),10,GOLD)
		label_at(battle.weapon_stats(u).name, Vector2(1193, 284), 13, MUTED)
		if battle.double_grip_factor(u) > 1.0: label_at("DOUBLE GRIP · +25% DAMAGE",Vector2(1100,459),11,GOLD)
		var morale = battle.morale_name(u) if battle.individual else ("STEADY" if u.morale >= 60 else ("WAVERING" if u.morale > 15 else "FLEEING"))
		label_at(morale + (" · resolve %d" % u.resolve if battle.individual else " · %d morale" % u.morale) + (" / GUARD" if u.guard else ""), Vector2(1100, 317), 12, BLUE if u.morale >= 60 else RED)
		var metrics = [["Health", u.hp, u.max_hp, Color("a2ad68")], ["Body armour", u.armor+u.padding, u.max_armor+u.max_padding, Color("9caaa6")], ["Helmet", u.helmet, u.max_helmet, Color("8b9c9e")], ["Fatigue", u.fatigue, battle.fatigue_max(u), RED]]
		for i in metrics.size():
			var m = metrics[i]
			var y = 342+i*27
			label_at(m[0], Vector2(1100, y), 12, MUTED)
			bar(Vector2(1191, y-9), 134, m[1], m[2], m[3], 6)
			label_at("%d/%d" % [m[1], m[2]], Vector2(1339, y), 11, PAPER)
		label_at("AP  %d / 9" % u.ap, Vector2(1100,484),14,GOLD)
		label_at(("INIT %d · queued %d" % [battle.initiative_value(u),battle.turn_scores.get(str(u.id),0)]) if battle.individual else "SHIELDS +%d defence" % (battle.shield_support(u)+battle.line_support(u)),Vector2(1220,484),11,MUTED)
		var status = battle.ORDERS[u.order]
		if not battle.core_rules and u.order == "line": status += " · linked" if battle.line_support(u) > 0 else (" · gap" if u.shield else " · spear support")
		if not battle.core_rules and u.order == "loose": status += " · spaced" if battle.spaced(u,battle.pos(u)) else " · crowded: no arrow cover"
		if battle.core_rules: status = "Shieldwall · +%d support" % battle.wall_support(u) if u.guard and u.shield else "No active Shieldwall"
		label_at(status,Vector2(1100,508),12,BLUE)
		if selected >= 0 and u.side != battle.units[selected].side:
			label_at("%d%% hit · %s" % [battle.hit_chance(selected,inspecting),"legal strike" if battle.can_attack(selected,inspecting) else "cannot strike now"],Vector2(1100,532),13,GOLD)
		else: label_at("Attack %d fatigue · Guard %d" % [battle.attack_fatigue(u),battle.guard_fatigue(u)],Vector2(1100,532),12,MUTED)
		if u.side == 1:
			var focus = battle.enemy_plan.get("focus",-1)
			label_at("Role: %s · focus %s" % [battle.enemy_role(u),battle.units[focus].name if focus >= 0 else "not assigned"],Vector2(1100,553),11,RED)
		else:
			label_at(("%d/%d %s%s" % [battle.ammo_count(u),battle.armor_catalog.get(u.arms.weapon.definition if Arsenal.family(u.weapon) == "throwing" else Arsenal.ammo_type(u.weapon),{}).get("durability",0),("throws left" if Arsenal.family(u.weapon) == "throwing" else Arsenal.ammo_type(u.weapon))," · LOADED" if Arsenal.family(u.weapon) == "crossbow" and u.arms.weapon.loaded else " · NEEDS RELOAD" if Arsenal.family(u.weapon) == "crossbow" else ""]) if battle.weapon_rules and u.weapon in Arsenal.RANGED else ", ".join(u.perks.map(func(id): return PerkProgression.definition(id).name)).left(46),Vector2(1100,553),11,BLUE)
	if battle.tiles.has(battle.key(hovered)):
		var tile: Dictionary = battle.tiles[battle.key(hovered)]
		label_at("%s · height %d · hex %d, %d" % [tile.terrain.capitalize(),tile.height,hovered.x+1,hovered.y+1],Vector2(1100,578),12,GOLD)
		if reachable.has(battle.key(hovered)):
			var cost: int = reachable[battle.key(hovered)].cost
			label_at("MOVE %d AP / %d fatigue%s" % [cost,cost*People.move_rate(battle.units[selected])," · line cost included" if battle.units[selected].order == "line" else ""],Vector2(1100,600),11,BLUE)
	button("inspect_open","I  Inspect companion",Rect2(1100,608,296,33),campaign.phase == "battle" and campaign.deployment.any(func(sid): return sid >= 0))
	if inspecting >= 0:
		var u: Dictionary = battle.units[inspecting]
		label_at("Comrades +%d resolve · -%d strain / -%d grief" % [battle.comrade_support(u),u.strain_penalty,u.grief_penalty],Vector2(1100,660),10,BLUE)
	var scars: Array = battle.units[inspecting].scars if inspecting >= 0 else []
	label_at("Scar: "+", ".join(scars.map(func(id): return Progression.SCARS[id].name)) if not scars.is_empty() else "Raise Shieldwall for adjacent wall support." if battle.core_rules else "Linked shields protect; gaps remove support.",Vector2(1100,684),11,RED if not scars.is_empty() else MUTED)

func _draw_roster() -> void:
	draw_line(Vector2(24, 713), Vector2(1416, 713), Color("635b3a"))
	var compact = battle.roster_rules
	for i in battle.player_slots():
		var u: Dictionary = battle.units[i]
		var x = 30+i*(86 if compact else 173)
		var rect = Rect2(x, 730, 80 if compact else 161, 72)
		buttons["unit%d" % i] = {"rect":rect, "enabled":battle.living(u)}
		panel(rect, Color("2b3328") if selected == i else Color("17201b"), GOLD if selected == i else Color("3a4535"))
		label_at(u.name.left(9) if compact else u.name, Vector2(x+6 if compact else x+12, 753), 12 if compact else 17, PAPER if battle.fighting(u) else RED, true)
		label_at("%s   %d AP" % [u.weapon.to_upper().left(7) if compact else u.weapon.to_upper(), u.ap], Vector2(x+6 if compact else x+12, 773), 8 if compact else 10, MUTED)
		bar(Vector2(x+6 if compact else x+12, 784), 68 if compact else 137, u.hp, u.max_hp, Color("94a060"))
	var can = battle.side == 0 and selected >= 0 and battle.can_act(selected) and battle.fighting(battle.units[selected])
	var u: Dictionary = battle.units[selected] if selected >= 0 else {}
	button("guard", "1  Shieldwall" if battle.core_rules else "1  Shieldwall / guard", Rect2(30, 816, 191, 35), can and (not battle.core_rules or u.get("shield",false)) and u.get("ap", 0) >= 4 and not u.get("guard", false) and u.get("fatigue", 100)+battle.guard_fatigue(u) <= battle.fatigue_max(u))
	button("recover", "2  Recover", Rect2(231, 816, 133, 35), can and battle.recover_reason(selected).is_empty())
	button("withdraw", "3  " + ("Choose retreat tile" if withdraw_mode else "Withdraw"), Rect2(374, 816, 184, 35), can and u.get("ap", 0) >= 4 and u.get("fatigue",100)+12 <= battle.fatigue_max(u) and not battle.adjacent_enemies(u, battle.pos(u)).is_empty())
	button("wait" if battle.individual else "finish", "Space  Wait" if battle.individual else "Finish soldier", Rect2(568,816,187,35),battle.can_wait(selected) if battle.individual else can)
	button("end", "F  END ACTIVATION  >" if battle.individual else "F  END COMPANY TURN  >", Rect2(771, 816, 285, 35), battle.side == 0 and battle.result.is_empty(), true)
	panel(Rect2(1080, 730, 336, 121))
	label_at("BATTLE JOURNAL", Vector2(1094, 750), 10, GOLD)
	var recent = battle.events.slice(maxi(0, battle.events.size()-4))
	for i in recent.size():
		var line: String = recent[i]
		if line.length() > 47: line = line.left(44)+"…"
		label_at(line, Vector2(1094, 773+i*21), 11, MUTED if i < recent.size()-1 else PAPER)

func _draw_tactics() -> void:
	draw_rect(Rect2(0,0,1440,900),Color(0.02,0.04,0.025,0.95))
	panel(Rect2(105,80,1230,750),Color("17231b"),GOLD)
	label_at("COMMAND THE LINE",Vector2(135,127),26,PAPER,true)
	button("tact_orders","FORMATION ORDERS",Rect2(665,100,240,40),true,tactics_tab == "orders")
	button("tact_odds","HIT ODDS",Rect2(918,100,180,40),true,tactics_tab == "odds")
	button("tact_close","CLOSE / ESC",Rect2(1111,100,194,40))
	if tactics_tab == "odds":
		_draw_odds()
		return
	label_at("SELECT SOLDIERS · ORDERS DO NOT REPOSITION THEM",Vector2(135,175),11,GOLD)
	for i in battle.player_slots():
		var u: Dictionary = battle.units[i]
		var y = 194+(i%6)*59
		var x = 135+(i/6)*178
		var width = 172 if battle.roster_rules else 350
		var chosen = i in formation_selection
		button("tact_unit_%d" % i,("[+] " if chosen else "[  ] ")+u.name,Rect2(x,y,width,52),battle.fighting(u) and (not battle.individual or battle.can_act(i)),chosen)
		label_at("%s · %s · %d AP / %d fatigue" % [u.weapon,"" if battle.roster_rules else battle.ORDERS[u.order],u.ap,u.fatigue],Vector2(x+8,y+45),10,MUTED)
	button("tact_all","All",Rect2(135,562,100,32))
	button("tact_line_gear","Shields / spears",Rect2(243,562,156,32))
	button("tact_none","Clear",Rect2(407,562,78,32))
	label_at("Active fighter only: free formation marker." if battle.core_rules else "Active fighter only: 2 AP + 4 fatigue.",Vector2(135,626),12,GOLD)
	label_at("Orders persist across turns and saves.",Vector2(135,650),12,MUTED)
	label_at("Markers do not change combat stats." if battle.core_rules else "Changing orders lowers an active guard.",Vector2(135,674),12,MUTED)
	label_at("Routed soldiers drop their orders.",Vector2(135,698),12,MUTED)
	label_at("Blocked orders change nobody.",Vector2(135,722),12,MUTED)
	label_at("ISSUE AN ORDER TO THE SELECTED GROUP",Vector2(515,175),11,GOLD)
	for i in 3:
		var order: String = ["line","loose","free"][i]
		var reason = battle.order_preview(formation_selection,order)
		button("tact_order_"+order,battle.ORDERS[order],Rect2(515+i*266,195,250,42),reason.is_empty())
		var rect = Rect2(515+i*266,195,250,42)
		if rect.has_point(get_global_mouse_position()) and not reason.is_empty():
			draw_multiline_string(font,Vector2(515,405),reason,HORIZONTAL_ALIGNMENT_LEFT,775,12,2,RED)
	var descriptions = [
		"SHIELD LINE: adjacent ordered shields add +5 defence each (max +10), on top of normal shield support.",
		"Ordered spears thrusting over an ordered shield gain +10 accuracy. Each movement step costs +1 AP.",
		"LOOSE ORDER: no adjacent ally gives -12 enemy bow accuracy. No shield support; enemies gain +5 melee accuracy.",
		"FREE ORDER: ordinary movement and passive shield support; no line or spacing bonus."]
	if battle.core_rules: descriptions = ["Orders mark formation intent; they grant no passive defence or accuracy.","SHIELDWALL: 4 AP / 20 fatigue. Doubles your shield defence until your next activation.","While walling, each adjacent active friendly wall adds +5 defence (maximum four).","Surrounding: +5 melee accuracy per additional melee opponent. Ranged attacks gain none."]
	for i in descriptions.size(): draw_multiline_string(font,Vector2(515,268+i*32),descriptions[i],HORIZONTAL_ALIGNMENT_LEFT,775,12,2,MUTED)
	label_at("ADVANCE TOGETHER · ONE HEX · PREVIEW BEFORE MOVING",Vector2(515,453),11,GOLD)
	for i in 6: button("tact_dir_%d" % i,["E →","NE ↗","NW ↖","W ←","SW ↙","SE ↘"][i],Rect2(515+i*132,470,119,35),true,formation_direction == i)
	var preview = battle.advance_preview(formation_selection,formation_direction)
	label_at("SOLDIER                 DESTINATION              COST",Vector2(515,534),11,GOLD)
	for i in preview.steps.size():
		var step: Dictionary = preview.steps[i]
		var y = 558+i*22
		label_at(battle.units[step.id].name,Vector2(515,y),12,PAPER)
		label_at("hex %d, %d" % [step.q+1,step.r+1],Vector2(675,y),12,MUTED)
		label_at("%d AP / %d fatigue" % [step.cost,step.cost*People.move_rate(battle.units[step.id])] if step.cost < 999 else "BLOCKED",Vector2(835,y),12,BLUE if step.reason.is_empty() else RED)
		if not step.reason.is_empty(): label_at(step.reason.left(37),Vector2(1000,y),10,RED)
	draw_multiline_string(font,Vector2(515,710),preview.reason,HORIZONTAL_ALIGNMENT_LEFT,775,12,2,BLUE if preview.ok else RED)
	button("tact_advance","ADVANCE SELECTED SOLDIERS",Rect2(515,753,790,44),preview.ok,true)

func _draw_odds() -> void:
	if detail_target < battle.player_slots(): detail_target = battle.player_slots()
	if selected < 0: return
	var u: Dictionary = battle.units[selected]
	label_at("ATTACKER: "+u.name+" · "+battle.weapon_stats(u).name,Vector2(135,180),17,GOLD)
	for i in range(battle.player_slots(),battle.units.size()):
		var v: Dictionary = battle.units[i]
		button("tact_enemy_%d" % i,v.name,Rect2(135,210+(i-battle.player_slots())*(29 if battle.roster_rules else 58),350,26 if battle.roster_rules else 48),battle.living(v),detail_target == i)
	var v: Dictionary = battle.units[detail_target]
	var detail = battle.hit_breakdown(selected,detail_target)
	label_at("%d%% TO HIT %s" % [detail.chance,v.name.to_upper()],Vector2(535,190),24,PAPER,true)
	label_at(battle.attack_block_reason(selected,detail_target),Vector2(535,219),12,BLUE if battle.can_attack(selected,detail_target) else RED)
	for i in detail.parts.size():
		var part: Dictionary = detail.parts[i]
		label_at(part.name,Vector2(535,255+i*28),14,MUTED)
		label_at("%+.1f" % part.value,Vector2(1080,255+i*28),14,BLUE if part.value > 0 else RED)
	label_at("Raw %.1f · 5–95%% limits · whole-number roll" % detail.raw,Vector2(535,736),12,GOLD)
	label_at("These are the exact modifiers used by the attack roll.",Vector2(535,768),12,MUTED)
	label_at("Change attacker by closing and selecting a soldier.",Vector2(135,602),11,MUTED)

func _draw_briefing() -> void:
	draw_rect(Rect2(0, 0, 1440, 900), Color(0.02, 0.04, 0.035, 0.85))
	panel(Rect2(350, 150, 740, 600), Color("19231d"), GOLD)
	centered("THE COMPANY AT REST" if campaign.phase == "camp" else "FIELD ENCOUNTER / THE BORDER MARCHES" if not campaign.encounter.is_empty() else "CONTRACT %03d  /  THE BORDER MARCHES" % (campaign.completed+1), Vector2(720, 200), 12, GOLD)
	centered("Keep the company alive" if campaign.phase == "camp" else campaign.battle_job().title, Vector2(720, 255), 32, PAPER, true)
	centered("A company is more than the men who survive the day.", Vector2(720, 294), 16, MUTED)
	draw_line(Vector2(395, 320), Vector2(1045, 320), Color("626044"))
	var lines = [
		["YOUR OBJECTIVE", battle.objective_text().left(70)],
		["", "Breaking every enemy also wins. Contesting stops capture."],
		["KEEP THE LINE", "4: paid orders and group advances. 5: exact hit modifiers."],
		["ARMOUR & HEAD HITS", "Body layers share protection. Head hits multiply HP loss, not armour wear." if battle.damage_rules else "This saved battle finishes with its original damage rules."],
		["READ THE FIELD", "Hills help attacks. Trees block arrows. Water blocks movement."],
		["GIVE YOUR ORDERS", "Click a man, then a lit tile or enemy. Hover for costs and odds."],
		["PACE YOUR MEN", "9 AP per activation. Initiative mixes both sides. Space waits; F finishes the active fighter."]
	]
	if campaign.phase == "camp":
		lines = [
			["TRAIN VETERANS", "Profile & Growth: pick 3 stats per level. Stars improve gains."],
			["WOUNDS & SCARS", "HP heals over time. Medicine treats injuries; temples speed treatment. Permanent scars remain."],
			["REPAIR THE DAMAGE", "One tool restores up to 12 armour. Repair covers worn layers."],
			["EARN EXPERIENCE", "Battle: 20, +10 win, +5/kill. Jobs: +10 to the signed roster."],
			["PAY EACH DAY", "Travel, rest and battles consume wages and one ration per soldier."],
			["COUNCILS & PATROLS", "Reputation changes prices. Fund patrols to protect a road."],
			["BUILD YOUR COMPANY", "No final day. Pay your company, replace losses and choose your battles."]
		]
	for i in lines.size():
		var y = 361+i*39
		label_at(lines[i][0], Vector2(394, y), 11, GOLD)
		label_at(lines[i][1], Vector2(557, y), 12, PAPER)
	centered("F5 save  ·  F9 load  ·  H help  ·  N found a new company", Vector2(720, 666), 12, MUTED)
	button("begin", "TAKE COMMAND" if intro else ("RETURN TO CAMP" if campaign.phase == "camp" else "RETURN TO THE FIELD"), Rect2(520, 691, 400, 40), true, true)

func camp_portrait(s: Dictionary) -> Dictionary:
	return {"side":0, "weapon":campaign.item_def(s.gear.weapon).get("weapon", "sword"), "armor":campaign.durability(s, "body"), "helmet":campaign.durability(s, "head"), "shield":campaign.items.get(s.gear.shield,{}).get("condition",0) > 0, "arms":campaign.soldier_arms(s), "appearance":campaign.armor_appearance(s), "armor_parts":campaign.battle_parts(s)}

func _draw_camp() -> void:
	draw_rect(Rect2(0, 0, 1440, 900), Color("101815"))
	for i in 90: draw_line(Vector2(0, i*10), Vector2(1440, i*10), Color(0.9, 0.85, 0.7, 0.012))
	draw_rect(Rect2(0, 0, 1440, 108), Color("0c1310"))
	draw_line(Vector2(24, 107), Vector2(1416, 107), Color("635b3a"))
	draw_arc(Vector2(52, 55), 31, 0, TAU, 36, Color("756c48"), 1.2, true)
	draw_line(Vector2(38, 35), Vector2(65, 75), GOLD, 3, true)
	draw_line(Vector2(65, 35), Vector2(38, 75), GOLD, 3, true)
	label_at("THE ASHEN COMPANY", Vector2(102, 36), 13, GOLD)
	label_at("Company", Vector2(100, 76), 34, PAPER, true)
	label_at("THE ASHEN COMPANY", Vector2(677, 36), 11, MUTED)
	label_at("DAY %02d" % campaign.day, Vector2(678, 70), 23, GOLD, true)
	label_at("%d / %d SOLDIERS" % [campaign.alive_count(),campaign.company_limit()], Vector2(852, 68), 13, BLUE)
	button("iron_menu", "Menu", Rect2(1310,30,106,40))
	label_at("%d CROWNS" % campaign.crowns, Vector2(30, 143), 17, GOLD)
	label_at("%d TOOLS" % campaign.tools, Vector2(228, 143), 17, MUTED)
	label_at("%d MEDICINE" % campaign.medicine, Vector2(402, 143), 17, MUTED)
	label_at("%d RATIONS  /  %d CROWNS A DAY" % [campaign.food, campaign.wage_cost()], Vector2(635, 143), 13, BLUE)
	button("world", "REGION MAP", Rect2(1010, 119, 185, 34), true, true)
	button("lineup_open","FORMATION & RESERVES",Rect2(30,157,300,27),true,true)
	label_at("SOLDIER & EQUIPMENT", Vector2(350, 178), 12, GOLD)
	button("service","PERSON & SERVICE",Rect2(650,157,210,27),true,true)
	label_at("COMPANY STORES", Vector2(880, 178), 12, GOLD)
	button("bonds","BONDS & CAMP",Rect2(1130,157,286,27),true,true)
	var roll = campaign.roll_ids()
	roll_page = clampi(roll_page, 0, maxi(0, ceili(float(roll.size())/6)-1))
	for n in mini(6, roll.size()-roll_page*6):
		var i = roll[roll_page*6+n]
		var s: Dictionary = campaign.soldiers[i]
		var y = 192+n*76
		var rect = Rect2(30, y, 300, 66)
		panel(rect, Color("2b3328") if camp_selected == i else Color("19211b"), GOLD if camp_selected == i else Color("354332"))
		buttons["camp_unit_%d" % i] = {"rect":rect, "enabled":true}
		label_at(s.name, Vector2(45, y+23), 20, PAPER if s.alive else RED, true)
		var status = "%d / %d HP" % [s.hp, campaign.max_hp(s)] if s.alive else "FALLEN · DAY %d" % s.fallen_day
		label_at(status, Vector2(194, y+22), 11, BLUE if s.alive else RED)
		var detail = "Lv%d · %d XP · %d perk points" % [Progression.level(s),s.xp,Progression.points(s)]
		if campaign.roster_version == 1 and s.alive: detail = ("FIELD" if s.id in campaign.active_ids() else "RESERVE")+" · "+detail
		if s.alive and s.wound_days > 0: detail = "DEEP WOUND · %d injury days" % s.wound_days
		label_at(detail, Vector2(45, y+44), 11, RED if s.wound_days > 0 else MUTED)
		bar(Vector2(45, y+54), 270, s.hp, campaign.max_hp(s), Color("94a060"), 3)
	button("roll_prev", "<", Rect2(30, 644, 45, 30), roll_page > 0)
	centered("Roll & memorial · %d / %d" % [roll_page+1, ceili(float(roll.size())/6)], Vector2(180, 665), 11, MUTED)
	button("roll_next", ">", Rect2(285, 644, 45, 30), (roll_page+1)*6 < roll.size())
	panel(Rect2(30, 688, 300, 162))
	label_at("COMPANY JOURNAL", Vector2(46, 710), 11, GOLD)
	var known = campaign.journal.filter(known_news)
	var recent = known.slice(maxi(0,known.size()-3))
	for i in recent.size():
		var text_line: String = recent[i]
		var y = 734+i*37
		var lines = wrapped_lines(text_line, 264, 11, 2)
		for n in lines.size(): label_at(lines[n], Vector2(46, y+n*16), 11, PAPER if i == recent.size()-1 else MUTED)
	var s: Dictionary = campaign.soldiers[camp_selected]
	panel(Rect2(350, 192, 510, 500))
	if s.alive: _draw_soldier(camp_portrait(s), Vector2(411, 249), 1.3)
	else:
		draw_line(Vector2(389, 221), Vector2(434, 270), Color("8d7560"), 5, true)
		draw_line(Vector2(434, 221), Vector2(389, 270), Color("8d7560"), 5, true)
	label_at(s.name, Vector2(476, 231), 29, PAPER, true)
	label_at(s.title, Vector2(477, 254), 11, GOLD)
	label_at("Melee %d / Ranged %d · Def %d / %d" % [campaign.effective_skill(s),campaign.effective_ranged_skill(s),s.base_defense,s.base_ranged_defense], Vector2(477, 280), 13, MUTED)
	label_at("Health  %d / %d" % [s.hp, campaign.max_hp(s)], Vector2(372, 317), 14, PAPER)
	bar(Vector2(551, 307), 284, s.hp, campaign.max_hp(s), Color("a2ad68"), 8)
	if not s.alive: label_at("Fallen on day %d. Their name stays on the roll." % s.fallen_day, Vector2(372, 346), 13, RED)
	elif s.wound_days > 0: label_at("Deep wound: -12 max HP, -10 skill · %d injury days" % s.wound_days, Vector2(372, 346), 12, RED)
	else: label_at("%s · %d crowns / day" % [s.trait, s.wage], Vector2(372, 346), 12, MUTED)
	var slot_names = {"weapon":"WEAPON", "body":"BODY ASSEMBLY", "head":"HELMET ASSEMBLY", "shield":"OFF HAND"}
	for i in 4:
		var slot: String = ["weapon","body","head","shield"][i]
		var y = 367+i*65
		var rect = Rect2(370, y, 470, 57)
		panel(rect, Color("2c3527") if gear_slot == slot else Color("1a241c"), GOLD if gear_slot == slot else Color("354332"))
		buttons["slot_"+slot] = {"rect":rect, "enabled":true}
		label_at(slot_names[slot], Vector2(382, y+17), 9, GOLD)
		var definition = campaign.item_def(s.gear[slot])
		label_at((campaign.kit_name(s.gear[slot]) if slot in ["body","head"] and not s.gear[slot].is_empty() else definition.get("name", "Empty")).left(25), Vector2(382, y+37), 13 if slot in ["body","head"] else 15, PAPER if not definition.is_empty() else MUTED)
		if slot in ["body","head"]:
			label_at("%d/%d  ·  %d pieces  ·  OPEN >" % [campaign.durability(s,slot)+(campaign.durability(s,"under") if slot == "body" else 0),campaign.maximum(s,slot)+(campaign.maximum(s,"under") if slot == "body" else 0),campaign.kit_parts(s.gear[slot]).values().filter(func(id):return id != "").size()],Vector2(585,y+37),11,BLUE)
		if definition.get("durability", 0) > 0:
			label_at("%d / %d" % [campaign.durability(s, slot), campaign.maximum(s, slot)], Vector2(742, y+20), 12, MUTED)
			bar(Vector2(669, y+32), 155, campaign.durability(s, slot), campaign.maximum(s, slot), Color("a8a485"), 4)
	button("loadout","WEAPONS · CARRIED KIT · AMMUNITION",Rect2(370,633,470,38),s.alive and not campaign.over())
	panel(Rect2(880, 192, 536, 500))
	label_at(slot_names[gear_slot], Vector2(902, 225), 15, GOLD)
	label_at("Unequipped items. Their condition travels with them.", Vector2(902, 253), 12, MUTED)
	var inventory = campaign.stash(gear_slot)
	var pages = maxi(1, ceili(float(inventory.size())/6))
	stash_page = clampi(stash_page, 0, pages-1)
	for i in mini(6, inventory.size()-stash_page*6):
		var id: String = inventory[stash_page*6+i]
		var d = campaign.item_def(id)
		var y = 272+i*55
		var rect = Rect2(900, y, 496, 46)
		var usable = s.alive and not campaign.over() and not (gear_slot == "shield" and campaign.item_def(s.gear.weapon).get("weapon", "") in Arsenal.TWO_HANDS)
		buttons["equip_"+id] = {"rect":rect, "enabled":usable}
		panel(rect, Color("263126") if rect.has_point(get_global_mouse_position()) else Color("1a251c"), Color("3e4b36"))
		label_at(campaign.kit_name(id) if d.get("assembly",false) else d.name, Vector2(915, y+20), 16, PAPER if usable else MUTED)
		label_at(id.replace("item_", "#")+"  ·  "+(campaign.kit_summary(id) if d.get("assembly",false) else "%d/%d condition" % [campaign.items[id].condition, d.durability] if d.durability > 0 else "Ready"), Vector2(915, y+37), 10, MUTED)
		label_at(("OPEN >" if d.get("assembly",false) else "EQUIP >") if usable else "FALLEN" if not s.alive else "ARCHIVED" if campaign.over() else "TWO HANDS", Vector2(1309, y+27), 10, GOLD if usable else MUTED)
	if inventory.is_empty():
		centered("No spare items for this slot.", Vector2(1148, 350), 17, MUTED, true)
	button("stash_prev", "<", Rect2(900, 613, 42, 30), stash_page > 0)
	centered("%d / %d" % [stash_page+1, pages], Vector2(995, 635), 12, MUTED)
	button("stash_next", ">", Rect2(1048, 613, 42, 30), stash_page < pages-1)
	button("unequip", "Return equipped item to stores", Rect2(900, 653, 496, 28), s.alive and gear_slot != "weapon" and s.gear[gear_slot] != "")
	var repair = campaign.repair_cost(camp_selected)
	button("temple","TEMPLE CARE · 40c",Rect2(350,710,250,42),campaign.in_town() and s.alive and s.wound_days > 0 and campaign.crowns >= 40 and not campaign.recovery.patients.get(str(s.id),{}).get("temple",false))
	button("buy_tools", "+12 tools · %d crowns" % campaign.supply_cost("tools"), Rect2(614, 710, 246, 42), campaign.in_town() and not campaign.over())
	button("rest", "Rest 1 day · %d crowns" % campaign.rest_cost(), Rect2(350, 767, 250, 42), not campaign.over())
	button("buy_medicine", "+6 medicine · %d crowns" % campaign.supply_cost("medicine"), Rect2(614, 767, 246, 42), campaign.in_town() and not campaign.over())
	label_at(campaign.Recovery.status(campaign,camp_selected), Vector2(350, 836), 11, BLUE)
	label_at("HP +1/h, +2 camping · armour +4/h, +6 camping · injuries use medicine",Vector2(350,858),10,MUTED)
	panel(Rect2(880, 710, 536, 140), Color("272b1e"), Color("756846"))
	var finished = campaign.over()
	label_at("The company’s chronicle." if finished else campaign.node().name, Vector2(900, 741), 22, PAPER, true)
	label_at("%d wins · %s · %d living" % [campaign.wins,"open campaign" if campaign.endless else "region secured" if campaign.region_secured() else "4 wins or secure region",campaign.alive_count()], Vector2(900, 768), 12, GOLD)
	label_at("Visit the map for jobs, recruitment, provisions and travel.", Vector2(900, 792), 12, MUTED)
	button("salvage_open","TRADE & SALVAGE",Rect2(1165,722,230,35),campaign.in_town() and not campaign.over())
	button("world_camp", "RETURN TO THE REGION  >", Rect2(900, 809, 496, 29), true, true)
	label_at("Select a soldier → choose a gear slot → equip from stores. Auto-saved after camp actions.", Vector2(350, 879), 12, MUTED)
	if notice_time > 0:
		panel(Rect2(350, 817, 510, 34), Color("101815"), GOLD)
		centered(notice.left(72), Vector2(605, 839), 12, GOLD)

func _draw_bonds() -> void:
	var s: Dictionary = campaign.soldiers[camp_selected]
	var relation = campaign.relationships
	var others = campaign.roll_ids().filter(func(id): return id != camp_selected)
	if not bond_partner in others: bond_partner = others[0]
	var partner: Dictionary = campaign.soldiers[bond_partner]
	draw_rect(Rect2(0,0,1440,900),Color(0.02,0.04,0.025,0.95))
	panel(Rect2(90,60,1260,790),Color("17231b"),GOLD)
	label_at("THE PEOPLE BEHIND THE SHIELDS",Vector2(120,99),12,GOLD)
	label_at(s.name+" · bonds & burdens",Vector2(120,140),29,PAPER,true)
	button("bond_service","PERSONAL HISTORY",Rect2(830,88,240,39))
	button("bond_close","CLOSE / ESC",Rect2(1090,88,230,39))
	panel(Rect2(120,163,385,147),Color("202e21"))
	label_at((("Next deployment: WAVERING" if "haunted" in s.scars else "Next deployment: STEADY") if battle.individual else "Next deployment: %d morale" % campaign.Relationships.starting_morale(s)) if s.alive else "Fallen · record preserved",Vector2(137,192),18,GOLD)
	label_at(("Strain %d / 6: -%d Resolve" if battle.individual else "Strain %d / 6: -%d starting morale") % [s.strain,s.strain*2],Vector2(137,219),12,MUTED)
	label_at(("Grief: -%d Resolve (cap 8)" if battle.individual else "Grief: -%d starting morale (cap 8)") % campaign.Relationships.grief_penalty(s),Vector2(137,243),12,MUTED)
	var loss_text = "No active grief."
	if not s.grief.is_empty(): loss_text = "%s · %d further battles%s" % [campaign.soldiers[s.grief[0].person].name,s.grief[0].remaining," (+%d more)" % (s.grief.size()-1) if s.grief.size() > 1 else ""]
	label_at(loss_text,Vector2(137,268),12,RED if not s.grief.is_empty() else MUTED)
	label_at(("Haunted: starts wavering" if battle.individual else "Haunted scar: -10") if "haunted" in s.scars else "No starting morale penalty" if battle.individual else "Base starting morale: 85",Vector2(137,292),11,MUTED)
	label_at("COMPANIONS · LIVING AND REMEMBERED",Vector2(120,337),11,GOLD)
	bond_roll_page = clampi(bond_roll_page,0,maxi(0,ceili(float(others.size())/6)-1))
	for i in mini(6,others.size()-bond_roll_page*6):
		var id: int = others[bond_roll_page*6+i]
		var other: Dictionary = campaign.soldiers[id]
		var y = 352+i*47
		button("bond_partner_%d" % id,other.name+(" · fallen" if not other.alive else ""),Rect2(120,y,385,42),true,id == bond_partner)
		label_at("%s · trust %d" % [relation.title(s.id,id),relation.trust(s.id,id)],Vector2(132,y+35),10,BLUE if relation.trust(s.id,id) >= 3 else MUTED)
	button("bond_roll_prev","<",Rect2(120,641,48,28),bond_roll_page > 0)
	button("bond_roll_next",">",Rect2(457,641,48,28),(bond_roll_page+1)*6 < others.size())
	label_at("Comrades at 3 trust; maximum 6.",Vector2(180,660),11,MUTED)
	label_at(s.name+" & "+partner.name+" · "+relation.title(s.id,partner.id),Vector2(535,184),21,PAPER,true)
	label_at("Nearby comrades add 2 Resolve each, cap 4, within 2 hexes." if battle.individual else "Nearby comrades reduce morale loss by 2 each, cap 4, within 2 hexes.",Vector2(535,211),12,BLUE)
	var remembered = s.grief.filter(func(loss): return loss.person == partner.id)
	var bond_note = "A fallen comrade causes grief: -4 Resolve per loss, capped at -8." if battle.core_rules else "A comrade's nearby death adds 8 shock; later grief starts at -4 morale."
	if not partner.alive: bond_note = "Remembered bond: no nearby support."+ (" Grief: %d further completed battles." % remembered[0].remaining if not remembered.is_empty() else " No active grief for this loss.")
	label_at(bond_note,Vector2(535,234),12,RED if not remembered.is_empty() else MUTED)
	var history: Array = relation.pairs.get(relation.pair_key(s.id,partner.id),{}).get("history",[]).duplicate(true)
	history.reverse()
	bond_page = clampi(bond_page,0,maxi(0,ceili(float(history.size())/5)-1))
	if history.is_empty(): label_at("No shared events yet. Bonds begin with actual service.",Vector2(552,300),14,MUTED)
	for i in mini(5,history.size()-bond_page*5):
		var entry: Dictionary = history[bond_page*5+i]
		var y = 260+i*70
		panel(Rect2(535,y,785,62),Color("1b281e"))
		label_at("DAY %02d · TRUST %+d" % [entry.day,entry.delta],Vector2(550,y+18),10,BLUE if entry.delta >= 0 else RED)
		draw_multiline_string(font,Vector2(550,y+38),entry.text,HORIZONTAL_ALIGNMENT_LEFT,750,12,2,PAPER)
	button("bond_prev","<",Rect2(535,620,48,29),bond_page > 0)
	centered("%d / %d" % [bond_page+1,maxi(1,ceili(float(history.size())/5))],Vector2(922,640),12,MUTED)
	button("bond_next",">",Rect2(1272,620,48,29),(bond_page+1)*5 < history.size())
	var actions = [["meal","Extra meal · 6 rations"],["support","Support grief · 1 day"],["mediate","Mediate dispute · 1 day"]]
	for i in actions.size():
		var kind: String = actions[i][0]
		var reason: String = campaign.camp_decision_reason(kind,s.id,partner.id)
		var rect = Rect2(120+i*406,698,388,42)
		button("bond_decide_"+kind,actions[i][1],rect,reason.is_empty(),true)
		if rect.has_point(get_global_mouse_position()) and not reason.is_empty(): draw_multiline_string(font,Vector2(120,824),reason,HORIZONTAL_ALIGNMENT_LEFT,1180,11,1,RED)
	label_at("Meal: -2 strain, once per soldier/day. Support: eases one loss. Mediation: +2 trust, at most neutral.",Vector2(120,766),12,MUTED)
	label_at("A day costs %d crowns (including arrears) and %d rations; ordinary healing, treatment and world events proceed." % [campaign.rest_cost(),campaign.alive_count()],Vector2(120,792),12,GOLD)

func _draw_service() -> void:
	var s: Dictionary = campaign.soldiers[camp_selected]
	draw_rect(Rect2(0,0,1440,900),Color(0.02,0.04,0.025,0.94))
	panel(Rect2(110,65,1220,770),Color("17231b"),GOLD)
	label_at("THE COMPANY REMEMBERS",Vector2(140,105),12,GOLD)
	label_at(s.name+" · "+s.background,Vector2(140,150),30,PAPER,true)
	label_at("LEVEL %d · %s · %d XP" % [Progression.level(s),Progression.rank_name(s).to_upper(),s.xp],Vector2(650,146),18,BLUE)
	button("person_open","PROFILE & GROWTH",Rect2(885,94,230,43),true,true)
	button("service_close","CLOSE / ESC",Rect2(1130,94,170,43),true,true)
	panel(Rect2(140,176,430,123),Color("202e21"))
	label_at("%d %s · %d kills · %s" % [s.battles,"battle" if s.battles == 1 else "battles",s.kills,"living" if s.alive else "fallen day %d" % s.fallen_day],Vector2(158,205),18,PAPER,true)
	label_at("%d / %d HP · %d injury days" % [s.hp,campaign.max_hp(s),s.wound_days],Vector2(158,232),13,MUTED)
	var next = Progression.next_xp(s)
	label_at("Next rank: %d / %d XP" % [s.xp,next] if next > 0 else "Level 11 reached. Further deeds remain recorded.",Vector2(158,259),12,GOLD)
	bar(Vector2(158,278),394,s.xp,next if next > 0 else s.xp,BLUE,5)
	label_at("LASTING SCARS",Vector2(140,328),11,GOLD)
	if s.scars.is_empty(): label_at("No permanent scars recorded.",Vector2(140,352),12,MUTED)
	for i in s.scars.size():
		var scar: Dictionary = Progression.SCARS[s.scars[i]]
		label_at(scar.name+": "+scar.effect,Vector2(140,350+i*19),11,RED)
	var choices = PerkProgression.available(s) if Perks.modern(s) else Progression.points(s)
	var training_status = "%d %s AVAILABLE · PERMANENT" % [choices,"PERK POINT" if choices == 1 else "PERK POINTS"]
	if not s.alive: training_status = "FALLEN · RECORD ONLY"
	elif campaign.over(): training_status = "CAMPAIGN ENDED · RECORD ONLY"
	label_at("PERKS · "+training_status,Vector2(140,399),11,GOLD)
	if Perks.modern(s):
		button("personal_perks","PERSONAL PERK TREE",Rect2(140,425,430,64),true,true)
		label_at("%d saved options · %d earned points available" % [s.perk_pool.size(),PerkProgression.available(s)],Vector2(140,518),16,BLUE)
		label_at("Choose across groups. Tiers unlock by total points spent.",Vector2(140,548),13,MUTED)
	for i in (0 if Perks.modern(s) else Progression.PERK_ORDER.size()):
		var id: String = Progression.PERK_ORDER[i]
		var perk: Dictionary = Progression.PERKS[id]
		var learned = id in s.perks
		var enabled = s.alive and not campaign.over() and not learned and Progression.points(s) > 0
		var y = 415+i*87
		var rect = Rect2(140,y,430,77)
		panel(rect,Color("293326") if learned else Color("1d291f"),BLUE if learned else (GOLD if enabled else Color("394736")))
		buttons["learn_"+id] = {"rect":rect,"enabled":enabled}
		label_at(perk.name,Vector2(155,y+24),19,PAPER if learned or enabled else MUTED,true)
		label_at("LEARNED" if learned else ("LEARN >" if enabled else "LOCKED"),Vector2(474,y+24),11,BLUE if learned else GOLD if enabled else MUTED)
		var lines = wrapped_lines(perk.effect,398,11,2)
		for n in lines.size(): label_at(lines[n],Vector2(155,y+45+n*15),11,MUTED)
	label_at("SERVICE RECORD · NEWEST FIRST",Vector2(600,200),11,GOLD)
	var history = s.history.duplicate(true)
	history.reverse()
	service_page = clampi(service_page,0,maxi(0,ceili(float(history.size())/7)-1))
	for i in mini(7,history.size()-service_page*7):
		var entry = history[service_page*7+i]
		var y = 218+i*74
		panel(Rect2(600,y,700,66),Color("1b281e"))
		label_at("DAY %02d · %s" % [entry.day,entry.kind.to_upper()],Vector2(614,y+18),10,RED if entry.kind in ["death","scar"] else GOLD)
		draw_multiline_string(font,Vector2(614,y+37),entry.text,HORIZONTAL_ALIGNMENT_LEFT,668,12,2,PAPER)
	button("history_prev","<",Rect2(600,753,48,30),service_page > 0)
	centered("%d / %d" % [service_page+1,maxi(1,ceili(float(history.size())/7))],Vector2(950,775),12,MUTED)
	button("history_next",">",Rect2(1252,753,48,30),(service_page+1)*7 < history.size())
	label_at("Stat training and perk points are separate; unused points stay banked.",Vector2(140,780),11,MUTED)
	label_at("Levels 2–11: one perk point and three different stat picks each. Open Profile & Growth to choose stats.",Vector2(140,810),12,MUTED)

func _draw_result() -> void:
	draw_rect(Rect2(0, 0, 1440, 900), Color(0.02, 0.04, 0.035, 0.89))
	panel(Rect2(350, 130, 740, 640), Color("1a231d"), GOLD)
	var a: Dictionary = campaign.aftermath
	centered("THE COMPANY CHRONICLE  /  DAY %d" % a.day, Vector2(720, 176), 12, GOLD)
	var title = "You abandon the field." if a.retreat else {"victory":"The company holds.", "defeat":"The line has broken.", "draw":"Night takes the field."}[a.result]
	centered(title, Vector2(720, 228), 30, PAPER, true)
	centered("%d crowns earned  /  %d fallen  /  %d wounded" % [a.pay, a.fallen, a.wounded], Vector2(720, 263), 14, GOLD)
	draw_line(Vector2(390, 286), Vector2(1050, 286), Color("555b42"))
	for i in a.rows.size():
		var row: Dictionary = a.rows[i]
		var y = (310+i*23) if a.rows.size()>6 else (330+i*41)
		label_at(row.name, Vector2(398, y), 16 if a.rows.size()>6 else 19, PAPER, true)
		label_at(row.status, Vector2(600, y), 13, RED if row.status in ["Fallen", "Deep wound"] else BLUE)
		label_at("%d HP" % row.hp, Vector2(843, y), 13, MUTED)
		label_at("+%d XP · Lv%d" % [row.get("xp",0),row.get("level",1)], Vector2(963, y), 13, MUTED)
	centered("%d soldiers remain in the company." % campaign.alive_count(), Vector2(720, 603), 17, PAPER, true)
	centered("Training choices and scars are recorded under Company → Person & Service.", Vector2(720, 634), 12, MUTED)
	var effect_lines = wrapped_lines(a.get("effect", "Deaths, wounds and damage carry into the next contract."), 650, 12, 2)
	for i in effect_lines.size(): centered(effect_lines[i], Vector2(720, 653+i*18), 12, GOLD)
	if a.has("ammunition"):
		var ammo: Dictionary = a.ammunition
		centered("Ammo: +%d looted · %d used · %d reserve · %d needed" % [ammo.looted,ammo.spent,ammo.reserve,ammo.missing],Vector2(720,689),12,RED if ammo.missing > 0 else BLUE)
	button("camp", ("CONTINUE EXPLORING  >" if campaign.aftermath.result == "victory" else "RETURN TO ENTRANCE  >") if campaign.encounter.get("kind") == "dungeon" else "RETURN TO CAMP  >", Rect2(440, 702, 335, 44), true, true)
	button("loot_open","LOOT · %d ITEMS" % a.get("loot",[]).size(),Rect2(790,702,210,44),not a.get("loot",[]).is_empty())
	if save_failed: centered("Autosave failed. Use F5 to retry saving.", Vector2(720, 757), 12, RED)

func _draw_confirmation() -> void:
	draw_rect(Rect2(0, 0, 1440, 900), Color(0.02, 0.04, 0.035, 0.90))
	panel(Rect2(420, 280, 600, 300), Color("1b251e"), GOLD)
	centered(("Retreat to the entrance?" if campaign.encounter.get("kind") == "dungeon" else "Leave this contract?") if confirmation == "retreat" else ("Abandon this contract?" if confirmation == "abandon" else "Found a new company?"), Vector2(720, 340), 28, PAPER, true)
	var lines = ["Surviving soldiers keep their wounds and damaged gear.", "This contract is spent. You receive no payment."] if confirmation in ["retreat", "abandon"] else ["This starts a fresh three-person company and replaces your save.", "The current company's progress will be lost."]
	if confirmation == "retreat" and campaign.encounter.get("kind") == "dungeon": lines = ["Survivors keep their wounds and damaged gear.", "Cleared rooms and enemy losses remain for your return."]
	for i in 2: centered(lines[i], Vector2(720, 388+i*30), 14, MUTED)
	if confirmation == "new": centered("SEED: "+seed_text+"  · type digits to replay / R to roll",Vector2(720,454),13,GOLD)
	button("cancel", "KEEP GOING", Rect2(458, 484, 244, 48))
	button("confirm", "RETREAT" if confirmation == "retreat" else ("ABANDON" if confirmation == "abandon" else "START FRESH"), Rect2(738, 484, 244, 48), confirmation != "new" or int(seed_text) > 0, true)

func _input(event: InputEvent) -> void:
	if iron.input(self,event): return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and world_controls_available() and campaign.region.get("generator") != 3 and campaign.news.pinned != "" and Rect2(52,625,904,62).has_point(event.position): return
	if region_camera.input(self,event): return
	if lineup.input(self,event): return
	if event is InputEventMouseMotion and campaign.phase == "battle":
		hovered = nearest_hex(get_global_mouse_position())
		var id = battle.at(hovered)
		if id >= battle.player_slots(): detail_target = id
	if event is InputEventKey and event.pressed and not event.echo:
		if vault_journal:
			if event.keycode == KEY_ESCAPE: action("vault_close")
			elif event.keycode == KEY_F5: action("save")
			elif event.keycode == KEY_F9: action("load")
			return
		if dungeon_door >= 0 and event.keycode == KEY_ESCAPE:
			action("dungeon_close"); return
		if news_view:
			if event.keycode == KEY_ESCAPE: action("news_close")
			elif event.keycode == KEY_F5: action("save")
			elif event.keycode == KEY_F9: action("load")
			return
		if inspection_view:
			if event.keycode in [KEY_ESCAPE,KEY_I]: action("inspect_close")
			elif event.keycode == KEY_F5: action("save")
			elif event.keycode == KEY_F9: action("load")
			return
		if perks_view:
			if event.keycode == KEY_ESCAPE: perks_view = false; refresh()
			elif event.keycode == KEY_F5: action("save")
			elif event.keycode == KEY_F9: action("load")
			return
		if event.keycode == KEY_ESCAPE: perk_target_mode = ""
		if arms_view or loot_view or salvage_view:
			if event.keycode == KEY_ESCAPE: arms_view = false; loot_view = false; salvage_view = false; refresh()
			elif event.keycode == KEY_F5: action("save")
			elif event.keycode == KEY_F9: action("load")
			return
		if armor_view:
			if event.keycode == KEY_ESCAPE: armor_view = false; refresh()
			elif event.keycode == KEY_F5: action("save")
			elif event.keycode == KEY_F9: action("load")
			return
		if person_view:
			if event.keycode == KEY_ESCAPE: action("person_close")
			elif event.keycode == KEY_F5: action("save")
			elif event.keycode == KEY_F9: action("load")
			return
		if guide_view or planner_view or record_view:
			if event.keycode == KEY_ESCAPE: guide_view = false; planner_view = false; record_view = false
			elif event.keycode == KEY_F5: action("save")
			elif event.keycode == KEY_F9: action("load")
			return
		if bonds_view:
			if event.keycode == KEY_ESCAPE: action("bond_close")
			elif event.keycode == KEY_F5: action("save")
			elif event.keycode == KEY_F9: action("load")
			return
		if tactics_view:
			if event.keycode == KEY_ESCAPE: action("tact_close")
			elif event.keycode == KEY_F5: action("save")
			elif event.keycode == KEY_F9: action("load")
			return
		if service_view:
			if event.keycode == KEY_ESCAPE: action("service_close")
			elif event.keycode == KEY_F5: action("save")
			elif event.keycode == KEY_F9: action("load")
			return
		if politics_view:
			if event.keycode == KEY_ESCAPE: action("politics_close")
			return
		if trade_view:
			if event.keycode == KEY_ESCAPE: action("trade_close")
			return
		if not confirmation.is_empty():
			if event.keycode == KEY_ESCAPE: action("cancel")
			elif confirmation == "new":
				if event.keycode == KEY_R: seed_text = str(fresh_seed()); seed_replace = true
				elif event.keycode == KEY_BACKSPACE: seed_text = seed_text.left(maxi(0,seed_text.length()-1)); seed_replace = false
				elif event.keycode >= KEY_0 and event.keycode <= KEY_9:
					if seed_replace: seed_text = ""; seed_replace = false
					if seed_text.length() < 9: seed_text += str(event.keycode-KEY_0)
				queue_redraw()
			return
		if help or intro:
			if event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_H]: action("begin")
			return
		if event.keycode == KEY_ESCAPE and campaign.phase == "camp" and campaign.region.get("generator") == 3:
			if iron.detail: iron.detail = false
			elif not world_view: world_view = true
			else: iron.sheet = "menu"
			refresh(); return
		match event.keycode:
			KEY_H: action("help")
			KEY_F5: action("save")
			KEY_F9: action("load")
			KEY_N: action("new")
		if world_controls_available():
			match event.keycode:
				KEY_SPACE: action("world_pause")
				KEY_1: action("world_speed_1")
				KEY_2: action("world_speed_2")
				KEY_3: action("world_speed_4")
		if campaign.phase == "battle":
			match event.keycode:
				KEY_I: action("inspect_open")
				KEY_TAB: choose_next()
				KEY_W: action("wait")
				KEY_1: action("guard")
				KEY_2: action("recover")
				KEY_3: action("withdraw")
				KEY_4: action("formations")
				KEY_5: action("combat_details")
				KEY_6: action("weapon_actions")
				KEY_SPACE:
					if battle.individual: action("wait")
					else: choose_next()
				KEY_F: action("end")
				KEY_ENTER:
					if not battle.individual: action("end")
				KEY_ESCAPE: withdraw_mode = false
		refresh()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and world_controls_available():
		action("world_stop")
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p = get_global_mouse_position()
		var allowed = buttons.keys()
		allowed.reverse()
		if news_view: allowed = buttons.keys().filter(func(id):return id.begins_with("news_"))
		elif inspection_view: allowed = buttons.keys().filter(func(id): return id.begins_with("inspect_"))
		elif perks_view: allowed = buttons.keys().filter(func(id): return id.begins_with("perk_"))
		elif not confirmation.is_empty(): allowed = ["confirm", "cancel"]
		elif salvage_view: allowed = buttons.keys().filter(func(id): return id.begins_with("salvage_"))
		elif arms_view: allowed = buttons.keys().filter(func(id): return id.begins_with("arms_") or id.begins_with("wa_"))
		elif loot_view: allowed = buttons.keys().filter(func(id): return id.begins_with("loot_"))
		elif armor_view: allowed = buttons.keys().filter(func(id): return id.begins_with("arm_"))
		elif person_view: allowed = buttons.keys().filter(func(id): return id.begins_with("person_") or id.begins_with("grow_"))
		elif guide_view: allowed = ["guide_close","guide_toggle"]
		elif planner_view: allowed = buttons.keys().filter(func(id): return id.begins_with("plan_"))
		elif record_view: allowed = ["record_close","record_prev","record_next"]
		elif bonds_view: allowed = buttons.keys().filter(func(id): return id.begins_with("bond_"))
		elif tactics_view: allowed = buttons.keys().filter(func(id): return id.begins_with("tact_"))
		elif service_view: allowed = buttons.keys().filter(func(id): return id in ["service_close","history_prev","history_next","person_open","personal_perks"] or id.begins_with("learn_"))
		elif politics_view: allowed = buttons.keys().filter(func(id): return id == "politics_close" or id.begins_with("fund_") or id.begins_with("report_"))
		elif trade_view: allowed = buttons.keys().filter(func(id): return id in ["trade_close", "trade_prev", "trade_next"] or id.begins_with("inspect_") or id.begins_with("report_"))
		elif intro or help: allowed = ["begin"]
		elif campaign.phase == "aftermath": allowed = ["camp","loot_open"]
		# Small moving markers remain selectable on top of larger site hit areas.
		# Panels and modal controls retain priority; among markers choose the nearest.
		if world_controls_available() and campaign.region.get("generator") == 3:
			var marker: String = region_camera.marker_at(self,p)
			if not marker.is_empty():
				if buttons[marker].enabled: action(marker)
				return
		if world_controls_available() and campaign.region.get("generator") != 3:
			var markers = allowed.filter(func(id): return (id.begins_with("scout_") or id.begins_with("convoy_") or id.begins_with("trace_") or id.begins_with("guard_open_") or id.begins_with("footprint_")) and buttons[id].rect.has_point(p))
			var control_hit = allowed.any(func(id): return id not in markers and not id.begins_with("place_") and buttons.has(id) and buttons[id].rect.has_point(p))
			if not control_hit and not markers.is_empty():
				markers.sort_custom(func(a,b):
					var da: float = buttons[a].rect.get_center().distance_squared_to(p); var db: float = buttons[b].rect.get_center().distance_squared_to(p)
					if not is_equal_approx(da,db): return da < db
					# At a shared mooring, freight remains selectable beside its guard.
					return (0 if a.begins_with("scout_") else 1 if a.begins_with("convoy_") else 2) < (0 if b.begins_with("scout_") else 1 if b.begins_with("convoy_") else 2))
				if buttons[markers[0]].enabled: action(markers[0])
				return
		for id in allowed:
			if buttons.has(id) and buttons[id].rect.has_point(p):
				if buttons[id].enabled: action(id)
				return
		if world_controls_available() and (region_camera.RECT if campaign.region.get("generator") == 3 else Rect2(40,216,928,480)).has_point(p):
			if campaign.region.get("generator") == 3 and iron.detail and Rect2(1008,116,408,746).has_point(p): return
			if campaign.begin_travel(region_camera.screen_to_world(p) if campaign.region.get("generator") == 3 else p): world_selected = ""; write_save(false)
			else: tell("No route there. Use a river crossing; escorts must clear their ambush.")
			refresh(); return
		if campaign.phase != "battle" or not confirmation.is_empty() or intro or help or tactics_view or guide_view or record_view or arms_view or loot_view or salvage_view or inspection_view: return
		var h = nearest_hex(p)
		if h.x < 0: return
		var clicked = battle.at(h)
		if battle.side != 0:
			if clicked >= 0 and battle.units[clicked].side == 0:
				inspected = clicked
				if event.double_click: action("inspect_open")
				refresh()
			return
		if not perk_target_mode.is_empty():
			if battle.use_perk(selected,perk_target_mode,h): perk_target_mode = ""; write_save(false)
			else: tell(battle.perk_action_reason(selected,perk_target_mode,h))
			refresh(); return
		var target = battle.at(h)
		if target >= 0 and battle.units[target].side == 0:
			if battle.individual:
				inspected = target
				if event.double_click: action("inspect_open")
				if target != battle.active_id: tell(battle.units[target].name+" acts when their portrait reaches the front of the queue.")
			else: selected = target
			weapon_special = false
			withdraw_mode = false
		elif selected >= 0:
			if target >= 0:
				if battle.attack(selected, target):
					flash_id = target
					flash_time = 0.24
				else: tell(battle.attack_block_reason(selected,target))
			elif withdraw_mode:
				if battle.withdraw(selected, h): withdraw_mode = false
				else: tell("Choose an empty adjacent tile. Withdrawal costs 4 AP.")
			elif not battle.move_unit(selected, h):
				tell(battle.movement_block_reason(selected,h))
		refresh()

func write_save(show_notice: bool = true) -> bool:
	if autosim or (perk_lab_mode and not show_notice): return true
	observe_guide()
	# A final hit can finish the model between input and the next process frame.
	# Never persist a completed battle with an unsettled campaign phase.
	if campaign.phase == "battle" and not battle.result.is_empty():
		if not campaign.resolve_battle():
			save_failed = true
			tell("Battle settlement failed; current progress remains in memory.")
			return false
		arms_view = false; weapon_special = false
	var data = campaign.snapshot()
	data["guide"] = guide.snapshot()
	data["selected"] = selected
	data["camp_selected"] = camp_selected
	var save_path = PERK_LAB_SAVE_PATH if perk_lab_mode else SAVE_PATH
	var temp_path = save_path+".tmp"
	var file = FileAccess.open(temp_path, FileAccess.WRITE)
	var ok = file != null
	if file:
		file.store_string(JSON.stringify(data,"",false,true))
		file.flush()
		ok = file.get_error() == OK
		file.close()
	if ok: ok = DirAccess.rename_absolute(temp_path, save_path) == OK
	save_failed = not ok
	if show_notice or not ok: tell("Company saved." if ok else "Save failed. Current progress is still in memory.")
	return ok

func action(id: String) -> void:
	if iron.action(self,id): refresh(); return
	if id.begins_with("vault_"):
		if campaign.phase != "camp": return
		if id == "vault_journal":
			vault_journal = true; vault_page = 0
			var rows = VaultJournal.Journal.entries(campaign)
			if rows.any(func(r):return r.id == world_selected): expedition_view.site = world_selected
			var sites = rows.map(func(r):return r.id)
			if expedition_view.site in sites: vault_page = sites.find(expedition_view.site)/5
		elif id == "vault_close": vault_journal = false
		elif id == "vault_prev": vault_page = maxi(0,vault_page-1)
		elif id == "vault_next": vault_page += 1
		elif id.begins_with("vault_locate_"):
			var site = id.trim_prefix("vault_locate_")
			if campaign.dungeons.active == "" and known_site(site):
				world_selected = site; world_view = true; vault_journal = false
				if campaign.region.get("generator") == 3:
					region_camera.region_seed = campaign.region.seed
					region_camera.follow = false; region_camera.center = campaign.overworld.places[site]; region_camera.bound(campaign)
		else: VaultJournal.action(self,id)
		refresh(); return
	if id == "news_journal" or id.begins_with("news_"):
		if id == "news_journal": news_view = true; news_tab = "reports"; news_page = 0; news_destination = campaign.news.pinned
		elif id == "news_close": news_view = false
		elif id == "news_reports": news_tab = "reports"; news_page = 0; news_destination = ""
		elif id == "news_routes": news_tab = "routes"; news_page = 0; news_destination = ""
		elif id == "news_prev": news_page = maxi(0,news_page-1)
		elif id == "news_next": news_page += 1
		elif id == "news_ask":
			var heard = campaign.hear_regional_news()
			if heard >= 0: tell("%d new or updated reports recorded." % heard); write_save(false)
		elif id == "news_other":
			var site = campaign.exploration.hear_rumour(campaign)
			if site != "": news_view = false; tell("Search area marked for "+campaign.node(site).name); write_save(false)
			else: tell("No further discovery rumours here.")
		elif id.begins_with("news_directions_"):
			var town = id.trim_prefix("news_directions_").get_slice("#",0)
			if campaign.news.directions.has(town): news_destination = town
		elif id == "news_back": news_destination = ""
		elif id == "news_bookmark":
			if campaign.news.directions.has(news_destination):
				campaign.news.pinned = "" if campaign.news.pinned == news_destination else news_destination
				write_save(false)

		refresh(); return
	if region_camera.action(self,id): return
	if id.begins_with("report_"):
		if id == "report_towns_prev": report_towns_page = maxi(0,report_towns_page-1)
		if id == "report_towns_next": report_towns_page += 1
		if id == "report_camps_prev": report_camps_page = maxi(0,report_camps_page-1)
		if id == "report_camps_next": report_camps_page += 1
		refresh(); return
	if lineup.action(self,id): refresh(); return
	if id == "queue_prev": queue_page = maxi(0,queue_page-1); refresh(); return
	if id == "queue_next": queue_page += 1; refresh(); return
	if inspection_view and not id.begins_with("inspect_") and not id in ["save","load"]: return
	if campaign.phase == "battle" and id.begins_with("inspect_"):
		if id == "inspect_open":
			var target = inspected if inspected >= 0 else selected
			var hover = battle.at(hovered)
			if hover >= 0 and battle.units[hover].side == 0: target = hover
			if target < 0 or target >= battle.player_slots() or campaign.deployment[target] < 0: target = campaign.deployment.find(campaign.deployment.filter(func(sid): return sid >= 0)[0])
			if target >= 0 and target < battle.player_slots() and campaign.deployment[target] >= 0:
				inspection_id = target; inspection_view = true; inspection_tab = "stats"; inspection_page = 0
		elif id == "inspect_close": inspection_view = false
		elif id.begins_with("inspect_tab_"): inspection_tab = id.trim_prefix("inspect_tab_"); inspection_page = 0
		elif id == "inspect_prev": inspection_page = maxi(0,inspection_page-1)
		elif id == "inspect_next": inspection_page += 1
		elif id.begins_with("inspect_unit_"): inspection_id = int(id.trim_prefix("inspect_unit_")); inspection_page = 0
		refresh(); return
	planning_cache.clear()
	if FootprintView.action(self,id): refresh(); return
	if RecoveryView.action(self,id): refresh(); return
	if GuardView.action(self,id): refresh(); return
	if FarmView.action(self,id): refresh(); return
	if TrafficView.action(self,id): refresh(); return
	if id.begins_with("dungeon_"):
		var changed = false
		if id == "dungeon_close": dungeon_door = -1
		elif id == "dungeon_rumour":
			var site = campaign.dungeon_rumour()
			if site != "":
				if known_site(site): world_selected = site
				changed = true
			else: tell("No further burial rumours here.")
		elif id.begins_with("dungeon_choice_"): changed = campaign.dungeon_choice(id.trim_prefix("dungeon_choice_"))
		elif id == "dungeon_enter": changed = campaign.enter_dungeon(world_selected)
		elif id == "dungeon_leave": changed = campaign.leave_dungeon(); world_selected = campaign.location; dungeon_door = -1
		elif id.begins_with("dungeon_room_"):
			var target = int(id.trim_prefix("dungeon_room_")); dungeon_door = -1
			if campaign.inspect_vault(target): dungeon_door = target; changed = true
			else: changed = campaign.dungeon_move(target)
		elif id.begins_with("dungeon_unlock_"):
			changed = campaign.unlock_vault(int(id.trim_prefix("dungeon_unlock_")))
			if changed: dungeon_door = -1
		elif id == "dungeon_down": changed = campaign.dungeon_stairs(true)
		elif id == "dungeon_up": changed = campaign.dungeon_stairs(false)
		elif id == "dungeon_search": changed = campaign.dungeon_search()
		elif id == "dungeon_rest": changed = campaign.dungeon_rest()
		if changed: world_view = true; write_save(false)
		refresh(); return
	if id.begins_with("explore_"):
		var changed = false
		if id == "explore_rumour":
			if campaign.economy.enabled:
				var heard = campaign.hear_regional_news()
				if heard >= 0: news_view = true; news_tab = "reports"; news_page = 0; news_destination = ""; write_save(false)
				refresh(); return
			if not campaign.traffic.rumour(campaign).is_empty():
				tell("Missing caravan reported. Search the marked area."); write_save(false); refresh(); return
			var site = campaign.exploration.hear_rumour(campaign)
			changed = not site.is_empty()
			tell("Search area marked for "+campaign.node(site).name if changed else "No new rumours here.")
		elif id == "explore_cancel": campaign.exploration.cancel(campaign); campaign.overworld.paused = true; changed = true
		elif id in ["explore_scout","explore_search"]: changed = campaign.exploration.begin(campaign,world_selected,id.trim_prefix("explore_"))
		if changed: write_save(false)
		refresh(); return
	if id.begins_with("world_speed_"):
		campaign.overworld.speed = int(id.trim_prefix("world_speed_")); refresh(); return
	if id == "world_pause":
		if campaign.dungeons.active == "" and campaign.encounter.is_empty() and not campaign.over(): campaign.overworld.paused = not campaign.overworld.paused
		refresh(); return
	if id in ["recon_watch","recon_stop"]:
		if id == "recon_watch": campaign.recon.begin(campaign,world_selected)
		else: campaign.recon.watch.clear(); campaign.overworld.paused = true
		write_save(false); refresh(); return
	if id == "world_stop":
		campaign.traffic.cancel_follow(campaign.overworld)
		campaign.recon.watch.clear()
		campaign.traffic.pursuit = ""
		campaign.exploration.cancel(campaign)
		campaign.overworld.path.clear(); campaign.overworld.destination = ""; campaign.overworld.rest_left = 0; campaign.overworld.paused = true
		refresh(); return
	if id.begins_with("scout_"):
		var scout = campaign.overworld.scouts.get(id.trim_prefix("scout_"),{})
		if not scout.is_empty() and not scout.defeated and scout.position.distance_to(campaign.overworld.position) <= campaign.overworld.sight() and campaign.begin_travel(scout.position):
			world_selected = ""
			if campaign.bandits.enabled:
				campaign.traffic.pursuit = scout.id; world_selected = "band:"+scout.id
		refresh(); return
	if id == "attack_camp":
		if campaign.attack_camp():
			battle = campaign.battle; bind_battle(); selected = 0; intro = true; write_save(false)
		refresh(); return
	if id in ["personal_perks","person_perks"]:
		if id == "personal_perks": person_offer = ""
		perks_view = true; perk_choice = ""; perk_filter = "All"; refresh(); return
	if id.begins_with("perk_"):
		if id == "perk_close": perks_view = false
		elif id.begins_with("perk_subject_") and perk_lab_mode:
			camp_selected = int(id.trim_prefix("perk_subject_")); person_offer = ""; perk_choice = ""; perk_filter = "All"
		elif id.begins_with("perk_cohort_") and perk_lab_mode:
			ranged_lab = id == "perk_cohort_ranged"
			for i in 3:
				if ranged_lab: RangedTrials.apply_build(campaign,i,i*3)
				else: PerkTrials.apply_build(campaign,i,i*3)
			perk_choice = ""; perk_filter = "All"
		elif id.begins_with("perk_preset_") and perk_lab_mode:
			if ranged_lab: RangedTrials.apply_build(campaign,camp_selected,int(id.trim_prefix("perk_preset_")))
			else: PerkTrials.apply_build(campaign,camp_selected,int(id.trim_prefix("perk_preset_")))
			perk_choice = ""
		elif id == "perk_reset" and perk_lab_mode:
			var s: Dictionary = campaign.soldiers[camp_selected]
			for attr in s.gifted_choices: s[People.FIELDS[attr]] -= Perks.GIFT[attr]
			s.perks = []; s.gifted_choices = []; s.hp = mini(s.hp,campaign.max_hp(s))
		elif id.begins_with("perk_select_"): perk_choice = id.trim_prefix("perk_select_")
		elif id.begins_with("perk_group_"): perk_filter = id.trim_prefix("perk_group_")
		elif id == "perk_buy" and person_offer.is_empty():
			if campaign.learn_perk(camp_selected,perk_choice): write_save(false)
		elif id.begins_with("perk_gift_") and person_offer.is_empty():
			if campaign.choose_gift(camp_selected,id.trim_prefix("perk_gift_")): write_save(false)
		refresh(); return
	if id == "guide": guide_view = true
	elif id == "guide_close": guide_view = false
	elif id == "guide_toggle":
		guide.enabled = not guide.enabled
		write_save(false)
	elif id == "planner": planner_view = true
	elif id == "plan_close": planner_view = false
	elif id == "plan_rest":
		if campaign.begin_rest():
			planner_view = false; world_view = true; world_selected = ""; write_save(false)
	elif id.begins_with("plan_unit_"):
		camp_selected = int(id.trim_prefix("plan_unit_"))
		planner_view = false
		world_view = false
		roll_page = campaign.roll_ids().find(camp_selected)/6
	elif id == "record": record_view = true; record_page = 0
	elif id == "record_close": record_view = false
	elif id == "record_prev": record_page = maxi(0,record_page-1)
	elif id == "record_next": record_page += 1
	elif id == "resources":
		salvage_view = true; salvage_mode = "resources"; sale_confirmation = -1
	elif id == "salvage_open":
		salvage_view = true; salvage_choice = ""; salvage_page = 0; sale_confirmation = -1
	elif id.begins_with("salvage_"):
		if salvage_action(id): write_save(false)
	elif id == "loadout": open_armory()
	elif id == "weapon_actions":
		arms_view = true; weapon_special = false
	elif id == "loot_open": loot_view = true; loot_page = 0
	elif id == "loot_close": loot_view = false
	elif id == "loot_prev": loot_page = maxi(0,loot_page-1)
	elif id == "loot_next": loot_page += 1
	elif id.begins_with("arms_"):
		if armory_action(id): write_save(false)
	elif id.begins_with("wa_"): weapon_ui_action(id)
	elif id == "save": write_save()
	elif id == "load":
		if not FileAccess.file_exists(PERK_LAB_SAVE_PATH if perk_lab_mode else SAVE_PATH): tell("No company save yet. Use F5 to create one.")
		else:
			var data = JSON.parse_string(FileAccess.get_file_as_string(PERK_LAB_SAVE_PATH if perk_lab_mode else SAVE_PATH))
			if campaign.restore(data):
				news_view = false; news_page = 0
				campaign.enable_economy()
				battle = campaign.battle
				bind_battle()
				guide.restore(data.get("guide"))
				guide_view = false
				planner_view = false
				record_view = false
				seed_number = campaign.seed_value
				selected = clampi(int(data.get("selected", 0)), 0, battle.units.size()-1)
				camp_selected = clampi(int(data.get("camp_selected", 0)), 0, campaign.soldiers.size()-1)
				world_selected = campaign.location
				trade_view = false
				politics_view = false
				inspection_view = false; arms_view = false; loot_view = false; salvage_view = false; weapon_special = false
				armor_view = false
				person_view = false; person_offer = ""; perk_choice = ""; perk_filter = "All"
				perks_view = perks_view and campaign.phase == "camp"
				if perk_lab_mode: ranged_lab = "Marksman" in campaign.soldiers[0].get("perk_groups",[])
				growth_selection.clear()
				perks_view = false; perk_choice = ""; perk_filter = "All"; perk_target_mode = ""
				service_view = false
				bonds_view = false
				service_page = 0
				tactics_view = false
				formation_selection.clear()
				job_page = 0
				roll_page = 0
				withdraw_mode = false
				help = false
				confirmation = ""
				stash_page = 0
				tell("Company restored: roster, gear, wounds and battle.")
			else: tell("Invalid company save. Current progress kept.")
	elif id == "continue_campaign":
		if campaign.continue_campaign():
			campaign.enable_economy(); world_view = true; world_selected = campaign.location
	elif id in ["new", "new_top"]:
		confirmation = "new"
		seed_text = str(fresh_seed())
		seed_replace = true
	elif id == "abandon": confirmation = "abandon"
	elif id == "retreat" and campaign.phase == "battle" and battle.side == 0:
		confirmation = "retreat"
		guide.mark("retreat")
	elif id == "cancel": confirmation = ""
	elif id == "confirm":
		if confirmation == "new":
			if int(seed_text) <= 0: return
			seed_number = int(seed_text)
			region_camera.region_seed = -1; report_towns_page = 0; report_camps_page = 0; news_view = false; news_page = 0
			campaign.setup(seed_number,-1 if "--smoke" in OS.get_cmdline_user_args() else seed_number,"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),false,"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args(),"--smoke" not in OS.get_cmdline_user_args())
			if "--smoke" not in OS.get_cmdline_user_args(): campaign.enable_dungeons()
			battle = campaign.battle
			bind_battle()
			guide = Playability.new()
			guide_view = false
			planner_view = false
			record_view = false
			selected = 0
			camp_selected = 0
			stash_page = 0
			world_view = true
			world_selected = campaign.location
			trade_view = false
			politics_view = false
			arms_view = false; loot_view = false; salvage_view = false; weapon_special = false
			armor_view = false
			person_view = false
			growth_selection.clear()
			perks_view = false; perk_choice = ""; perk_filter = "All"; perk_target_mode = ""
			service_view = false
			bonds_view = false
			service_page = 0
			tactics_view = false
			formation_selection.clear()
			job_page = 0
			roll_page = 0
		elif confirmation == "abandon": campaign.abandon_job()
		elif confirmation == "retreat": campaign.retreat_from_battle()
		confirmation = ""
		write_save(false)
	elif id == "begin":
		intro = false
		help = false
	elif id == "help": help = true
	elif id == "camp":
		if campaign.return_to_camp():
			campaign.enable_economy()
			world_view = campaign.dungeons.active != "" or campaign.dungeons.sites.has(campaign.location)
			world_selected = campaign.location
			for s in campaign.soldiers:
				if s.alive:
					camp_selected = s.id
					break
			write_save(false)
	elif campaign.phase == "camp":
		var changed = false
		if id.begins_with("arm_"):
			changed = armor_action(id)
		elif id == "bonds":
			bonds_view = true
			bond_partner = -1
			bond_page = 0
			bond_roll_page = 0
		elif id == "bond_close": bonds_view = false
		elif id == "bond_service": bonds_view = false; service_view = true; service_page = 0
		elif id == "bond_prev": bond_page = maxi(0,bond_page-1)
		elif id == "bond_next": bond_page += 1
		elif id == "bond_roll_prev": bond_roll_page = maxi(0,bond_roll_page-1)
		elif id == "bond_roll_next": bond_roll_page += 1
		elif id.begins_with("bond_partner_"): bond_partner = int(id.trim_prefix("bond_partner_")); bond_page = 0
		elif id.begins_with("bond_decide_"):
			changed = campaign.camp_decision(id.trim_prefix("bond_decide_"),camp_selected,bond_partner)
		elif id == "person_open": person_offer = ""; growth_selection.clear(); person_view = true
		elif id == "person_close": person_view = false; growth_selection.clear()
		elif id.begins_with("person_offer_"): person_offer = id.trim_prefix("person_offer_"); growth_selection.clear(); person_view = true
		elif id == "person_hire":
			changed = campaign.hire(person_offer)
			if changed: person_view = false; camp_selected = campaign.soldiers.size()-1
		elif id == "person_train":
			changed = campaign.develop(camp_selected,growth_selection)
			if changed: growth_selection.clear()
		elif id == "person_clear": growth_selection.clear()
		elif id.begins_with("grow_"):
			var attr = id.trim_prefix("grow_")
			var soldier: Dictionary = campaign.soldiers[camp_selected]
			var index = Progression.pending(soldier)
			if attr in growth_selection: growth_selection.erase(attr)
			elif index >= 0 and growth_selection.size() < 3-soldier.training[index].size(): growth_selection.append(attr)
		elif id == "service":
			service_view = true
			service_page = 0
		elif id == "service_close": service_view = false
		elif id == "history_prev": service_page = maxi(0,service_page-1)
		elif id == "history_next": service_page += 1
		elif id.begins_with("learn_"): changed = campaign.learn_perk(camp_selected,id.trim_prefix("learn_"))
		elif id == "politics" or id.begins_with("patrol_"): politics_view = true
		elif id == "politics_close": politics_view = false
		elif id.begins_with("fund_"): changed = campaign.sponsor_patrol(id.trim_prefix("fund_"))
		elif id == "trade": trade_view = true
		elif id == "trade_close": trade_view = false
		elif id == "trade_prev": trade_page = maxi(0, trade_page-1)
		elif id == "trade_next": trade_page += 1
		elif id.begins_with("inspect_"): trade_selected = id.trim_prefix("inspect_")
		elif id.begins_with("convoy_"):
			trade_selected = id.trim_prefix("convoy_")
			trade_page = campaign.world.caravans.keys().find(trade_selected)/6
			trade_view = true
		elif id == "jobs_prev": job_page = maxi(0, job_page-1)
		elif id == "jobs_next": job_page += 1
		elif id == "escort_move":
			changed = campaign.begin_travel(campaign.overworld.places[campaign.next_escort_stop()],campaign.next_escort_stop())
			world_selected = campaign.location
		elif id in ["world", "world_camp"]:
			world_view = true
			world_selected = campaign.location
		elif id == "company": world_view = false
		elif id.begins_with("place_"): world_selected = id.trim_prefix("place_")
		elif id in ["contracts", "recruits"]: town_tab = id
		elif id == "travel":
			changed = campaign.begin_travel(campaign.overworld.places[world_selected],world_selected)
			if not changed: tell("Travel refused. Escorts must follow their route and defeat the ambush.")
		elif id.begins_with("accept_"):
			changed = campaign.accept_job(id.trim_prefix("accept_"))
		elif id.begins_with("hire_"):
			changed = campaign.hire(id.trim_prefix("hire_"))
			if changed: tell("New recruit joins. Select Company to equip them.")
			else: tell("Cannot hire: company limit is %d, or insufficient crowns." % campaign.company_limit())
		elif id == "roll_prev": roll_page = maxi(0, roll_page-1)
		elif id == "roll_next": roll_page += 1
		elif id.begins_with("camp_unit_"):
			camp_selected = int(id.trim_prefix("camp_unit_"))
			stash_page = 0
		elif id.begins_with("slot_"):
			gear_slot = id.trim_prefix("slot_")
			stash_page = 0
			if gear_slot in ["body","head"]: open_armor(gear_slot)
			else: open_armory(gear_slot)
		elif id.begins_with("equip_"):
			if gear_slot in ["body","head"]:
				open_armor(gear_slot,"kits")
				armor_choice = id.trim_prefix("equip_")
			else: changed = campaign.equip(camp_selected, id.trim_prefix("equip_"))
			if not changed: tell("Cannot equip that item. Bows need both hands.")
		elif id == "unequip":
			if gear_slot in ["body","head"]: open_armor(gear_slot,"kits"); armor_choice = "__remove__"
			else: changed = campaign.unequip(camp_selected,gear_slot)
		elif id == "temple":
			changed = campaign.temple(camp_selected)
		elif id == "repair":
			changed = campaign.repair(camp_selected)
			if not changed: tell("No repairs needed, or this soldier cannot repair equipment.")
		elif id == "rest":
			changed = campaign.begin_rest()
			if changed: world_view = true; world_selected = ""
			if not changed: tell("The company can no longer rest.")
		elif id in ["buy_tools", "buy_medicine", "buy_food", "buy_ammo"]:
			changed = campaign.buy_supply(id.trim_prefix("buy_"))
			if not changed: tell("Purchase refused: insufficient town stock, money, or no market.")
		elif id == "stash_prev": stash_page = maxi(0, stash_page-1)
		elif id == "stash_next": stash_page += 1
		elif id == "deploy":
			changed = campaign.deploy()
			if changed:
				battle = campaign.battle
				bind_battle()
				selected = 0
				if not battle.living(battle.units[0]): choose_next()
				withdraw_mode = false
				intro = true
		if changed:
			write_save(false)
			if campaign.over(): world_view = true
	elif campaign.phase == "battle" and battle.side == 0 and (id in ["formations","combat_details"] or id.begins_with("tact_")):
		if id in ["formations","combat_details"]:
			tactics_view = true
			tactics_tab = "orders" if id == "formations" else "odds"
			formation_selection = formation_selection.filter(func(unit): return battle.fighting(battle.units[unit]))
			if formation_selection.is_empty() and selected >= 0 and battle.fighting(battle.units[selected]): formation_selection = [selected]
		elif id == "tact_close": tactics_view = false
		elif id == "tact_orders": tactics_tab = "orders"
		elif id == "tact_odds": tactics_tab = "odds"
		elif id == "tact_all": formation_selection = battle.units.filter(func(u): return u.side == 0 and battle.fighting(u) and (not battle.individual or battle.can_act(u.id))).map(func(u): return u.id)
		elif id == "tact_line_gear": formation_selection = battle.units.filter(func(u): return u.side == 0 and battle.fighting(u) and (not battle.individual or battle.can_act(u.id)) and (u.shield or Arsenal.family(u.weapon) == "spear")).map(func(u): return u.id)
		elif id == "tact_none": formation_selection.clear()
		elif id.begins_with("tact_unit_"):
			var unit = int(id.trim_prefix("tact_unit_"))
			if unit in formation_selection: formation_selection.erase(unit)
			else: formation_selection.append(unit)
		elif id.begins_with("tact_enemy_"): detail_target = int(id.trim_prefix("tact_enemy_"))
		elif id.begins_with("tact_dir_"): formation_direction = int(id.trim_prefix("tact_dir_"))
		elif id == "tact_advance": battle.advance_group(formation_selection,formation_direction)
		elif id.begins_with("tact_order_"): battle.set_order(formation_selection,id.trim_prefix("tact_order_"))
	elif id.begins_with("unit") and campaign.phase == "battle":
		if battle.individual: inspected = int(id.trim_prefix("unit"))
		else: selected = int(id.trim_prefix("unit"))
		weapon_special = false
		withdraw_mode = false
	elif id.begins_with("queue_") and campaign.phase == "battle":
		inspected = int(id.trim_prefix("queue_"))
		detail_target = inspected; weapon_target = inspected
	elif campaign.phase == "battle" and battle.side == 0 and battle.result.is_empty():
		match id:
			"guard":
				if not battle.guard_unit(selected): tell("Shieldwall requires a working shield." if battle.core_rules and not battle.units[selected].shield else "Need 4 AP and %d free fatigue; cannot guard twice." % battle.guard_fatigue(battle.units[selected]))
			"recover":
				if not battle.recover(selected): tell(battle.recover_reason(selected))
			"withdraw":
				if selected < 0 or not battle.can_act(selected): return
				if battle.adjacent_enemies(battle.units[selected],battle.pos(battle.units[selected])).is_empty():
					withdraw_mode = false
					tell("No adjacent enemy. Use ordinary movement.")
				elif battle.units[selected].ap < 4 or battle.units[selected].fatigue+12 > battle.fatigue_max(battle.units[selected]):
					withdraw_mode = false
					tell("Withdraw needs 4 AP and 12 free fatigue.")
				else:
					withdraw_mode = not withdraw_mode
					if withdraw_mode: tell("Click an adjacent empty tile. Each adjacent foe gets a strike.")
			"wait":
				if battle.wait_unit(selected): sync_active()
			"finish":
				battle.finish_unit(selected)
				choose_next()
			"end":
				withdraw_mode = false
				battle.end_turn()
	refresh()

func choose_next() -> void:
	if battle.individual:
		selected = battle.active_id; inspected = -1; withdraw_mode = false; perk_target_mode = ""; refresh(); return
	for i in range(1, 7):
		var candidate = (maxi(selected, 0)+i) % 6
		if battle.living(battle.units[candidate]) and battle.units[candidate].ap > 0:
			selected = candidate
			break
	withdraw_mode = false
	refresh()

func tell(message: String) -> void:
	notice = message
	notice_time = 4.0

func bind_battle() -> void:
	iron.sheet = ""; iron.detail = false; iron.town_page = "home"
	vault_journal = false; dungeon_door = -1
	lineup.opened = false; lineup.selected = -1; queue_page = 0
	weapon_target = battle.player_slots(); detail_target = battle.player_slots()
	observed_active = -99; inspected = -1
	if not battle.combat_feedback.is_connected(on_combat_feedback): battle.combat_feedback.connect(on_combat_feedback)
	feedback_popups.clear()
	observed_commands = battle.commands.size()

func observe_guide() -> void:
	if campaign.phase != "battle": return
	while observed_commands < battle.commands.size():
		guide.observe_command(battle.commands[observed_commands],battle)
		observed_commands += 1

func on_combat_feedback(event: Dictionary) -> void:
	var popup = event.duplicate(true)
	popup["life"] = 2.8
	feedback_popups.append(popup)
	while feedback_popups.size() > 24: feedback_popups.pop_front()
	if event.kind == "hit": flash_id = event.id; flash_time = 0.24

func _draw_feedback() -> void:
	var counts = {}
	var occupied: Array = []
	for i in range(feedback_popups.size()-1,-1,-1):
		var popup: Dictionary = feedback_popups[i]
		var id: int = popup.id
		if popup.kind == "gap" and battle.line_support(battle.units[id]) > 0: continue
		var count: int = counts.get(id,0)
		if count >= 2: continue
		counts[id] = count+1
		var point = hex_center(battle.pos(battle.units[id]))+Vector2(0,-42-count*20-(2.8-popup.life)*5)
		var color = BLUE if popup.kind == "recover" else (GOLD if popup.kind in ["miss","gap"] else RED)
		var caption: String = popup.text
		var width = font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x+12
		point.x = clampf(point.x,35+width/2,1050-width/2)
		var placed = false
		for shift in 20:
			var candidate = point+Vector2(0,((shift+1)/2)*21*(-1 if shift%2 == 1 else 1))
			var rect = Rect2(candidate-Vector2(width/2,14),Vector2(width,19))
			if rect.position.y < 150 or rect.end.y > 650 or occupied.any(func(other): return other.intersects(rect.grow(2))): continue
			occupied.append(rect)
			point = candidate
			placed = true
			break
		if not placed: continue
		panel(Rect2(point-Vector2(width/2,14),Vector2(width,19)),Color("101815"),color.darkened(0.5))
		centered(caption,point,10,color)

func _draw_playability_buttons() -> void:
	if campaign.phase == "camp" and campaign.region.get("generator") == 3:
		if not world_view and not (person_view or armor_view or arms_view or salvage_view or perks_view or bonds_view or service_view):
			button("planner","Recovery plan",Rect2(30,851,300,32))
			button("vault_journal","Expeditions",Rect2(1200,851,215,32))
		return
	if campaign.economy.enabled and world_controls_available(): button("news_journal","LEAD JOURNAL",Rect2(790,795,185,32))
	if campaign.dungeons.active != "": return
	if intro or help or not confirmation.is_empty() or armor_view or arms_view or loot_view or person_view or bonds_view or service_view or politics_view or trade_view or tactics_view: return
	button("guide","First contract" if guide.enabled and campaign.completed == 0 else "Field guide",Rect2(950,29,148,41),true,guide.enabled and campaign.completed == 0)
	if campaign.phase == "camp": button("planner","COMPANY PLAN",Rect2(790,755,185,28) if world_view else Rect2(30,851,300,32),true,true)
	elif campaign.phase == "battle":
		button("record","Battle record",Rect2(1250,733,155,25))
		if guide.enabled and campaign.completed == 0:
			var lesson = guide.lesson(campaign)
			panel(Rect2(1084,761,328,85))
			label_at(lesson.title.left(36),Vector2(1095,780),12,GOLD)
			var lines = wrapped_lines(lesson.text,305,10,3)
			for i in lines.size(): label_at(lines[i],Vector2(1095,799+i*14),10,PAPER)
	if guide.enabled and campaign.phase == "camp" and world_view and campaign.completed == 0:
		var lesson = guide.lesson(campaign)
		panel(Rect2(25,753,760,107),Color("17271e"),GOLD)
		label_at(lesson.title,Vector2(44,778),16,GOLD)
		var lines = wrapped_lines(lesson.text,715,12,3)
		for i in lines.size(): label_at(lines[i],Vector2(44,802+i*18),12,PAPER)
	if guide.enabled and not guide_view and not planner_view and campaign.completed == 0:
		var target: String = guide.lesson(campaign).target
		if buttons.has(target): draw_rect(buttons[target].rect.grow(3),GOLD,false,2)

	if campaign.phase == "camp": button("vault_journal","EXPEDITIONS",Rect2(585,755,190,28) if world_view else Rect2(1200,851,215,32))

func _draw_guide() -> void:
	draw_rect(Rect2(0,0,1440,900),Color(0.02,0.04,0.025,0.94))
	panel(Rect2(285,145,870,610),Color("17231b"),GOLD)
	var lesson = guide.lesson(campaign)
	label_at("FIRST CONTRACT · OPTIONAL · REAL COMPANY RULES",Vector2(320,190),12,GOLD)
	label_at(lesson.title,Vector2(320,242),28,PAPER,true)
	var lines = wrapped_lines(lesson.text,780,18,6)
	for i in lines.size(): label_at(lines[i],Vector2(320,291+i*28),18,PAPER)
	label_at("Practised: "+(", ".join(guide.learned) if not guide.learned.is_empty() else "none yet"),Vector2(320,493),13,BLUE)
	label_at("Progress follows successful commands. Pausing this guide gives no free actions.",Vector2(320,531),13,MUTED)
	label_at("Retreat lesson records reviewing its confirmation, not abandoning the company.",Vector2(320,557),12,MUTED)
	button("guide_toggle","HIDE HINTS" if guide.enabled else "SHOW HINTS",Rect2(320,615,300,48))
	button("guide_close","RETURN TO PLAY / ESC",Rect2(642,615,477,48),true,true)
	label_at("The guide can be reopened any time. F5/F9 preserve its progress.",Vector2(320,710),12,MUTED)

func cached_forecast(target: String = "", rest: bool = false) -> Dictionary:
	var key = "rest" if rest else target
	if not planning_cache.has(key): planning_cache[key] = Playability.forecast(campaign,target,rest)
	return planning_cache[key]

func _draw_planner() -> void:
	draw_rect(Rect2(0,0,1440,900),Color(0.02,0.04,0.025,0.95))
	panel(Rect2(85,75,1270,755),Color("17231b"),GOLD)
	label_at("BEFORE THE NEXT CONTRACT",Vector2(115,117),12,GOLD)
	label_at("Company plan",Vector2(115,160),30,PAPER,true)
	button("plan_close","CLOSE / ESC",Rect2(1128,100,196,42))
	var count: int = campaign.alive_count()
	var wages: int = campaign.wage_cost()
	label_at("%d crowns · %d rations" % [campaign.crowns,campaign.food],Vector2(115,214),22,GOLD)
	label_at("Daily: %d crowns + %d rations" % [wages,count],Vector2(115,249),16,PAPER)
	label_at("Full food days: %d · fully paid days: %d" % [campaign.food/maxi(1,count),maxi(0,campaign.crowns-campaign.arrears)/maxi(1,wages)],Vector2(115,281),14,BLUE)
	label_at("Unpaid wages: %d · consecutive unpaid days %d / 3" % [campaign.arrears,campaign.unpaid_days],Vector2(115,314),13,RED if campaign.arrears else MUTED)
	label_at("Budget before uncertain contract pay",Vector2(115,363),17,PAPER,true)
	label_at("Five days require %d crowns and %d rations." % [wages*5+campaign.arrears,count*5],Vector2(115,394),13,GOLD)
	label_at("Hiring adds both an upfront cost and a daily wage.",Vector2(115,423),12,MUTED)
	var plan = cached_forecast("",true)
	label_at("IF YOU REST ONE DAY",Vector2(115,475),12,GOLD)
	if plan.ok:
		label_at("Day %d: %d crowns / %d rations / %d arrears" % [plan.day,plan.crowns,plan.food,plan.arrears],Vector2(115,510),15,PAPER)
		label_at("If uninterrupted: %d medicine. Raiders can interrupt camp." % plan.medicine_used,Vector2(115,541),12,MUTED)
		var warnings: Array = [plan.contract]
		if plan.hunger: warnings.append("Hunger: each soldier loses 8 HP; no healing.")
		if plan.arrears > 0: warnings.append("Wages remain unpaid; hardship grows.")
		if not plan.ending.is_empty(): warnings.append(plan.ending)
		var lines = wrapped_lines(" ".join(warnings),510,13,5)
		for i in lines.size(): label_at(lines[i],Vector2(115,577+i*21),13,RED if plan.hunger or plan.arrears or not plan.ending.is_empty() else BLUE)
	else: label_at(plan.reason,Vector2(115,510),13,MUTED)
	if campaign.progression_version == 1:
		var work_lines = wrapped_lines(campaign.work_hint(),510,12,2)
		for i in work_lines.size(): label_at(work_lines[i],Vector2(115,680+i*18),12,BLUE)
	button("plan_rest","REST 1 DAY · %dc + %d food" % [campaign.rest_cost(),count],Rect2(115,737,510,48),plan.ok,true)
	label_at("SELECT A SOLDIER TO EQUIP, TREAT OR TRAIN",Vector2(660,206),11,GOLD)
	var rows = Playability.readiness(campaign)
	for i in rows.size():
		var row: Dictionary = rows[i]
		var y = 229+i*78
		button("plan_unit_%d" % row.id,row.name,Rect2(660,y,157,65))
		var lines = wrapped_lines(row.text,490,12,2)
		for j in lines.size(): label_at(lines[j],Vector2(833,y+19+j*18),12,GOLD if row.attention else BLUE)
		if plan.ok:
			var future: Dictionary = plan.rows[i]
			var next_lines = wrapped_lines("After rest: "+future.text,480,10,1)
			label_at(next_lines[0],Vector2(833,y+59),10,MUTED)
	label_at("Preview advances a separate copy. No combat result or future contract pay is assumed.",Vector2(660,747),11,MUTED)
	label_at("World events and deadlines still advance when you actually rest or travel.",Vector2(660,775),11,MUTED)

func _draw_record() -> void:
	draw_rect(Rect2(0,0,1440,900),Color(0.02,0.04,0.025,0.95))
	panel(Rect2(145,90,1150,720),Color("17231b"),GOLD)
	label_at("BATTLE RECORD · NEWEST FIRST",Vector2(180,141),23,PAPER,true)
	button("record_close","CLOSE / ESC",Rect2(1068,115,190,41))
	var entries = battle.events.duplicate()
	entries.reverse()
	record_page = clampi(record_page,0,maxi(0,ceili(entries.size()/8.0)-1))
	for i in mini(8,entries.size()-record_page*8):
		var lines = wrapped_lines(entries[record_page*8+i],1060,15,2)
		for j in lines.size(): label_at(lines[j],Vector2(180,202+i*64+j*22),15,PAPER if i == 0 else MUTED)
	button("record_prev","< NEWER",Rect2(180,738,155,36),record_page > 0)
	centered("%d / %d · latest 100 events saved" % [record_page+1,maxi(1,ceili(entries.size()/8.0))],Vector2(720,762),12,GOLD)
	button("record_next","OLDER >",Rect2(1100,738,155,36),(record_page+1)*8 < entries.size())

func _draw_world() -> void:
	if campaign.region.get("generator") == 3:
		iron.draw_world(self); return
	draw_rect(Rect2(0, 0, 1440, 900), Color("101815"))
	draw_rect(Rect2(0, 0, 1440, 106), Color("0c1310"))
	label_at("THE ASHEN COMPANY", Vector2(30, 33), 13, GOLD)
	label_at(campaign.region.get("name","The Border Marches"), Vector2(30,77),30,PAPER,true)
	label_at("UNIFIED 0.45 · SEED %s" % campaign.region.seed if campaign.region.has("generator") else "FREE ROAM / THE BORDER MARCHES",Vector2(545,32),11,MUTED)
	label_at("DAY %02d · %02d:%02d" % [campaign.day,int(roundi(campaign.overworld.hour*60)/60),posmod(roundi(campaign.overworld.hour*60),60)], Vector2(545,74),23,GOLD,true)
	label_at(("REGION SECURED" if campaign.region_secured() else ("%d JOBS WON" if campaign.endless else "%d / 4 JOBS WON") % campaign.wins), Vector2(774, 73), 14, BLUE)
	button("save", "F5 Save", Rect2(1110, 30, 92, 40))
	button("load", "F9 Load", Rect2(1210, 30, 92, 40), FileAccess.file_exists(PERK_LAB_SAVE_PATH if perk_lab_mode else SAVE_PATH))
	button("help", "? Rules", Rect2(1310, 30, 106, 40))
	label_at("%d CROWNS" % campaign.crowns, Vector2(30, 140), 16, GOLD)
	label_at("%d RATIONS" % campaign.food, Vector2(220, 140), 16, BLUE if campaign.food >= campaign.alive_count()*3 else RED)
	label_at("%d TOOLS" % campaign.tools, Vector2(410, 140), 16, MUTED)
	label_at("%d MEDICINE" % campaign.medicine, Vector2(565, 140), 16, MUTED)
	label_at("%d AMMO" % campaign.ammunition, Vector2(760, 140), 16, BLUE if campaign.ammunition >= campaign.company_ammo_needed() else RED)
	label_at("%dc + %d rations/day" % [campaign.wage_cost(),campaign.alive_count()],Vector2(760,160),10,MUTED)
	button("company", "COMPANY & EQUIPMENT", Rect2(1015, 116, 250, 39), true, true)
	button("new_top", "New company", Rect2(1275, 116, 141, 39))
	panel(Rect2(24, 178, 964, 558), Color("202b20"), Color("5c6041"))
	for i in 45:
		var y = 187+i*12
		draw_line(Vector2(28, y), Vector2(982, y), Color(0.7, 0.7, 0.5, 0.025))
	if not campaign.farm.enabled: label_at("THE SOUTHERN MARCH", Vector2(52, 216), 12, Color("7f886a"))
	if campaign.overworld.tracks.enabled: button("tracks_scout","SCOUTING · 70% PACE" if campaign.overworld.tracks.scouting else "SCOUT",Rect2(1109,78,195,25),not campaign.over(),campaign.overworld.tracks.scouting)
	if campaign.rebuilding.enabled: button("recovery_report","RECOVERY",Rect2(949,78,148,25))
	button("politics", "COUNCILS", Rect2(343,185,160,25))
	if campaign.region.has("generator") and campaign.in_town(): button("explore_rumour","LOCAL RUMOURS",Rect2(190,185,145,25))
	button("trade", "TRADE & ROADS", Rect2(511,185,160,25))
	if not campaign.guards.enabled: label_at("N", Vector2(940, 210), 14, GOLD, true)
	draw_line(Vector2(947, 224), Vector2(947, 261), GOLD, 1, true)
	draw_colored_polygon(PackedVector2Array([Vector2(947, 216), Vector2(941, 232), Vector2(953, 232)]), GOLD)
	if campaign.region.get("generator") == 3:
		region_camera.draw(self)
	elif campaign.region.has("generator"):
		ProceduralView.draw_map(self)
	else:
		var river = PackedVector2Array([Vector2(390, 179), Vector2(418, 255), Vector2(445, 335), Vector2(483, 405), Vector2(454, 492), Vector2(490, 570), Vector2(526, 637), Vector2(532, 734)])
		draw_polyline(river, Color("345550"), 23, true)
		draw_polyline(river, Color("55776a"), 2, true)
		for i in 42:
			var c = Vector2(687+(i*47)%239, 370+(i*37)%225)
			if c.distance_to(Vector2(790, 465)) < 54: continue
			draw_colored_polygon(PackedVector2Array([c+Vector2(0,-12), c+Vector2(-8,7), c+Vector2(8,7)]), Color("13291d"))
			draw_line(c+Vector2(0,4), c+Vector2(0,12), Color("4d5939"), 2)
		for i in 13:
			var c = Vector2(140+(i*53)%250, 535+(i*31)%145)
			draw_polyline(PackedVector2Array([c+Vector2(-15,8), c+Vector2(0,-11), c+Vector2(18,8)]), Color("4f593b"), 2, true)
		# Two traversable river crossings; all other water blocks the route planner.
		for y in [335,624]:
			var x = campaign.overworld.river_x(y)
			draw_line(Vector2(x-24,y),Vector2(x+24,y),Color("a58c62"),12,true)
		for road in campaign.region.roads:
			var a = campaign.node(road[0])
			var b = campaign.node(road[1])
			var p = Vector2(a.x, a.y)
			var q = Vector2(b.x, b.y)
			draw_line(p, q, Color("101c15"), 7, true)
			var threatened = (campaign.world.camps.has(road[0]) and not campaign.world.protected_road(road[0])) or (campaign.world.camps.has(road[1]) and not campaign.world.protected_road(road[1]))
			draw_dashed_line(p, q, RED.darkened(0.35) if threatened else BLUE.darkened(0.25), 2, 8, true)
		_draw_free_roam_terrain()
		for place in campaign.region.locations:
			var p = Vector2(place.x, place.y)
			if not campaign.overworld.discovered(p): continue
			var here = place.id == campaign.location and campaign.overworld.at_site(place.id)
			var chosen = place.id == world_selected
			if chosen: draw_arc(p, 31, 0, TAU, 40, GOLD, 2, true)
			if not campaign.active.is_empty() and campaign.active.target == place.id:
				draw_line(p+Vector2(25,-24), p+Vector2(25,-55), GOLD, 2)
				draw_colored_polygon(PackedVector2Array([p+Vector2(25,-55), p+Vector2(48,-49), p+Vector2(25,-41)]), GOLD)
			draw_circle(p, 25, Color("111e16"))
			draw_arc(p, 25, 0, TAU, 40, BLUE if here else Color("8d8863"), 2, true)
			if place.kind == "town":
				draw_rect(Rect2(p+Vector2(-15,-7), Vector2(30,21)), Color("a5a17e"))
				for dx in [-15, -3, 9]: draw_rect(Rect2(p+Vector2(dx,-15), Vector2(6,13)), Color("a5a17e"))
				draw_rect(Rect2(p+Vector2(-4,3), Vector2(8,11)), Color("263024"))
			else:
				draw_colored_polygon(PackedVector2Array([p+Vector2(-16,13), p+Vector2(0,-14), p+Vector2(16,13)]), Color("ae8b61"))
				draw_colored_polygon(PackedVector2Array([p+Vector2(-5,13), p+Vector2(0,0), p+Vector2(5,13)]), Color("2a2c1b"))
			var name_width = serif.get_string_size(place.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
			panel(Rect2(p+Vector2(-name_width/2-10,33), Vector2(name_width+20,27)), Color("1a251b"), Color("35432c"))
			centered(place.name, p+Vector2(0,53), 18, PAPER, true)
			if here: centered("YOUR COMPANY", p+Vector2(0,-39), 10, BLUE)
			if place.kind == "town":
				centered("%s · %d food · %dc / 24" % [campaign.world.towns[place.id].owner.capitalize(),campaign.world.towns[place.id].stock, campaign.food_quote_at(place.id)], p+Vector2(0,76), 10, GOLD)
			else:
				var camp = campaign.world.camps[place.id]
				centered(campaign.camp_label(place.id), p+Vector2(0,76), 10, BLUE if campaign.world.protected_road(place.id) else RED)
			buttons["place_"+place.id] = {"rect":Rect2(p-Vector2(52,32), Vector2(104,96)), "enabled":true}
	if campaign.region.get("generator") != 3:
		FootprintView.draw_map(self)
		TrafficView.draw_map(self)
		FarmView.draw_map(self)
		GuardView.draw_map(self)
		_draw_free_roam_parties()
		DungeonView.draw_sites(self)
		NewsView.draw_landmarks(self)
	if campaign.in_town(): button("dungeon_rumour","BURIAL RUMOURS",Rect2(817,185,160,25))
	label_at("Click ground to travel · middle-drag / WASD to pan · wheel to zoom · Home follows company" if campaign.region.get("generator") == 3 else "Click ground to travel · Space pauses · right-click stops", Vector2(46,718),12,MUTED)
	NewsView.map_note(self)
	_draw_world_detail()
	panel(Rect2(24, 752, 964, 109), Color("151f18"))
	label_at("COMPANY JOURNAL", Vector2(44, 776), 10, GOLD)
	var known = campaign.journal.filter(known_news)
	var recent = known.slice(maxi(0,known.size()-3))
	for i in recent.size(): label_fit(str(recent[i]), Vector2(44, 800+i*22), 725, 12, PAPER if i == recent.size()-1 else MUTED)
	var footer = "No final day. Battles pause time; travel and rest advance wages, recovery and the living world." if campaign.endless else "Survive 30 days debt-free. Win 4 jobs OR remove every raider band. Continue your surviving company afterward."
	if campaign.roster_version == 1 and campaign.active_ids().is_empty(): footer = "NO FIELD PARTY: assign companions in Company & Equipment > Formation & Reserves before resuming time."
	elif campaign.arrears > 0: footer = "UNPAID WAGES: %d crowns. %d / 3 unpaid days; the company leaves on the third." % [campaign.arrears, campaign.unpaid_days]
	elif campaign.food < campaign.alive_count(): footer = "NO FULL RATIONS: the next day costs each soldier 8 HP. Buy provisions at a town."
	label_at(footer, Vector2(30, 886), 12, RED if campaign.arrears > 0 or campaign.food < campaign.alive_count() else MUTED)
	if notice_time > 0:
		panel(Rect2(220, 690, 660, 38), Color("111d16"), GOLD)
		centered(notice.left(85), Vector2(550, 715), 12, GOLD)

func _draw_world_detail() -> void:
	panel(Rect2(1008, 178, 408, 683), Color("18221a"))
	if not campaign.encounter.is_empty():
		label_at("CONTACT · TIME PAUSED",Vector2(1030,214),12,RED)
		label_at(campaign.encounter.title,Vector2(1030,254),28,PAPER,true)
		var count = campaign.encounter_enemy_count()
		label_at("%s · %d enemies · %dc" % [campaign.enemy_label(campaign.encounter.site,campaign.encounter.threat,campaign.encounter.kind),count,campaign.encounter.pay],Vector2(1030,296),14,GOLD)
		var message = wrapped_lines("Your company has met the raiders. Review your equipment, then take the field. You can retreat during your turn in battle.",355,15,5)
		for i in message.size(): label_at(message[i],Vector2(1030,344+i*25),15,MUTED)
		button("deploy","TAKE THE FIELD",Rect2(1030,506,364,48),true,true)
		button("company","REVIEW COMPANY",Rect2(1030,568,364,42))
		_draw_job_reminder(1030,690)
		return
	if world_selected.begins_with("footprints:") and campaign.overworld.tracks.enabled:
		FootprintView.detail(self); return
	if world_selected.begins_with("recovery:") and campaign.rebuilding.enabled:
		RecoveryView.detail(self); return
	if world_selected.begins_with("guard:") and campaign.guards.enabled:
		GuardView.detail(self); return
	if world_selected.begins_with("farm:") and campaign.farm.enabled:
		FarmView.detail(self); return
	if world_selected.begins_with("wagon:") or world_selected.begins_with("trace:"):
		TrafficView.detail(self,world_selected); return
	if world_selected.begins_with("band:"):
		BanditView.detail(self,world_selected.get_slice(":",1)); return
	if world_selected.is_empty() or not known_site(world_selected):
		_draw_wilderness_detail()
		return
	var place = campaign.node(world_selected)
	if place.get("kind") == "camp" and campaign.recon.enabled and not campaign.over():
		ReconView.detail(self,world_selected); return
	if place.get("kind") == "dungeon":
		DungeonView.entrance(self,world_selected); return
	if place.get("kind") == "discovery":
		ProceduralView.draw_discovery(self,world_selected)
		return
	label_at("CURRENT CAMP" if world_selected == campaign.location and campaign.overworld.at_site(world_selected) else "DESTINATION", Vector2(1030, 208), 11, GOLD)
	label_at(place.name, Vector2(1030, 242), 27, PAPER, true)
	var description: String = place.description
	if place.kind == "town":
		var t = campaign.world.towns[place.id]
		description = "%s · %s (%+d). %d food; +%d / -%d daily. %d food lost to raids." % [campaign.world.faction_name(t.owner),campaign.attitude(t.owner),campaign.reputation[t.owner],t.stock,t.production,t.demand,t.raided]
		var farm = campaign.farm.for_town(place.id)
		if farm != null: description = "%s · %d food. Farm output %d/day, delivered by cart; town consumes %d/day." % [campaign.world.faction_name(t.owner),t.stock,farm.output(campaign.world),t.demand]
	else:
		var camp = campaign.world.camps[place.id]
		description = ("%s · %d enemies · %d food reserves. Patrol strength %d. Bands recruit using stolen cargo." % [campaign.enemy_label(place.id,camp.strength), campaign.enemy_count(place.id,camp.strength), campaign.world.camp_food(place.id),campaign.world.patrol_power(place.id)]) if camp.active else "Band destroyed. Another band needs 36 stolen food to reoccupy this road. Stationed patrols deter expansion."
		var quiet_days = maxi(0,camp.cleared_day+int(campaign.world.config.politics.get("reoccupy_delay",0))-campaign.day)
		if not camp.active and quiet_days > 0: description = "Band destroyed. No reoccupation before day %d. After that, another band needs stolen supplies; stationed patrols deter its return." % (campaign.day+quiet_days)
		if campaign.camp_life.enabled: description = campaign.camp_life.description(campaign,place.id)
	var lines = wrapped_lines(description, 360, 12, 3)
	for i in lines.size(): label_at(lines[i], Vector2(1030, 268+i*17), 12, MUTED)
	if campaign.over():
		label_at("THE END OF THE ROAD" if campaign.endless or campaign.day <= 30 else "THE THIRTIETH DAY", Vector2(1030, 340), 12, GOLD)
		lines = wrapped_lines(campaign.ending, 350, 22, 3)
		for i in lines.size(): label_at(lines[i], Vector2(1030, 380+i*30), 22, PAPER, true)
		label_at("%d jobs won · %s" % [campaign.wins,"all bands destroyed" if campaign.region_secured() else "bands remain" if campaign.endless else "4 wins required"], Vector2(1030, 505), 16, BLUE)
		label_at("%d living · %d names in the memorial" % [campaign.alive_count(), campaign.soldiers.size()-campaign.alive_count()], Vector2(1030, 539), 14, MUTED)
		label_at("%d crowns · %d unpaid wages" % [campaign.crowns, campaign.arrears], Vector2(1030, 573), 14, GOLD)
		label_at("Your company and chronicle remain saved.", Vector2(1030, 635), 12, MUTED)
		button("company", "READ THE ROLL & MEMORIAL", Rect2(1030, 675, 364, 43))
		if campaign.can_continue_campaign(): button("continue_campaign","CONTINUE CAMPAIGN",Rect2(1030,728,364,39),true,true)
		button("new", "FOUND A NEW COMPANY", Rect2(1030, 777, 364, 50), true, true)
		return
	if world_selected != campaign.location or not campaign.overworld.at_site(world_selected):
		label_at("CHOOSE YOUR OWN ROUTE",Vector2(1030,346),12,GOLD)
		var planned = campaign.overworld.route(campaign.overworld.position,campaign.overworld.places[world_selected])
		var distance = 0.0
		var from = campaign.overworld.position
		for p in planned:
			distance += from.distance_to(p)*campaign.overworld.travel_cost(from,p)
			from = p
		label_at("About %.1f hours of travel" % (distance/campaign.Overworld.MOVE_SPEED) if planned.all(func(p): return campaign.overworld.discovered(p)) else "Route crosses unexplored land",Vector2(1030,386),21,PAPER,true)
		var message = wrapped_lines("Roads are fastest. Forests and hills slow the company. Explore to find river crossings. Scouts may force a detour.",355,14,5)
		for i in message.size(): label_at(message[i],Vector2(1030,428+i*24),14,MUTED)
		button("travel","SET COURSE TO "+place.name.to_upper(),Rect2(1030,575,364,48),not planned.is_empty(),true)
		label_at("Wages and rations are paid at midnight.",Vector2(1030,650),12,MUTED)
		_draw_job_reminder(1030,700)
		return
	if not campaign.active.is_empty() and (not campaign.in_town() or town_tab != "recruits"):
		var job = campaign.active
		label_at("ACCEPTED CONTRACT", Vector2(1030, 335), 11, GOLD)
		label_at(job.title, Vector2(1030, 365), 20, PAPER, true)
		lines = wrapped_lines(job.brief, 356, 13, 2)
		for i in lines.size(): label_at(lines[i], Vector2(1030, 393+i*19), 13, MUTED)
		label_at("%d crowns · due day %d" % [job.pay, job.deadline], Vector2(1030, 440), 13, GOLD)
		label_at(campaign.job_danger(job), Vector2(1030, 461), 12, PAPER)
		if campaign.can_deploy():
			button("deploy", "DEFEND THE WAGONS  >" if job.kind == "escort" else "DEPLOY THE COMPANY  >", Rect2(1030, 478, 364, 45), true, true)
		elif job.kind == "escort" and not campaign.next_escort_stop().is_empty():
			var next = campaign.next_escort_stop()
			button("escort_move", "ESCORT TO "+campaign.node(next).name.to_upper(), Rect2(1030, 478, 364, 45), campaign.endless or campaign.day+campaign.travel_days(next) <= 31, true)
		else:
			label_at("Travel to "+campaign.node(job.target).name+".", Vector2(1030, 496), 14, BLUE)
		button("abandon", "Abandon contract", Rect2(1030, 539, 364, 32))
		label_at("Bounty paid on victory. Local camp remains separate." if campaign.RoadContracts.is_road(job.kind) else "Escort pay is due on delivery." if job.kind == "escort" else "Victory changes road security or returns stolen food.", Vector2(1030, 600), 12, MUTED)
		if campaign.in_town(): button("recruits", "VISIT THE RECRUITS", Rect2(1030, 620, 364, 36))
		elif campaign.world.camps.get(campaign.location,{}).get("active",false) and not campaign.can_deploy(): button("attack_camp","ASSAULT THIS CAMP",Rect2(1030,620,364,36),true,true)
	elif campaign.in_town():
		button("contracts", "CONTRACT BOARD", Rect2(1030, 320, 178, 36), true, town_tab == "contracts")
		button("recruits", "RECRUITS", Rect2(1218, 320, 176, 36), true, town_tab == "recruits")
		if town_tab == "contracts":
			var jobs = campaign.offers()
			job_page = clampi(job_page, 0, maxi(0, ceili(float(jobs.size())/2)-1))
			for i in mini(2, jobs.size()-job_page*2):
				var job: Dictionary = jobs[job_page*2+i]
				var y = 372+i*137
				label_at(job.title, Vector2(1030, y+18), 19, PAPER, true)
				label_at("%dc · day %d · %s" % [job.pay, job.deadline, campaign.node(job.target).name], Vector2(1030, y+44), 12, GOLD)
				label_at(campaign.job_danger(job), Vector2(1030, y+67), 12, MUTED)
				button("accept_"+job.id, "ACCEPT CONTRACT", Rect2(1030, y+80, 364, 35), true, true)
			if jobs.is_empty():
				var work_lines = wrapped_lines(campaign.work_hint(),355,14,4)
				for i in work_lines.size(): label_at(work_lines[i],Vector2(1030,405+i*23),14,MUTED)
			if jobs.size() > 2:
				if campaign.economy.enabled: label_at("Actual camps and shipments · council-funded pay",Vector2(1030,639),10,MUTED)
				elif campaign.progression_version == 1: label_at("Road bounties: weekly from day 8 · payment on victory",Vector2(1030,639),10,MUTED)
				button("jobs_prev", "<", Rect2(1030, 646, 45, 25), job_page > 0)
				centered("%d / %d jobs" % [job_page+1, ceili(float(jobs.size())/2)], Vector2(1210, 664), 11, MUTED)
				button("jobs_next", ">", Rect2(1349, 646, 45, 25), (job_page+1)*2 < jobs.size())
		else:
			var recruits = campaign.recruits()
			for i in recruits.size():
				var recruit: Dictionary = recruits[i]
				var y = 372+i*137
				label_at(recruit.person+" · "+recruit.name, Vector2(1030, y+18), 17, PAPER, true)
				label_at(recruit.trait, Vector2(1030, y+44), 12, MUTED)
				label_at("%d crowns to hire · %d per day" % [recruit.price, recruit.wage], Vector2(1030, y+67), 12, GOLD)
				var reserve: int = campaign.crowns-recruit.price-campaign.arrears-5*(campaign.wage_cost()+recruit.wage)
				if campaign.alive_count() < campaign.company_limit():
					label_at("After hire + 5 days' wages: %dc" % reserve,Vector2(1030,y+129),10,RED if reserve < 0 else BLUE)
				button("hire_"+recruit.id, "HIRE WITH GEAR" if campaign.alive_count() < campaign.company_limit() else "COMPANY FULL", Rect2(1030, y+80, 242, 35), campaign.alive_count() < campaign.company_limit() and campaign.crowns >= recruit.price, true)
				button("person_offer_"+recruit.id,"PROFILE",Rect2(1282,y+80,112,35),true,true)
			if recruits.is_empty(): label_at("No recruits left here this week.", Vector2(1030, 405), 13, MUTED)
	else:
		label_at("NO WORK AT THIS CAMP", Vector2(1030, 345), 12, GOLD)
		label_at("Scout the country or assault this camp directly." if campaign.world.camps.get(campaign.location,{}).get("active",false) else "This band is gone. Its trade road is clear.", Vector2(1030,385),13,MUTED)
		if campaign.world.camps.get(campaign.location,{}).get("active",false): button("attack_camp","ASSAULT RAIDER CAMP",Rect2(1030,465,364,44),true,true)
		label_at("Rest or prepare your company for the next road.", Vector2(1030, 415), 12, MUTED)
	if campaign.in_town():
		button("buy_food", "+24 rations · %d crowns" % campaign.supply_cost("food"), Rect2(1030, 678, 364, 39), campaign.crowns >= campaign.supply_cost("food") and campaign.world.towns[campaign.location].stock >= 24)
		if campaign.economy.enabled: button("resources","MARKET · CARGO & SUPPLIES",Rect2(1030,724,364,39),true,true)
		else: button("buy_ammo", "+30 ammo · %d crowns" % campaign.supply_cost("ammo"), Rect2(1030, 724, 364, 39), campaign.crowns >= campaign.supply_cost("ammo"))
	else: label_at("Supplies and recruitment are available in towns.", Vector2(1030, 717), 12, MUTED)
	button("rest", "REST 1 DAY · %d crowns + %d food" % [campaign.rest_cost(), campaign.alive_count()], Rect2(1030, 777, 364, 45))

func _draw_job_reminder(x: float, y: float) -> void:
	if campaign.active.is_empty(): return
	label_at("CONTRACT: "+campaign.active.title, Vector2(x, y), 13, GOLD)
	label_at("At %s · due day %d" % [campaign.node(campaign.active.target).name, campaign.active.deadline], Vector2(x, y+27), 13, MUTED)

func _draw_patrols() -> void:
	var index = 0
	for p in campaign.world.patrols.values():
		if campaign.world.has_physical(p.faction): continue
		if not p.status in ["marching","stationed"]: continue
		var place = campaign.node(p.site)
		var center = Vector2(place.x,place.y)
		if p.status == "marching":
			var home = campaign.node(campaign.world.config.factions[p.faction].town)
			center = Vector2(home.x,home.y).lerp(center,0.5)
		center += Vector2(-72,-10-index*28)
		var color = Color(campaign.world.config.factions[p.faction].color)
		draw_colored_polygon(PackedVector2Array([center+Vector2(-12,-13),center+Vector2(12,-13),center+Vector2(10,6),center+Vector2(0,15),center+Vector2(-10,6)]),color)
		centered(str(p.strength),center+Vector2(0,3),12,INK)
		label_at(p.id.replace("patrol_","P"),center+Vector2(-14,32),10,color)
		buttons["patrol_"+p.id] = {"rect":Rect2(center-Vector2(15,16),Vector2(38,53)),"enabled":true}
		index += 1

func _draw_politics() -> void:
	draw_rect(Rect2(0,0,1440,900),Color(0.02,0.04,0.025,0.94))
	panel(Rect2(110,65,1220,770),Color("17231b"),GOLD)
	label_at("WHO HOLDS THE MARCHES",Vector2(140,105),12,GOLD)
	label_at("Councils, patrols & growing warbands",Vector2(140,150),30,PAPER,true)
	button("politics_close","CLOSE / ESC",Rect2(1130,94,170,43),true,true)
	var w = campaign.world
	var index = 0
	var council_ids = w.FACTIONS.filter(func(id):return known_site(w.config.factions[id].town))
	var council_page = report_page(council_ids,"towns",Vector2(925,143))
	for id in council_page:
		var f: Dictionary = w.factions[id]
		var definition: Dictionary = w.config.factions[id]
		if not known_site(definition.town): continue
		var t: Dictionary = w.towns[definition.town]
		var x = 140+index*390
		var color = Color(definition.color)
		panel(Rect2(x,176,370,270),Color("202e21"),color.darkened(0.4))
		label_fit(definition.name,Vector2(x+16,205),338,23,color,true)
		label_fit("Rules "+w.place_name(definition.town)+" · rival: "+w.faction_name(definition.rival),Vector2(x+16,230),338,12,MUTED)
		label_at("%d crowns in treasury" % f.treasury,Vector2(x+16,263),19,GOLD,true)
		label_at("Tax +%d · trade +%d · patrons +%d" % [f.taxes,f.trade,f.contributions],Vector2(x+16,288),11,MUTED)
		label_at("Patrols -%d · raids -%d · pressure %d / 5" % [f.spent,f.losses,t.pressure],Vector2(x+16,307),11,MUTED)
		label_at("%s · reputation %+d" % [campaign.attitude(id),campaign.reputation[id]],Vector2(x+16,337),16,color)
		label_at("Supply prices %+d%% · contract pay %+.1f%%" % [-clampi(campaign.reputation[id],-20,20),campaign.reputation[id]/2.0],Vector2(x+16,359),11,MUTED)
		var patrol_text = "No active patrol. Dispatch costs 90 crowns."
		for p in w.patrols.values():
			if p.faction == id and p.status in ["marching","stationed"]:
				patrol_text = "%s · %s at %s · %dd" % [p.id.replace("patrol_","P"),p.status,p.site,p.remaining if p.status == "marching" else p.days_left]
		if campaign.guards.enabled and w.has_physical(id): patrol_text = GuardView.council_caption(campaign,definition.town)
		label_at(patrol_text,Vector2(x+16,388),11,PAPER)
		label_at("Next patrol: "+f.priority.capitalize() if not f.priority.is_empty() else ("Escort work refused: rebuild trust." if campaign.reputation[id] <= -12 else "Escort work available when cargo needs it."),Vector2(x+16,419),11,GOLD if not f.priority.is_empty() else MUTED)
		index += 1
	label_at("THREATS SPEND REAL FOOD · 36 TO RECRUIT · 36 TO EXPAND · 12 TO RAID",Vector2(140,478),11,GOLD)
	var known_camps = report_page(w.SITES.filter(known_site),"camps",Vector2(1060,475))
	for i in known_camps.size():
		var site: String = known_camps[i]
		if not known_site(site): continue
		var c: Dictionary = w.camps[site]
		var x = 140+i*390
		panel(Rect2(x,493,370,101),Color("1b281d"))
		label_fit(campaign.node(site).name+" · "+("band %d" % c.generation if c.active else "cleared"),Vector2(x+16,520),338,20,PAPER,true)
		label_at(campaign.camp_label(site),Vector2(x+16,545),12,BLUE if w.protected_road(site) else RED)
		label_at("Watch the camp for a dated reconnaissance report." if campaign.recon.enabled else "%d food · %d spent · %d raids · %d expansions" % [w.camp_food(site),c.spent,c.raids,c.expansions],Vector2(x+16,570),11,MUTED)
	label_at("DIRECT THE NEXT PATROL",Vector2(140,630),11,GOLD)
	if campaign.in_town():
		var owner: String = w.towns[campaign.location].owner
		var sites = w.adjacent_sites(campaign.location).filter(known_site)
		for i in sites.size():
			button("fund_"+sites[i],"90c · "+campaign.node(sites[i]).name.to_upper(),Rect2(140+(i%2)*255,649+(i/2)*36,248,30),not campaign.over() and campaign.crowns >= 90 and w.factions[owner].priority.is_empty(),true)
		label_at("+4 reputation here, -1 with its rival. No second order while queued.",Vector2(140,774),11,MUTED)
	else: label_at("Visit a town to fund its council's next patrol.",Vector2(140,668),13,MUTED)
	label_at("REGIONAL NEWS",Vector2(680,630),11,GOLD)
	var y = 654
	for event in w.events.filter(func(e): return known_news(e.text)).slice(-3):
		for line in wrapped_lines("D%d · %s" % [event.day,event.text],615,11,2):
			label_at(line,Vector2(680,y),11,PAPER)
			y += 16
		y += 8
	label_at("Patrols: strength 2, 6 crowns/day, four days on station. Equal strength protects traffic; superior strength clears bands.",Vector2(140,811),11,MUTED)

func _draw_convoys() -> void:
	for c in campaign.world.caravans.values():
		if c.status in ["seized", "delivered", "plundered"]: continue
		var route = campaign.world.route_data(c.route)
		var from = campaign.node(route.path[c.index])
		var p = Vector2(from.x, from.y)
		if c.status == "transit" and c.remaining > 0:
			var destination = campaign.node(route.path[c.index+1])
			var progress = 1.0-float(c.remaining)/float(route.days[c.index])
			p = p.lerp(Vector2(destination.x, destination.y), progress)
		p += Vector2(68, -4-(int(c.id.trim_prefix("wagon_"))%3)*48)
		panel(Rect2(p-Vector2(18,12), Vector2(36,24)), Color("1a291f"), BLUE if c.status == "escort" else GOLD)
		draw_rect(Rect2(p+Vector2(-10,-7), Vector2(20,9)), GOLD)
		draw_circle(p+Vector2(-7,7), 3, PAPER)
		draw_circle(p+Vector2(7,7), 3, PAPER)
		centered(campaign.world.short_id(c.id), p+Vector2(0,-18), 10, GOLD)
		buttons["convoy_"+c.id] = {"rect":Rect2(p-Vector2(20,30),Vector2(40,44)), "enabled":true}

func _draw_trade() -> void:
	draw_rect(Rect2(0,0,1440,900), Color(0.02,0.04,0.025,0.94))
	panel(Rect2(110,65,1220,770), Color("17231b"), GOLD)
	label_at("THE BORDER LEDGER", Vector2(140,105), 12, GOLD)
	label_at("Cargo, wagons & the roads between", Vector2(140,150), 31, PAPER, true)
	button("trade_close", "CLOSE  /  ESC", Rect2(1130,94,170,43), true, true)
	var world = campaign.world
	var known_towns = report_page(world.TOWNS.filter(known_site),"towns",Vector2(925,143))
	for i in known_towns.size():
		var town: String = known_towns[i]
		if not known_site(town): continue
		var t: Dictionary = world.towns[town]
		var x = 140+i*390
		panel(Rect2(x,176,370,104), Color("202e21"))
		label_at(campaign.node(town).name, Vector2(x+16,202), 22, PAPER, true)
		label_at("%d food  ·  %d crowns / 24 rations" % [t.stock,campaign.food_quote_at(town)], Vector2(x+16,231), 15, GOLD)
		label_at("Daily +%d / -%d  ·  %d food delivered" % [t.production,t.demand,t.delivered], Vector2(x+16,259), 12, MUTED)
	label_at("SHIPMENTS · CLICK A ROW", Vector2(140,316), 11, GOLD)
	var ids = world.caravans.keys().filter(func(id):
		var w: Dictionary=world.caravans[id];var path: Array=world.route_data(w.route).path
		return path.all(known_site) or w.has("material") and (known_site(path[0]) or known_site(path[2])))
	trade_page = clampi(trade_page,0,maxi(0,ceili(float(ids.size())/6)-1))
	for i in mini(6,ids.size()-trade_page*6):
		var id: String = ids[trade_page*6+i]
		var c: Dictionary = world.caravans[id]
		var route = world.route_data(c.route)
		var y = 330+i*51
		var rect = Rect2(140,y,690,45)
		panel(rect, Color("2b3525") if trade_selected == id else Color("1c291e"), GOLD if trade_selected == id else Color("364833"))
		buttons["inspect_"+id] = {"rect":rect,"enabled":true}
		label_at(world.short_id(id), Vector2(152,y+20), 15, GOLD)
		label_at("%s → %s" % [trade_place(route.path[0]),trade_place(route.path[2])], Vector2(218,y+20), 14, PAPER)
		label_at(world.cargo_text(id), Vector2(550,y+20), 13, MUTED)
		label_at(c.status.to_upper(), Vector2(670,y+20), 12, RED if c.status == "seized" else BLUE)
		var detail = "At "+trade_place(world.shipment_at(id))
		if c.status == "waiting": detail += " · leaves day %d" % c.depart_day
		elif c.status == "transit": detail = ("Travelling · arrival follows its position on the road" if campaign.traffic.enabled else detail+" · %d day(s) to next stop" % c.remaining)
		elif c.status == "delivered": detail += " · delivered day %d" % c.delivered_day
		elif c.status == "escort": detail += " · moves with your company"
		elif c.status in ["seized","plundered"]:
			if c.has("material"):detail += " · "+("Taken as company loot" if c.status=="plundered" else "Unpacked in camp" if campaign.economy.freight.state.shipments[id].phase=="camp" else "Cargo held by raiders")
			else:detail += " · %d food already spent by raiders" % c.spent
		label_at(detail, Vector2(218,y+38), 10, MUTED)
	button("trade_prev", "<", Rect2(140,645,45,28), trade_page > 0)
	centered("%d / %d" % [trade_page+1,maxi(1,ceili(float(ids.size())/6))], Vector2(485,665),12,MUTED)
	button("trade_next", ">", Rect2(785,645,45,28),(trade_page+1)*6 < ids.size())
	label_at("ROAD SECURITY",Vector2(860,316),11,GOLD)
	var known_camps = report_page(world.SITES.filter(known_site),"camps",Vector2(1100,305))
	for i in known_camps.size():
		var site: String = known_camps[i]
		if not known_site(site): continue
		var c: Dictionary = world.camps[site]
		var y = 345+i*74
		label_at(campaign.node(site).name,Vector2(860,y),19,PAPER,true)
		label_at(campaign.camp_label(site),Vector2(860,y+23),12,BLUE if world.protected_road(site) else RED)
		label_at("Camp intelligence requires a visit." if campaign.recon.enabled else "%d food held · %d spent · %d raids" % [world.camp_food(site),c.spent,c.raids],Vector2(860,y+42),11,MUTED)
	label_at("RECENT TRADE NEWS",Vector2(860,586),11,GOLD)
	var recent = world.events.filter(func(e): return known_news(e.text)).slice(-3)
	var y = 610
	for event in recent:
		var lines = wrapped_lines("D%d · %s" % [event.day,event.text],430,11,3)
		for line in lines:
			label_at(line,Vector2(860,y),11,PAPER)
			y += 16
		y += 9
	if not trade_selected.is_empty() and trade_selected in ids:
		var c = world.caravans[trade_selected]
		var route = world.route_data(c.route)
		label_at("%s · %s → %s → %s" % [world.short_id(c.id),trade_place(route.path[0]),trade_place(route.path[1]),trade_place(route.path[2])],Vector2(140,715),16,GOLD)
		var protection="Recovered." if c.recovered else ("Company escort." if c.guarded else ("Patrol: "+c.protection if not c.protection.is_empty() else "Unprotected."))
		label_at(world.cargo_text(c.id)+" · "+protection,Vector2(140,744),12,MUTED)
		if c.has("material"):
			var shipment: Dictionary=campaign.economy.freight.state.shipments[c.id]
			label_at("Buyer paid %dc + %dc freight. Stock arrives with the wagon."%[shipment.cost,shipment.fee],Vector2(140,770),12,MUTED)
	else:
		label_at("Caravans use wagon roads. Your company can also use foot trails.",Vector2(140,715),13,MUTED)
		label_at("Clearing a camp releases seized cargo and protects later deliveries.",Vector2(140,744),13,MUTED)
	label_at("Food sustains the region. Materials supply workshops and repairs. Raids interrupt both; recovery returns paid cargo to its buyer.",Vector2(140,800),12,MUTED)

func _draw_person() -> void:
	buttons.clear()
	var offer = not person_offer.is_empty()
	var candidates: Array = campaign.recruits().filter(func(p): return p.id == person_offer) if offer else []
	if offer and candidates.is_empty(): return
	var s: Dictionary = candidates[0] if offer else campaign.soldiers[camp_selected]
	draw_rect(Rect2(0,0,1440,900),Color(0.02,0.04,0.025,0.97))
	panel(Rect2(110,65,1220,770),Color("17231b"),GOLD)
	label_at("A PERSON, A PLACE IN THE COMPANY",Vector2(140,105),12,GOLD)
	label_at((s.person if offer else s.name)+" · "+(s.name if offer else s.background),Vector2(140,151),29,PAPER,true)
	var perk_points = 0 if offer else maxi(0,Progression.points(s))
	button("person_perks","PERSONAL PERKS"+(" · +%d" % perk_points if perk_points > 0 else ""),Rect2(870,94,240,43),true,true)
	button("person_close","CLOSE / ESC",Rect2(1130,94,170,43),true,true)
	label_at(("Age %d" % s.age if s.age > 0 else "Age unrecorded")+" · %d crowns per day" % s.wage,Vector2(140,185),16,MUTED)
	var next = 40 if offer else Progression.next_xp(s)
	panel(Rect2(140,204,430,123),Color("202e21"))
	if not offer:
		label_fit("%d %s · %d kills · %s" % [s.battles,"battle" if s.battles == 1 else "battles",s.kills,"living" if s.alive else "fallen day %d" % s.fallen_day],Vector2(158,233),394,18,PAPER,true)
		label_at("%d / %d HP · %d injury days" % [s.hp,campaign.max_hp(s),s.wound_days],Vector2(158,260),15,MUTED)
		label_at("Next rank: %d / %d XP" % [s.xp,next] if next > 0 else "Maximum rank · service remains recorded",Vector2(158,287),13,GOLD)
		bar(Vector2(158,306),394,s.xp,next if next > 0 else s.xp,BLUE,5)
	else:
		label_at("New recruit · no company service yet",Vector2(158,241),17,PAPER,true)
		label_at("Level 1 · Next rank at %d XP" % next,Vector2(158,279),15,GOLD)
	label_at(People.TEMPERAMENTS[s.temperament].name.to_upper(),Vector2(140,363),18,GOLD,true)
	var lines = wrapped_lines(People.TEMPERAMENTS[s.temperament].effect,400,16,3)
	for i in lines.size(): label_at(lines[i],Vector2(140,392+i*22),16,PAPER)
	label_at("LEVEL 1 · NEW RECRUIT" if offer else "LEVEL %d / 11 · %d PERK %s" % [Progression.level(s),perk_points,"POINT" if perk_points == 1 else "POINTS"],Vector2(140,460),13,GOLD)
	label_at("WHAT THEY CAN SUSTAIN",Vector2(140,493),12,GOLD)
	var worn = person_preview(s,offer)
	label_at("%d stamina − %d gear = %d available" % [worn.stamina,People.equipment_load(worn),People.fatigue_max(worn)],Vector2(140,522),16,BLUE)
	label_at("%d initiative when fresh" % battle.initiative_value(worn),Vector2(140,549),17,BLUE)
	label_at("%d fatigue recovered each activation" % People.recovery(worn),Vector2(140,576),15,MUTED)
	label_at("EQUIPMENT",Vector2(140,613),12,GOLD)
	var gear: Array = []
	if offer:
		for definition in [s.loadout.weapon,s.loadout.shield,s.ammo_loadout]:
			if not definition.is_empty(): gear.append(campaign.catalog[definition].name)
		for definition in s.carried_loadout:
			if not definition.is_empty(): gear.append(campaign.catalog[definition].name+" (carried)")
		for group in s.armor_loadout:
			for definition in s.armor_loadout[group].values():
				if not definition.is_empty(): gear.append(campaign.catalog[definition].name)
		for slot in ["hands","feet","cloak","belt"]:
			var definition: String = s.get("support_loadout",{}).get(slot,"")
			if not definition.is_empty(): gear.append(campaign.catalog[definition].name)
	else:
		for slot in ["weapon","shield"]+Arsenal.bag_slots(s)+["ammo"]:
			var id: String = s.gear.get(slot,"")
			if not id.is_empty(): gear.append(campaign.item_name(id)+(" (carried)" if slot in Arsenal.CARRIED else ""))
		for part in campaign.battle_parts(s): gear.append(campaign.item_name(part.item))
	lines = wrapped_lines(", ".join(gear),400,14,7 if offer else 4)
	for i in lines.size(): label_at(lines[i],Vector2(140,641+i*20),14,PAPER)
	if not offer: button("person_details","DETAILS · RARITY ROLLS",Rect2(140,735,430,44))
	label_at("ATTRIBUTE",Vector2(600,235),12,GOLD)
	label_at("BASE",Vector2(790,235),11,GOLD)
	label_at("EQUIPPED",Vector2(855,235),11,GOLD)
	label_at("TALENT",Vector2(973,235),11,GOLD)
	label_at("LEVEL GAIN",Vector2(1124,235),11,GOLD)
	var index = -1 if offer else Progression.pending(s)
	var available = 0 if offer else Progression.training_levels(s)
	var needed = 0 if index < 0 else 3-s.training[index].size()
	for i in People.ATTRS.size():
		var attr: String = People.ATTRS[i]
		var value: int = PersonStats.permanent(s,attr,offer)
		var effective = equipped_attribute(s,worn,attr,offer)
		var y = 252+i*47
		var selected_growth = attr in growth_selection and index >= 0
		panel(Rect2(600,y,700,43),Color("303c29") if selected_growth else Color("202e21"),GOLD if selected_growth else Color("394736"))
		label_at(People.LABELS[attr],Vector2(614,y+27),15,PAPER)
		centered(str(value),Vector2(810,y+27),16,PAPER)
		centered(str(effective),Vector2(887,y+27),16,BLUE if effective >= value else RED)
		for star in 3: talent_star(Vector2(981+star*18,y+21),star < s.aptitudes[attr])
		var bounds = People.growth_range(s,attr)
		var range_text = "+%d" % bounds[0] if bounds[0] == bounds[1] else "+%d–%d" % bounds
		if offer: centered(range_text+" per level",Vector2(1182,y+27),14,MUTED)
		else:
			var gain = People.growth(s,attr)
			var already = index >= 0 and attr in s.training[index]
			var title = "KEPT EARLIER PICK" if already else (("SELECTED +%d" if selected_growth else "CHOOSE +%d") % gain if index >= 0 else range_text+" POTENTIAL")
			button("grow_"+attr,title,Rect2(1080,y+4,205,35),s.alive and not campaign.over() and index >= 0 and not already and (selected_growth or growth_selection.size() < needed),selected_growth)
	var status = "GROWTH POTENTIAL · THREE TALENTED STATS" if offer else ("LEVEL %d · SELECTED %d / %d · %d %s READY" % [index+2,growth_selection.size(),needed,available,"LEVEL" if available == 1 else "LEVELS"] if index >= 0 else "NO UNSPENT STAT LEVELS · EARN XP IN BATTLE")
	label_at(status,Vector2(600,656),12,GOLD)
	var explanation = "Stars improve future gains, not starting stats. Any three different stats can be trained each level. Background never locks a role."
	if index >= 0:
		explanation = "Select three different stats, then confirm. These exact rolls are saved; reopening or loading does not reroll them."
		if needed < 3: explanation = "Your earlier pick and its full gain are preserved. Choose the two remaining stats to complete this level. Saved rolls cannot be rerolled."
	lines = wrapped_lines(explanation,690,14,3)
	for i in lines.size(): label_at(lines[i],Vector2(600,683+i*21),14,MUTED)
	label_at("Base: current growth + saved rarity. Equipped: gear, perks, wounds & scars.",Vector2(600,742),12,MUTED)
	if offer:
		var available_offer = not candidates.is_empty()
		button("person_hire","HIRE · %dc + %dc/day" % [s.price,s.wage],Rect2(600,758,700,44),available_offer and campaign.alive_count() < campaign.company_limit() and campaign.crowns >= s.price,true)
	else:
		button("person_clear","CLEAR PICKS",Rect2(600,758,170,44),not growth_selection.is_empty())
		button("person_train","CONFIRM LEVEL %d · %d STAT PICKS" % [index+2,needed] if index >= 0 else "NO TRAINING AVAILABLE",Rect2(785,758,515,44),s.alive and not campaign.over() and index >= 0 and growth_selection.size() == needed,true)

	label_at("Company seed %d · People and recruit boards persist when you save or load." % campaign.seed_value,Vector2(140,810),12,MUTED)

func talent_star(center: Vector2, filled: bool) -> void:
	var points = PackedVector2Array()
	for i in 10:
		var angle = -PI/2.0+i*PI/5.0
		points.append(center+Vector2(cos(angle),sin(angle))*(7.5 if i%2 == 0 else 3.5))
	draw_colored_polygon(points,GOLD if filled else Color("40503b"))


func open_armor(group: String, mode: String = "parts") -> void:
	armor_view = true
	armor_group = group
	armor_layer = Armor.LAYERS[group][0]
	armor_mode = mode
	armor_source = "stores"
	armor_choice = ""
	armor_page = 0

func offer_armor_stats(p: Dictionary) -> Dictionary:
	var parts: Array = []
	for group in p.armor_loadout:
		for layer in p.armor_loadout[group]:
			var definition: String = p.armor_loadout[group][layer]
			if definition.is_empty(): continue
			var d: Dictionary = campaign.catalog[definition]
			parts.append({"pool":"helmet" if group == "head" else ("padding" if layer == "base" else "armor"),"condition":int(d.durability),"maximum":int(d.durability),"weight":0 if p.legacy_armor else int(d.weight)})
	return Armor.totals(parts)

func armor_entries() -> Array:
	if armor_mode == "exchange":
		return campaign.soldiers.filter(func(s): return s.alive and s.id != camp_selected).map(func(s): return str(s.id))
	if armor_mode == "kits": return campaign.stash(armor_group)
	if armor_source == "armorer": return campaign.armorer_stock(armor_group,armor_layer).map(func(p): return p.id)
	return campaign.components(armor_group,armor_layer)

func armor_preview() -> Dictionary:
	var s: Dictionary = campaign.soldiers[camp_selected]
	var before = campaign.armor_stats(s)
	var result = {"ok":false,"reason":"Select a piece to preview; nothing changes until you confirm.","before":before,"after":before.duplicate(),"appearance":campaign.armor_appearance(s),"price":0,"definition":""}
	if armor_choice.is_empty(): return result
	if armor_mode == "parts":
		if armor_choice == "__remove__": return campaign.component_preview(camp_selected,armor_group,armor_layer)
		if armor_source == "armorer":
			for offer in campaign.armorer_stock(armor_group,armor_layer):
				if offer.id != armor_choice: continue
				result = campaign.component_preview(camp_selected,armor_group,armor_layer,"",offer.definition)
				result["price"] = offer.price
				result["definition"] = offer.definition
				return result
			return result
		return campaign.component_preview(camp_selected,armor_group,armor_layer,armor_choice)
	var parts = {}
	if armor_choice != "__remove__":
		var kit = campaign.soldiers[int(armor_choice)].gear[armor_group] if armor_mode == "exchange" else armor_choice
		parts = campaign.kit_parts(kit)
	result.after = campaign.armor_stats(s,armor_group,parts)
	result.appearance[armor_group] = campaign.component_definitions(parts)
	result.ok = s.alive and not campaign.over()
	result.reason = "Both complete assemblies change owners; every component keeps its condition." if armor_mode == "exchange" else ("The complete assembly goes to stores; your soldier will be unprotected there." if armor_choice == "__remove__" else "Equip the complete assembly. The previous assembly goes to stores intact.")
	return result

func armor_action(id: String) -> bool:
	if id == "arm_close": armor_view = false
	elif id.begins_with("arm_group_"): open_armor(id.trim_prefix("arm_group_"),armor_mode)
	elif id.begins_with("arm_mode_"): armor_mode = id.trim_prefix("arm_mode_"); armor_choice = ""; armor_page = 0
	elif id.begins_with("arm_layer_"): armor_layer = id.trim_prefix("arm_layer_"); armor_mode = "parts"; armor_choice = ""; armor_page = 0
	elif id.begins_with("arm_source_"): armor_source = id.trim_prefix("arm_source_"); armor_choice = ""; armor_page = 0
	elif id.begins_with("arm_pick_"): armor_choice = id.trim_prefix("arm_pick_")
	elif id == "arm_prev": armor_page = maxi(0,armor_page-1)
	elif id == "arm_next": armor_page += 1
	elif id == "arm_remove": armor_choice = "__remove__"
	elif id == "arm_apply":
		var preview = armor_preview()
		var changed = false
		if armor_mode == "parts" and armor_source == "armorer" and armor_choice != "__remove__":
			var bought = campaign.buy_component(armor_choice)
			if not bought.is_empty(): armor_source = "stores"; armor_choice = bought; tell("Bought into stores. Preview the fit, then confirm."); return true
		elif not preview.ok: return false
		elif armor_mode == "parts": changed = campaign.fit_component(camp_selected,armor_group,armor_layer,"" if armor_choice == "__remove__" else armor_choice)
		elif armor_mode == "exchange": changed = campaign.swap_kit(camp_selected,int(armor_choice),armor_group)
		elif armor_choice == "__remove__": changed = campaign.unequip(camp_selected,armor_group)
		else: changed = campaign.equip(camp_selected,armor_choice)
		if changed: armor_choice = ""
		return changed
	return false

func armor_costs(s: Dictionary, stats: Dictionary) -> Dictionary:
	var unit = campaign.preview_unit(s,stats)
	return {"move":People.move_rate(unit),"attack":battle.attack_fatigue(unit),"guard":battle.guard_fatigue(unit),"recovery":People.recovery(unit),"capacity":People.fatigue_max(unit),"initiative":battle.initiative_value(unit),"burden":People.equipment_load(unit)}

func armor_condition_detail(item: Dictionary, definition: Dictionary) -> String:
	if definition.durability == 0: return "Cosmetic"
	return "%d/%d · %s" % [item.condition,definition.durability,Armor.condition_state(item.condition,definition.durability)]

func armor_state_color(current: int, maximum: int) -> Color:
	return RED if current == 0 and maximum > 0 else GOLD if current < maximum else MUTED

func _draw_armor_editor() -> void:
	buttons.clear()
	var s: Dictionary = campaign.soldiers[camp_selected]
	var current_parts = campaign.kit_parts(s.gear[armor_group])
	var preview = armor_preview()
	draw_rect(Rect2(0,0,1440,900),Color("0c1310"))
	panel(Rect2(28,35,1384,830),Color("17231b"),GOLD)
	label_at(s.name+" · "+("Body assembly" if armor_group == "body" else "Helmet assembly"),Vector2(55,82),29,PAPER,true)
	button("arm_group_body","BODY · 6 LAYERS",Rect2(735,55,184,43),true,armor_group == "body")
	button("arm_group_head","HELMET · 5 PARTS",Rect2(930,55,184,43),true,armor_group == "head")
	button("arm_close","CLOSE / ESC",Rect2(1225,55,160,43),true,true)
	for i in 3:
		var mode: String = ["parts","kits","exchange"][i]
		button("arm_mode_"+mode,["COMPONENTS","WHOLE KITS","EXCHANGE KITS"][i],Rect2(55+i*195,115,184,40),true,armor_mode == mode)
	label_at("%d CROWNS  ·  %d TOOLS" % [campaign.crowns,campaign.tools],Vector2(1050,143),14,GOLD)
	label_at("CURRENT COMPONENTS",Vector2(55,190),12,GOLD)
	for i in Armor.LAYERS[armor_group].size():
		var layer: String = Armor.LAYERS[armor_group][i]
		var item: String = current_parts.get(layer,"")
		var d = campaign.item_def(item)
		var y = 209+i*77
		var rect = Rect2(55,y,355,68)
		panel(rect,Color("2b3526") if armor_mode == "parts" and armor_layer == layer else Color("1d2a20"),GOLD if armor_mode == "parts" and armor_layer == layer else Color("394737"))
		buttons["arm_layer_"+layer] = {"rect":rect,"enabled":true}
		label_at(Armor.LABELS[layer].to_upper(),Vector2(68,y+17),10,GOLD)
		label_at(d.get("name","Empty"),Vector2(68,y+39),17,PAPER if not d.is_empty() else MUTED,true)
		if not d.is_empty(): label_at(armor_condition_detail(campaign.items[item],d)+" · %d load" % Armor.part_weight(campaign.items[item],campaign.catalog),Vector2(68,y+57),11,armor_state_color(campaign.items[item].condition,d.durability))
	centered("CURRENT",Vector2(545,190),12,MUTED)
	centered("PREVIEW",Vector2(760,190),12,GOLD)
	var portrait = camp_portrait(s)
	_draw_soldier(portrait,Vector2(545,294),2.4)
	portrait = portrait.duplicate(true)
	portrait.appearance = preview.appearance
	portrait.armor_parts = []
	portrait.armor = preview.after.armor
	portrait.helmet = preview.after.helmet
	_draw_soldier(portrait,Vector2(760,294),2.4)
	var before_cost = armor_costs(s,preview.before)
	var after_cost = armor_costs(s,preview.after)
	panel(Rect2(450,404,430,310),Color("1d2a20"))
	label_at("CURRENT / MAX",Vector2(465,425),10,GOLD)
	centered("EQUIPPED",Vector2(691,425),10,MUTED)
	centered("PREVIEW",Vector2(811,425),10,GOLD)
	for i in 2:
		var group: String = "body" if i == 0 else "head"
		var comparison = Armor.comparison(preview.before,preview.after,group)
		var a: Dictionary = comparison.before; var b: Dictionary = comparison.after
		var y = 452+i*71
		label_at("Body armour" if i == 0 else "Helmet armour",Vector2(465,y),14,PAPER)
		centered("%d / %d" % [a.current,a.maximum],Vector2(691,y),15,PAPER)
		centered("%d / %d" % [b.current,b.maximum],Vector2(811,y),15,PAPER)
		centered(Armor.condition_state(a.current,a.maximum),Vector2(691,y+18),10,armor_state_color(a.current,a.maximum))
		centered(Armor.condition_state(b.current,b.maximum),Vector2(811,y+18),10,armor_state_color(b.current,b.maximum))
		label_at("Change:",Vector2(465,y+38),11,MUTED)
		label_at("%+d now" % comparison.now_change,Vector2(565,y+38),12,BLUE if comparison.now_change > 0 else RED if comparison.now_change < 0 else MUTED)
		label_at("%+d max" % comparison.max_change,Vector2(715,y+38),12,BLUE if comparison.max_change > 0 else RED if comparison.max_change < 0 else MUTED)
	var metrics = [["Total gear load","burden",false],["Stamina available","capacity",true],["Initiative","initiative",true],["Attack fatigue","attack",false],["Turn recovery","recovery",true]]
	for i in metrics.size():
		var m = metrics[i]
		var a: int = preview.before.get(m[1],before_cost.get(m[1],0))
		var b: int = preview.after.get(m[1],after_cost.get(m[1],0))
		var y = 598+i*23
		label_at(m[0],Vector2(465,y),13,MUTED)
		centered(str(a),Vector2(691,y),14,PAPER)
		centered("%d (%+d)" % [b,b-a] if a != b else str(b),Vector2(811,y),14,BLUE if (b>a)==m[2] and a!=b else (RED if a!=b else PAPER))
	var inspected: Dictionary = campaign.items.get(armor_choice,{}) if armor_mode == "parts" and armor_source == "stores" and not armor_choice.is_empty() else campaign.items.get(current_parts.get(armor_layer,""),{}) if armor_mode == "parts" else {}
	var named_note = "Now = usable durability. Max = fully repaired capacity. All body layers form one armour pool."
	if inspected.has("named"):
		var ordinary: Dictionary = campaign.catalog[inspected.definition]
		named_note = "NAMED · Ordinary %s: %d protection / %d load. %s." % [ordinary.name,ordinary.durability,ordinary.weight,Named.summary(inspected)]
	var lines = wrapped_lines(named_note,420,11,3)
	for i in lines.size(): label_at(lines[i],Vector2(455,733+i*16),11,MUTED)
	lines = wrapped_lines(inspected.named.lore if inspected.has("named") else "Shown burden includes Brawny; Perfect Fit can reduce initiative loss further. Armour perk effectiveness uses raw weight. Recovery is normally 15.",420,11,3)
	for i in lines.size(): label_at(lines[i],Vector2(455,782+i*16),11,MUTED)
	if armor_mode == "parts":
		button("arm_source_stores","COMPANY STORES",Rect2(925,177,220,37),true,armor_source == "stores")
		button("arm_source_armorer","TOWN ARMOURER",Rect2(1155,177,230,37),true,armor_source == "armorer")
	else: label_at("STORED ASSEMBLIES" if armor_mode == "kits" else "CHOOSE A COMPANY MEMBER",Vector2(925,200),14,GOLD)
	var entries = armor_entries()
	var pages = maxi(1,ceili(float(entries.size())/5))
	armor_page = clampi(armor_page,0,pages-1)
	for i in mini(5,entries.size()-armor_page*5):
		var id: String = entries[armor_page*5+i]
		var name = ""; var detail = ""
		if armor_mode == "exchange":
			var other: Dictionary = campaign.soldiers[int(id)]
			name = other.name
			var stats = campaign.armor_stats(other)
			detail = "Body %d/%d · helmet %d/%d · %d load" % [stats.armor+stats.padding,stats.max_armor+stats.max_padding,stats.helmet,stats.max_helmet,stats.load]
		elif armor_mode == "parts" and armor_source == "armorer":
			var offer: Dictionary = campaign.armorer_stock(armor_group,armor_layer).filter(func(o): return o.id == id)[0]
			var d: Dictionary = campaign.catalog[offer.definition]
			name = d.name
			detail = "%dc · %d protection · %d load · one this week" % [offer.price,d.durability,d.weight]
		else:
			var d = campaign.item_def(id)
			name = campaign.kit_name(id) if armor_mode == "kits" else d.name
			if armor_mode == "kits":
				detail = campaign.kit_summary(id)
			else: detail = armor_condition_detail(campaign.items[id],d)+" · %d load · %s" % [Armor.part_weight(campaign.items[id],campaign.catalog),id.replace("item_","#")]
		var y = 235+i*73
		var rect = Rect2(925,y,460,65)
		panel(rect,Color("303927") if armor_choice == id else Color("1c291f"),GOLD if armor_choice == id else Color("3b4a38"))
		buttons["arm_pick_"+id] = {"rect":rect,"enabled":true}
		label_at(name,Vector2(939,y+25),18,PAPER,true)
		label_at(detail.left(70),Vector2(939,y+48),11,MUTED)
	if entries.is_empty():
		lines = wrapped_lines("The armourer is available in towns." if armor_mode == "parts" and armor_source == "armorer" and not campaign.in_town() else "No available items here. Try another component slot or the town armourer.",430,16,4)
		for i in lines.size(): label_at(lines[i],Vector2(939,270+i*24),16,MUTED)
	button("arm_prev","<",Rect2(925,612,45,32),armor_page > 0)
	centered("%d / %d" % [armor_page+1,pages],Vector2(1155,635),12,MUTED)
	button("arm_next",">",Rect2(1340,612,45,32),armor_page+1 < pages)
	var message: String = preview.reason
	if armor_mode == "exchange" and not armor_choice.is_empty():
		var other: Dictionary = campaign.soldiers[int(armor_choice)]
		var a = campaign.armor_stats(other); var b = campaign.armor_stats(other,armor_group,current_parts)
		var costs_a = armor_costs(other,a); var costs_b = armor_costs(other,b)
		message = "%s: body %d/%d → %d/%d; helmet %d/%d → %d/%d. Load %d→%d; move %d→%d, attack %d→%d, guard %d→%d, recovery %d→%d." % [other.name,a.armor+a.padding,a.max_armor+a.max_padding,b.armor+b.padding,b.max_armor+b.max_padding,a.helmet,a.max_helmet,b.helmet,b.max_helmet,a.load,b.load,costs_a.move,costs_b.move,costs_a.attack,costs_b.attack,costs_a.guard,costs_b.guard,costs_a.recovery,costs_b.recovery]
	elif preview.ok: message = "Preview only. Confirm below to change this soldier's equipment."
	var buying = armor_mode == "parts" and armor_source == "armorer" and armor_choice != "__remove__"
	if buying and preview.has("price"):
		message = ("Fit is compatible." if preview.ok else preview.reason)+" Bought pieces enter stores first."
		label_at("After purchase + 5 days' wages: %dc" % [campaign.crowns-preview.price-campaign.arrears-5*campaign.wage_cost()],Vector2(925,742),11,GOLD)
	lines = wrapped_lines(message,450,13,4)
	for i in lines.size(): label_at(lines[i],Vector2(925,671+i*18),13,BLUE if preview.ok else MUTED if armor_choice.is_empty() else RED)
	var title = "CONFIRM COMPONENT SWAP" if armor_mode == "parts" else ("EXCHANGE COMPLETE KITS" if armor_mode == "exchange" else "EQUIP COMPLETE KIT")
	if armor_choice == "__remove__": title = "REMOVE TO STORES" if armor_mode == "parts" else "STORE COMPLETE KIT"
	elif buying: title = "BUY TO STORES · %dc" % preview.get("price",0)
	button("arm_apply",title,Rect2(925,764,460,45),(preview.ok and not armor_choice.is_empty()) if not buying else preview.get("price",0) > 0 and campaign.crowns >= preview.price and not campaign.over(),true)
	button("arm_remove","PREVIEW REMOVAL" if armor_mode == "parts" else "PREVIEW STORING KIT",Rect2(55,764,355,45),s.alive and not campaign.over() and ((not current_parts.get(armor_layer,"").is_empty()) if armor_mode == "parts" else not s.gear[armor_group].is_empty()) and armor_mode != "exchange")
	label_at("Pieces retain their condition. Whole kits stay assembled in stores and when exchanged. F5 saves · F9 loads.",Vector2(55,841),12,MUTED)

func _draw_equipped_soldier(u: Dictionary, p: Vector2, zoom: float) -> void:
	var appearance: Dictionary = u.get("appearance",{"body":{},"head":{}}).duplicate(true)
	if not u.has("appearance"):
		for part in u.get("armor_parts",[]): appearance[part.group][part.layer] = part.definition
	var body: Dictionary = appearance.get("body",{})
	var head: Dictionary = appearance.get("head",{})
	draw_set_transform(p,0,Vector2.ONE*zoom)
	var base: Dictionary = campaign.catalog.get(body.get("base",""),{})
	var cloth = Color(base.get("color","6d7460"))
	draw_circle(Vector2(1,15),30,Color(0,0,0,0.3))
	var cape: Dictionary = campaign.catalog.get(body.get("cloak",""),{})
	if not cape.is_empty():
		var color = Color(cape.color)
		if cape.shape != "fur": draw_colored_polygon(PackedVector2Array([Vector2(-15,-3),Vector2(15,-3),Vector2(30,38),Vector2(-29,38)]),color.darkened(0.17))
	draw_colored_polygon(PackedVector2Array([Vector2(-20,2),Vector2(-12,-7),Vector2(13,-7),Vector2(21,3),Vector2(17,30),Vector2(-17,30)]),Color("121b17"))
	draw_colored_polygon(PackedVector2Array([Vector2(-17,3),Vector2(-10,-5),Vector2(11,-5),Vector2(18,4),Vector2(14,29),Vector2(-14,29)]),cloth)
	for i in 5: draw_line(Vector2(-13,2+i*5),Vector2(13,2+i*5),cloth.darkened(0.25),0.7)
	var mail: Dictionary = campaign.catalog.get(body.get("mail",""),{})
	if not mail.is_empty():
		var color = Color(mail.color); var height = 34 if mail.shape == "mail_long" else 22
		draw_rect(Rect2(-13,-2,26,height),color.darkened(0.1))
		if mail.shape != "mail_short":
			draw_rect(Rect2(-20,0,7,20),color); draw_rect(Rect2(13,0,7,20),color)
		for y in range(1,height,4):
			for x in range(-10,12,4): draw_arc(Vector2(x,y),1.4,0,TAU,6,color.darkened(0.45),0.6)
	var outer: Dictionary = campaign.catalog.get(body.get("outer",""),{})
	if not outer.is_empty():
		var color = Color(outer.color)
		draw_colored_polygon(PackedVector2Array([Vector2(-12,-3),Vector2(12,-3),Vector2(15,13),Vector2(11,24),Vector2(-11,24),Vector2(-15,13)]),color)
		if outer.shape in ["plate","patched"]:
			draw_line(Vector2(0,-2),Vector2(0,23),color.lightened(0.25),1.5)
			draw_line(Vector2(-11,18),Vector2(11,18),color.darkened(0.3),1.2)
		elif outer.shape == "scale":
			for y in range(1,22,5):
				for x in range(-9,11,5): draw_arc(Vector2(x,y),3,0,PI,6,color.darkened(0.4),1)
		elif outer.shape == "brigandine":
			for y in range(2,22,6):
				for x in [-8,0,8]: draw_circle(Vector2(x,y),0.8,GOLD)
	var over: Dictionary = campaign.catalog.get(body.get("cloth",""),{})
	if not over.is_empty():
		var color = Color(over.color)
		if over.shape == "sash": draw_line(Vector2(-13,-3),Vector2(13,23),color,5)
		else:
			draw_rect(Rect2(-7,-3,14,35 if over.shape == "surcoat" else 30),color)
			draw_line(Vector2(-6,8),Vector2(6,8),PAPER,2); draw_line(Vector2(0,2),Vector2(0,16),PAPER,2)
	var rein: Dictionary = campaign.catalog.get(body.get("reinforce",""),{})
	if not rein.is_empty():
		var color = Color(rein.color)
		if rein.shape == "shoulders": draw_circle(Vector2(-18,0),6,color); draw_circle(Vector2(18,0),6,color)
		else: draw_arc(Vector2(0,-5),11,0,PI,12,color,4)
	if cape.get("shape","") == "fur":
		for x in range(-19,21,5): draw_circle(Vector2(x,-2+absi(x)/5),4,Color(cape.color))
	draw_line(Vector2(-14,23),Vector2(14,23),Color("4b3b2b"),3)
	draw_circle(Vector2(0,-14),12,Color("182119"))
	var liner: Dictionary = campaign.catalog.get(head.get("padding",""),{})
	if not liner.is_empty(): draw_circle(Vector2(0,-14),11.5,Color(liner.color))
	var coif: Dictionary = campaign.catalog.get(head.get("mail",""),{})
	if not coif.is_empty():
		draw_rect(Rect2(-12,-12,24,14),Color(coif.color))
		for x in range(-11,12,3): draw_line(Vector2(x,-10),Vector2(x,1),Color(coif.color).darkened(0.4),0.6)
	draw_circle(Vector2(0,-14),8.5,Color("d4d0ae") if u.get("faction","") == "undead" else Color("c9ad88"))
	var shell: Dictionary = campaign.catalog.get(head.get("shell",""),{})
	if not shell.is_empty():
		var color = Color(shell.color)
		draw_arc(Vector2(0,-15),10,PI,TAU,18,color,5)
		draw_rect(Rect2(-11,-18,22,4),color.darkened(0.2))
		if shell.shape == "kettle": draw_line(Vector2(-17,-14),Vector2(17,-14),color,4)
		elif shell.shape == "nasal": draw_line(Vector2(0,-21),Vector2(0,-8),color.lightened(0.17),3)
		elif shell.shape == "bascinet": draw_colored_polygon(PackedVector2Array([Vector2(-8,-22),Vector2(2,-31),Vector2(10,-22)]),color)
	draw_line(Vector2(-6,-12),Vector2(-3,-12),Color("2b2c20"),1.5)
	draw_line(Vector2(3,-12),Vector2(6,-12),Color("2b2c20"),1.5)
	if u.get("faction","") == "undead":
		draw_circle(Vector2(-4,-13),2.4,Color("18221d")); draw_circle(Vector2(4,-13),2.4,Color("18221d"))
		for x in [-3,0,3]: draw_line(Vector2(x,-8),Vector2(x,-5),Color("4b4d3d"),1)
	var face: Dictionary = campaign.catalog.get(head.get("face",""),{})
	if not face.is_empty():
		var color = Color(face.color)
		if face.shape == "visor":
			draw_rect(Rect2(-10,-14,20,10),color); draw_line(Vector2(-7,-12),Vector2(7,-12),Color("18231e"),2)
		else: draw_rect(Rect2(-10,-13,5,10),color); draw_rect(Rect2(5,-13,5,10),color)
	var decor: Dictionary = campaign.catalog.get(head.get("decor",""),{})
	if not decor.is_empty():
		var color = Color(decor.color)
		if decor.shape == "wrap": draw_arc(Vector2(0,-15),11,PI,TAU,12,color,3)
		elif decor.shape == "crest": draw_line(Vector2(0,-24),Vector2(0,-35),color,3)
		else: draw_line(Vector2(0,-24),Vector2(5,-37),color,5); draw_line(Vector2(5,-37),Vector2(13,-39),color,4)
	if u.shield:
		var shield_def: String = u.get("arms",{}).get("shield",{}).get("definition","shield")
		if shield_def in ["buckler","round_shield"]:
			var radius = 9 if shield_def == "buckler" else 13
			draw_circle(Vector2(-21,12),radius,Color("b3a483"))
			draw_circle(Vector2(-21,12),radius-2,Color("7e6744"))
			draw_line(Vector2(-21,12-radius+2),Vector2(-21,12+radius-2),Color("b29b6f"),1)
			draw_circle(Vector2(-21,12),3,Color("a7aaa1"))
		else:
			draw_colored_polygon(PackedVector2Array([Vector2(-29,1),Vector2(-12,1),Vector2(-12,18),Vector2(-20,28),Vector2(-29,18)]),Color("c2b58e"))
			draw_colored_polygon(PackedVector2Array([Vector2(-27,3),Vector2(-14,3),Vector2(-14,17),Vector2(-20,24),Vector2(-27,17)]),cloth.darkened(0.2))
			draw_line(Vector2(-20,3),Vector2(-20,22),PAPER,2)
	var length = 1.3 if u.weapon in ["greatsword","greataxe","maul","glaive","warbow","heavy_crossbow","heavy_spear"] else 0.72 if u.weapon in ["shortsword","hatchet","knife","shortbow","militia_spear"] else 1.0
	match Arsenal.family(u.weapon):
		"throwing":
			if u.weapon == "bolas":
				for end in [Vector2(18,0),Vector2(35,5),Vector2(30,-14)]:
					draw_line(Vector2(24,26),end,Color("aa8659"),2)
					draw_circle(end,4,PAPER)
			else: draw_line(Vector2(24,26),Vector2(27,-26 if u.weapon == "javelins" else -10),Color("aa8659"),3)
			if u.weapon == "javelins": draw_colored_polygon(PackedVector2Array([Vector2(27,-35),Vector2(23,-24),Vector2(31,-24)]),PAPER)
			elif u.weapon != "bolas": draw_colored_polygon(PackedVector2Array([Vector2(25,-12),Vector2(36,-17),Vector2(37,-4),Vector2(26,-2)]),PAPER)
		"sword": draw_line(Vector2(23,20),Vector2(27,-25*length),Color("d5daca"),3); draw_line(Vector2(18,11),Vector2(29,12),GOLD,3)
		"spear": draw_line(Vector2(24,30),Vector2(25,-35*length),Color("aa8659"),3); draw_colored_polygon(PackedVector2Array([Vector2(25,-44*length),Vector2(20,-32*length),Vector2(30,-32*length)]),PAPER)
		"axe": draw_line(Vector2(23,25),Vector2(27,-26),Color("aa8659"),4); draw_colored_polygon(PackedVector2Array([Vector2(25,-27),Vector2(37,-32),Vector2(39,-18),Vector2(26,-15)]),Color("b2bdb4"))
		"bow": draw_arc(Vector2(18,0),24*length,-1.3,1.3,20,Color("bc9962"),3); draw_line(Vector2(24,-23),Vector2(24,23),PAPER,1)
		"mace": draw_line(Vector2(23,25),Vector2(25,-20),Color("aa8659"),4); draw_circle(Vector2(25,-22),7,Color("a2aaa8")); draw_line(Vector2(19,-25),Vector2(31,-19),PAPER,2)
		"hammer": draw_line(Vector2(23,25),Vector2(25,-23),Color("aa8659"),4); draw_rect(Rect2(17,-27,18,9),Color("a2aaa8")); draw_line(Vector2(35,-23),Vector2(41,-27),PAPER,3)
		"dagger": draw_line(Vector2(23,22),Vector2(25,15-16*length),PAPER,3); draw_line(Vector2(19,14),Vector2(29,14),GOLD,2)
		"polearm": draw_line(Vector2(24,31),Vector2(25,-39),Color("aa8659"),3); draw_colored_polygon(PackedVector2Array([Vector2(25,-45),Vector2(35,-28),Vector2(29,-24),Vector2(28,-34)]),PAPER)
		"crossbow": draw_line(Vector2(24,22),Vector2(26,-22),Color("aa8659"),6); draw_arc(Vector2(25,2),17,PI+0.2,TAU-0.2,18,Color("aab4ab"),3); draw_line(Vector2(9,-1),Vector2(41,-1),PAPER,1)

	draw_set_transform(Vector2.ZERO)

func open_armory(slot: String = "weapon") -> void:
	arms_view = true; arms_slot = slot; arms_source = "stores"; arms_choice = ""; arms_page = 0

func armory_entries() -> Array:
	if arms_source == "shop": return campaign.weapons_stock().filter(func(p): return Arsenal.allowed(arms_slot,p.definition,campaign.catalog)).map(func(p): return p.id)
	return campaign.stash(arms_slot)

func armory_selection() -> Dictionary:
	if arms_source == "shop":
		for offer in campaign.weapons_stock():
			if offer.id == arms_choice: return {"definition":offer.definition,"price":offer.price,"condition":int(campaign.catalog[offer.definition].durability)}
	elif campaign.items.has(arms_choice): return campaign.items[arms_choice].duplicate()
	return {}

func armory_action(id: String) -> bool:
	if campaign.phase != "camp": return false
	if id == "arms_close": arms_view = false
	elif id.begins_with("arms_slot_"): arms_slot = id.trim_prefix("arms_slot_"); arms_choice = ""; arms_page = 0
	elif id.begins_with("arms_source_"): arms_source = id.trim_prefix("arms_source_"); arms_choice = ""; arms_page = 0
	elif id.begins_with("arms_pick_"): arms_choice = id.trim_prefix("arms_pick_")
	elif id == "arms_prev": arms_page = maxi(0,arms_page-1)
	elif id == "arms_next": arms_page += 1
	elif id == "arms_remove": return campaign.unequip(camp_selected,arms_slot)
	elif id == "arms_refill": return campaign.refill_ammo(camp_selected)
	elif id == "arms_apply":
		if arms_source == "shop":
			var item = campaign.buy_weapon(arms_choice)
			if item.is_empty(): return false
			arms_source = "stores"; arms_choice = item
			return true
		var changed = campaign.equip(camp_selected,arms_choice,arms_slot)
		if changed: arms_choice = ""
		return changed
	return false

func weapon_profile(s: Dictionary, definition: String, item: Dictionary = {}) -> Dictionary:
	if not definition in Arsenal.WEAPONS: return {}
	var unit = campaign.preview_unit(s)
	unit["weapon"] = definition
	unit.arms.weapon = item.duplicate(true) if not item.is_empty() else {"definition":definition}
	if definition in Arsenal.TWO_HANDS: unit.arms.shield = {}
	var stats: Dictionary = battle.weapon_stats(unit).duplicate(); stats.reach = battle.weapon_reach(unit)
	if battle.perk_rules: stats.pierce = battle.perk_penetration(unit,stats)
	var grip = battle.double_grip_factor(unit)
	stats.min = roundi(stats.min*grip); stats.max = roundi(stats.max*grip)
	stats.armor *= battle.hammer_armor_factor(unit)
	var special_available = not (battle.perk_rules and Arsenal.family(definition) == "sword" and definition in Arsenal.TWO_HANDS)
	return {"definition":definition,"stats":stats,"double_grip":grip > 1.0,"primary":battle.action_cost(unit,false),"special":battle.action_cost(unit,true),"special_available":special_available,"capacity":People.fatigue_max(unit),"initiative":battle.initiative_value(unit)}

func armory_comparison() -> Dictionary:
	var s: Dictionary = campaign.soldiers[camp_selected]
	var chosen = armory_selection()
	var definition: String = chosen.get("definition",campaign.item_def(s.gear.get(arms_slot,"")).get("weapon",""))
	if not definition in Arsenal.WEAPONS: return {}
	var reference_slot = arms_slot
	if not campaign.items.get(s.gear[reference_slot],{}).get("definition","") in Arsenal.WEAPONS: reference_slot = "weapon"
	return {"before":weapon_profile(s,campaign.items[s.gear[reference_slot]].definition,campaign.items[s.gear[reference_slot]]),"after":weapon_profile(s,definition,chosen if not chosen.is_empty() else campaign.items.get(s.gear.get(arms_slot,""),{})),"reference_slot":reference_slot,"selected":not chosen.is_empty()}

func weapon_comparison_rows(comparison: Dictionary) -> Array:
	var a: Dictionary = comparison.before; var b: Dictionary = comparison.after
	var x: Dictionary = a.stats; var y: Dictionary = b.stats
	var rows: Array = []
	for entry in [["Damage",x.min,x.max,y.min,y.max],["Reach (hexes)",x.min_range,x.reach,y.min_range,y.reach]]:
		var low = entry[3]-entry[1]; var high = entry[4]-entry[2]
		var good = low >= 0 and high >= 0 if entry[0] == "Damage" else low <= 0 and high >= 0
		var bad = low <= 0 and high <= 0 if entry[0] == "Damage" else low >= 0 and high <= 0
		rows.append({"label":entry[0],"before":"%d–%d" % [entry[1],entry[2]],"after":"%d–%d" % [entry[3],entry[4]],"change":"—" if low == 0 and high == 0 else "%+d / %+d" % [low,high],"color":MUTED if low == 0 and high == 0 else BLUE if good else RED if bad else GOLD})
	for entry in [["Attack AP",a.primary.ap,b.primary.ap,false,"number"],["Attack fatigue",a.primary.fatigue,b.primary.fatigue,false,"number"],["Attack accuracy",x.skill,y.skill,true,"signed"],["Armour damage",x.armor,y.armor,true,"multiplier"],["Penetration",roundi(x.pierce*100),roundi(y.pierce*100),true,"percent"],["Hands",x.hands,y.hands,false,"number"]]:
		var delta = entry[2]-entry[1]
		var left = "%d" % entry[1]; var right = "%d" % entry[2]; var change = "%+d" % delta
		if entry[4] == "signed": left = "%+d" % entry[1]; right = "%+d" % entry[2]
		elif entry[4] == "multiplier": left = "×%.2f" % entry[1]; right = "×%.2f" % entry[2]; change = "%+.2f×" % delta
		elif entry[4] == "percent": left += "%"; right += "%"; change += " pp"
		rows.append({"label":entry[0],"before":left,"after":right,"change":"—" if is_zero_approx(delta) else change,"color":MUTED if is_zero_approx(delta) else BLUE if (delta > 0) == entry[3] else RED})
	rows.append({"label":"Ammunition","before":ammo_label(a.definition),"after":ammo_label(b.definition),"change":"Same" if ammo_label(a.definition) == ammo_label(b.definition) else "Changed","color":MUTED if Arsenal.ammo_type(a.definition) == Arsenal.ammo_type(b.definition) else GOLD})
	return rows

func weapon_preview_notes(comparison: Dictionary) -> Array:
	if comparison.is_empty() or not comparison.selected: return ["Choose an item to compare. Nothing changes until you confirm."]
	var s: Dictionary = campaign.soldiers[camp_selected]
	var definition: String = comparison.after.definition
	var notes: Array = []
	if arms_slot == "weapon":
		notes.append("Stamina capacity %d → %d; fresh initiative %d → %d." % [comparison.before.capacity,comparison.after.capacity,comparison.before.initiative,comparison.after.initiative])
	if arms_slot in Arsenal.CARRIED:
		notes.append("Stores in the carried slot; main hand stays equipped. Stats show this weapon when wielded.")
		if definition in Arsenal.TWO_HANDS and s.gear.shield != "": notes.append("Battle switch needs the other carried slot empty to stow your shield.")
	elif definition in Arsenal.TWO_HANDS and s.gear.shield != "": notes.append("Two hands: equipping returns your shield to stores.")
	elif definition not in Arsenal.TWO_HANDS and s.gear.shield == "": notes.append("One hand: off hand stays empty until you equip a shield.")
	var perk_note = ""
	# Preview the candidate weapon using this mercenary's saved perks.
	var note_unit = campaign.preview_unit(s); note_unit.weapon = definition
	perk_note = battle.weapon_perk_notes(note_unit)
	if not perk_note.is_empty(): notes.append(perk_note)
	if comparison.after.double_grip:
		notes.append("Double Grip: +25% damage included. Puncture and Split Shield receive no bonus.")
	if Arsenal.family(definition) == "throwing":
		notes.append("Five throws per full bundle; carried bundles keep their own count. Shield compatible; can throw while engaged. Refill in town.")
	elif definition in Arsenal.RANGED:
		var needed = Arsenal.ammo_type(definition)
		var ammo = campaign.items.get(s.gear.ammo,{})
		if ammo.get("definition","") != needed: notes.append("Needs %s: fit a matching ammunition pack before battle." % needed)
		elif ammo.get("condition",0) == 0: notes.append("Equipped %s are empty: refill before battle." % needed)
		else: notes.append("Uses equipped %s: %d remaining." % [needed,ammo.condition])
	if arms_source == "shop": notes.append("Buying puts this item in stores. Equipping is a separate confirmation.")
	elif arms_slot == "weapon": notes.append("Preview only. Confirm to equip; your old weapon returns to stores.")
	return notes

func _draw_weapon_comparison(s: Dictionary, comparison: Dictionary) -> void:
	var slots = {"weapon":"MAIN HAND","carry1":"CARRIED I","carry2":"CARRIED II","carry3":"CARRIED III","carry4":"CARRIED IV"}
	var reference = slots.get(comparison.reference_slot,"MAIN HAND")
	centered(("CURRENT " if comparison.reference_slot == arms_slot else "REFERENCE: ")+reference,Vector2(555,188),10,MUTED)
	centered("PREVIEW",Vector2(775,188),11,GOLD)
	for i in 2:
		var profile: Dictionary = comparison.before if i == 0 else comparison.after
		var x = 555+i*220
		var portrait = camp_portrait(s); portrait.weapon = profile.definition
		if profile.definition in Arsenal.TWO_HANDS: portrait.shield = false
		_draw_soldier(portrait,Vector2(x,257),1.65)
		var lines = wrapped_lines(profile.stats.name,205,15,2)
		for j in lines.size(): centered(lines[j],Vector2(x,333+j*18),15,PAPER,true)
		centered("%s · %d%% head chance" % [Arsenal.primary(profile.definition),profile.stats.get("head_chance",20)],Vector2(x,369),11,MUTED)
	panel(Rect2(450,382,430,247),Color("1d2a20"))
	centered("CURRENT",Vector2(625,401),10,MUTED)
	centered("PREVIEW",Vector2(719,401),10,GOLD)
	centered("CHANGE",Vector2(822,401),10,MUTED)
	var rows = weapon_comparison_rows(comparison)
	for i in rows.size():
		var row: Dictionary = rows[i]; var y = 426+i*23
		label_at(row.label,Vector2(460,y),11,MUTED)
		centered(row.before,Vector2(625,y),13,PAPER)
		centered(row.after,Vector2(719,y),13,PAPER)
		centered(row.change,Vector2(822,y),11,row.color)
	for i in 2:
		var profile: Dictionary = comparison.before if i == 0 else comparison.after
		var special = battle.special_info(profile.definition); var x = 450+i*220
		panel(Rect2(x,640,210,154),Color("1b281e"))
		label_at(special.name,Vector2(x+10,661),15,PAPER,true)
		label_at("%d AP / %d fatigue" % [profile.special.ap,profile.special.fatigue] if profile.special_available else "Unavailable with this weapon",Vector2(x+10,680),11,BLUE if profile.special_available else MUTED)
		var lines = wrapped_lines(special.text if profile.special_available else "Riposte requires a one-handed sword.",190,10,7)
		for j in lines.size(): label_at(lines[j],Vector2(x+10,699+j*13),10,MUTED)
	label_at("Costs / penetration include perks. pp = percentage points.",Vector2(450,812),10,MUTED)
	label_at("Damage includes Double Grip when active; temporary combat bonuses are excluded.",Vector2(450,828),10,MUTED)

func _draw_armory() -> void:
	buttons.clear()
	var s: Dictionary = campaign.soldiers[camp_selected]
	draw_rect(Rect2(0,0,1440,900),Color("0c1310"))
	panel(Rect2(28,35,1384,830),Color("17231b"),GOLD)
	label_at(s.name+" · Weapons & carried kit",Vector2(55,82),29,PAPER,true)
	button("arms_close","CLOSE / ESC",Rect2(1225,55,160,43),true,true)
	label_at("%d CROWNS · %d AMMO · %s market" % [campaign.crowns,campaign.ammunition,campaign.Market.LABELS.get(campaign.market().get("tier",0),"No")],Vector2(55,130),14,GOLD)
	var names = {"weapon":"MAIN HAND","shield":"OFF HAND","carry1":"CARRIED I","carry2":"CARRIED II","carry3":"CARRIED III","carry4":"CARRIED IV","ammo":"AMMUNITION"}
	var visible_slots = ["weapon","shield"]+Arsenal.bag_slots(s)+["ammo"]
	for i in visible_slots.size():
		var slot: String = visible_slots[i]
		var item: String = s.gear.get(slot,"")
		var d = campaign.item_def(item)
		var y = 180+i*62
		var rect = Rect2(55,y,355,56)
		panel(rect,Color("2b3526") if slot == arms_slot else Color("1c291f"),GOLD if slot == arms_slot else Color("394737"))
		buttons["arms_slot_"+slot] = {"rect":rect,"enabled":true}
		label_at(names[slot],Vector2(68,y+18),11,GOLD)
		label_at(d.get("name","Empty"),Vector2(68,y+36),16,PAPER,true)
		if d.get("durability",0) > 0: label_at("%d / %d %s" % [campaign.items[item].condition,d.durability,"shots" if slot == "ammo" else "throws" if Arsenal.family(d.get("weapon","")) == "throwing" else "condition"],Vector2(68,y+51),10,MUTED)
	var selected_item = armory_selection()
	var definition: String = selected_item.get("definition",campaign.items.get(s.gear.get(arms_slot,""),{}).get("definition",""))
	var d: Dictionary = campaign.catalog.get(definition,{})
	var lines: Array = []
	var comparison = armory_comparison()
	if not comparison.is_empty():
		_draw_weapon_comparison(s,comparison)
	else:
		var portrait = camp_portrait(s)
		_draw_soldier(portrait,Vector2(640,275),2.5)
		label_at(d.get("name","Choose an item"),Vector2(450,405),23,PAPER,true)
		if Arsenal.shield(definition): lines = wrapped_lines("+%d melee / +%d ranged defence. Shieldwall doubles this; adjacent active walls add +5 each (up to four). Blocks wear 1 condition. Broken shields give no defence." % [d.get("melee_defense",20),d.get("ranged_defense",15)],420,16,6)
		elif definition in ["arrows","bolts"]: lines = wrapped_lines("%d shots when full. Arrows feed bows; bolts feed crossbows. Shooting consumes one round even on a miss. Refills from company supplies after battle: 1 ammo per round. Buy supplies in town. Spare packs stay in stores." % d.durability,420,16,6)
		for i in lines.size(): label_at(lines[i],Vector2(450,444+i*22),14,MUTED)
	button("arms_source_stores","COMPANY STORES",Rect2(925,125,220,38),true,arms_source == "stores")
	button("arms_source_shop","TOWN WEAPONSMITH",Rect2(1155,125,230,38),true,arms_source == "shop")
	var entries = armory_entries(); var pages = maxi(1,ceili(float(entries.size())/5))
	arms_page = clampi(arms_page,0,pages-1)
	for i in mini(5,entries.size()-arms_page*5):
		var id: String = entries[arms_page*5+i]
		var entry = campaign.items.get(id,{}).duplicate()
		if arms_source == "shop": entry = campaign.weapons_stock().filter(func(o): return o.id == id)[0]
		var def: Dictionary = Named.definition(entry,campaign.catalog)
		var y = 183+i*76
		var rect = Rect2(925,y,460,67)
		panel(rect,Color("303927") if id == arms_choice else Color("1c291f"),GOLD if id == arms_choice else Color("394737"))
		buttons["arms_pick_"+id] = {"rect":rect,"enabled":true}
		label_at(def.name,Vector2(940,y+27),17,GOLD if entry.has("named") else PAPER,true)
		label_at("%dc · one in stock this week" % entry.price if arms_source == "shop" else ("%d/%d %s" % [entry.condition,def.durability,"shots" if def.slot == "ammo" else "condition"] if def.durability > 0 else "Ready · "+id.replace("item_","#")),Vector2(940,y+50),12,MUTED)
	if entries.is_empty(): label_at("No stock here. Visit a town or choose another slot.",Vector2(925,215),13,MUTED)
	button("arms_prev","<",Rect2(925,578,45,32),arms_page > 0)
	button("arms_next",">",Rect2(1340,578,45,32),arms_page+1 < pages)
	centered("%d / %d" % [arms_page+1,pages],Vector2(1155,600),12,MUTED)
	var reason = "Weapon swaps cost 4 AP and no fatigue. Quick Hands grants one eligible free swap per round; shield swaps cost 4 AP."
	if arms_source == "shop": reason = "Weekly stock reflects local supplies, wealth and trade. Sold entries return next week."
	var allowed = s.alive and not campaign.over() and not selected_item.is_empty()
	if arms_slot == "shield" and campaign.item_def(s.gear.weapon).get("weapon","") in Arsenal.TWO_HANDS:
		reason = "A two-handed weapon is equipped. Change the main hand before equipping a shield."
		if arms_source != "shop": allowed = false
	elif arms_slot == "weapon" and definition in Arsenal.TWO_HANDS and s.gear.shield != "": reason = "Equipping this two-handed weapon returns the current shield to company stores."
	if arms_source == "shop":
		reason += " Buying places the item in stores; fitting is a separate step."
		allowed = allowed and campaign.crowns >= selected_item.get("price",999999)
	if not comparison.is_empty():
		var notes = weapon_preview_notes(comparison)
		reason = " ".join(notes)
	var inspected = selected_item if not selected_item.is_empty() else campaign.items.get(s.gear.get(arms_slot,""),{})
	if inspected.has("named"):
		var ordinary: Dictionary = battle.weapons[inspected.definition]
		reason = "Ordinary %s: %d–%d base damage. %s. %s" % [ordinary.name,ordinary.min,ordinary.max,Named.summary(inspected),inspected.named.lore]
	label_at("NAMED · MASTERWORK" if inspected.has("named") else "PREVIEW EFFECTS",Vector2(925,634),11,GOLD)
	lines = wrapped_lines(reason,455,12,7)
	for i in lines.size(): label_at(lines[i],Vector2(925,657+i*15),12,MUTED)
	button("arms_apply","BUY TO STORES · %dc" % selected_item.get("price",0) if arms_source == "shop" else "EQUIP IN "+names[arms_slot],Rect2(925,764,460,45),allowed,true)
	button("arms_remove","RETURN SELECTED SLOT TO STORES",Rect2(55,643,355,40),s.alive and not campaign.over() and arms_slot != "weapon" and s.gear.get(arms_slot,"") != "")
	var refill = campaign.ammo_refill_cost(camp_selected)
	button("arms_refill","REFILL · %d AMMO NEEDED" % refill,Rect2(55,698,355,40),campaign.can_refill_ammo(camp_selected))
	label_at("%d in reserve · partial refills allowed" % campaign.ammunition,Vector2(55,760),13,BLUE)
	label_at("1 per arrow/bolt · 3 per thrown weapon",Vector2(55,784),12,MUTED)
	label_at("Automatically replenished after battle.",Vector2(55,805),12,MUTED)
	label_at("Camp changes are free. Two bags; Bags and Belts adds two more. F5 saves · F9 loads.",Vector2(55,841),12,MUTED)

func weapon_ui_action(id: String) -> void:
	if campaign.phase != "battle" or selected < 0: return
	if id.begins_with("wa_perk_"):
		var perk = id.trim_prefix("wa_perk_")
		if perk == "indomitable":
			if battle.use_perk(selected,perk): write_save(false)
			else: tell(battle.perk_action_reason(selected,perk))
		else:
			perk_target_mode = perk; arms_view = false
			tell("Click an adjacent ally for Rotation." if perk == "rotation" else "Click an empty adjacent hex for Footwork. Escape cancels.")
	elif id == "wa_close": arms_view = false
	elif id == "wa_basic": weapon_special = false
	elif id == "wa_special": weapon_special = true
	elif id.begins_with("wa_target_"): weapon_target = int(id.trim_prefix("wa_target_"))
	elif id.begins_with("wa_switch_"):
		var slot = id.trim_prefix("wa_switch_")
		if battle.switch_carried(selected,slot): weapon_special = false
		else: tell(battle.switch_reason(selected,slot))
	elif id == "wa_apply":
		if not battle.use_weapon(selected,weapon_special,weapon_target): tell(battle.weapon_action_reason(selected,weapon_special,weapon_target))

func _draw_weapon_actions() -> void:
	buttons.clear()
	if selected < 0: return
	var u: Dictionary = battle.units[selected]
	draw_rect(Rect2(0,0,1440,900),Color("0c1310"))
	panel(Rect2(28,35,1384,830),Color("17231b"),GOLD)
	label_at(u.name+" · "+battle.weapon_stats(u).name,Vector2(55,82),29,PAPER,true)
	button("wa_close","CLOSE / ESC",Rect2(1225,55,160,43),true,true)
	label_at("%d AP · %d/%d fatigue · %s" % [u.ap,u.fatigue,battle.fatigue_max(u),battle.ORDERS[u.order]],Vector2(55,126),15,GOLD)
	if not battle.weapon_rules:
		label_at("This saved battle keeps its original weapon rules.",Vector2(55,210),25,PAPER,true)
		label_at("Finish this fight using the board's ordinary attacks and orders.",Vector2(55,260),18,MUTED)
		label_at("Weapon actions, carried switches, ammunition and enemy equipment begin with your next deployment.",Vector2(55,305),18,BLUE)
		return
	for i in 2:
		var special = i == 1
		var cost = battle.action_cost(u,special,weapon_target)
		var title: String = battle.special_info(u.weapon).name if special else Arsenal.primary(u.weapon)
		var y = 159+i*108
		var rect = Rect2(55,y,355,94)
		panel(rect,Color("303927") if weapon_special == special else Color("1c291f"),GOLD if weapon_special == special else Color("394737"))
		buttons["wa_special" if special else "wa_basic"] = {"rect":rect,"enabled":true}
		label_at(title,Vector2(72,y+32),24,PAPER,true)
		label_at("%d AP / %d fatigue" % [cost.ap,cost.fatigue],Vector2(72,y+63),15,BLUE)
	var text = battle.special_info(u.weapon).text if weapon_special else "Ordinary weapon attack. Select an enemy to inspect its worn equipment and your exact hit chance."
	if weapon_special and Arsenal.family(u.weapon) == "crossbow": text = "Ready this unloaded crossbow. Requires a bolt and no adjacent enemy. The cost above includes your perks; loaded state follows this weapon through switches."
	if battle.axe_mace_rules and battle.perk_rules and weapon_special and Arsenal.family(u.weapon) == "axe":
		text = "Automatic adjacent shield hit: %d condition, or %d against Shield Expert. No HP damage." % [battle.split_shield_damage(u),battle.split_shield_damage(u,{"perks":["shield_expert"]})]
	var lines = wrapped_lines(text,355,15,6)
	for i in lines.size(): label_at(lines[i],Vector2(55,403+i*23),15,MUTED)
	label_at("Stance: "+(u.stance if not u.stance.is_empty() else "none")+" · %d reactions left" % u.reactions,Vector2(55,570),13,BLUE)
	if u.weapon in Arsenal.RANGED:
		label_at("%d/%d %s%s" % [battle.ammo_count(u),battle.armor_catalog.get(u.arms.weapon.definition if Arsenal.family(u.weapon) == "throwing" else Arsenal.ammo_type(u.weapon),{}).get("durability",0),("throws left" if Arsenal.family(u.weapon) == "throwing" else Arsenal.ammo_type(u.weapon))," · LOADED" if Arsenal.family(u.weapon) == "crossbow" and u.arms.weapon.loaded else " · UNLOADED" if Arsenal.family(u.weapon) == "crossbow" else ""],Vector2(55,602),15,GOLD)
	if battle.perk_rules:
		var state = battle.vital_state(u)
		var status: Array = []
		if Perks.has(u,"head_hunter"): status.append("HEAD READY" if state.head_ready else "Head Hunter: unprimed")
		if Perks.has(u,"opportunist"): status.append("%d cheap throws" % (2-state.throws_used))
		if Perks.has(u,"hip_shooter"): status.append("%d bow shots this round" % state.bow_shots)
		label_at(" · ".join(status),Vector2(55,630),11,BLUE)
	for i in Arsenal.bag_slots(u).size():
		var slot = "carry%d" % (i+1); var item: Dictionary = u.arms.get(slot,{})
		var switch_name: String = Named.definition(item,campaign.catalog).get("name","Empty slot")
		var switch_rect = Rect2(55+(i%2)*182,655+(i/2)*56,173,44)
		button("wa_switch_"+slot,"",switch_rect,battle.switch_reason(selected,slot).is_empty())
		var shown = switch_name
		while font.get_string_size(shown,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x > 153 and shown.length() > 4: shown = shown.left(shown.length()-2)+"…"
		centered(shown,switch_rect.position+Vector2(86,18),11,GOLD if item.has("named") else PAPER)
		centered("%d AP" % battle.switch_ap(u,slot) if not item.is_empty() else "Empty slot",switch_rect.position+Vector2(86,35),11,MUTED)
	label_at("4 AP / 0 fatigue; shield swaps cannot be free." if battle.inventory_rules else "Legacy fight: 2 AP / 4 fatigue.",Vector2(55,788),11,MUTED)
	if battle.perk_rules:
		for i in 3:
			var perk: String = ["rotation","footwork","indomitable"][i]
			if Perks.has(u,perk):
				var ap = 5 if perk == "indomitable" else 3
				var fatigue = Perks.fatigue_cost(u,20 if perk == "footwork" else 25,false)
				var enabled = battle.can_act(selected) and u.ap >= ap and u.fatigue+fatigue <= battle.fatigue_max(u) and not (perk == "indomitable" and battle.vital_state(u).indomitable)
				var rect = Rect2(925+i*155,690,149,56)
				panel(rect,Color("343b29") if enabled else Color("1c291f"),GOLD if enabled else Color("394737"))
				buttons["wa_perk_"+perk] = {"rect":rect,"enabled":enabled}
				centered(Perks.catalog()[perk].name,Vector2(rect.get_center().x,713),15,PAPER if enabled else MUTED,true)
				centered("%d AP / %d fatigue" % [ap,fatigue],Vector2(rect.get_center().x,735),11,GOLD if enabled else MUTED)
	var enemy_row = 0
	for i in range(battle.player_slots(),battle.units.size()):
		var v: Dictionary = battle.units[i]
		if v.name == "Empty rank": continue
		var dense = battle.units.filter(func(v): return v.side == 1 and v.name != "Empty rank").size()>6
		var y = 159+enemy_row*(39 if dense else 75); enemy_row += 1
		var rect = Rect2(925,y,460,36 if dense else 67)
		panel(rect,Color("303927") if weapon_target == i else Color("1c291f"),GOLD if weapon_target == i else Color("394737"))
		buttons["wa_target_%d" % i] = {"rect":rect,"enabled":v.name != "Empty rank"}
		label_at(v.name+" · "+battle.weapon_stats(v).name,Vector2(940,y+16 if dense else y+25),12 if dense else 16,PAPER if battle.living(v) else MUTED,true)
		label_at("%d HP · body %d/%d · head %d/%d%s" % [v.hp,v.armor+v.padding,v.max_armor+v.max_padding,v.helmet,v.max_helmet," · ROUTING" if v.routed else ""],Vector2(940,y+31 if dense else y+49),10 if dense else 12,MUTED)
	var v: Dictionary = battle.units[weapon_target]
	_draw_soldier(v,Vector2(650,260),2.6)
	centered(v.name,Vector2(650,386),24,PAPER,true)
	centered(v.title,Vector2(650,409),11,MUTED)
	var targeted = not weapon_special or battle.special_info(u.weapon).target
	if targeted:
		centered("%d%% HIT · %d HEXES" % [battle.hit_chance(selected,weapon_target,weapon_special),battle.distance(battle.pos(u),battle.pos(v))],Vector2(650,438),16,GOLD)
	var equipment: Array = []
	for part in v.armor_parts: equipment.append(Named.definition(part,campaign.catalog).name+(" %d/%d" % [part.condition,part.maximum] if part.maximum > 0 else ""))
	for slot in Arsenal.SLOTS:
		var item: Dictionary = v.arms.get(slot,{})
		if not item.is_empty(): equipment.append(Named.definition(item,campaign.catalog).name+(" %d/%d" % [item.condition,Named.definition(item,campaign.catalog).durability] if Named.definition(item,campaign.catalog).durability > 0 else ""))
	label_at("VISIBLE ENEMY EQUIPMENT",Vector2(450,465),12,GOLD)
	lines = wrapped_lines(", ".join(equipment),430,14,10)
	for i in lines.size(): label_at(lines[i],Vector2(450,497+i*23),14,MUTED)
	var perk_notes = wrapped_lines(battle.weapon_perk_notes(u,v),430,13,3)
	for i in perk_notes.size(): label_at(perk_notes[i],Vector2(450,680+i*21),13,BLUE)
	label_at("Victory recovers killed enemies' gear at its final condition.",Vector2(450,758),11,MUTED)
	label_at("Routed or escaped enemies keep their equipment.",Vector2(450,780),11,MUTED)
	var reason = battle.weapon_action_reason(selected,weapon_special,weapon_target)
	lines = wrapped_lines(reason if not reason.is_empty() else "Ready. This spends the displayed AP, fatigue and ammunition.",455,15,5)
	for i in lines.size(): label_at(lines[i],Vector2(925,655+i*23),15,RED if not reason.is_empty() else BLUE)
	button("wa_apply","USE "+(battle.special_info(u.weapon).name if weapon_special else Arsenal.primary(u.weapon)).to_upper(),Rect2(925,764,460,45),reason.is_empty(),true)
	label_at("Combat pauses while this panel is open. F5 saves · F9 loads. Close to move or let the enemy turn run.",Vector2(55,841),12,MUTED)

func _draw_loot() -> void:
	buttons.clear()
	draw_rect(Rect2(0,0,1440,900),Color("0c1310"))
	panel(Rect2(105,55,1230,790),Color("17231b"),GOLD)
	label_at("Recovered equipment",Vector2(140,107),30,PAPER,true)
	button("loot_close","CLOSE / ESC",Rect2(1120,78,180,43),true,true)
	label_at("Already in company stores. Kits retain their surviving components and final battle condition.",Vector2(140,150),14,MUTED)
	var loot: Array = campaign.aftermath.get("loot",[])
	var pages = maxi(1,ceili(float(loot.size())/7)); loot_page = clampi(loot_page,0,pages-1)
	for i in mini(7,loot.size()-loot_page*7):
		var row: Dictionary = loot[loot_page*7+i]; var d = campaign.item_def(row.item); var y = 180+i*77
		panel(Rect2(140,y,1160,67),Color("1c291f"))
		label_at(row.name,Vector2(157,y+28),21,GOLD if campaign.items[row.item].has("named") else PAPER,true)
		label_at("From "+row.source,Vector2(1050,y+28),14,GOLD)
		var detail = campaign.kit_summary(row.item) if d.get("assembly",false) else "%d/%d condition" % [campaign.items[row.item].condition,d.durability] if d.durability > 0 else "Weapon recovered"
		if campaign.items[row.item].has("named"): detail = "NAMED · "+Named.summary(campaign.items[row.item])+" · "+detail
		label_at(detail,Vector2(157,y+51),13,BLUE)
	button("loot_prev","<",Rect2(140,760,60,40),loot_page > 0)
	button("loot_next",">",Rect2(1240,760,60,40),loot_page+1 < pages)
	centered("%d items / assemblies · page %d / %d" % [loot.size(),loot_page+1,pages],Vector2(720,788),15,GOLD)


func salvage_entries() -> Array:
	var out: Array = []
	if salvage_mode == "sell":
		for id in campaign.sale_items(): out.append({"id":id,"definition":campaign.items[id].definition,"name":campaign.item_name(id),"condition":campaign.items[id].condition})
	else:
		for definition in campaign.market().get("stock",[]):
			var id = campaign.market_key()+"_"+definition
			if id in campaign.purchased_gear: continue
			out.append({"id":id,"definition":definition,"name":campaign.catalog[definition].name,"condition":int(campaign.catalog[definition].durability)})
	return out.filter(func(row): return salvage_filter == "all" or (campaign.catalog[row.definition].slot in ["weapon","shield"] if salvage_filter == "weapons" else campaign.catalog[row.definition].slot == "ammo" if salvage_filter == "ammo" else campaign.catalog[row.definition].has("group") or campaign.catalog[row.definition].get("assembly",false)))

func salvage_action(id: String) -> bool:
	if id.begins_with("salvage_resource_buy_"): return campaign.economy.trade(campaign,id.trim_prefix("salvage_resource_buy_"),false)
	if id.begins_with("salvage_resource_sell_"): return campaign.economy.trade(campaign,id.trim_prefix("salvage_resource_sell_"),true)
	if id == "salvage_close": salvage_view = false
	elif id.begins_with("salvage_mode_"): salvage_mode = id.trim_prefix("salvage_mode_"); salvage_choice = ""; salvage_page = 0; sale_confirmation = -1
	elif id.begins_with("salvage_filter_"): salvage_filter = id.trim_prefix("salvage_filter_"); salvage_choice = ""; salvage_page = 0; sale_confirmation = -1
	elif id.begins_with("salvage_pick_"): salvage_choice = id.trim_prefix("salvage_pick_"); sale_confirmation = -1
	elif id == "salvage_prev": salvage_page = maxi(0,salvage_page-1)
	elif id == "salvage_next": salvage_page += 1
	elif id == "salvage_repair": sale_confirmation = -1; return campaign.repair_stored(salvage_choice)
	elif id == "salvage_apply":
		if salvage_mode == "buy":
			var item = campaign.buy_weapon(salvage_choice)
			if item.is_empty(): item = campaign.buy_component(salvage_choice)
			if item.is_empty(): return false
			salvage_mode = "sell"; salvage_choice = item; salvage_page = 0; sale_confirmation = -1
			return true
		var quote = campaign.sale_quote(salvage_choice)
		if not quote.reason.is_empty(): return false
		if sale_confirmation < 0: sale_confirmation = quote.price; return false
		var changed = campaign.sell_item(salvage_choice,sale_confirmation)
		sale_confirmation = -1
		if changed: salvage_choice = ""
		return changed
	return false

func _draw_salvage() -> void:
	buttons.clear()
	draw_rect(Rect2(0,0,1440,900),Color("0c1310")); panel(Rect2(28,35,1384,830),Color("17231b"),GOLD)
	label_at(campaign.node().name+" · Trade & salvage",Vector2(55,83),30,PAPER,true)
	button("salvage_close","CLOSE / ESC",Rect2(1225,55,160,43),true,true)
	var book = campaign.market()
	label_at("%d company crowns · %d tools · merchant purse %dc" % [campaign.crowns,campaign.tools,book.get("cash",0)],Vector2(55,126),16,GOLD)
	label_at("Local materials, funded work and household demand" if salvage_mode in ["resources","cargo","work"] else "Week %d · %s market · workshop selection reviewed on day %d" % [book.get("week",0)+1,campaign.Market.LABELS.get(book.get("tier",0),"Unavailable"),(int(book.get("week",0))+1)*7+1],Vector2(55,153),14,MUTED)
	var modes = ["sell","buy","resources","cargo","work"] if campaign.economy.enabled else ["sell","buy"]
	var titles = {"sell":"SELL EQUIPMENT","buy":"BUY EQUIPMENT","resources":"SUPPLIES","cargo":"TRADE GOODS","work":"TOWN WORK"}
	for i in modes.size(): button("salvage_mode_"+modes[i],titles[modes[i]],Rect2(55+i*266,180,256,42),true,salvage_mode == modes[i])
	if salvage_mode == "work" and campaign.economy.enabled:
		_draw_town_work(); return
	if salvage_mode in ["resources","cargo"] and campaign.economy.enabled:
		_draw_resources(); return
	for i in 4:
		var f = ["all","weapons","armour","ammo"][i]
		button("salvage_filter_"+f,f.to_upper(),Rect2(55+i*160,236,150,31),true,salvage_filter == f)
	var entries = salvage_entries(); var pages = maxi(1,ceili(float(entries.size())/7))
	salvage_page = clampi(salvage_page,0,pages-1)
	var chosen: Dictionary = {}
	for row in entries:
		if row.id == salvage_choice: chosen = row
	for i in mini(7,entries.size()-salvage_page*7):
		var row: Dictionary = entries[salvage_page*7+i]; var d: Dictionary = campaign.item_def(row.id) if salvage_mode == "sell" else campaign.catalog[row.definition]; var y = 282+i*63
		var rect = Rect2(55,y,630,56)
		panel(rect,Color("303927") if row.id == salvage_choice else Color("1c291f"),GOLD if row.id == salvage_choice else Color("394737"))
		buttons["salvage_pick_"+row.id] = {"rect":rect,"enabled":true}
		label_at(row.name,Vector2(70,y+24),18,PAPER,true)
		var detail = campaign.kit_summary(row.id) if d.get("assembly",false) else "%d/%d %s" % [row.condition,d.durability,"shots" if d.slot == "ammo" else "condition"] if d.durability > 0 else "Cosmetic · no protection" if d.has("group") else Arsenal.family(row.definition).capitalize()+" · weapon"
		label_at(detail,Vector2(70,y+44),11,MUTED)
		label_at("%dc" % (campaign.sale_quote(row.id).price if salvage_mode == "sell" else campaign.quoted_price(campaign.location,campaign.equipment_price(row.definition))),Vector2(605,y+25),14,GOLD)
	button("salvage_prev","<",Rect2(55,745,55,35),salvage_page > 0); button("salvage_next",">",Rect2(630,745,55,35),salvage_page+1 < pages)
	centered("%d / %d" % [salvage_page+1,pages],Vector2(365,769),13,MUTED)
	if chosen.is_empty():
		label_at("Select equipment to inspect its value.",Vector2(740,225),22,PAPER,true)
		var help_lines = wrapped_lines("Only unequipped items can be sold. Stored armour kits include all their components. Buying sends equipment to stores; fit it through the armour or weapon editor.",620,18,6)
		for i in help_lines.size(): label_at(help_lines[i],Vector2(740,278+i*29),18,MUTED)
	else:
		var inspected: Dictionary = campaign.items.get(chosen.id,{"definition":chosen.definition})
		var d: Dictionary = Named.definition(inspected,campaign.catalog)
		label_at(chosen.name,Vector2(740,220),28,PAPER,true)
		var details: Array = []
		if d.slot == "weapon":
			var w = Named.weapon(inspected,battle.weapons[chosen.definition])
			details = ["%d–%d damage · %d AP · %d fatigue · %+d accuracy" % [w.min,w.max,w.ap,w.fatigue,w.skill],"%d hand(s) · reach %d–%d · armour ×%.2f · pierce %d%%" % [w.hands,w.min_range,w.reach,w.armor,w.pierce*100]]
			if not inspected.has("named"): details.append_array(wrapped_lines(w.description,620,15,3))
		elif d.get("assembly",false):
			for part in campaign.kit_parts(chosen.id).values():
				if not part.is_empty(): details.append(campaign.item_name(part)+" · %d/%d" % [campaign.items[part].condition,campaign.item_def(part).durability])
		else: details = ["%d/%d %s" % [chosen.condition,d.durability,"shots" if d.slot == "ammo" else "condition"]]
		if inspected.has("named"):
			details.append_array(wrapped_lines("NAMED · "+Named.summary(inspected),620,14,2))
			details.append_array(wrapped_lines(inspected.named.lore,620,14,2))
		for i in details.size(): label_at(details[i],Vector2(740,262+i*25),15,MUTED)
		if salvage_mode == "sell":
			var quote = campaign.sale_quote(chosen.id)
			label_at("Sale now: %dc" % quote.price,Vector2(740,475),23,GOLD,true)
			label_at("Repair over time: %d tools · replacement value: %dc" % [quote.repair,quote.replacement],Vector2(740,514),15,BLUE)
			label_at("Replacement value is a comparison; local stock may differ.",Vector2(740,541),13,MUTED)
			var warning = quote.reason if not quote.reason.is_empty() else "This sells the whole kit and all %d components. No buyback." % quote.parts if d.get("assembly",false) else "This item leaves company stores. No buyback."
			var lines = wrapped_lines(warning,620,16,4)
			for i in lines.size(): label_at(lines[i],Vector2(740,596+i*25),16,RED if sale_confirmation >= 0 or not quote.reason.is_empty() else MUTED)
			button("salvage_repair","STOP REPAIRING" if salvage_choice in campaign.recovery.stored else "QUEUE REPAIRS · %d TOOLS" % quote.repair,Rect2(740,695,645,43),quote.repair > 0 and not campaign.over())
			button("salvage_apply",("CONFIRM SALE" if sale_confirmation >= 0 else "REVIEW SALE")+" · %dc" % quote.price,Rect2(740,759,645,49),quote.reason.is_empty(),true)
		else:
			var price = campaign.quoted_price(campaign.location,campaign.equipment_price(chosen.definition))
			label_at("Purchase: %dc · %dc left afterward" % [price,campaign.crowns-price],Vector2(740,475),21,GOLD,true)
			label_at("One in this week's stock. Purchase first; equip from stores.",Vector2(740,520),15,MUTED)
			button("salvage_apply","BUY TO STORES · %dc" % price,Rect2(740,759,645,49),campaign.crowns >= price and not campaign.over(),true)
	label_at("New stock each week. Conditions on your first visit set that week's selection. Purchases replenish the merchant's purse.",Vector2(55,840),12,MUTED)

func sync_active() -> void:
	if campaign.phase != "battle" or not battle.individual: return
	if observed_active == battle.active_id: return
	queue_page = 0
	observed_active = battle.active_id; selected = battle.active_id; perk_target_mode = ""
	inspected = -1; withdraw_mode = false; weapon_special = false; arms_view = false; tactics_view = false
	formation_selection = [selected] if selected >= 0 and battle.side == 0 else []
	reachable = battle.movement_map(selected) if selected >= 0 else {}
	ai_clock = 0

func _draw_turn_queue() -> void:
	var full_queue = battle.upcoming()
	queue_page = clampi(queue_page,0,maxi(0,(full_queue.size()-1)/12))
	var queue = full_queue.slice(queue_page*12,queue_page*12+12)
	if full_queue.size()>12:
		button("queue_prev","<",Rect2(999,112,29,32),queue_page>0)
		button("queue_next",">",Rect2(1037,112,29,32),queue_page*12+12<full_queue.size())
		centered("%d–%d / %d"%[queue_page*12+1,mini(queue_page*12+12,full_queue.size()),full_queue.size()],Vector2(1032,169),9,GOLD)
	for i in queue.size():
		var id: int = queue[i]; var u: Dictionary = battle.units[id]; var x = 30+i*(80 if battle.roster_rules else 85)
		var inspected_id = battle.at(hovered) if battle.at(hovered) >= 0 else inspected
		var border = GOLD if id == battle.active_id else PAPER if id == inspected_id else BLUE if u.side == 0 else RED
		var rect = Rect2(x,112,77 if battle.roster_rules else 81,65)
		panel(rect,Color("303628") if id == battle.active_id else Color("18201d"),border)
		buttons["queue_%d" % id] = {"rect":rect,"enabled":true}
		_draw_soldier(u,Vector2(x+22,138),0.44)
		centered(str(battle.turn_scores.get(str(id),0)),Vector2(x+60,140),14,border)
		centered("WAIT" if id in battle.waited else "NOW" if id == battle.active_id else str(queue_page*12+i+1),Vector2(x+59,153),8,MUTED)
		centered(u.name.left(12),Vector2(x+40,170),10,PAPER)

func person_preview(s: Dictionary, offer: bool) -> Dictionary:
	if not offer: return campaign.preview_unit(s)
	return PersonStats.offer_preview(s,campaign.catalog)

func equipped_attribute(s: Dictionary, u: Dictionary, attr: String, offer: bool) -> int:
	# The real preview has already installed rarity, wound/scar skill penalties
	# and support equipment once. Keep the modal's existing derived bonuses.
	var permanent: int = PersonStats.permanent(s,attr,offer)
	var penalty: int = 0 if offer else (10 if s.wound_days > 0 else 0)+(4 if "clouded_eye" in s.scars else 0)
	var base: int = int(u.get(attr,permanent-(penalty if attr in ["skill","ranged_skill"] else 0)))
	match attr:
		"stamina": return People.fatigue_max(u)
		"initiative": return battle.initiative_value(u)
		"health": return int(u.get("max_hp",permanent if offer else campaign.max_hp(s)))
		"skill", "ranged_skill":
			var bonus = (5 if u.temperament == "aggressive" else -4 if u.temperament == "cautious" else 0)+(5 if "weapon_drill" in s.get("perks",[]) else 0)
			if (attr == "ranged_skill") == (u.weapon in Arsenal.RANGED): bonus += battle.weapon_stats(u).skill
			if Perks.has(s,"hybridization"):
				var opposite = "skill" if attr == "ranged_skill" else "ranged_skill"
				var value: int = int(u.get(opposite,PersonStats.permanent(s,opposite,offer)-penalty))
				bonus += floori(value*0.1)
			return base+bonus
		"defense", "ranged_defense": return base+(floori(0.15*maxi(0,battle.initiative_value(u))) if Perks.has(s,"dodge") else 0)+(floori(6*Perks.medium(u)) if Perks.has(s,"balance") else 0)+(battle.shield_defence(u,attr == "ranged_defense") if battle.core_rules else 10 if u.shield else 0)+(5 if u.temperament == "cautious" else 0)
		"resolve": return floori(base*(1.25 if Perks.has(s,"fortified_mind") else 1.0))+(10 if u.temperament == "stoic" else 0)+(15 if "steadfast" in s.get("perks",[]) else 0)
	return base

func _draw_perk_tree() -> void:
	buttons.clear()
	_ui_perk_cards = {}
	var offer = not person_offer.is_empty()
	var s: Dictionary = campaign.recruit_pools[person_offer] if offer else campaign.soldiers[camp_selected]
	draw_rect(Rect2(0,0,1440,900),Color("101913"))
	panel(Rect2(24,28,1392,842),Color("17231b"),GOLD)
	label_at("PERSONAL PERKS",Vector2(48,65),12,GOLD)
	label_at((s.person if offer else s.name)+" · "+(s.name if offer else s.background),Vector2(48,104),30,PAPER,true)
	button("perk_close","CLOSE / ESC",Rect2(1210,48,180,44),true,true)
	if not Perks.modern(s):
		label_at("This saved recruit keeps their earlier training.",Vector2(48,175),25,PAPER,true)
		label_at("New personal trees are adopted at camp after this saved battle finishes.",Vector2(48,220),18,MUTED)
		for i in Progression.PERK_ORDER.size():
			var d: Dictionary = Progression.PERKS[Progression.PERK_ORDER[i]]
			label_at(d.name,Vector2(48,285+i*100),20,GOLD,true)
			var lines = wrapped_lines(d.effect,1230,15,3)
			for n in lines.size(): label_at(lines[n],Vector2(48,311+i*100+n*21),15,PAPER)
		return
	var options := Perks.offered_perks(s)
	var learned: Array = s.get("perks",[])
	var earned = 0 if offer else PerkProgression.earned(s)
	label_at("%d OPTIONS   ·   %d / 10 CAREER PICKS   ·   %d POINTS AVAILABLE" % [options.size(),learned.size(),maxi(0,earned-learned.size())],Vector2(48,143),14,BLUE)
	label_at("Background changes odds only. Gear never rerolls this tree. Spend points anywhere to unlock tiers." if s.perk_version == 3 else "All groups can be mixed. A tier needs its number minus one points spent anywhere.",Vector2(48,171),13,MUTED)
	var filters = ["All"]+s.perk_groups
	for i in filters.size():
		button("perk_group_"+filters[i],filters[i],Rect2(48+i*(1342.0/filters.size()),193,1342.0/filters.size()-8,34),true,perk_filter == filters[i])
	if perk_lab_mode and not offer and camp_selected < 3:
		for i in 3:
			button("perk_subject_%d" % i,(["Lysa","Oren","Tova"] if ranged_lab else ["Runa","Hagen","Mara"])[i],Rect2(710+i*156,80,145,32),true,camp_selected == i)
		for i in 3:
			var index = camp_selected*3+i
			button("perk_preset_%d" % index,(RangedTrials.builds() if ranged_lab else PerkTrials.builds())[index].title,Rect2(104+i*294,229,286,21),s.get("alive",false) and not campaign.over())
		button("perk_cohort_melee","MELEE FIXTURES",Rect2(710,135,180,34),true,not ranged_lab)
		button("perk_cohort_ranged","RANGED FIXTURES",Rect2(900,135,180,34),true,ranged_lab)
		button("perk_reset","RESET PICKS",Rect2(1190,135,200,34),true)
	var inspected_perk = perk_choice
	for tier in range(1,8):
		var y = 252+(tier-1)*77
		label_at("T%d" % tier,Vector2(48,y+28),17,GOLD if learned.size() >= tier-1 else MUTED,true)
		label_at("%d spent" % (tier-1),Vector2(43,y+49),9,MUTED)
		var row = options.filter(func(id): return Perks.catalog()[id].tier == tier)
		var width = minf(147,880.0/maxi(1,row.size()))
		# Keep the original card widths and 7px gaps; center the complete row.
		var row_width = row.size()*width-7
		var row_x = 104+(880-row_width)*0.5
		for i in row.size():
			var id: String = row[i]; var d: Dictionary = Perks.catalog()[id]
			var relevant = perk_filter == "All" or id in Perks.GROUPS[perk_filter]
			var matching = perk_filter != "All" and relevant
			var subdued = perk_filter != "All" and not relevant
			var rect = Rect2(row_x+i*width,y,width-7,63)
			var bought = id in learned
			var chosen = perk_choice == id
			panel(rect,Color("294239") if bought else Color("253123") if relevant else Color("19231b"),BLUE if bought else GOLD if chosen else Color("44503b"))
			# Explicit overlays survive the textured skin, which ignores panel fill.
			if matching:
				draw_rect(rect.grow(-5),Color(0.70,0.43,0.10,0.40))
				draw_rect(rect.grow(-3),GOLD,false,2)
				var marker = Vector2(rect.end.x-12,y+51)
				draw_colored_polygon(PackedVector2Array([marker+Vector2(0,-4),marker+Vector2(4,0),marker+Vector2(0,4),marker+Vector2(-4,0)]),GOLD)
			elif subdued:
				draw_rect(rect.grow(-2),Color(0.02,0.025,0.025,0.68))
			# Selection and learning remain distinct from the gold filter marker.
			if chosen: draw_rect(rect.grow(1),BLUE,false,2)
			if bought: draw_line(Vector2(rect.position.x+5,y+43),Vector2(rect.position.x+5,y+57),BLUE,2)
			_ui_perk_cards[id] = {"rect":rect,"tier":tier,"match":matching,"accent":matching,"marker":matching,"subdued":subdued,"learned":bought,"selected":chosen,"tier_open":learned.size() >= tier-1}
			_ui_perk_cards[id].make_read_only()
			buttons["perk_select_"+id] = {"rect":rect,"enabled":true}
			var name_size = 12
			var lines = wrapped_lines(d.name,rect.size.x-10,name_size,2)
			while name_size > 9 and lines.any(func(line): return serif.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,name_size).x > rect.size.x-10):
				name_size -= 1; lines = wrapped_lines(d.name,rect.size.x-10,name_size,2)
			for n in lines.size(): label_at(lines[n],Vector2(rect.position.x+5,y+20+n*15),name_size,PAPER if relevant else MUTED,true)
			label_at("LEARNED" if bought else "TIER OPEN" if learned.size() >= tier-1 else "TIER LOCKED",Vector2(rect.position.x+7,y+54),8,BLUE if bought else GOLD if relevant else MUTED)
			if rect.has_point(get_global_mouse_position()): inspected_perk = id
	_ui_perk_cards.make_read_only()
	panel(Rect2(1000,252,390,525),Color("1c2a20"))
	if not inspected_perk.is_empty():
		var d: Dictionary = Perks.catalog()[inspected_perk]
		var names = wrapped_lines(d.name,346,24,2)
		for i in names.size(): label_at(names[i],Vector2(1020,286+i*29),24,PAPER,true)
		label_at("TIER %d · ONE POINT" % d.tier,Vector2(1020,341),12,GOLD)
		var tags = s.perk_groups.filter(func(g): return inspected_perk in Perks.GROUPS[g])
		if inspected_perk in Perks.CORE+["bags_and_belts",Perks.RALLY]: tags.push_front("Shared")
		label_at(" · ".join(tags),Vector2(1020,367),11,BLUE)
		var lines = wrapped_lines(d.effect,346,14,15)
		for i in lines.size(): label_at(lines[i],Vector2(1020,400+i*21),14,PAPER)
	else:
		label_at("Choose your own route",Vector2(1020,291),24,PAPER,true)
		var lines = wrapped_lines("Inspect any perk to see its exact effect and equipment requirements. Highlight a group to explore its options; the other groups stay available.",346,16,10)
		for i in lines.size(): label_at(lines[i],Vector2(1020,334+i*25),16,MUTED)
	var gifted = not offer and Perks.has(s,"gifted") and s.gifted_choices.size() < 3
	if gifted:
		panel(Rect2(1000,370,390,407),Color("1c2a20"),GOLD)
		label_at("GIFTED · CHOOSE %d MORE" % (3-s.gifted_choices.size()),Vector2(1020,401),16,GOLD,true)
		for i in People.ATTRS.size():
			var attr: String = People.ATTRS[i]
			button("perk_gift_"+attr,"%s +%d" % [People.LABELS[attr],Perks.GIFT[attr]],Rect2(1020,420+i*40,350,34),not attr in s.gifted_choices,true)
	var reason = "Preview before hiring · this exact pool is saved." if offer else "Select a perk to learn it."
	if not offer and not perk_choice.is_empty(): reason = Perks.learn_reason(s,perk_choice,earned)
	var can_buy = not offer and s.get("alive",false) and not campaign.over() and not perk_choice.is_empty() and reason.is_empty()
	button("perk_buy","LEARN "+Perks.catalog()[perk_choice].name.to_upper() if can_buy else "PRE-HIRE PREVIEW" if offer else "NO PURCHASE AVAILABLE",Rect2(1000,794,390,46),can_buy,true)
	var worn = person_preview(s,offer)
	label_at("RAW ARMOUR LOAD %d · MEDIUM EFFECTIVENESS %d%%" % [worn.load,roundi(100*Perks.medium(worn))],Vector2(48,813),13,BLUE)
	label_at(reason if not reason.is_empty() else "Spend one earned point. Your choice is permanent.",Vector2(48,843),13,GOLD)

func ammo_label(weapon: String) -> String:
	return "5 per bundle" if Arsenal.family(weapon) == "throwing" else Arsenal.ammo_type(weapon).capitalize() if weapon in Arsenal.RANGED else "None"


func world_controls_available() -> bool:
	return iron.sheet.is_empty() and not vault_journal and campaign.phase == "camp" and campaign.dungeons.active == "" and world_view and not intro and not help and confirmation.is_empty() and not (lineup.opened or perks_view or person_view or armor_view or arms_view or salvage_view or loot_view or service_view or bonds_view or politics_view or trade_view or guide_view or planner_view or record_view or tactics_view or news_view)

func _draw_free_roam_terrain() -> void:
	var ow = campaign.overworld
	# Draw routes below an opaque mask; hidden bends cannot reveal geography.
	if not ow.path.is_empty():
		var points = PackedVector2Array([ow.position])
		for p in ow.path: points.append(p)
		draw_polyline(points,GOLD,2,true)
		draw_arc(ow.path.back(),8,0,TAU,24,GOLD,2,true)
	var fog = Color("080e0b")
	for rect in [Rect2(24,168,964,48),Rect2(24,696,964,56),Rect2(24,216,16,480),Rect2(968,216,20,480)]: draw_rect(rect,fog)
	for y in ow.SIZE.y:
		for x in ow.SIZE.x:
			var p = ow.cell_point(Vector2i(x,y))
			if not ow.discovered(p): draw_rect(Rect2(p-Vector2.ONE*8,Vector2.ONE*16),fog)
	if not campaign.in_town(): label_at("THE SOUTHERN MARCH",Vector2(52,204),12,MUTED)
	button("politics","COUNCILS & PATROLS",Rect2(548,185,184,25))
	button("trade","TRADE & ROAD REPORT",Rect2(744,185,180,25))

func known_site(id: String) -> bool:
	if campaign.dungeons.sites.has(id) and campaign.dungeons.sites[id].rumour: return true
	return campaign.overworld.places.has(id) and (campaign.overworld.discovered(campaign.overworld.places[id]) or campaign.traffic.camp_known(id) or campaign.farm.camp_known(id))

func known_news(message: String) -> bool:
	for place in campaign.region.locations:
		if not known_site(place.id) and (place.name.to_lower() in message.to_lower() or place.id.capitalize() in message): return false
	return true

func _draw_free_roam_parties() -> void:
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
		centered(("RELIEF " if campaign.rebuilding.enabled and campaign.rebuilding.shipments.has(party.id) else "")+party.name,p+Vector2(0,-15),10,tint)
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
	panel(Rect2(40,226,394,38),INK,Color("4e5b48"))
	button("world_pause","RESUME" if ow.paused else "PAUSE",Rect2(46,230,94,30),campaign.encounter.is_empty() and not campaign.over(),ow.paused)
	for i in 3:
		var speed = [1,2,4][i]
		button("world_speed_%d" % speed,"%dx" % speed,Rect2(147+i*47,230,42,30),true,ow.speed == speed)
	label_at("SPACE · pause",Vector2(298,250),11,MUTED)
	if not ow.path.is_empty(): label_at("%.1fh to destination" % ow.hours_left() if ow.path.all(func(p): return ow.discovered(p)) else "Exploring · travel time unknown",Vector2(48,288),12,GOLD)
	elif ow.rest_left > 0: label_at("Camping · %.1fh remaining" % ow.rest_left,Vector2(48,288),12,BLUE)
	elif not campaign.exploration.task.is_empty(): label_at("%s · %.1fh remaining" % [campaign.exploration.task.kind.capitalize(),campaign.exploration.task.remaining*0.05],Vector2(48,288),12,GOLD)
	elif not ow.paused: label_at("Waiting · world time is passing",Vector2(48,288),12,GOLD)

func _draw_wilderness_detail() -> void:
	var ow = campaign.overworld
	label_at("ON THE MARCH",Vector2(1030,214),12,GOLD)
	label_at(ow.terrain(ow.position).capitalize(),Vector2(1030,254),30,PAPER,true)
	label_at("PAUSED" if ow.paused else ("CAMPING" if ow.rest_left > 0 else "TRAVELLING" if not ow.path.is_empty() else "WAITING"),Vector2(1030,295),13,BLUE)
	var lines = wrapped_lines("Click any open ground to change course. Raiders pursue nearby companies; keep your distance or intercept them. Town walls offer shelter.",355,15,5)
	for i in lines.size(): label_at(lines[i],Vector2(1030,342+i*25),15,MUTED)
	label_at("Roads  100%   Plains  74%",Vector2(1030,490),14,GOLD)
	label_at("Hills  56%   Forests  45%",Vector2(1030,518),14,GOLD)
	label_at("Night reduces sight. Menus pause time.",Vector2(1030,557),12,MUTED)
	if not campaign.active.is_empty(): label_at(campaign.contract_direction(),Vector2(1030,620),13,GOLD)
	button("world_stop","HALT COMPANY",Rect2(1030,590,364,42))
	_draw_job_reminder(1030,680)
	button("rest","CAMP FOR 24 HOURS",Rect2(1030,777,364,45))

func _draw_battle_inspection() -> void:
	buttons.clear()
	var u: Dictionary = battle.units[inspection_id]
	var sid: int = campaign.deployment[inspection_id]
	var s: Dictionary = campaign.soldiers[sid]
	draw_rect(Rect2(0,0,1440,900),Color("0c1310"))
	panel(Rect2(28,35,1384,830),Color("17231b"),GOLD)
	label_at(u.name+" · "+s.background,Vector2(55,82),29,PAPER,true)
	label_at("BATTLE INSPECTION · paused · read only",Vector2(55,115),12,GOLD)
	button("inspect_close","CLOSE / ESC",Rect2(1225,55,160,43),true,true)
	for i in 3:
		var tab: String = ["stats","equipment","perks"][i]
		button("inspect_tab_"+tab,tab.to_upper(),Rect2(55+i*190,145,178,40),true,inspection_tab == tab)
	var slot_index = 0
	for i in battle.player_slots():
		if campaign.deployment[i] < 0: continue
		button("inspect_unit_%d" % i,battle.units[i].name,Rect2(55+slot_index*(108 if battle.roster_rules else 215),804,102 if battle.roster_rules else 202,38),true,inspection_id == i)
		slot_index += 1
	if inspection_tab == "stats":
		_draw_soldier(u,Vector2(180,315),2.8)
		label_at("Level %d · %d XP" % [Progression.level(s),s.xp],Vector2(70,440),19,PAPER,true)
		label_at(People.TEMPERAMENTS[s.temperament].name,Vector2(70,478),17,GOLD)
		var trait_lines = wrapped_lines(People.TEMPERAMENTS[s.temperament].effect,285,14,4)
		for i in trait_lines.size(): label_at(trait_lines[i],Vector2(70,508+i*22),14,MUTED)
		var metrics = [["Health","%d / %d" % [u.hp,u.max_hp]],["Body armour","%d / %d" % [u.armor+u.padding,u.max_armor+u.max_padding]],["Helmet","%d / %d" % [u.helmet,u.max_helmet]],["Fatigue","%d / %d" % [u.fatigue,battle.fatigue_max(u)]],["Melee skill",str(u.skill)],["Ranged skill",str(u.ranged_skill)],["Melee defence",str(u.defense)+" + %d shield" % battle.shield_defence(u,false)],["Ranged defence",str(u.ranged_defense)+" + %d shield" % battle.shield_defence(u,true)],["Resolve",str(u.resolve)],["Initiative",str(battle.initiative_value(u))],["Action points","%d / 9" % u.ap]]
		for i in metrics.size():
			label_at(metrics[i][0],Vector2(405,230+i*43),16,MUTED)
			label_at(metrics[i][1],Vector2(630,230+i*43),17,PAPER)
		label_at("ACTIVE EFFECTS",Vector2(910,230),12,GOLD)
		var effects = [battle.morale_name(u)+" morale",("Acting now" if battle.active_id == inspection_id else "Finished this round" if inspection_id in battle.finished else "Waiting for activation"),"Shieldwall" if u.guard else "No Shieldwall","Stance: "+(u.get("stance","") if not u.get("stance","").is_empty() else "none")]
		if s.wound_days > 0: effects.append("Deep wound: -12 max HP, -10 attack skills")
		if u.get("stagger",0) > 0: effects.append("Staggered: -%d AP next turn" % u.stagger)
		if battle.impact_active(u): effects.append("Deep Impact: -10 attack, -20% damage")
		var state: Dictionary = u.get("perk_state",{})
		if state.get("overwhelm",0) > 0: effects.append("Overwhelm: -%d%% attack skills" % (state.overwhelm*10))
		if state.get("indomitable",false): effects.append("Indomitable active")
		if state.get("head_ready",false): effects.append("Head Hunter ready")
		if state.get("frenzy_end",0) > state.get("activation",0): effects.append("Killing Frenzy active")
		if state.get("quick_used",false): effects.append("Free swap used this round")
		for scar in s.scars: effects.append(Progression.SCARS[scar].name)
		var y = 265
		for effect in effects:
			for line in wrapped_lines(effect,435,14,2): label_at(line,Vector2(910,y),14,BLUE); y += 20
			y += 10
		label_at("Attack skills include injuries/scars; target, morale and perk modifiers apply when attacking.",Vector2(405,745),12,MUTED)
	elif inspection_tab == "equipment":
		var rows = []
		for slot in ["weapon","shield"]+Arsenal.bag_slots(u)+["ammo"]:
			var item: Dictionary = u.arms.get(slot,{})
			var d: Dictionary = campaign.catalog.get(item.get("definition",""),{})
			var details = "Empty"
			if not item.is_empty():
				details = d.name
				if d.durability > 0: details += " · %d / %d" % [item.condition,d.durability]
				if Arsenal.family(item.definition) == "crossbow": details += " · LOADED" if item.loaded else " · UNLOADED"
			rows.append([slot.replace("carry","Bag ").capitalize(),details])
		for group in Armor.LAYERS:
			for layer in Armor.LAYERS[group]:
				var parts: Array = u.armor_parts.filter(func(p): return p.group == group and p.layer == layer)
				rows.append([(group+" · "+Armor.LABELS[layer]).capitalize(),"Empty" if parts.is_empty() else "%s · %d / %d" % [Named.definition(parts[0],campaign.catalog).name,parts[0].condition,parts[0].maximum]])
		for i in rows.size():
			var x = 60+(i/10)*680; var y = 230+(i%10)*52
			label_at(rows[i][0],Vector2(x,y),12,GOLD)
			label_at(rows[i][1],Vector2(x,y+23),16,PAPER)
		label_at("These are current battle conditions and ammunition counts. Change weapons through Weapons & active perks on your turn.",Vector2(60,770),12,MUTED)
	else:
		var pages = maxi(1,ceili(u.perks.size()/5.0)); inspection_page = clampi(inspection_page,0,pages-1)
		if u.perks.is_empty(): label_at("No perks learned yet. Gain experience and choose your build after battle.",Vector2(60,260),19,MUTED)
		for i in mini(5,u.perks.size()-inspection_page*5):
			var perk: Dictionary = PerkProgression.definition(u.perks[inspection_page*5+i])
			var y = 233+i*101
			label_at(perk.name,Vector2(60,y),20,GOLD,true)
			var lines = wrapped_lines(perk.get("effect",perk.get("text","")),1260,14,3)
			for j in lines.size(): label_at(lines[j],Vector2(60,y+25+j*19),14,PAPER)
		button("inspect_prev","<",Rect2(60,747,45,32),inspection_page > 0)
		button("inspect_next",">",Rect2(1338,747,45,32),inspection_page+1 < pages)

func _draw_resources() -> void:
	var e = campaign.economy
	label_at("Resource",Vector2(75,263),14,GOLD)
	label_at("Company / town stock",Vector2(315,263),14,GOLD)
	label_at("Buy from town",Vector2(700,263),14,GOLD)
	label_at("Sell to town",Vector2(1040,263),14,GOLD)
	var goods: Array = e.TRADE_GOODS if salvage_mode == "cargo" else e.SUPPLIES
	var pages = maxi(1,ceili(goods.size()/4.0)); salvage_page = clampi(salvage_page,0,pages-1)
	for i in mini(4,goods.size()-salvage_page*4):
		var kind: String = goods[salvage_page*4+i]; var y = 280+i*115
		panel(Rect2(55,y,1330,105),Color("1c291f"),Color("394737"))
		var buy: Dictionary = e.quote(campaign,campaign.location,kind,false)
		var sell: Dictionary = e.quote(campaign,campaign.location,kind,true)
		label_at(e.NAMES[kind],Vector2(75,y+35),22,PAPER,true)
		label_at("Bundle: %d" % buy.amount,Vector2(75,y+62),13,MUTED)
		label_at("%d / %d" % [e.owned(campaign,kind),e.stock(campaign,campaign.location,kind)],Vector2(315,y+35),22,PAPER)
		var note = e.Industry.USES[kind] if kind in e.TRADE_GOODS else "Also feeds your mercenaries" if kind == "food" else "Reserve ammo; excludes loaded weapons" if kind == "ammo" else "Also used for repairs" if kind == "tools" else "Also used for healing"
		label_at(note,Vector2(315,y+64),12,MUTED)
		button("salvage_resource_buy_"+kind,"BUY %d · %dc" % [buy.amount,buy.price],Rect2(700,y+12,290,42),buy.reason.is_empty(),true)
		button("salvage_resource_sell_"+kind,"SELL %d · %dc" % [sell.amount,sell.price],Rect2(1040,y+12,290,42),sell.reason.is_empty())
		label_at(buy.reason,Vector2(700,y+78),12,MUTED)
		label_at(sell.reason,Vector2(1040,y+78),12,MUTED)
	button("salvage_prev","<",Rect2(55,748,55,32),salvage_page>0)
	button("salvage_next",">",Rect2(1330,748,55,32),salvage_page+1<pages)
	centered("%d / %d"%[salvage_page+1,pages],Vector2(720,770),14,MUTED)
	label_at("Prices reflect local stock and funded demand. Open TOWN WORK to see what needs materials.",Vector2(75,805),15,BLUE)
	label_at("Cargo stays separate from company supplies. Towns use delivered materials automatically.",Vector2(75,835),14,MUTED)

func _draw_town_work() -> void:
	var c=campaign;var e=c.economy;var town: String=c.location;var s: Dictionary=e.industry.state.towns[town]
	var jobs: Array=e.industry.orders(c,town);var pages=maxi(1,ceili(jobs.size()/6.0));salvage_page=clampi(salvage_page,0,pages-1)
	label_at("Council %dc · households %dc · freight wagons ready %d · town damage %d"%[c.world.factions[c.world.towns[town].owner].treasury,s.households,c.world.wagon_stock[town],s.damage],Vector2(75,252),15,GOLD)
	for i in mini(6,jobs.size()-salvage_page*6):
		var job: Dictionary=jobs[salvage_page*6+i];var y=275+i*76
		panel(Rect2(55,y,1330,68),Color("1c291f"),Color("394737"))
		label_at(job.name,Vector2(75,y+26),19,PAPER,true)
		var inputs: Array=[]
		for kind in job.inputs:inputs.append("%d %s"%[job.inputs[kind],e.NAMES[kind].to_lower()])
		label_at(", ".join(inputs),Vector2(75,y+51),13,MUTED)
		label_at(e.industry.blocked(c,town,job),Vector2(620,y+27),16,BLUE)
		label_at("Paid by %s · %dc labour / service"%[job.payer,job.fee],Vector2(620,y+51),13,MUTED)
	if jobs.is_empty():label_at("Local needs are met. New work appears as stocks run low or damage occurs.",Vector2(75,310),18,PAPER)
	button("salvage_prev","<",Rect2(55,748,55,32),salvage_page>0);button("salvage_next",">",Rect2(1330,748,55,32),salvage_page+1<pages)
	centered("%d / %d"%[salvage_page+1,pages],Vector2(720,770),14,MUTED)
	label_at("Workers complete up to two orders per day; hunger and damage reduce capacity. Missing inputs delay work.",Vector2(75,805),14,BLUE)
	var inbound: Array=[]
	for kind in e.TRADE_GOODS:
		var amount: int=e.freight.incoming(c,town,kind)
		if amount>0:inbound.append("%d %s"%[amount,kind])
	label_at("Incoming paid cargo: "+(", ".join(inbound) if not inbound.is_empty() else "none")+". Check the road report for shipments.",Vector2(75,835),14,MUTED)

func trade_place(id: String) -> String:
	return campaign.node(id).name if known_site(id) else "Unknown"

func report_page(ids: Array, kind: String, at: Vector2) -> Array:
	var pages = maxi(1,ceili(ids.size()/3.0)); var page = clampi(report_towns_page if kind == "towns" else report_camps_page,0,pages-1)
	if kind == "towns": report_towns_page = page
	else: report_camps_page = page
	if pages > 1:
		button("report_"+kind+"_prev","<",Rect2(at,Vector2(30,24)),page > 0)
		label_at("%d/%d" % [page+1,pages],at+Vector2(39,17),11,MUTED)
		button("report_"+kind+"_next",">",Rect2(at+Vector2(78,0),Vector2(30,24)),page+1 < pages)
	return ids.slice(page*3,page*3+3)
