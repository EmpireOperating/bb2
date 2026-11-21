extends RefCounted
## World-caused work, conserved company trade and finite persistent town purses.
const SUPPLIES = ["food","tools","medicine","ammo"]
const TRADE_GOODS = ["furs","cloth","silk","salt"]
const GOODS = SUPPLIES+TRADE_GOODS
const STORED = ["tools","medicine","ammo","furs","cloth","silk","salt"]
const BUNDLE = {"food":24,"tools":12,"medicine":6,"ammo":30,"furs":1,"cloth":1,"silk":1,"salt":1}
const FIELD = {"food":"food","tools":"tools","medicine":"medicine","ammo":"ammunition"}
const NAMES = {"food":"Rations","tools":"Tools","medicine":"Medicine","ammo":"Ammunition","furs":"Furs","cloth":"Cloth","silk":"Silk","salt":"Salt"}
const STOCK = {"ashwick":[48,18,90,2,18,1,3],"stonecross":[120,12,210,3,3,10,18],"dunmere":[24,54,60,12,2,1,3]}
const OUTPUT = {"ashwick":[1,1,8,0,3,0,0],"stonecross":[10,0,24,0,0,2,3],"dunmere":[1,5,6,3,0,0,0]}
const DEMAND = {"tools":2,"medicine":1,"ammo":6,"furs":1,"cloth":1,"silk":1,"salt":1}
const TARGET = {"tools":36,"medicine":18,"ammo":90,"furs":6,"cloth":8,"silk":4,"salt":8}
const BASE = {"tools":36,"medicine":30,"ammo":30,"furs":85,"cloth":45,"silk":180,"salt":30}
var enabled = false
var started = 1
var last_day = 1
var towns: Dictionary = {}
var cargo: Dictionary = {"furs":0,"cloth":0,"silk":0,"salt":0}
var cargo_bought: Dictionary = {"furs":0,"cloth":0,"silk":0,"salt":0}
var cargo_sold: Dictionary = {"furs":0,"cloth":0,"silk":0,"salt":0}
var escrow: Dictionary = {}
var contracts: Dictionary = {}
var legacy_job = ""
var camp_claims: Dictionary = {}
var food_bought = 0
var food_sold = 0

func setup(c, fresh: bool) -> void:
	enabled = true; started = c.day; last_day = c.day
	for kind in TRADE_GOODS: cargo[kind] = 0; cargo_bought[kind] = 0; cargo_sold[kind] = 0
	towns.clear(); contracts.clear(); escrow.clear(); camp_claims.clear(); food_bought = 0; food_sold = 0
	legacy_job = c.active.get("id","")
	var losses = 0
	for f in c.world.factions.values(): losses += f.losses
	c.world.raid_wealth = {"baseline":losses,"camps":{}}
	for site in c.world.SITES: c.world.raid_wealth.camps[site] = {"held":0,"taken":0,"lost":0}
	for town in c.world.TOWNS:
		var t: Dictionary = c.world.towns[town]; var faction: Dictionary = c.world.factions[t.owner]
		# Initial civic reserve belongs to the new world, never to the player.
		if fresh: faction.treasury += 240; faction.contributions += 240
		contracts[t.owner] = {"reserved":0,"paid":0,"refunded":0}
		var cash: int = c.Market.CASH[c.Market.tier(t.stock,faction.treasury,t.demand,t.pressure)]
		var book = latest_book(c,town)
		if not book.is_empty(): cash = book.cash
		towns[town] = {"initial":cash,"cash":cash,"receipts":0,"retail":0,"paid":0,"goods":{}}
		for i in STORED.size():
			var kind: String = STORED[i]
			towns[town].goods[kind] = {"stock":STOCK[town][i],"produced":0,"consumed":0,"bought":0,"sold":0}

func latest_book(c, town: String) -> Dictionary:
	var out: Dictionary = {}
	for book in c.market_books.values():
		if book.town == town and (out.is_empty() or book.week > out.week): out = book
	return out

