extends RefCounted
## Read-only projections plus delegates to the retained Campaign/Economy authority.
## Quotes are bound to the visible town and consumed before dispatch.
var commands := {}
var selected_offer := ""
var seen_offers := {}
var row_count := 0
var row_ids: Array = []
var _buy_paint := {}
const UI = preload("res://ui_polish/style.gd")
const Economy = preload("res://src/economy.gd")
const InventoryArt = preload("res://iron_oath/inventory_art.gd")
const Equipment = preload("res://hollow_campaign/appearance.gd")
const Offer = preload("res://company_town/equipment_offer.gd")
const Rarity = preload("res://hollow_campaign/rarity.gd")
var sales = preload("res://town_selling/sales.gd").new()

func draw(app, view) -> void:
 retire_buy()
 sales.sync(app,view)
 commands.clear(); row_count=0; row_ids.clear()
 if view.section == "market": _market(app,view)
 elif view.section == "equipment": _equipment(app,view)
 elif view.section == "recruits": _recruits(app,view)
 elif view.section == "treatment": _treatment(app,view)
 elif view.section == "contracts": _contracts(app,view)
 elif view.section == "news": _news(app,view)

func retire_buy() -> void:
 _buy_paint.clear()
 for id: String in commands.keys():
  if id in ["town_purchase","town_buy_cancel"] or id.begins_with("town_pick_"):commands.erase(id)

func _buy_available(app, view) -> bool:
 return app.is_visible_in_tree() and app.can_process() and not app.blocked() and app.host!=null and app.host.world==app and app.host.session.campaign==app.campaign and app.world_view and app.town_is_open() and app._clear_surface() and app._surface()=="town" and view.section=="equipment" and sales.mode=="buy"

func _arm_buy(app, view, id: String) -> void:
 # Detached paint recorders never acquire live command authority.
 if not app is Node or not _buy_available(app,view) or not commands.has(id) or not app.buttons.get(id,{}).get("enabled",false):return
 var offer: Dictionary=commands[id].offer
 var record: Dictionary=app.campaign.merchant_stock.records.get(offer.id,{})
 if record.is_empty() or Offer.stock_item(offer).is_empty():return
 _buy_paint[id]={"campaign":app.campaign,"site":view.site,"market":app.campaign.market_key(),"page":view.page,"offer":offer.duplicate(true),"uid":offer.item.id,"record":record.duplicate(true),"control":app.buttons[id]}

func _buy_current(app, view, id: String, token: Dictionary) -> bool:
 if not _buy_available(app,view):return false
 var c=app.campaign
 if token.campaign!=c or token.site!=view.site or token.market!=c.market_key() or token.page!=view.page:return false
 if not commands.has(id) or commands[id].get("offer",{})!=token.offer:return false
 var control: Dictionary=app.buttons.get(id,{})
 if not is_same(control,token.control) or not control.get("enabled",false) or not control.rect.has_area():return false
 if id in ["town_purchase","town_buy_cancel"] and selected_offer!=token.offer.id:return false
 # Offers are detached dictionaries: compare values and literal physical UID,
 # not their Dictionary references. Include all custody and item metadata.
 var record: Dictionary=c.merchant_stock.records.get(token.offer.id,{})
 if record!=token.record or record.get("item",{}).get("id","")!=token.uid:return false
 return equipment_offers(c).any(func(row):return row==token.offer and row.item.id==token.uid)

func sync_buy(app, view) -> void:
 for id: String in _buy_paint:
  if not _buy_current(app,view,id,_buy_paint[id]):
   retire_buy();return

func _control(app, id: String, title: String, rect: Rect2, data: Dictionary, reason := "") -> void:
 app.button(id,title,rect,reason.is_empty())
 if reason.is_empty(): commands[id]=data

func _rows(view, rows: Array) -> Array:
 row_count=rows.size()
 view.page=clampi(view.page,0,maxi(0,row_count-3))
 return rows.slice(view.page,view.page+3)

func _footer(app, view) -> void:
 app.button("town_prev","Previous",Rect2(354,746,148,44),view.page>0)
 app.label_at("%d–%d of %d · scroll for more" % [mini(row_count,view.page+1),mini(row_count,view.page+3),row_count],Vector2(530,774),14,UI.MUTED)
 app.button("town_next","Next",Rect2(1220,746,168,44),view.page+3<row_count)

