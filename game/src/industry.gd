extends RefCounted
## Towns order work from real shortages; all inputs, labour and deliveries are booked.
const RAW = {"ashwick":{"cloth":3,"grain":4,"hides":1,"lumber":1},"stonecross":{"iron":3,"salt":3,"silk":1,"grain":1},"dunmere":{"furs":2,"hides":3,"lumber":4,"grain":1,"cloth":1}}
const USES = {"furs":"Warm clothing and bedding", "cloth":"Clothing, padding and medical dressings", "silk":"Prosperous households and fine overclothes", "salt":"Preserves town food reserves", "lumber":"Repairs, wagons, shields and ammunition", "iron":"Weapons, armour, tools and wagon fittings", "grain":"Milled and baked into rations", "hides":"Leather armour, shields and wagon harnesses"}
const RECIPES = {
 "farm":{"name":"Farm repairs","inputs":{"lumber":4,"iron":1,"tools":2},"outputs":{},"fee":18,"payer":"council"},
 "town":{"name":"Town repairs","inputs":{"lumber":3,"iron":1,"tools":2},"outputs":{},"fee":16,"payer":"council"},
 "wagon":{"name":"Freight wagon","inputs":{"lumber":4,"iron":1,"hides":1},"outputs":{},"fee":10,"payer":"merchant"},
 "bread":{"name":"Mill and bakery","inputs":{"grain":1},"outputs":{"food":24},"fee":3,"payer":"merchant"},
 "preserve":{"name":"Preserve food reserves","inputs":{"salt":1},"outputs":{},"fee":2,"payer":"merchant"},
 "tools":{"name":"Toolsmith","inputs":{"iron":1,"lumber":1},"outputs":{"tools":12},"fee":4,"payer":"merchant"},
 "ammo":{"name":"Fletcher","inputs":{"iron":1,"lumber":1},"outputs":{"ammo":30},"fee":4,"payer":"merchant"},
 "medicine":{"name":"Medical dressings","inputs":{"cloth":1},"outputs":{"medicine":6},"fee":3,"payer":"merchant"},
 "clothes":{"name":"Household clothing","inputs":{"cloth":1},"outputs":{},"fee":16,"payer":"households"},
 "furs":{"name":"Warm clothing and bedding","inputs":{"furs":1},"outputs":{},"fee":30,"payer":"households"},
 "luxury":{"name":"Fine silk clothing","inputs":{"silk":1},"outputs":{},"fee":70,"payer":"households"},
 "treatment":{"name":"Treat raid casualties","inputs":{"medicine":2},"outputs":{},"fee":8,"payer":"council"}}
var state: Dictionary = {}
var acquisition = null # Explicit owner opt-in; never persisted or inferred.

func initialize(data: Dictionary, world, economy, catalog: Dictionary) -> void:
 state = {"version":1,"started":data.day,"first_wagon":world.next_caravan,"returned":[],"towns":{}}
 world.wagon_stock = {}
 for town in world.TOWNS:
  var market: Dictionary = economy.towns[town]
  var local = {"damage":0,"raided":world.towns[town].raided,"farm_paid":0,"wagons_made":0,"pantry_until":0,"clothing":3,"luxury":0,"households":60,"earnings":0,"spending":0,"spoiled":0,"baked":0,"completed":{},"equipment":{},"gear_made":{},"gear_sold":{},"gear_initial":{},"inputs":{},"outputs":{},"base_consumed":{},"base_produced":{}}
  var farm: Dictionary = data.get("farm",{})
  if farm.get("version") == 2: farm = farm.farms.get(town,{})
  elif town != "ashwick": farm = {}
  local.farm_paid = maxi(0,int(farm.get("incident",0))-(1 if farm.get("damage",0)>0 else 0))
  var book: Dictionary = {}
  for b in data.market_books.values():
   if b.town==town and (book.is_empty() or b.week>book.week): book=b
  var t: Dictionary = world.towns[town]
  var level = preload("res://src/market.gd").tier(t.stock,world.factions[t.owner].treasury,t.demand,t.pressure)
  var definitions: Array = book.stock if not book.is_empty() else preload("res://src/market.gd").stock(economy.role(world,town),level,data.seed,(data.day-1)/7,catalog,true,true,true,acquisition)
  for definition in definitions:
   var count = 0 if "%s_%d_%s"%[town,(data.day-1)/7,definition] in data.purchased_gear else 1
   local.equipment[definition]=count;local.gear_initial[definition]=count
  for kind in economy.STORED:
   local.inputs[kind]=0;local.outputs[kind]=0
   local.base_consumed[kind]=market.goods[kind].consumed;local.base_produced[kind]=market.goods[kind].produced
  state.towns[town]=local;world.wagon_stock[town]=2