func receive(town: String, amount: int) -> void:
	towns[town].cash += amount; towns[town].receipts += amount

func pay(town: String, amount: int) -> void:
	towns[town].cash -= amount; towns[town].paid += amount

func daily(c, _food_eaten: int) -> void:
	if not enabled or last_day == c.day: return
	last_day = c.day
	for town in towns:
		var t: Dictionary = c.world.towns[town]; var market: Dictionary = towns[town]
		var fed: bool = t.stock >= t.demand
		var income = t.demand*2 if fed else 0
		for i in STORED.size():
			var kind: String = STORED[i]; var good: Dictionary = market.goods[kind]
			# Workshops slow under shortages/raids; finite storage prevents infinite hoards.
			var output: int = OUTPUT[town][i] if fed and t.pressure == 0 else OUTPUT[town][i]/2
			output = mini(output,maxi(0,TARGET[kind]*5-good.stock))
			good.stock += output; good.produced += output
			var used = mini(DEMAND[kind],good.stock)
			good.stock -= used; good.consumed += used
			income += used*(maxi(1,BASE[kind]/4) if kind in TRADE_GOODS else 3 if kind == "tools" else 5 if kind == "medicine" else 1)
		market.cash += income; market.retail += income
		var book = latest_book(c,town)
		if not book.is_empty(): book.cash += income; book.income += income

func funded_offers(c, jobs: Array) -> Array:
	var out = []
	for original in jobs:
		var job: Dictionary = original.duplicate(true)
		# Secured roads do not need a standing mercenary escort subscription.
		if job.kind == "escort" and c.world.protected_road(job.target): continue
		var available: int = c.world.factions[job.client].treasury
		if available < 50: continue
		job.pay = mini(job.pay,available)
		job.brief += " Council funds set aside on signing; no extra supply reward."
		out.append(job)
	return out

func reserve(c, job: Dictionary) -> bool:
	if not enabled: return true
	if not escrow.is_empty() or job.pay > c.world.factions[job.client].treasury: return false
	var f: Dictionary = c.world.factions[job.client]
	f.treasury -= job.pay; f.spent += job.pay
	escrow = {"id":job.id,"client":job.client,"pay":job.pay}
	contracts[job.client].reserved += job.pay
	return true

func release(c, won: bool) -> void:
	if not enabled: return
	if legacy_job != "": legacy_job = ""; return
	if escrow.is_empty(): return
	var account: Dictionary = contracts[escrow.client]
	if won: account.paid += escrow.pay
	else:
		account.refunded += escrow.pay
		c.world.factions[escrow.client].treasury += escrow.pay
		c.world.factions[escrow.client].spent -= escrow.pay
	escrow.clear()

func stock(c, town: String, kind: String) -> int:
	return c.world.towns[town].stock if kind == "food" else towns[town].goods[kind].stock

func unit_price(c, town: String, kind: String, amount: int) -> float:
	if kind == "food": return (c.world.towns[town].base_price+ceil(maxf(0.0,120.0-amount)/3.0))/24.0
	return float(BASE[kind])/BUNDLE[kind]*clampf(2.0*TARGET[kind]/(amount+TARGET[kind]),0.5,2.5)

func quote(c, town: String, kind: String, selling: bool) -> Dictionary:
	var out = {"price":0,"reason":"Unavailable","amount":0}
	if not enabled or not towns.has(town) or kind not in GOODS: return out
	var count: int = BUNDLE[kind]; var available = stock(c,town,kind); var value = 0.0
	for i in count:
		value += unit_price(c,town,kind,available+i+1 if selling else maxi(0,available-i))
	# A spread plus marginal pricing prevents buy/sell pumping and stale batch quotes.
	out.price = floori(value*0.75) if selling else ceili(value)
	out.amount = count; out.reason = ""
	if c.phase != "camp" or c.over() or not c.in_town() or town != c.location or not c.encounter.is_empty(): out.reason = "Trade at this town."
	elif selling and owned(c,kind) < count: out.reason = "Not enough in company stores."
	elif selling and towns[town].cash < out.price: out.reason = "Merchant lacks funds."
	elif not selling and available < count: out.reason = "Not enough local stock."
	elif not selling and c.crowns < out.price: out.reason = "Not enough crowns."
	return out

