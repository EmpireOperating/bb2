extends RefCounted
## Weekly equipment inventories and finite private merchant purses.
const Arsenal = preload("res://src/arsenal.gd")
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
static func stock(town: String, level: int, seed_number: int, week: int, catalog: Dictionary, ranged_stock: bool = false, bolas_stock: bool = false, opening_stock: bool = false, acquisition = null) -> Array:
 var out: Array = BASIC.duplicate()
 if opening_stock: out.append_array(["buckler","round_shield"])
 if ranged_stock: out.append_array(["javelins","throwing_axes"])
 if bolas_stock: out.append("bolas")
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
  if d.get("opening_item",false) and not opening_stock: continue
  if not d.has("price"): continue
  if not d.has("group") and not (d.get("campaign_adopted",false) and d.get("slot") in ["weapon","shield"]): continue
  if d.price <= (45 if level == 1 else 115 if level == 2 else 999): out.append(definition)
 if acquisition != null: out = acquisition.stock(out,catalog)
 out.sort()
 return out
static func create(c, town: String) -> Dictionary:
 var t: Dictionary = c.world.towns[town]
 var treasury: int = c.world.factions[t.owner].treasury
 var pressure: int = t.pressure
 var level = tier(t.stock,treasury,t.demand,pressure)
 var week: int = (c.day-1)/7
 var out = {"town":town,"week":week,"day":c.day,"food":t.stock,"treasury":treasury,"raided":pressure,"tier":level,"ranged_stock":true,"bolas_stock":true,"opening_stock":true,"stock":stock(c.world.config.towns[town].get("market_role",town),level,c.seed_value,week,c.catalog,true,true,true,c.acquisition_policy()),"income":0,"spent":0,"cash":CASH[level]}
 if c.economy.enabled:
  out["opening_cash"] = c.economy.towns[town].cash; out.cash = out.opening_cash
 return out
static func valid(books: Variant, sales: Variant, d: Dictionary, catalog: Dictionary, config: Dictionary, acquisition = null) -> bool:
 if not books is Dictionary or (books.size() > config.towns.size()*((d.day-1)/7+1) if d.get("endless",false) else books.size() > config.towns.size()*5) or not sales is Array: return false
 if d.location in config.towns and not books.has("%s_%d" % [d.location,(d.day-1)/7]): return false
 var paid = {}; var ids = {}
 for sale in sales:
  if not sale is Dictionary: return false
  if not sale.get("item") is String or not sale.item.begins_with("item_") or not sale.item.trim_prefix("item_").is_valid_int() or int(sale.item.trim_prefix("item_")) >= d.next_item or ids.has(sale.item) or d.items.has(sale.item): return false
  ids[sale.item] = true
  if not sale.get("market") is String or not books.has(sale.market) or not books[sale.market] is Dictionary or not sale.get("name") is String: return false
  if not sale.get("price") is int or sale.price < 0 or sale.price > 10000 or not sale.get("day") is int or sale.day < 1 or sale.day > d.day: return false
  if (sale.day-1)/7 != books[sale.market].get("week"): return false
  paid[sale.market] = paid.get(sale.market,0)+sale.price
 for key in books:
  var b = books[key]
  if not key is String or not b is Dictionary or not b.get("town") in config.towns: return false
  for field in ["week","day","food","treasury","raided","tier","income","spent","cash"]:
   if not b.get(field) is int or b[field] < 0: return false
  if b.day < 1 or b.day > d.day or b.week != (b.day-1)/7 or key != "%s_%d" % [b.town,b.week] or not b.tier in LABELS: return false
  if b.tier != tier(b.food,b.treasury,config.towns[b.town].demand,b.raided): return false
  if b.has("ranged_stock") and not b.ranged_stock is bool: return false
  if b.has("opening_stock") and not b.opening_stock is bool: return false
  if b.has("bolas_stock") and not b.bolas_stock is bool: return false
  var expected: Array = stock(config.towns[b.town].get("market_role",b.town),b.tier,d.seed,b.week,catalog,b.get("ranged_stock",false),b.get("bolas_stock",false),b.get("opening_stock",false),acquisition)
  var prior_maul := expected.duplicate()
  prior_maul.erase("hm_trial_v1:twohand_maul")
  if b.get("stock") not in [expected,prior_maul]:
   if acquisition == null: return false
   var older := []
   if acquisition.has_method("stock_before_cap"):older.append_array([acquisition.stock_before_cap(expected),acquisition.stock_before_cap(prior_maul)])
   if acquisition.has_method("stock_before_crossbows"):older.append(acquisition.stock_before_crossbows(prior_maul))
   if b.get("stock") not in older:return false
  var opening = b.get("opening_cash",CASH[b.tier]); var resource_paid = b.get("resource_spent",0)
  if not opening is int or opening < 0 or not resource_paid is int or resource_paid < 0: return false
  if (b.has("opening_cash") or b.has("resource_spent")) and not d.has("economy"): return false
  if b.spent != paid.get(key,0)+resource_paid or b.cash != opening+b.income-b.spent: return false
 return true