func _supply_current(app, view, id: String, data: Dictionary) -> bool:
 if not app is Node or app.host==null or app.host.world!=app or app.host.session.campaign!=app.campaign:return false
 if not app.is_visible_in_tree() or not app.can_process() or app.blocked() or not app.town_is_open() or not app._clear_surface() or app._surface()!="town" or view.section!="market":return false
 var token: Dictionary=data.get("supply_paint",{})
 var c=app.campaign
 if token.is_empty() or token.campaign!=c or token.site!=view.site or token.page!=view.page or token.market!=c.market_key():return false
 var control: Dictionary=app.buttons.get(id,{})
 if not is_same(control,token.control) or not control.get("enabled",false):return false
 if c.crowns!=token.crowns or c.economy.owned(c,data.kind)!=token.owned:return false
 return not c.economy.enabled or c.economy.stock(c,view.site,data.kind)==token.stock
func _market(app, view) -> void:
 var c=app.campaign
 var goods: Array=Economy.GOODS if c.economy.enabled else Economy.SUPPLIES
 app.label_at("Live local stock · each price is for the stated bundle",Vector2(354,277),14,UI.MUTED)
 var rows:=_rows(view,goods)
 for i in rows.size():
  var kind: String=rows[i]; row_ids.append(kind)
  var y:=294+i*144
  app.panel(Rect2(354,y,1034,130),UI.SURFACE,UI.LINE)
  var buy: Dictionary
  var sell: Dictionary={"reason":"Trading unavailable","price":0,"amount":0}
  var stock: int=-1
  if c.economy.enabled:
   buy=c.economy.quote(c,view.site,kind,false); sell=c.economy.quote(c,view.site,kind,true)
   stock=c.economy.stock(c,view.site,kind)
  else:
   stock=c.world.towns[view.site].stock if kind=="food" else -1
   buy={"price":c.supply_cost(kind),"amount":Economy.BUNDLE[kind],"reason":""}
   if c.crowns<buy.price: buy.reason="Not enough crowns."
   elif stock>=0 and stock<buy.amount: buy.reason="Not enough local stock."
  app.label_at(Economy.NAMES[kind],Vector2(376,y+33),23,UI.TEXT,true)
  var owned: int=c.economy.owned(c,kind) if c.economy.enabled else c.get(Economy.FIELD[kind])
  app.label_at("Local stock: %s · Company stores: %d" % [str(stock) if stock>=0 else "available",owned],Vector2(376,y+65),15,UI.MUTED)
  _control(app,"town_buy_"+kind,"Buy %d · %dc" % [buy.amount,buy.price],Rect2(1002,y+18,176,46),{"kind":kind,"selling":false,"quote":buy.duplicate(true)},buy.reason)
  if c.economy.enabled:
   _control(app,"town_sell_"+kind,"Sell %d · %dc" % [sell.amount,sell.price],Rect2(1194,y+18,176,46),{"kind":kind,"selling":true,"quote":sell.duplicate(true)},sell.reason)
  if app is Node:
   for id: String in ["town_buy_"+kind,"town_sell_"+kind]:
    if commands.has(id):commands[id]["supply_paint"]={"campaign":c,"site":view.site,"page":view.page,"market":c.market_key(),"control":app.buttons[id],"crowns":c.crowns,"owned":owned,"stock":stock}
  var reasons: Array=[]
  if not buy.reason.is_empty(): reasons.append("Buy: "+buy.reason)
  if c.economy.enabled and not sell.reason.is_empty(): reasons.append("Sell: "+sell.reason)
  var hint: String="Buy automatically fills carried packs; %d supply needed. Arrows/bolts 1 per round; throwing 3." % c.company_ammo_needed() if kind=="ammo" else "Trading changes this town's stock and merchant funds."
  app.label_fit(" · ".join(reasons) if not reasons.is_empty() else hint,Vector2(376,y+104),988,14,UI.GOLD if not buy.reason.is_empty() else UI.MUTED)
 _footer(app,view)

func equipment_offers(c) -> Array:
 # Same retained catalogue adapter as hollow_campaign/outfitting._market_offers.
 var out: Array=[]
 for offer: Dictionary in c.weapons_stock():
  var row:=offer.duplicate(true); row.kind=offer.get("kind","weapon"); out.append(row)
 for group in ["body","head"]:
  for layer in (["base","mail","outer"] if group=="body" else ["shell"]):
   for offer: Dictionary in c.armorer_stock(group,layer):
    var row:=offer.duplicate(true); row.kind=offer.get("kind","component"); out.append(row)
 return out

