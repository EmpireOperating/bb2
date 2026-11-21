extends RefCounted
## Merchant custody is separate from company inventory. Sold records are immutable
## provenance tombstones, not merchant ownership and never regenerating offers.
const Rarity = preload("res://hollow_campaign/rarity.gd")
const Arsenal = preload("res://src/arsenal.gd")
const SUPPORT = ["hands","feet","cloak","belt"]
static func fresh(seed_number: int) -> Dictionary:
 return {"version":1,"seed":seed_number,"records":{},"batches":[]}
static func kind(definition: String, catalog: Dictionary) -> String:
 if not catalog.has(definition): return ""
 var d: Dictionary = catalog[definition]
 if d.get("assembly",false) or not d.has("price"): return ""
 if d.get("group") in ["body","head"]: return "component"
 if d.get("slot") in ["weapon","shield","ammo"]+SUPPORT: return "weapon"
 return ""
static func sources(c) -> Dictionary:
 var out := {}
 if c.has_method("shelf_offers"):
  if not c.economy.enabled: return out
  for town in c.economy.industry.state.towns:
   for unit in c.economy.industry.state.towns[town].get("shelf",[]):
    if kind(unit.definition,c.catalog).is_empty(): continue
    out[unit.id] = {"town":town,"market":"","definition":unit.definition,"kind":kind(unit.definition,c.catalog),"sold":unit.sold}
 else:
  for key in c.market_books:
   var book: Dictionary = c.market_books[key]
   for definition in book.stock:
    var k := kind(definition,c.catalog)
    if k.is_empty(): continue
    var id := "%s_%d_%s" %[book.town,book.week,definition]
    # Empty industry shelves must not reserve nonexistent equipment.
    if c.economy.enabled and not c.economy.industry.available(book.town,definition) and id not in c.purchased_gear: continue
    out[id] = {"town":book.town,"market":key,"definition":definition,"kind":k,"sold":id in c.purchased_gear}
 return out
static func arrive(c, ledger: Dictionary) -> void:
 var expected := sources(c); var ids: Array = expected.keys(); ids.sort()
 var added := []; var first: int = c.next_item; var pending := {};var used := {}
 if first<1:return
 for record in ledger.records.values(): used[record.item.id]=true
 for id in ids:
  if ledger.records.has(id) or expected[id].sold: continue
  var record: Dictionary = expected[id].duplicate(true)
  if added.size()>=9223372036854775807-first:return
  var uid := "item_%03d" %(first+added.size())
  # Preflight the complete batch before publishing any record or UID advance.
  if c.items.has(uid) or used.has(uid): return
  var definition: String = record.definition
  var item := {"id":uid,"definition":definition,"instance_roll":Rarity.roll_item(c.seed_value,uid,definition)}
  item["condition"] = int(Rarity.effective_definition(item,c.catalog[definition]).durability)
  if Arsenal.family(definition)=="crossbow": item["loaded"] = false
  record["item"] = item
  pending[id] = record; added.append(id)
 if not added.is_empty():
  ledger.records.merge(pending)
  ledger.batches.append({"first":first,"offers":added})
  c.next_item = first+added.size()
static func offers(c, ledger: Dictionary) -> Array:
 var out := []
 if not c.in_town() or c.over(): return out
 for id in ledger.records:
  var r: Dictionary = ledger.records[id]
  # Keep historical custody/tombstones intact. buy() reuses this offer projection.
  if r.definition == preload("res://painted_merge/acquisition.gd").LEGACY_CAP: continue
  if r.town != c.location or r.sold or id in c.purchased_gear: continue
  if not r.market.is_empty() and r.market != c.market_key(): continue
  if c.economy.enabled and not c.economy.industry.available(c.location,r.definition): continue
  # Detached snapshots may be edited by callers, never by shared reference.
  out.append({"id":id,"definition":r.definition,"kind":r.kind,"price":c.quoted_price(c.location,c.equipment_price(r.definition)),"item":r.item.duplicate(true)})
 return out
static func buy(c, ledger: Dictionary, id: String, wanted: String) -> String:
 if c.phase != "camp" or c.over() or not c.in_town(): return ""
 if not valid(ledger,c.snapshot(),c.catalog,c.has_method("shelf_offers")): return ""
 for offer in offers(c,ledger):
  if offer.id != id or offer.kind != wanted: continue
  if c.crowns < offer.price or offer.price < 1 or c.items.has(offer.item.id): return ""
  var record: Dictionary = ledger.records[id]
  if record.item != offer.item or not Rarity.valid_item(record.item) or record.item.instance_roll.seed != c.seed_value: return ""
  if c.market().is_empty(): return ""
  # Every refusal precedes all writes. sell_gear has no fallible return;
  # its finite availability was checked by offers().
  if c.economy.enabled:
   if c.has_method("shelf_offers"):
    var found := false
    for unit in c.economy.industry.state.towns[c.location].shelf:
     if unit.id == id and not unit.sold and unit.definition == offer.definition: found = true
    if not found: return ""
   c.economy.industry.sell_gear(c.location,offer.definition)
   if c.has_method("shelf_offers"):
    for unit in c.economy.industry.state.towns[c.location].shelf:
     if unit.id == id: unit.sold = true
  c.crowns -= offer.price; c.purchased_gear.append(id); c.market_receive(offer.price)
  c.items[offer.item.id] = record.item.duplicate(true); record.sold = true
  c.note("Bought %s for %d crowns; placed in stores." %[c.catalog[offer.definition].name,offer.price])
  return offer.item.id
 return ""