func trade(c, kind: String, selling: bool) -> bool:
	var q = quote(c,c.location,kind,selling)
	if not q.reason.is_empty(): return false
	c.ensure_market()
	var amount: int = q.amount; var town: String = c.location; var book: Dictionary = c.market()
	if kind == "food":
		if selling:
			c.world.towns[town].stock += amount; c.world.company_food_in += amount; food_sold += amount
		else:
			if not c.world.buy_food(town,amount): return false
			food_bought += amount
	else:
		var good: Dictionary = towns[town].goods[kind]
		good.stock += amount if selling else -amount
		good["sold" if selling else "bought"] += amount
	if kind in TRADE_GOODS:
		cargo[kind] += -amount if selling else amount
		if selling: cargo_sold[kind] += amount
		else: cargo_bought[kind] += amount
	else: c.set(FIELD[kind],c.get(FIELD[kind])+(-amount if selling else amount))
	c.crowns += q.price if selling else -q.price
	if selling:
		pay(town,q.price); book.cash -= q.price; book.spent += q.price
		book["resource_spent"] = book.get("resource_spent",0)+q.price
	else: c.market_receive(q.price)
	if kind == "ammo" and not selling: c.refill_company_ammo()
	c.note("%s %d %s for %d crowns at %s. Local stock: %d." % ["Sold" if selling else "Bought",amount,NAMES[kind].to_lower(),q.price,c.node(town).name,stock(c,town,kind)])
	return true

func claim_camp(c, site: String) -> void:
	var camp: Dictionary = c.world.camps[site]; var id = "%s/%d" % [site,camp.generation]
	if camp_claims.has(id): return
	var food: int = camp.reserves; var coins: int = c.world.raid_wealth.camps[site].held
	camp.reserves = 0; c.world.sold += food; c.food += food
	c.world.raid_wealth.camps[site].held = 0; c.world.raid_wealth.camps[site].taken += coins; c.crowns += coins
	camp_claims[id] = {"food":food,"crowns":coins}
	c.note("Camp stores taken: %d rations and %d stolen crowns. Identified freight returns to its owners." % [food,coins])

func work_hint(c) -> String:
	if not c.in_town(): return "Town contracts follow actual threats and shipments. Camp stores and equipment can be taken without a contract."
	var money: int = c.world.factions[c.world.towns[c.location].owner].treasury
	return "No funded work here. Council funds: %dc. Jobs appear for active camps, stolen cargo and exposed shipments. Trade local resources or seek camps elsewhere." % money

func snapshot() -> Dictionary:
	return {"version":1,"started":started,"last_day":last_day,"towns":towns.duplicate(true),"escrow":escrow.duplicate(true),"contracts":contracts.duplicate(true),"legacy_job":legacy_job,"camp_claims":camp_claims.duplicate(true),"food_bought":food_bought,"food_sold":food_sold,"cargo":cargo.duplicate(),"cargo_bought":cargo_bought.duplicate(),"cargo_sold":cargo_sold.duplicate()}