func _equipment(app, view) -> void:
 sales.tabs(app,view)
 if sales.mode == "sell":
  sales.draw(app,view,self);return
 var c=app.campaign
 var live:=equipment_offers(c)
 for row: Dictionary in live: seen_offers[row.id]=row.duplicate(true)
 app.label_at(Offer.BASE_NOTE,Vector2(354,277),14,UI.MUTED)
 var rows:=_rows(view,seen_offers.values())
 for i in rows.size():
  var offer: Dictionary=rows[i]; row_ids.append(offer.id)
  var y:=294+i*128
  var available: bool=live.any(func(row):return row.id==offer.id)
  var d: Dictionary=c.catalog.get(offer.definition,{})
  var item:=Offer.stock_item(offer)
  available=available and not item.is_empty()
  var tier: String=Equipment.item_tier(item,c.catalog)
  app.panel(Rect2(354,y,1034,120),UI.SURFACE,UI.GOLD if selected_offer==offer.id else UI.LINE)
  var stage:=Rect2(368,y+13,88,88)
  var icon:=InventoryArt.item_icon(item,c.catalog,null,"")
  if not icon.is_empty():
   UI.Press.impression(app,stage.grow(2),"well")
   var texture: Texture2D=icon.texture
   var fit: Vector2=texture.get_size()*minf(stage.size.x/texture.get_width(),stage.size.y/texture.get_height())
   app.draw_texture_rect(texture,Rect2(stage.get_center()-fit/2,fit),false)
  else:
   app.panel(stage,UI.SURFACE,UI.LINE)
   app.label_at("No art",Vector2(382,y+62),13,UI.MUTED)
  app.label_fit("%s · %s" % [d.get("name",offer.definition),tier.capitalize() if not tier.is_empty() else "Roll unavailable"],Vector2(476,y+28),670,23,Rarity.tier_color(tier),true)
  app.label_fit("%s · %d crowns · %s" % [str(d.get("slot",d.get("group","equipment"))).capitalize(),offer.price,"Roll unavailable" if item.is_empty() else "In stock" if available else "Sold out"],Vector2(476,y+51),670,16,UI.GOLD)
  var details := Offer.lines(offer,c.catalog,c.battle.weapons)
  for line in mini(2,details.size()):
   app.label_fit(details[line],Vector2(476,y+71+line*19),888,14,UI.MUTED)
  # Utility items can have two independent rolls. Give them a shared baseline
  # inside the plate instead of drawing one through the following offer.
  if details.size()>2:
   app.label_fit("   /   ".join(details.slice(2)),Vector2(476,y+109),888,14,UI.MUTED)
  # Distinct action IDs keep the inspection callback read-only after repaint.
  var selected_row: bool=selected_offer==offer.id
  var id: String="town_purchase" if selected_row else "town_pick_"+offer.id
  var refusal: String="Sold out" if not available else "Not enough crowns." if selected_row and c.crowns<offer.price else ""
  _control(app,id,"Confirm buy · %dc" % offer.price if selected_row else "Inspect offer",Rect2(1174,y+10,196,46),{"offer":offer},refusal)
  _arm_buy(app,view,id)
 var selected: Dictionary={}
 for offer: Dictionary in live:
  if offer.id==selected_offer: selected=offer; break
 var valid:=not Offer.stock_item(selected).is_empty()
 var reason: String="Choose an offer." if selected_offer.is_empty() else "Sold out or no longer offered here." if selected.is_empty() else "Roll details unavailable. No purchase possible." if not valid else "Not enough crowns." if c.crowns<selected.price else "Ready to buy; fitting is separate in Company."
 app.label_fit(reason,Vector2(354,707),690,15,UI.MUTED)
 if not selected.is_empty():
  _control(app,"town_buy_cancel","Cancel",Rect2(902,680,160,46),{"offer":selected,"cancel_offer":true})
  _arm_buy(app,view,"town_buy_cancel")
 if rows.is_empty(): app.label_at("No equipment is offered in this town today.",Vector2(376,337),18,UI.MUTED)
 _footer(app,view)