func gear_recipe(definition: String, catalog: Dictionary) -> Dictionary:
 var d: Dictionary = catalog[definition];var inputs = {}
 if d.get("slot")=="shield": inputs={"lumber":1,"hides":1,"iron":1}
 elif d.get("slot")=="ammo": inputs={"lumber":1,"iron":1}
 elif d.has("group"):
  var layer: String=d.get("layer","")
  if "fur" in definition or layer=="cloak": inputs={"furs":1,"cloth":1}
  elif layer in ["base","padding"]: inputs={"cloth":1}
  elif layer in ["cloth","decoration"]: inputs={"silk":1} if d.price>=55 else {"cloth":1}
  elif "leather" in definition or definition in ["jerkin","cap"]: inputs={"hides":1}
  else: inputs={"iron":2 if d.price>=100 else 1,"cloth":1}
 else:
  var family: String=preload("res://src/arsenal.gd").family(definition)
  inputs={"lumber":2,"hides":1} if family in ["bow","crossbow"] else {"lumber":1} if definition=="club" else {"iron":2 if d.get("price",0)>=150 else 1,"lumber":1}
 return {"name":d.name,"inputs":inputs,"outputs":{},"fee":8 if d.get("price",0)>=100 else 4,"payer":"merchant"}

func order(key: String) -> Dictionary:
 var result: Dictionary=RECIPES[key].duplicate(true);result.key=key;return result

func freight_needed(c, town: String) -> bool:
 if c.world.wagon_stock[town]>0:return false
 if c.economy.freight.enabled and not c.economy.freight.best_order(c,town,false).is_empty():return true
 for route in c.world.config.routes:
  if route.path[0]!=town:continue
  var dest: Dictionary=c.world.towns[route.path[2]];var incoming=0
  for wagon in c.world.caravans.values():
   if wagon.route==route.id and wagon.status in ["waiting","transit","escort"]:incoming+=wagon.cargo
  if dest.stock+incoming<dest.demand*8 and c.world.towns[town].stock>=route.cargo+24:return true
 return false

func orders(c, town: String,include_freight: bool=true) -> Array:
 var out: Array=[];var s: Dictionary=state.towns[town];var t: Dictionary=c.world.towns[town];var e=c.economy
 var farm=c.farm.for_town(town)
 if farm!=null and farm.damage>0 and s.farm_paid<farm.incident:out.append(order("farm"))
 if s.damage>0:out.append(order("town"))
 if t.stock<t.demand*6:out.append(order("bread"))
 if t.stock>t.demand*4 and s.pantry_until<c.day:out.append(order("preserve"))
 if include_freight and freight_needed(c,town):out.append(order("wagon"))
 if t.pressure>0 and c.day%3==0:out.append(order("treatment"))
 for kind in ["tools","medicine","ammo"]:
  if e.stock(c,town,kind)<e.TARGET[kind]:out.append(order(kind))
 if s.clothing==0:
  out.append(order("furs" if e.role(c.world,town)=="dunmere" or e.stock(c,town,"cloth")==0 and e.stock(c,town,"furs")>0 else "clothes"))
 if s.luxury==0 and prosperous(c,town):out.append(order("luxury"))
 var level=c.Market.tier(t.stock,c.world.factions[t.owner].treasury,t.demand,t.pressure)
 var definitions=c.Market.stock(e.role(c.world,town),level,c.seed_value,(c.day-1)/7,c.catalog,true,true,true,acquisition)
 for definition in definitions:
  if s.equipment.get(definition,0)>0 or "%s_%d_%s"%[town,(c.day-1)/7,definition] in c.purchased_gear:continue
  var job=gear_recipe(definition,c.catalog);job.key="gear:"+definition;out.append(job)
 return out

