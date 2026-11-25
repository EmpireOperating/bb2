extends "res://src/industry.gd"
const Shelf = preload("res://local_markets/policy.gd")
const MASON := Shelf.Arsenal.MASON_HAMMER
# Sorts after the numbered shelf IDs in the opening merchant allocation, so
# the additional physical copy does not change any original opening UID or roll.
const MASON_OFFER := "smith:ashwick:mason_hammer"

func _recorded_design(id: String, catalog: Dictionary) -> bool:
 # Local shelf restore below owns the exact source; do not add it to shared pools.
 if Shelf.ForgeMarket.enabled(): return Shelf.ForgeMarket.tradeable(id,catalog)
 return (id == MASON and catalog.has(MASON)) or super._recorded_design(id,catalog)

func initialize(data: Dictionary, world, economy, catalog: Dictionary) -> void:
 super.initialize(data,world,economy,catalog)
 for town in world.TOWNS:
  var s: Dictionary = state.towns[town]
  s.equipment.clear(); s.gear_initial.clear()
  s["shelf"] = []
  var role: String = economy.role(world,town)
  var t: Dictionary = world.towns[town]
  var level: int = preload("res://src/market.gd").tier(t.stock,world.factions[t.owner].treasury,t.demand,t.pressure)
  for serial in Shelf.CAPS[role]:
   var definition: String = Shelf.choose(data.seed,town,role,level,serial,1,catalog)
   s.shelf.append({"id":"shelf:%s:%d" %[town,serial+1],"definition":definition,"day":1,"level":level,"sold":false})
   s.equipment[definition] = s.equipment.get(definition,0)+1
   s.gear_initial[definition] = s.gear_initial.get(definition,0)+1
  if town == "ashwick" and catalog.has(MASON):
   s.shelf.append({"id":MASON_OFFER,"definition":MASON,"day":1,"level":level,"sold":false})
   s.equipment[MASON] = 1; s.gear_initial[MASON] = 1

func gear_recipe(definition: String, catalog: Dictionary) -> Dictionary:
 var recipe: Dictionary = super.gear_recipe(definition,catalog)
 # Paid Ashwick leatherwork, not a change to ordinary cloak recipes.
 if definition == Shelf.ForgeMarket.LEATHER_BACKED_MANTLE: recipe.inputs = {"hides":1,"cloth":1}
 if definition == Shelf.ForgeMarket.PADDED_TEMPLE_WRAP: recipe.inputs = {"cloth":1}
 return recipe

func _gear_job(c,town: String) -> Dictionary:
 var s: Dictionary = state.towns[town]
 # The one-off opening commission neither occupies a regular production slot
 # nor consumes a draw/serial. It is never selected by a replacement job.
 var shelf: Array = s.shelf.filter(func(unit):return unit.id!=MASON_OFFER) if town=="ashwick" else s.shelf
 var count := 0
 for serial in shelf.size():
  var unit: Dictionary = shelf[serial]
  if not unit.sold: count += 1
  if unit.day == c.day and serial >= Shelf.CAPS[c.economy.role(c.world,town)]: return {}
 var role: String = c.economy.role(c.world,town)
 if count >= Shelf.CAPS[role]: return {}
 var t: Dictionary = c.world.towns[town]
 var level: int = c.Market.tier(t.stock,c.world.factions[t.owner].treasury,t.demand,t.pressure)
 var definition: String = Shelf.forge_wave2_restock(town,shelf.size(),c.day,c.catalog)
 if definition.is_empty(): definition = Shelf.forge_restock(role,shelf.size(),c.day,c.catalog)
 if definition.is_empty(): definition = Shelf.choose(c.seed_value,town,role,level,shelf.size(),c.day,c.catalog)
 var job: Dictionary = gear_recipe(definition,c.catalog)
 job.key = "gear:"+definition
 job["shelf_day"] = c.day; job["shelf_level"] = level; job["shelf_serial"] = shelf.size()+1
 return job
func orders(c,town: String,include_freight: bool=true) -> Array:
 var out: Array = super.orders(c,town,include_freight).filter(func(j):return not j.key.begins_with("gear:"))
 var job: Dictionary = _gear_job(c,town)
 if not job.is_empty(): out.append(job)
 return out
func execute(c,town: String,job: Dictionary) -> bool:
 if not job.key.begins_with("gear:"): return super.execute(c,town,job)
 var expected: Dictionary = _gear_job(c,town)
 if expected.is_empty() or job != expected: return false
 if not super.execute(c,town,job): return false
 state.towns[town].shelf.append({"id":"shelf:%s:%d" %[town,job.shelf_serial],"definition":job.key.trim_prefix("gear:"),"day":job.shelf_day,"level":job.shelf_level,"sold":false})
 return true