func _recruits(app, view) -> void:
 var c=app.campaign
 app.label_at("%d / %d companions · hired recruits bring their own starting gear" % [c.alive_count(),c.company_limit()],Vector2(354,277),14,UI.MUTED)
 var rows:=_rows(view,c.recruits())
 for i in rows.size():
  var recruit: Dictionary=rows[i]; row_ids.append(recruit.id)
  var y:=294+i*144
  app.panel(Rect2(354,y,1034,130),UI.SURFACE,UI.LINE)
  app.label_fit(recruit.person+" · "+recruit.name,Vector2(376,y+30),770,23,UI.TEXT,true)
  app.label_fit(recruit.trait,Vector2(376,y+50),770,14,UI.MUTED)
  app.label_at("%d crowns to hire · %d crowns per day · kit included" % [recruit.price,recruit.wage],Vector2(376,y+72),16,UI.GOLD)
  var arms := [recruit.weapon,recruit.loadout.shield,recruit.ammo_loadout]
  var arms_text := " · ".join(arms.filter(func(id):return not id.is_empty()).map(func(id):return c.catalog[id].name))
  var spares: Array = recruit.carried_loadout.filter(func(id):return not id.is_empty()).map(func(id):return c.catalog[id].name)
  if not spares.is_empty(): arms_text += " · Spare: "+", ".join(spares)
  var outfit := []
  for group in ["body","head"]: outfit.append_array(recruit.armor_loadout[group].values())
  for slot in ["hands","feet","cloak","belt"]: outfit.append(recruit.get("support_loadout",{}).get(slot,""))
  var outfit_text := " · ".join(outfit.filter(func(id):return not id.is_empty()).map(func(id):return c.catalog[id].name))
  app.label_fit(arms_text,Vector2(376,y+96),770,14,UI.TEXT)
  app.label_fit(outfit_text if not outfit_text.is_empty() else "No other equipment",Vector2(376,y+117),770,14,UI.TEXT)
  var reason: String="Company full" if c.alive_count()>=c.company_limit() else "Not enough crowns" if c.crowns<recruit.price else ""
  _control(app,"town_hire_"+recruit.id,"Hire · %dc" % recruit.price if reason.is_empty() else reason,Rect2(1164,y+14,206,46),{"recruit":recruit},reason)
  _control(app,"town_profile_"+recruit.id,"Read profile",Rect2(1164,y+72,206,42),{"profile":recruit.id})
 if rows.is_empty(): app.label_at("No recruits remain here this week.",Vector2(376,337),19,UI.MUTED)
 _footer(app,view)

func _treatment(app, view) -> void:
 var c=app.campaign
 app.label_at("Injury recovery is twice as fast · medicine still required · scars remain",Vector2(354,277),14,UI.MUTED)
 var rows:=_rows(view,c.soldiers.filter(func(s):return s.alive))
 for i in rows.size():
  var person: Dictionary=rows[i]; row_ids.append(str(person.id))
  var y:=294+i*144
  app.panel(Rect2(354,y,1034,130),UI.SURFACE,UI.LINE)
  app.label_fit(person.name,Vector2(376,y+33),730,23,UI.TEXT,true)
  app.label_fit(c.Recovery.status(c,person.id),Vector2(376,y+66),740,16,UI.MUTED)
  var treated: bool=c.recovery.patients.get(str(person.id),{}).get("temple",false)
  var reason: String="No injury" if person.wound_days<=0 else "Already receiving care" if treated else "Not enough crowns" if c.crowns<40 else ""
  _control(app,"town_treat_%d" % person.id,"Arrange care · 40c" if reason.is_empty() else reason,Rect2(1134,y+24,236,50),{"patient":person.id},reason)
  app.label_at("Recovery happens as time passes, not immediately.",Vector2(376,y+105),14,UI.MUTED)
 if rows.is_empty(): app.label_at("No living companions need care.",Vector2(376,337),19,UI.MUTED)
 _footer(app,view)