func prosperous(c,town: String) -> bool:
 var t: Dictionary=c.world.towns[town]
 return t.stock>=t.demand*8 and t.pressure==0 and state.towns[town].damage==0 and c.world.factions[t.owner].treasury>=60

func funds(c,town: String,job: Dictionary) -> int:
 if job.payer=="council":return c.world.factions[c.world.towns[town].owner].treasury
 if job.payer=="households":return state.towns[town].households
 return c.economy.towns[town].cash

func blocked(c,town: String,job: Dictionary) -> String:
 if funds(c,town,job)<job.fee:return "Awaiting funds"
 var missing: Array=[]
 for kind in job.inputs:
  var shortfall: int=job.inputs[kind]-c.economy.stock(c,town,kind)
  if shortfall>0:missing.append("%d %s"%[shortfall,c.economy.NAMES[kind].to_lower()])
 return "Needs "+", ".join(missing) if not missing.is_empty() else "Ready for local workers"

func needed(c,town: String,kind: String,include_freight: bool=true) -> int:
 var amount=0
 for job in orders(c,town,include_freight):
  if funds(c,town,job)>=job.fee:amount+=job.inputs.get(kind,0)
 return mini(amount,12) # A bounded price signal, never an unlimited emergency markup.

func credit(c,town: String,amount: int,retail: bool=false) -> void:
 var e=c.economy
 e.towns[town].cash+=amount;e.towns[town]["retail" if retail else "receipts"]+=amount
 var book=e.latest_book(c,town)
 if not book.is_empty():book.cash+=amount;book.income+=amount

func debit(c,town: String,amount: int) -> void:
 c.economy.pay(town,amount)
 var book=c.economy.latest_book(c,town)
 if not book.is_empty():
  book.cash-=amount;book.spent+=amount;book["resource_spent"]=book.get("resource_spent",0)+amount

func produce(c,town: String,kind: String,amount: int) -> void:
 if amount<=0:return
 var g: Dictionary=c.economy.towns[town].goods[kind]
 g.stock+=amount;g.produced+=amount;state.towns[town].outputs[kind]+=amount

func execute(c,town: String,job: Dictionary) -> bool:
 if blocked(c,town,job)!="Ready for local workers":return false
 var e=c.economy;var s: Dictionary=state.towns[town]
 if job.payer=="merchant":debit(c,town,job.fee)
 elif job.payer=="council":
  var council: Dictionary=c.world.factions[c.world.towns[town].owner]
  council.treasury-=job.fee;council.spent+=job.fee;credit(c,town,job.fee)
 else:
  s.households-=job.fee;s.spending+=job.fee;credit(c,town,job.fee,true)
 for kind in job.inputs:
  var amount: int=job.inputs[kind];var g: Dictionary=e.towns[town].goods[kind]
  g.stock-=amount;g.consumed+=amount;s.inputs[kind]+=amount
 for kind in job.outputs:
  if kind=="food":
   c.world.towns[town].stock+=job.outputs[kind];c.world.produced+=job.outputs[kind];s.baked+=job.outputs[kind]
  else:produce(c,town,kind,job.outputs[kind])
 s.completed[job.key]=s.completed.get(job.key,0)+1
 match job.key:
  "farm":s.farm_paid=c.farm.for_town(town).incident;c.world.log_event(c.node(town).name+" supplies timber, iron and tools for farm repairs. Safe work can begin.")
  "town":s.damage-=1;c.world.log_event(c.node(town).name+" repairs raid damage; local workshops recover.")
  "wagon":c.world.wagon_stock[town]+=1;s.wagons_made+=1;c.world.log_event(c.node(town).name+" completes a freight wagon from lumber, iron and hides.")
  "preserve":s.pantry_until=c.day+3
  "clothes":s.clothing=4
  "furs":s.clothing=7
  "luxury":s.luxury=10
  "treatment":c.world.towns[town].pressure=maxi(0,c.world.towns[town].pressure-1)
 if job.key.begins_with("gear:"):
  var definition: String=job.key.trim_prefix("gear:")
  s.equipment[definition]=s.equipment.get(definition,0)+1;s.gear_made[definition]=s.gear_made.get(definition,0)+1
 return true

