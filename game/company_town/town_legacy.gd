extends RefCounted
## Admission for retained paid controls. Rules, prices and mutation remain inherited.
## A control must be painted on its current surface at this physical town; its
## literal target and quote must still match, and each paint is consumed once.
var quotes := {}
var consumed := {}
var sale_review := {}

func handles(app, id: String) -> bool:
 return id in ["temple","person_hire","salvage_apply"] or id.begins_with("salvage_resource_buy_") or id.begins_with("salvage_resource_sell_") or (id=="arms_apply" and app.arms_source=="shop") or (id=="arm_apply" and app.armor_mode=="parts" and app.armor_source=="armorer" and app.armor_choice!="__remove__")

func context(app, id: String) -> Dictionary:
 if not app.visible or app.blocked(): return {}
 var site: String=app._town_location()
 var c=app.campaign
 if site.is_empty() or not c.encounter.is_empty() or not c.dungeons.active.is_empty() or c.over(): return {}
 var surface: String=app._surface()
 var out: Dictionary={"site":site,"market":c.market_key(),"surface":surface}
 if id=="person_hire":
  if surface!="person" or not app.person_view: return {}
  var live: Array=c.recruits().filter(func(r):return r.id==app.person_offer)
  if live.is_empty(): return {}
  out["recruit"]=live[0].duplicate(true)
 elif id=="temple":
  # No temple payment control is rendered by the successor Company surface.
  # The explicit per-person Town care control owns this service now.
  return {}
 elif id.begins_with("salvage_resource_"):
  if surface!="salvage" or not app.salvage_view or app.salvage_mode not in ["resources","cargo"]: return {}
  var selling:=id.begins_with("salvage_resource_sell_")
  var kind:=id.trim_prefix("salvage_resource_sell_" if selling else "salvage_resource_buy_")
  var q: Dictionary=c.economy.quote(c,site,kind,selling)
  if not q.reason.is_empty(): return {}
  out.merge({"kind":kind,"selling":selling,"mode":app.salvage_mode,"quote":q.duplicate(true)})
 elif id=="salvage_apply" and app.salvage_mode=="sell":
  if surface!="salvage" or not app.salvage_view: return {}
  var uid: String=app.salvage_choice
  var q: Dictionary=c.sale_quote(uid)
  if not q.reason.is_empty(): return {}
  var items: Dictionary={uid:c.items[uid].duplicate(true)}
  for part in c.kit_parts(uid).values():
   if not part.is_empty(): items[part]=c.items[part].duplicate(true)
  out.merge({"uid":uid,"quote":q.duplicate(true),"items":items,"review":app.sale_confirmation})
 else:
  var choice: String=""
  if id=="salvage_apply" and app.salvage_mode=="buy" and surface=="salvage" and app.salvage_view: choice=app.salvage_choice
  elif id=="arms_apply" and surface=="arms" and app.arms_view: choice=app.arms_choice
  elif id=="arm_apply" and surface=="arm" and app.armor_view: choice=app.armor_choice
  else: return {}
  var offers: Array=app.town.services.equipment_offers(c).filter(func(row):return row.id==choice)
  if offers.is_empty() or c.crowns<offers[0].price: return {}
  out["offer"]=offers[0].duplicate(true)
 return out

func capture(app, id: String, enabled: bool) -> void:
 if not enabled or not handles(app,id): return
 var current:=context(app,id)
 if not current.is_empty(): quotes[id]=current

func available(app, id: String) -> bool:
 var painted: Dictionary=quotes.get(id,{})
 return not consumed.has(id) and not painted.is_empty() and painted==context(app,id)

func admit(app, id: String) -> bool:
 consumed[id]=true
 var painted: Dictionary=quotes.get(id,{})
 quotes.erase(id) # Consume before inherited callbacks and checkpoint errors.
 var current:=context(app,id)
 if painted.is_empty() or current.is_empty() or painted!=current:
  if id=="salvage_apply": app.sale_confirmation=-1; sale_review.clear()
  app.refresh(); return false
 if current.has("review"):
  var token:=current.duplicate(true); token.erase("review")
  if current.review<0: sale_review=token
  elif sale_review!=token:
   app.sale_confirmation=-1; sale_review.clear(); app.refresh(); return false
  else: sale_review.clear()
 return true