func _contracts(app, view) -> void:
 var c=app.campaign
 app.label_at("Council-funded camp-clearing work · only admitted contracts can be signed",Vector2(354,277),14,UI.MUTED)
 if c.has_method("payment_direction") and not c.payment_pending.is_empty():
  var quote: Dictionary=c.payment_pending.duplicate(true)
  UI.Press.impression(app,Rect2(354,294,1034,352),"paper")
  var job: Dictionary=quote.job
  app.label_fit(job.title,Vector2(376,337),980,27,UI.Press.PAPER_INK,true)
  app.label_at("Objective complete · %d crowns DUE (not received)" % job.pay,Vector2(376,394),21,UI.Press.PAPER_INK)
  app.label_fit("Return to "+c.node(job.origin).name+" · Contract Board",Vector2(376,443),980,20,UI.Press.PAPER_INK)
  var reason: String="Contract host unavailable." if app.host==null else app.host.session.payment_collect_reason(quote)
  app.label_fit(reason if not reason.is_empty() else "Council funds are reserved. Collect the agreed payment below.",Vector2(376,500),980,16,UI.Press.PAPER_NOTE)
  _control(app,"town_collect_payment","Collect payment · %d crowns" % job.pay,Rect2(376,568,422,48),{"payment":quote,"site":view.site},reason)
  return
 if not c.active.is_empty():
  UI.Press.impression(app,Rect2(354,294,1034,352),"paper")
  var job: Dictionary=c.active
  app.label_fit(job.title,Vector2(376,337),980,27,UI.Press.PAPER_INK,true)
  var lines: Array=app.wrapped_lines(job.brief,960,17,4)
  for i in lines.size(): app.label_at(lines[i],Vector2(376,382+i*25),17,UI.Press.PAPER_NOTE)
  app.label_at("%d crowns · collect at %s after victory" % [job.pay,c.node(job.origin).name] if c.has_method("payment_direction") else "%d crowns on success · due day %d" % [job.pay,job.deadline],Vector2(376,520),19,UI.Press.PAPER_INK)
  app.label_fit("Destination · %s · objective due day %d" % [c.node(job.target).name,job.deadline],Vector2(376,559),960,18,UI.Press.PAPER_INK)
  app.label_at(c.job_danger(job),Vector2(376,598),16,UI.Press.PAPER_RED)
  app.button("abandon","Abandon contract…",Rect2(376,676,304,46))
  return
 var rows:=_rows(view,c.offers())
 for i in rows.size():
  var job: Dictionary=rows[i]; row_ids.append(job.id)
  var y:=294+i*144
  var reason: String="Contract host unavailable." if app.host==null else app.host.session.contract_accept_preview_reason(job.id)
  UI.Press.impression(app,Rect2(354,y,1034,130),"paper")
  app.label_fit(job.title,Vector2(376,y+31),720,23,UI.Press.PAPER_INK,true)
  app.label_fit("%dc · due day %d · %s" % [job.pay,job.deadline,c.node(job.target).name],Vector2(376,y+62),720,16,UI.Press.PAPER_INK)
  app.label_fit(c.job_danger(job) if reason.is_empty() else reason,Vector2(376,y+102),980,14,UI.Press.PAPER_RED)
  _control(app,"town_sign_"+job.id,"Sign contract" if reason.is_empty() else "Unavailable",Rect2(1164,y+20,206,48),{"contract":job},reason)
 if rows.is_empty():
  var lines: Array=app.wrapped_lines(c.work_hint(),950,18,6)
  for i in lines.size(): app.label_at(lines[i],Vector2(376,337+i*29),18,UI.MUTED)
 _footer(app,view)

func _news(app, view) -> void:
 var c=app.campaign
 app.label_at("This town’s board · ask for local conditions; caravans bring word from elsewhere.",Vector2(354,277),14,UI.MUTED)
 _control(app,"town_hear_news","Ask for local news",Rect2(354,294,310,46),{"news":"reports"})
 _control(app,"town_hear_rumour","Ask about old ruins",Rect2(680,294,310,46),{"news":"ruins"})
 _control(app,"town_hear_other","Other rumours",Rect2(1006,294,382,46),{"news":"other"})
 var rows:=_rows(view,c.news.town_rows(c))
 for i in rows.size():
  var row: Dictionary=rows[i]; var r: Dictionary=row.report
  row_ids.append(str(r.town)+":"+str(r.kind))
  var y:=360+i*118
  app.panel(Rect2(354,y,1034,104),UI.SURFACE,UI.LINE)
  app.label_fit(c.news.title(c,r),Vector2(376,y+31),980,20,UI.TEXT,true)
  var stale: bool=c.news.clock(c)-r.observed>=c.news.OLD_HOURS*60
  app.label_fit("%s · observed day %d · %s%s" % [c.node(r.town).name,r.observed/1440+1,c.news.age(c,r)," · May be outdated" if stale else ""],Vector2(376,y+62),980,15,UI.GOLD)
  var source: String="Local account" if row.carrier=="" else "Caravan %s from %s · arrived day %d" % [c.world.short_id(row.carrier),c.node(row.via).name,1+row.received/1440]
  app.label_fit(source,Vector2(376,y+87),980,14,UI.MUTED)
 if rows.is_empty(): app.label_at("No reports recorded yet. Ask the people of this town.",Vector2(376,404),18,UI.MUTED)
 _footer(app,view)