static func checkpoint_sources(d: Dictionary, catalog: Dictionary, shelf_mode: bool) -> Variant:
 var out := {}
 if shelf_mode:
  if not d.get("economy") is Dictionary or not d.economy.get("industry") is Dictionary or not d.economy.industry.get("towns") is Dictionary: return null
  for town in d.economy.industry.towns:
   var local = d.economy.industry.towns[town]
   if not town is String or not local is Dictionary or not local.get("shelf") is Array: return null
   for unit in local.shelf:
    if not unit is Dictionary or not unit.get("id") is String or not unit.get("definition") is String or not unit.get("sold") is bool: return null
    if out.has(unit.id) or kind(unit.definition,catalog).is_empty(): return null
    out[unit.id] = {"town":town,"market":"","definition":unit.definition,"kind":kind(unit.definition,catalog),"sold":unit.sold}
 else:
  if not d.get("market_books") is Dictionary: return null
  for key in d.market_books:
   var book = d.market_books[key]
   if not key is String or not book is Dictionary or not book.get("town") is String or not book.get("week") is int or not book.get("stock") is Array: return null
   for definition in book.stock:
    if not definition is String: return null
    var k := kind(definition,catalog)
    if k.is_empty(): continue
    var id := "%s_%d_%s" %[book.town,book.week,definition]
    out[id] = {"town":book.town,"market":key,"definition":definition,"kind":k,"sold":id in d.purchased_gear}
 return out
static func valid(ledger: Variant, d: Dictionary, catalog: Dictionary, shelf_mode: bool) -> bool:
 if not ledger is Dictionary or ledger.size()!=4 or not ledger.get("version") is int or ledger.version!=1: return false
 if not d.get("seed") is int or not ledger.get("seed") is int or ledger.seed!=d.seed: return false
 if not d.get("next_item") is int or not d.get("items") is Dictionary or not d.get("purchased_gear") is Array or not d.get("sales") is Array: return false
 if d.next_item<1:return false
 if not ledger.get("records") is Dictionary or not ledger.get("batches") is Array: return false
 var expected = checkpoint_sources(d,catalog,shelf_mode)
 if not expected is Dictionary or (shelf_mode and ledger.records.size()!=expected.size()): return false
 var allocated := {}; var identities := {}; var end := 1
 for batch in ledger.batches:
  if not batch is Dictionary or batch.size()!=2 or not batch.get("first") is int or not batch.get("offers") is Array or batch.offers.is_empty(): return false
  if batch.first<end or batch.offers.size()>d.next_item-batch.first: return false
  var ordered: Array=batch.offers.duplicate()
  for id in ordered:
   if not id is String: return false
  ordered.sort()
  if ordered!=batch.offers: return false
  for index in batch.offers.size():
   var id: String = batch.offers[index]
   if allocated.has(id): return false
   allocated[id]="item_%03d" %(batch.first+index)
  end=batch.first+batch.offers.size()
 if allocated.size()!=ledger.records.size(): return false
 var sold_ids := {};var sale_ids := {}
 for sale in d.sales:
  if not sale is Dictionary or not sale.get("item") is String: return false
  sale_ids[sale.item]=true
 for id in ledger.records:
  var record = ledger.records[id]
  if not id is String or not allocated.has(id) or not expected.has(id) or not record is Dictionary or record.size()!=6: return false
  for field in ["town","market","definition","kind","sold"]:
   if typeof(record.get(field))!=typeof(expected[id][field]) or record[field]!=expected[id][field]: return false
  if not record.get("item") is Dictionary: return false
  var item: Dictionary=record.item; var definition: String=record.definition
  if item.size()!=(5 if Arsenal.family(definition)=="crossbow" else 4): return false
  if not item.get("id") is String or not item.get("definition") is String: return false
  if item.id!=allocated[id] or item.definition!=definition or identities.has(allocated[id]): return false
  if not item.get("instance_roll") is Dictionary or not Rarity.valid_item(item) or item.instance_roll.seed!=d.seed: return false
  if not item.get("condition") is int or item.condition!=int(Rarity.effective_definition(item,catalog[definition]).durability): return false
  if Arsenal.family(definition)=="crossbow" and (not item.get("loaded") is bool or item.loaded): return false
  identities[item.id]=true
  if record.sold:
   sold_ids[id]=true
   if d.items.has(item.id):
    var owned = d.items[item.id]
    if not owned is Dictionary or owned.get("id")!=item.id or owned.get("definition")!=definition or owned.get("instance_roll")!=item.instance_roll: return false
  elif d.items.has(item.id) or sale_ids.has(item.id): return false
 var purchased := {}
 for id in d.purchased_gear:
  if not id is String or purchased.has(id): return false
  purchased[id]=true
 if purchased!=sold_ids: return false
 if not shelf_mode:
  for id in expected:
   if ledger.records.has(id): continue
   var r: Dictionary=expected[id]
   if not d.get("economy") is Dictionary: return false
   if int(d.economy.get("industry",{}).get("towns",{}).get(r.town,{}).get("equipment",{}).get(r.definition,0))>0: return false
 return true