func restore(raw: Variant,data: Dictionary,world,economy,catalog: Dictionary) -> bool:
 if not Shelf.shape(raw) or not raw.get("version") is int or not raw.get("started") is int: return false
 if raw.started!=1 or not data.get("purchased_gear") is Array: return false
 if raw.towns.size()!=world.TOWNS.size(): return false
 # Reconstruct opening prosperity from the same stock world and civic credit.
 var opening = world.get_script().new()
 opening.configure(data.region); opening.setup()
 for town in opening.TOWNS: opening.factions[opening.towns[town].owner].treasury+=240
 var sold_ids := {}; var all_ids := {}
 for town in world.TOWNS:
  if not raw.towns.has(town): return false
  var s: Dictionary=raw.towns[town]
  var role: String=economy.role(world,town);var cap: int=Shelf.CAPS[role]
  if s.shelf.size()<cap or s.shelf.size()>cap+data.day+(1 if town=="ashwick" else 0): return false
  var initial := {};var made := {};var sold := {};var equipment := {};var count := 0;var last_day := 0
  var t: Dictionary=opening.towns[town]
  var initial_level: int=preload("res://src/market.gd").tier(t.stock,opening.factions[t.owner].treasury,t.demand,0)
  var serial := 0
  for unit: Dictionary in s.shelf:
   var mason: bool = unit.id==MASON_OFFER
   if all_ids.has(unit.id) or not unit.level in [1,2,3]: return false
   all_ids[unit.id]=true
   if mason:
    # Legacy shelves omit this row; admit only the exact authored home-town copy.
    if town!="ashwick" or serial!=cap or unit.day!=1 or unit.level!=initial_level or unit.definition!=MASON or not catalog.has(MASON): return false
   else:
    if unit.id!="shelf:%s:%d" %[town,serial+1]: return false
    if serial<cap:
     if unit.day!=1 or unit.level!=initial_level: return false
    else:
     if unit.day<1 or unit.day>data.day or unit.day<=last_day: return false
     last_day=unit.day
    # Keep the original deterministic cohorts and exact predecessor admissions.
    var current := Shelf.choose(data.seed,town,role,unit.level,serial,unit.day,catalog)
    if Shelf.ForgeMarket.enabled():
     if unit.definition != current:
      # Admit only the exact replacement for this position in either wave.
      # Old draws, sold tombstones and work totals remain literal.
      var restock := Shelf.forge_restock(role,serial,unit.day,catalog)
      var wave2 := Shelf.forge_wave2_restock(town,serial,unit.day,catalog)
      if unit.definition.is_empty() or unit.definition not in [restock,wave2]: return false
    else:
     var pre_maul := Shelf.choose(data.seed,town,role,unit.level,serial,unit.day,catalog,false,true)
     if unit.definition not in [current,Shelf.Acquisition.previous_design(current),pre_maul,Shelf.Acquisition.previous_design(pre_maul)] and unit.definition!=Shelf.choose(data.seed,town,role,unit.level,serial,unit.day,catalog,true): return false
   var book: Dictionary=initial if mason or serial<cap else made
   book[unit.definition]=book.get(unit.definition,0)+1
   equipment[unit.definition]=equipment.get(unit.definition,0)+(0 if unit.sold else 1)
   if unit.sold:
    sold[unit.definition]=sold.get(unit.definition,0)+1;sold_ids[unit.id]=true
   elif not mason: count+=1
   if not mason: serial+=1
  if serial<cap or serial>cap+data.day or count>cap or s.get("gear_initial")!=initial or s.get("gear_made")!=made or s.get("gear_sold")!=sold or s.get("equipment")!=equipment: return false
  if not s.get("completed") is Dictionary: return false
  var work := 0;var completed_gear := {}
  for key in s.completed:
   if not key is String or not s.completed[key] is int or s.completed[key]<0: return false
   if key.begins_with("gear:"):completed_gear[key.trim_prefix("gear:")]=s.completed[key]
   if key.begins_with("gear:") or RECIPES.has(key) and RECIPES[key].payer!="households":work+=s.completed[key]
  if completed_gear!=made or work>data.day*2: return false
 var purchases := {}
 for id in data.purchased_gear:
  if not id is String or purchases.has(id) or not sold_ids.has(id): return false
  purchases[id]=true
 if purchases!=sold_ids: return false
 # Retain all existing recipe/input/output, goods, vehicle and world conservation.
 return super.restore(raw,data,world,economy,catalog)