func restore(raw: Variant, data: Dictionary, world) -> bool:
	if not raw is Dictionary or raw.get("version") != 1: return false
	for key in ["started","last_day","food_bought","food_sold"]:
		if not raw.get(key) is int or raw[key] < 0: return false
	if raw.started < 1 or raw.started > data.day or raw.last_day != data.day or world.raid_wealth.is_empty() or raw.food_sold != world.company_food_in: return false
	for key in ["towns","escrow","contracts","camp_claims","cargo","cargo_bought","cargo_sold"]:
		if not raw.get(key) is Dictionary: return false
	if raw.towns.size() != 3 or raw.contracts.size() != 3 or not raw.get("legacy_job") is String: return false
	if raw.legacy_job != "" and (not raw.escrow.is_empty() or data.active.get("id") != raw.legacy_job): return false
	if not raw.escrow.is_empty():
		if raw.escrow.size() != 3 or data.active.is_empty(): return false
		for key in ["id","client","pay"]:
			if raw.escrow.get(key) != data.active.get(key): return false
	elif not data.active.is_empty() and raw.legacy_job == "": return false
	for town in world.TOWNS:
		var t = raw.towns.get(town)
		if not t is Dictionary or not t.get("goods") is Dictionary or t.goods.size() != STORED.size(): return false
		for key in ["initial","cash","receipts","retail","paid"]:
			if not t.get(key) is int or t[key] < 0: return false
		if t.cash != t.initial+t.receipts+t.retail-t.paid: return false
		var book = {}
		for b in data.market_books.values():
			if b.town == town and (book.is_empty() or b.week > book.week): book = b
		if not book.is_empty() and book.cash != t.cash: return false
		for i in STORED.size():
			var kind: String = STORED[i]; var g = t.goods.get(kind)
			if not g is Dictionary: return false
			for key in ["stock","produced","consumed","bought","sold"]:
				if not g.get(key) is int or g[key] < 0: return false
			if g.stock != STOCK[town][i]+g.produced+g.sold-g.consumed-g.bought or g.produced > OUTPUT[town][i]*(data.day-raw.started) or g.consumed > DEMAND[kind]*(data.day-raw.started): return false
		var f = raw.contracts.get(world.towns[town].owner)
		if not f is Dictionary: return false
		for key in ["reserved","paid","refunded"]:
			if not f.get(key) is int or f[key] < 0: return false
		var held: int = raw.escrow.get("pay",0) if raw.escrow.get("client") == world.towns[town].owner else 0
		if f.reserved != f.paid+f.refunded+held or f.paid+held > world.factions[world.towns[town].owner].spent: return false
	var taken = 0; var food = raw.food_bought
	for id in raw.camp_claims:
		if not id is String: return false
		var parts = id.split("/"); var claim = raw.camp_claims[id]
		if parts.size() != 2 or parts[0] not in world.SITES or not parts[1].is_valid_int(): return false
		var generation = int(parts[1])
		if generation < 1 or generation > world.camps[parts[0]].generation or (generation == world.camps[parts[0]].generation and world.camps[parts[0]].active): return false
		if not claim is Dictionary: return false
		for key in ["food","crowns"]:
			if not claim.get(key) is int or claim[key] < 0: return false
		taken += claim.crowns; food += claim.food
	var treasury_taken = 0
	for value in world.raid_wealth.camps.values(): treasury_taken += value.taken
	if taken != treasury_taken or food > world.sold: return false
	for field in ["cargo","cargo_bought","cargo_sold"]:
		if raw[field].size() != TRADE_GOODS.size(): return false
		for kind in TRADE_GOODS:
			if not raw[field].get(kind) is int or raw[field][kind] < 0: return false
	for kind in TRADE_GOODS:
		if raw.cargo[kind] != raw.cargo_bought[kind]-raw.cargo_sold[kind]: return false
		var bought = 0; var sold = 0
		for town in raw.towns.values(): bought += town.goods[kind].bought; sold += town.goods[kind].sold
		if bought != raw.cargo_bought[kind] or sold != raw.cargo_sold[kind]: return false
	enabled = true
	for key in ["started","last_day","towns","escrow","contracts","legacy_job","camp_claims","food_bought","food_sold","cargo","cargo_bought","cargo_sold"]: set(key,raw[key])
	return true

func owned(c, kind: String) -> int:
	return cargo[kind] if kind in TRADE_GOODS else c.get(FIELD[kind])