func daily(c) -> void:
 for id in c.world.caravans:
  var wagon: Dictionary=c.world.caravans[id]
  if int(id.trim_prefix("wagon_"))<state.first_wagon or id in state.returned or wagon.status!="delivered":continue
  var route=c.world.route_data(wagon.route)
  if c.day<wagon.delivered_day+route.days[0]+route.days[1]:continue
  c.world.wagon_stock[route.path[0]]+=1;state.returned.append(id)
 for town in state.towns:
  var s: Dictionary=state.towns[town];var t: Dictionary=c.world.towns[town];var e=c.economy
  if t.raided>s.raided:s.damage+=ceili(float(t.raided-s.raided)/c.world.config.politics.raid_loot);s.raided=t.raided
  var fed: bool=t.stock>=t.demand
  var earnings: int=t.demand*(5 if fed and t.pressure==0 else 1)
  s.households+=earnings;s.earnings+=earnings
  # Food shops earn household spending; ration goods themselves are consumed by World.tick.
  var food_sales=mini(s.households,t.demand*2 if fed else 0)
  s.households-=food_sales;s.spending+=food_sales;credit(c,town,food_sales,true)
  s.clothing=maxi(0,s.clothing-1);s.luxury=maxi(0,s.luxury-1)
  for kind in RAW[e.role(c.world,town)]:
   var amount: int=RAW[e.role(c.world,town)][kind]
   var farm=c.farm.for_town(town)
   if kind in ["grain","hides","cloth"] and farm!=null and farm.output(c.world)==0:amount=0
   elif not fed or t.pressure>0 or s.damage>0:amount/=2
   amount=mini(amount,maxi(0,e.TARGET[kind]*4-e.stock(c,town,kind)))
   amount=mini(amount,e.towns[town].cash/2)
   if amount>0:debit(c,town,amount*2);produce(c,town,kind,amount)
  var work=0
  for job in orders(c,town):
   var household: bool=job.payer=="households"
   if not household and work>=(2 if s.damage==0 and fed else 1):continue
   if execute(c,town,job) and not household:work+=1
  if c.day>s.pantry_until:
   var spoiled=ceili(maxi(0,t.stock-t.demand*4)*0.025)
   t.stock-=spoiled;c.world.spoiled_food+=spoiled;s.spoiled+=spoiled

func farm_ready(town: String,incident: int) -> bool:
 return state.towns[town].farm_paid>=incident

func available(town: String,definition: String) -> bool:
 return state.towns[town].equipment.get(definition,0)>0

func sell_gear(town: String,definition: String) -> void:
 var s: Dictionary=state.towns[town]
 s.equipment[definition]-=1;s.gear_sold[definition]=s.gear_sold.get(definition,0)+1

func snapshot() -> Dictionary:return state.duplicate(true)

# Admission only: historical production, sale and inventory counters stay literal.
func _recorded_design(id: String, catalog: Dictionary) -> bool:
 if not catalog.has(id):return false
 if acquisition == null:return true
 return acquisition.recorded_design(id,catalog) if acquisition.has_method("recorded_design") else acquisition.active(id,catalog)

