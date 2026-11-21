extends "res://hollow_campaign/campaign.gd"
func create_economy():
 var out = Economy.new()
 out.industry = preload("res://local_markets/industry.gd").new()
 return out

func snapshot() -> Dictionary:
 var out: Dictionary = super.snapshot()
 out["local_markets"] = 1
 return out
func restore(raw: Variant) -> bool:
 if not raw is Dictionary: return false
 var d: Dictionary = battle.normalize_json_numbers(raw)
 if not d.get("local_markets") is int or d.local_markets != 1: return false
 if not d.get("economy") is Dictionary or not d.economy.get("version") is int or d.economy.version != 3: return false
 if not preload("res://local_markets/policy.gd").shape(d.economy.get("industry")): return false
 if not d.economy.industry.get("version") is int or not d.economy.industry.get("started") is int: return false
 return super.restore(d)
func valid_purchase_ids(data: Dictionary,_definitions: Dictionary,_config: Dictionary) -> Dictionary:
 var out := {}
 for s in data.economy.industry.towns.values():
  for unit in s.shelf:
   if unit.sold: out[unit.id] = true
 return out

func shelf_offers() -> Array:
 return merchant_offers()
func armorer_stock(group: String,layer: String) -> Array:
 return shelf_offers().filter(func(o):return catalog[o.definition].get("slot") in ["body","head"] and catalog[o.definition].get("group")==group and catalog[o.definition].get("layer")==layer)
func weapons_stock() -> Array:
 return shelf_offers().filter(func(o):return catalog[o.definition].get("slot") not in ["body","head"])
func _buy_shelf(id: String,component: bool) -> String:
 return Stock.buy(self,merchant_stock,id,"component" if component else "weapon")
func buy_weapon(id: String) -> String:
 return _buy_shelf(id,false)
func buy_component(id: String) -> String:
 return _buy_shelf(id,true)
