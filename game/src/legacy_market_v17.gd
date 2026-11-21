extends RefCounted
## Weekly equipment inventories and finite private merchant purses.
const Arsenal = preload("res://src/legacy_arsenal_v17.gd")
const TOWNS = ["ashwick","stonecross","dunmere"]
const BASIC = ["knife","club","hatchet","militia_spear","shortbow","shield","arrows","bolts"]
const SPECIALTIES = {
 "ashwick":["shortsword","sword","spear","mace","crossbow"],
 "stonecross":["falchion","axe","hammer","crossbow","dagger"],
 "dunmere":["bow","polearm","heavy_spear","shortsword","axe"]}
const PREMIUM = {
 "ashwick":["greatsword","greataxe","heavy_crossbow"],
 "stonecross":["maul","greatsword","heavy_crossbow"],
 "dunmere":["warbow","glaive","greataxe"]}
const LABELS = {1:"Strained",2:"Supplied",3:"Prosperous"}
const CASH = {1:140,2:300,3:520}
static func tier(food: int, treasury: int, demand: int, raided: int) -> int:
 if food < demand*5 or raided > 0: return 1
 return 3 if food >= demand*12 and treasury >= 90 else 2
static func stock(town: String, level: int, seed_number: int, week: int, catalog: Dictionary) -> Array:
 var out: Array = BASIC.duplicate()
 if level >= 2:
  out.append_array(SPECIALTIES[town])
  # One visiting trader's ordinary weapon rotates without consuming RNG.
  var visiting = ["bow","polearm","hammer","dagger","heavy_spear","falchion"]
  var extra = visiting[posmod(seed_number+week*7+TOWNS.find(town)*3,visiting.size())]
  if not extra in out: out.append(extra)
 if level >= 3:
  for i in 2: out.append(PREMIUM[town][(week+seed_number+i)%3])
 for definition in catalog:
  var d: Dictionary = catalog[definition]
  if d.get("opening_item",false): continue # Historical markets never stocked later additions.
  if not d.has("group") or not d.has("price"): continue
  if d.price <= (45 if level == 1 else 115 if level == 2 else 999): out.append(definition)
 out.sort()
 return out
static func create(c, town: String) -> Dictionary:
 var t: Dictionary = c.world.towns[town]
 var treasury: int = c.world.factions[t.owner].treasury
 var pressure: int = t.pressure
 var level = tier(t.stock,treasury,t.demand,pressure)
 var week: int = (c.day-1)/7
 return {"town":town,"week":week,"day":c.day,"food":t.stock,"treasury":treasury,"raided":pressure,"tier":level,"stock":stock(town,level,c.seed_value,week,c.catalog),"income":0,"spent":0,"cash":CASH[level]}
static func valid(books: Variant, sales: Variant, d: Dictionary, catalog: Dictionary, config: Dictionary) -> bool:
 if not books is Dictionary or books.size() > 15 or not sales is Array or sales.size() > 10000: return false
 if d.location in TOWNS and not books.has("%s_%d" % [d.location,(d.day-1)/7]): return false
 var paid = {}; var ids = {}
 for sale in sales:
  if not sale is Dictionary: return false
  if not sale.get("item") is String or not sale.item.begins_with("item_") or not sale.item.trim_prefix("item_").is_valid_int() or int(sale.item.trim_prefix("item_")) >= d.next_item or ids.has(sale.item) or d.items.has(sale.item): return false
  ids[sale.item] = true
  if not sale.get("market") is String or not books.has(sale.market) or not books[sale.market] is Dictionary or not sale.get("name") is String: return false
  if not sale.get("price") is int or sale.price < 1 or sale.price > 10000 or not sale.get("day") is int or sale.day < 1 or sale.day > d.day: return false
  if (sale.day-1)/7 != books[sale.market].get("week"): return false
  paid[sale.market] = paid.get(sale.market,0)+sale.price
 for key in books:
  var b = books[key]
  if not key is String or not b is Dictionary or not b.get("town") in TOWNS: return false
  for field in ["week","day","food","treasury","raided","tier","income","spent","cash"]:
   if not b.get(field) is int or b[field] < 0: return false
  if b.day < 1 or b.day > d.day or b.week != (b.day-1)/7 or key != "%s_%d" % [b.town,b.week] or not b.tier in LABELS: return false
  if b.tier != tier(b.food,b.treasury,config.towns[b.town].demand,b.raided): return false
  if b.get("stock") != stock(b.town,b.tier,d.seed,b.week,catalog): return false
  if b.spent != paid.get(key,0) or b.cash != CASH[b.tier]+b.income-b.spent: return false
 return true