func restore(raw: Variant,data: Dictionary,world,economy,catalog: Dictionary) -> bool:
 if not raw is Dictionary or raw.get("version")!=1 or not raw.get("towns") is Dictionary or raw.towns.size()!=world.TOWNS.size():return false
 for key in ["started","first_wagon"]:
  if not raw.get(key) is int or raw[key]<1:return false
 if raw.started>data.day or raw.first_wagon>world.next_caravan or not raw.get("returned") is Array or world.wagon_stock.size()!=world.TOWNS.size():return false
 var returns={};var launched={};var returned={}
 for town in world.TOWNS:launched[town]=0;returned[town]=0
 for id in world.caravans:
  if int(id.trim_prefix("wagon_"))>=raw.first_wagon:launched[world.route_data(world.caravans[id].route).path[0]]+=1
 for id in raw.returned:
  if not id is String or returns.has(id) or not world.caravans.has(id) or int(id.trim_prefix("wagon_"))<raw.first_wagon:return false
  var wagon: Dictionary=world.caravans[id];var route=world.route_data(wagon.route)
  if wagon.status!="delivered" or data.day<wagon.delivered_day+route.days[0]+route.days[1]:return false
  returns[id]=true;returned[route.path[0]]+=1
 var spoiled=0
 for town in world.TOWNS:
  var s=raw.towns.get(town)
  if not s is Dictionary:return false
  for key in ["damage","raided","farm_paid","wagons_made","pantry_until","clothing","luxury","households","earnings","spending","spoiled","baked"]:
   if not s.get(key) is int or s[key]<0:return false
  var farm: Dictionary=data.get("farm",{})
  if farm.get("version")==2:farm=farm.farms.get(town,{})
  elif town!="ashwick":farm={}
  if s.farm_paid>int(farm.get("incident",0)):return false
  if s.raided>world.towns[town].raided or s.pantry_until>data.day+3 or s.clothing>7 or s.luxury>10 or s.households!=60+s.earnings-s.spending:return false
  for key in ["completed","equipment","gear_made","gear_sold","gear_initial","inputs","outputs","base_consumed","base_produced"]:
   if not s.get(key) is Dictionary:return false
   for k in s[key]:
    if not k is String or not s[key][k] is int or s[key][k]<0:return false
  var expected_inputs={};var expected_outputs={}
  for key in s.completed:
   var recipe: Dictionary={}
   if key.begins_with("gear:"):
    var definition: String=key.trim_prefix("gear:")
    if not _recorded_design(definition,catalog):return false
    recipe=gear_recipe(definition,catalog)
    if s.gear_made.get(definition,0)!=s.completed[key]:return false
   elif RECIPES.has(key):recipe=RECIPES[key]
   else:return false
   for kind in recipe.inputs:expected_inputs[kind]=expected_inputs.get(kind,0)+recipe.inputs[kind]*s.completed[key]
   for kind in recipe.outputs:expected_outputs[kind]=expected_outputs.get(kind,0)+recipe.outputs[kind]*s.completed[key]
  if s.baked!=s.completed.get("bread",0)*24 or s.wagons_made!=s.completed.get("wagon",0):return false
  if world.wagon_stock[town]!=2+s.wagons_made+returned[town]-launched[town]:return false
  for key in ["equipment","gear_made","gear_sold","gear_initial"]:
   for definition in s[key]:
    if not _recorded_design(definition,catalog) or not s.equipment.has(definition):return false
  for definition in s.equipment:
   if s.equipment[definition]!=s.gear_initial.get(definition,0)+s.gear_made.get(definition,0)-s.gear_sold.get(definition,0):return false
  for key in ["inputs","outputs","base_consumed","base_produced"]:
   if s[key].size()!=economy.STORED.size():return false
  for kind in economy.STORED:
   for key in ["inputs","outputs","base_consumed","base_produced"]:
    if not s[key].has(kind):return false
   var g: Dictionary=economy.towns[town].goods[kind]
   if g.consumed!=s.base_consumed[kind]+s.inputs[kind] or g.produced!=s.base_produced[kind]+s.outputs[kind]:return false
   if s.inputs[kind]!=expected_inputs.get(kind,0):return false
   var harvested: int=s.outputs[kind]-expected_outputs.get(kind,0)
   if harvested<0 or harvested>RAW[economy.role(world,town)].get(kind,0)*(data.day-raw.started):return false
  spoiled+=s.spoiled
 if spoiled!=world.spoiled_food:return false
 state=raw.duplicate(true);return true