func action(app, view, id: String) -> bool:
 sync_buy(app,view)
 if sales.handles(id):
  retire_buy();return sales.action(app,view,id)
 if id in ["town_purchase","town_buy_cancel"] or id.begins_with("town_pick_"):
  if not _buy_paint.has(id):return false
  _buy_paint.clear() # Consume before domain writes, changed and synchronous callbacks.
 if not commands.has(id): return false
 var data: Dictionary=commands[id]
 if data.has("kind") and not _supply_current(app,view,id,data):return false
 if not app.visible or app.blocked() or not app.town_is_open() or not app._clear_surface(): return false
 commands.clear() # Consume first, including synchronous callbacks/save-error paths.
 var c=app.campaign
 if data.has("payment"):
  if view.section=="contracts" and view.site==data.site and app.host!=null:
   app.host._collect_contract_payment(data.payment)
  app.refresh(); return true
 if data.has("contract"):
  var job: Dictionary=data.contract
  if app.host!=null and app.host.session.contract_accept_reason(job.id).is_empty() and c.offers().any(func(row):return row.id==job.id and row.pay==job.pay and row.generation==job.generation):
   app.host._accept_contract(job.id)
  app.refresh(); return true
 if data.has("news"):
  var changed:=false
  if data.news=="reports":
   var heard: int=c.hear_regional_news()
   if heard>=0: changed=true; app.tell("%d new or updated reports recorded." % heard)
  else:
   var site: String=c.dungeon_rumour() if data.news=="ruins" else c.exploration.hear_rumour(c)
   changed=not site.is_empty()
   app.tell("Directions recorded for "+c.node(site).name if changed else "No further rumours here.")
  if changed and app.host!=null: app.host.session.changed.emit()
  app.refresh(); return true
 if data.has("patient"):
  if c.temple(data.patient):
   app.tell("Temple care arranged for 40 crowns. Medicine is still required.")
   if app.host!=null: app.host.session.changed.emit()
  app.refresh(); return true
 if data.has("profile"):
  app.action("person_offer_"+data.profile); return true
 if data.has("recruit"):
  var r: Dictionary=data.recruit
  if not c.recruits().any(func(row):return row==r):
   app.tell("This recruit is no longer available."); app.refresh(); return true
  if c.hire(r.id):
   app.tell("%s joins for %d crowns · listed kit equipped." % [r.person,r.price])
   if app.host!=null: app.host.session.changed.emit()
  else: app.tell("Cannot hire: company full or insufficient crowns.")
  app.refresh(); return true
 if data.has("offer"):
  var offer: Dictionary=data.offer
  if data.get("cancel_offer",false):
   selected_offer="";app.refresh();return true
  if id.begins_with("town_pick_"):
   selected_offer=offer.id; app.refresh(); return true
  var live:=equipment_offers(c)
  if not live.any(func(row):return row.id==offer.id and row.price==offer.price and row.kind==offer.kind):
   app.tell("This offer is no longer available. No purchase made."); app.refresh(); return true
  var uid: String=c.buy_weapon(offer.id) if offer.kind=="weapon" else c.buy_component(offer.id)
  if not uid.is_empty():
   app.tell("Bought %s for %d crowns · placed in company stores." % [c.catalog[offer.definition].name,offer.price])
   if app.host!=null: app.host.session.changed.emit()
  else: app.tell("Purchase refused; no item received.")
  app.refresh(); return true
 var q: Dictionary=c.economy.quote(c,view.site,data.kind,data.selling) if c.economy.enabled else {"price":c.supply_cost(data.kind),"amount":Economy.BUNDLE[data.kind],"reason":""}
 if not q.reason.is_empty() or q.price!=data.quote.price or q.amount!=data.quote.amount:
  app.tell("This quote has changed. Review the current stock."); app.refresh(); return true
 var changed: bool=c.economy.trade(c,data.kind,data.selling) if c.economy.enabled else c.buy_supply(data.kind)
 if changed:
  app.tell("%s %d %s for %d crowns." % ["Sold" if data.selling else "Bought",q.amount,Economy.NAMES[data.kind].to_lower(),q.price])
  if app.host != null: app.host.session.changed.emit()
 else: app.tell("No trade made. Review local stock and company funds.")
 app.refresh(); return true
