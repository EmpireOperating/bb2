extends RefCounted
## Read-only projections plus delegates to the retained Campaign/Economy authority.
var commands := {}
var row_count := 0
var row_ids: Array = []
var market_mode := "buy"
var _market_paint := {}
var _review := {}
const UI = preload("res://ui_polish/style.gd")
const Economy = preload("res://src/economy.gd")
const Offer = preload("res://company_town/equipment_offer.gd")
const Board = preload("res://company_town/market_board.gd")
const Sales = preload("res://town_selling/sales.gd")
const MASON := preload("res://local_markets/industry.gd").MASON_OFFER
const TAVERN_ROUND := "town_tavern_round"
const TRADE_LEADS := ["shortage","lean","surplus"]
var board := Board.new()

func draw(app, view) -> void:
 commands.clear(); row_count=0; row_ids.clear()
 if view.section == "market": _market(app,view)
 elif view.section == "recruits": _recruits(app,view)
 elif view.section == "treatment": _treatment(app,view)
 elif view.section == "contracts": _contracts(app,view)
 elif view.section == "news": _news(app,view)

func retire_market() -> void:
 _review.clear()
 _market_paint.clear()
 for id: String in commands.keys():
  if commands[id].has("market_intent"):commands.erase(id)

func reset_market() -> void:
 retire_market()
 market_mode = "buy"
 board.reset()

func _market_context(app, view) -> Dictionary:
 return {"campaign":app.campaign,"site":view.site,"market":app.campaign.market_key(),"page":view.page,"mode":market_mode} if view.market_available(app) else {}

func sync_market(app, view) -> void:
 if not _market_paint.is_empty() and _market_paint != _market_context(app,view):retire_market()

func page_step(view, wheel := false) -> int:
 return (Board.COLS if wheel else Board.CAPACITY) if view.section == "market" else (1 if wheel else 3)

func page_limit(view) -> int:
 return ceili(float(maxi(0,row_count-Board.CAPACITY))/Board.COLS)*Board.COLS if view.section == "market" else maxi(0,row_count-3)

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

func _supply_stock(c, site: String, kind: String) -> int:
 return c.economy.stock(c,site,kind) if c.economy.enabled else c.world.towns[site].stock if kind=="food" else -1

func _supply_details(c, site: String, kind: String) -> Dictionary:
 var stock := _supply_stock(c,site,kind)
 var buy: Dictionary
 var sell := {"reason":"Trading unavailable","price":0,"amount":0}
 if c.economy.enabled:
  buy=c.economy.quote(c,site,kind,false)
  sell=c.economy.quote(c,site,kind,true)
 else:
  buy={"price":c.supply_cost(kind),"amount":Economy.BUNDLE[kind],"reason":""}
  if c.crowns<buy.price:buy.reason="Not enough crowns."
  elif stock>=0 and stock<buy.amount:buy.reason="Not enough local stock."
 return {"buy":buy,"sell":sell,"stock":stock,"owned":c.economy.owned(c,kind),"crowns":c.crowns,
  "cash":c.market().get("cash",-1),"local_cash":c.economy.towns[site].cash if c.economy.enabled else -1,
  "refill":c.company_ammo_needed() if kind=="ammo" else 0}

func equipment_offers(c) -> Array:
 return c.merchant_offers()

func _market_detail(c, site: String, row: Dictionary) -> Dictionary:
 if row.has("good"):return _supply_details(c,site,row.good)
 if row.has("uid"):return Sales.capture(c,site,row.uid)
 var offer: Dictionary = row.offer
 var reason := Offer.armor_lab_refusal(c.catalog.get(offer.definition,{}))
 if row.item.is_empty():reason="Roll details unavailable."
 elif c.items.has(row.item.id) or c.market().is_empty():reason="This offer is no longer available."
 elif reason.is_empty() and c.crowns<offer.price:reason="Not enough crowns."
 return {"offer":offer,"record":c.merchant_stock.records.get(offer.id,{}).duplicate(true),"crowns":c.crowns,
  "quote":{"price":offer.price,"reason":reason}}

func _active_quote(detail: Dictionary) -> Dictionary:
 return detail[market_mode] if detail.has("buy") else detail.quote

func _record_intent(app, id: String, intent: Dictionary) -> void:
 if not _market_paint.is_empty() and app.buttons.get(id,{}).get("enabled",false):
  commands[id]={"market_intent":intent,"control":app.buttons[id]}

func _market_button(app, id: String, title: String, rect: Rect2, intent: Dictionary, enabled := true, primary := false) -> void:
 app.button(id,title,rect,enabled,primary)
 if enabled:_record_intent(app,id,intent)

func _market(app, view) -> void:
 var c=app.campaign
 var rows := []
 for kind: String in (Economy.GOODS if c.economy.enabled else Economy.SUPPLIES):
  rows.append({"id":"town_market_good_"+kind,"good":kind})
 if market_mode=="buy":
  for offer: Dictionary in equipment_offers(c):
   rows.append({"id":"town_market_offer_"+offer.id,"offer":offer,"item":Offer.stock_item(offer),"commission":offer.id==MASON and offer.definition=="mason_hammer"})
 else:
  for uid: String in Sales.rows(c):
   rows.append({"id":"town_market_item_"+uid,"uid":uid,"item":c.items[uid]})
 row_count=rows.size()
 view.page=clampi(view.page,0,page_limit(view))
 _market_paint = _market_context(app,view)
 if not _review.is_empty() and _review.context!=_market_paint:_review.clear()
 _market_button(app,"town_market_buy","Buy",Rect2(850,217,144,44),{"mode":"buy"},true,market_mode=="buy")
 _market_button(app,"town_market_sell","Sell",Rect2(1006,217,144,44),{"mode":"sell"},true,market_mode=="sell")
 if c.has_method("fresh_freight_delivery"):
  var note: String=c.fresh_freight_delivery(view.site)
  if note!="":app.label_fit(note,Vector2(354,251),465,15,UI.GOLD)
 app.label_at("LOCAL STOCK" if market_mode=="buy" else "COMPANY STOCK",Vector2(354,293),14,UI.GOLD)
 app.label_at("Supplies · trade goods · equipment" if market_mode=="buy" else "Goods and loose equipment only",Vector2(524,293),14,UI.MUTED)
 var pointer: Vector2 = app.get_global_mouse_position() if app is Node else Vector2(-1,-1)
 var keyboard: bool = app is Node and app._keyboard_paint
 var inspected := {}
 var reviewed := {}
 var visible_rows := rows.slice(view.page,view.page+Board.CAPACITY)
 for i in visible_rows.size():
  var row: Dictionary = visible_rows[i]
  row_ids.append(row.id)
  var is_reviewed: bool = _review.get("card","")==row.id
  var hot: bool = not _market_paint.is_empty() and (app._keyboard_id==row.id if keyboard else board.slot(i).has_point(pointer))
  if is_reviewed:reviewed=row
  if hot:inspected=row
  var count: int = -1
  if row.has("good"):count=_supply_stock(c,view.site,row.good) if market_mode=="buy" else c.economy.owned(c,row.good)
  board.card(app,row,i,c.catalog,view.RESOURCE_ART,hot,is_reviewed,count)
  _record_intent(app,row.id,{"pick":row})
 if reviewed.is_empty():_review.clear()
 var review_detail := {} if reviewed.is_empty() else _market_detail(c,view.site,reviewed)
 if not reviewed.is_empty() and not _same_review(_review.detail,review_detail):_review.stale=true
 if inspected.is_empty():inspected=reviewed
 var show_review: bool = not reviewed.is_empty() and inspected.id==reviewed.id
 var detail := review_detail if show_review else {} if inspected.is_empty() else _market_detail(c,view.site,inspected)
 board.inspector(app,c,inspected,detail,market_mode,show_review,_review.get("stale",false) and show_review)
 if show_review:
  _market_button(app,"town_market_cancel","Cancel",Board.CANCEL,{"cancel":true})
  var quote := _active_quote(detail)
  var verb := "Buy" if market_mode=="buy" else "Sell"
  var title := "%s %d · %dc" % [verb,quote.amount,quote.price] if inspected.has("good") else "Confirm %s · %dc" % ["purchase" if market_mode=="buy" else "sale",quote.price]
  _market_button(app,_confirm_id(inspected),title,Board.CONFIRM,{"confirm":inspected},not _review.stale and quote.reason.is_empty(),true)
 app.label_fit("Merchant purse: %d crowns" % c.market().get("cash",0) if market_mode=="sell" else "Each piece of equipment is individual stock.",Vector2(354,726),606,14,UI.MUTED)
 if row_count>Board.CAPACITY:
  app.button("town_prev","Previous",Rect2(354,746,126,44),view.page>0)
  app.button("town_next","Next",Rect2(848,746,126,44),view.page<page_limit(view))
  app.centered("%d–%d of %d" % [view.page+1,view.page+visible_rows.size(),row_count],Vector2(664,774),14,UI.MUTED)

func _same_review(old: Dictionary, live: Dictionary) -> bool:
 if old.has("record_ref") and not is_same(old.record_ref,live.record_ref):return false
 return old == live

func _confirm_id(row: Dictionary) -> String:
 if row.has("good"):return "town_"+market_mode+"_"+row.good
 return "town_sell_confirm_"+row.uid if row.has("uid") else "town_buy_offer_"+row.offer.id

func _live_row(c, row: Dictionary) -> Dictionary:
 if row.has("good"):return row
 if row.has("uid"):
  if row.uid in Sales.rows(c):return row.merged({"item":c.items[row.uid]},true)
  return {}
 for offer: Dictionary in equipment_offers(c):
  if offer.id==row.offer.id:return row.merged({"offer":offer,"item":Offer.stock_item(offer)},true)
 return {}

func _market_action(app, view, id: String, data: Dictionary) -> bool:
 if _market_paint.is_empty() or _market_paint!=_market_context(app,view):return false
 var control: Dictionary=app.buttons.get(id,{})
 if not is_same(control,data.control) or not control.get("enabled",false) or not control.rect.has_area():return false
 var intent: Dictionary = data.market_intent
 var c=app.campaign
 if intent.has("mode"):
  if market_mode!=intent.mode:
   retire_market();market_mode=intent.mode;view.page=0
  app.refresh();return true
 if intent.has("cancel"):
  app._keyboard_id=_review.get("card","")
  retire_market();app.refresh();return true
 var row: Dictionary=intent.get("pick",intent.get("confirm",{}))
 var live:=_live_row(c,row)
 if intent.has("pick"):
  # Selecting is inspection only. Do not retarget a retired physical card.
  if live.is_empty() or row.get("item",{})!=live.get("item",{}):retire_market();app.refresh();return false
  _review={"card":row.id,"context":_market_paint,"detail":_market_detail(c,view.site,live),"stale":false}
  commands.clear() # A confirm doesn't exist until this review has been painted.
  if app._keyboard_paint:app._keyboard_id="town_market_cancel"
  app.refresh();return true
 if _review.get("card","")!=row.id or _review.stale or _review.context!=_market_paint:return false
 var detail: Dictionary = _review.detail
 # Recompute against the exact reviewed instance and quote even if no redraw
 # has occurred yet. Close review before any synchronous changed/rebind callback.
 var current: bool = not live.is_empty() and _same_review(detail,_market_detail(c,view.site,live)) and _active_quote(detail).reason.is_empty()
 if live.has("uid"):current=current and Sales.current(c,view.site,detail)
 retire_market()
 if not current:
  app.tell("Quote changed. No trade made.");app.refresh();return true
 app._keyboard_id=row.id
 var quote := _active_quote(detail)
 var changed := false
 if row.has("good"):
  var selling := market_mode=="sell"
  changed=c.economy.trade(c,row.good,selling) if c.economy.enabled else not selling and c.buy_supply(row.good)
  if changed:app.tell("%s %d %s for %d crowns." % ["Sold" if selling else "Bought",quote.amount,Economy.NAMES[row.good].to_lower(),quote.price])
 elif row.has("uid"):
  changed=Sales.commit(app,view,detail)
 else:
  var offer: Dictionary = detail.offer
  var uid: String = c.buy_weapon(offer.id) if offer.kind=="weapon" else c.buy_component(offer.id)
  changed=not uid.is_empty()
  if changed:app.tell("Bought %s for %d crowns · placed in company stores." % [c.catalog[offer.definition].name,offer.price])
 if changed:app.host.session.changed.emit()
 else:app.tell("No trade made. Review current stock and funds.")
 app.refresh();return true

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
 var automatic: bool = c.has_method("pays_contracts_on_arrival") and c.pays_contracts_on_arrival()
 var courier_board: bool = c.has_method("courier_enabled") and c.courier_enabled()
 app.label_at("Council-funded contracts · clearing, courier and escort work" if courier_board and c.has_method("freight_escort_enabled") and c.freight_escort_enabled() else "Council-funded contracts · camp clearing and courier work" if courier_board else "Council-funded camp-clearing work · only admitted contracts can be signed",Vector2(354,277),14,UI.MUTED)
 if c.has_method("payment_direction") and not c.payment_pending.is_empty():
  var quote: Dictionary=c.payment_pending.duplicate(true)
  UI.Press.impression(app,Rect2(354,294,1034,352),"paper")
  var job: Dictionary=quote.job
  app.label_fit(job.title,Vector2(376,337),980,27,UI.Press.PAPER_INK,true)
  app.label_at("Objective complete · %d crowns DUE (not received)" % job.pay,Vector2(376,394),21,UI.Press.PAPER_INK)
  if automatic:
   app.label_fit("Return to "+c.node(job.origin).name+" · paid automatically on arrival",Vector2(376,443),980,20,UI.Press.PAPER_INK)
   return
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
  if job.kind=="courier": app.label_fit("%d crowns · Paid on arrival in %s" % [job.pay,c.node(job.target).name],Vector2(376,520),960,19,UI.Press.PAPER_INK)
  elif job.kind=="freight_escort":app.label_fit("%d crowns · Paid on intact delivery at %s" % [job.pay,c.node(job.target).name],Vector2(376,520),960,19,UI.Press.PAPER_INK)
  elif automatic: app.label_at("%d crowns · paid on return to %s after victory" % [job.pay,c.node(job.origin).name],Vector2(376,520),19,UI.Press.PAPER_INK)
  else: app.label_at("%d crowns · collect at %s after victory" % [job.pay,c.node(job.origin).name] if c.has_method("payment_direction") else "%d crowns on success · due day %d" % [job.pay,job.deadline],Vector2(376,520),19,UI.Press.PAPER_INK)
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

func _round_outcome(c, receipt: Dictionary) -> String:
 var names: PackedStringArray = []
 for id: int in receipt.raised:names.append(c.soldiers[id].name)
 return "Nobody’s spirits lifted." if names.is_empty() else "Spirits lifted: "+", ".join(names)+"."

func _tavern(app, view, c) -> void:
 app.panel(Rect2(354,272,674,176),Color("2c211a"),UI.LINE)
 app.label_at("AT THE BAR  /  A WORD WITH THE LOCALS",Vector2(372,298),13,UI.GOLD)
 if not c.has_method("tavern_quote"):return
 var quote: Dictionary = c.tavern_quote(view.site)
 var enabled: bool = view.tavern_available(app) and quote.reason.is_empty()
 app.button(TAVERN_ROUND,"Buy a round of ale · %d crowns" % quote.price,Rect2(372,311,310,44),enabled,true)
 if enabled:commands[TAVERN_ROUND]={"round":quote,"owner":c,"control":app.buttons[TAVERN_ROUND]}
 app.label_fit("%d living · %d crowns each" % [quote.attendees.size(),c.TAVERN_COST_PER_PERSON] if quote.reason.is_empty() else quote.reason,Vector2(698,338),310,15,UI.TEXT)
 app.label_fit("%d%% each to lift mood now. It fades over campaign time; victories help." % c.TAVERN_CHANCE,Vector2(372,376),636,15,UI.MUTED)
 var result: Dictionary = c.tavern_result_today()
 if not result.is_empty():
  var lines: Array = app.wrapped_lines(_round_outcome(c,result),636,15,3)
  for i in lines.size():app.label_fit(lines[i],Vector2(372,397+i*19),636,15,UI.GOLD)

func _tavern_action(app, view, data: Dictionary) -> bool:
 if not view.tavern_available(app) or data.owner!=app.campaign:return false
 var control: Dictionary = app.buttons.get(TAVERN_ROUND,{})
 if not is_same(control,data.control) or not control.get("enabled",false) or not control.rect.has_area():return false
 commands.erase(TAVERN_ROUND) # Retire before any changed callback or redraw.
 var c = app.campaign
 if not c.buy_tavern_round(data.round):
  app.tell("The round offer changed. No crowns spent.")
  app.refresh(); return false
 app.tell("Paid %d crowns. %s" % [data.round.price,_round_outcome(c,c.tavern_result_today())])
 app.host.session.changed.emit()
 app.refresh(); return true

func _news(app, view) -> void:
 var c=app.campaign
 _tavern(app,view,c)
 _control(app,"town_hear_news","Ask for local news",Rect2(354,461,310,44),{"news":"reports"})
 _control(app,"town_hear_rumour","Ask about old ruins",Rect2(680,461,310,44),{"news":"ruins"})
 _control(app,"town_hear_other","Other rumours",Rect2(1006,461,382,44),{"news":"other"})
 var all: Array = c.news.town_rows(c)
 var trade := all.filter(func(e):return e.report.kind in TRADE_LEADS)
 var other := all.filter(func(e):return e.report.kind not in TRADE_LEADS)
 var rows := _rows(view,trade+other)
 var heading := "Trade leads · none recorded" if trade.is_empty() else "Trade leads" if view.page<trade.size() else "Other reports"
 app.label_at(heading,Vector2(354,533),20,UI.TEXT,true)
 app.label_at("Dated accounts, not price quotes · the Market has live local prices",Vector2(634,533),14,UI.MUTED)
 for i in rows.size():
  var row: Dictionary=rows[i]; var r: Dictionary=row.report
  row_ids.append(str(r.town)+":"+str(r.kind))
  var y:=544+i*64
  var lead: bool=r.kind in TRADE_LEADS
  app.panel(Rect2(354,y,1034,60),UI.SURFACE,UI.LINE)
  app.label_fit(c.news.title(c,r),Vector2(376,y+21),806,18,UI.TEXT,true)
  app.label_at("TRADE LEAD" if lead else "OTHER REPORT",Vector2(1208,y+21),12,UI.GOLD if lead else UI.MUTED)
  var stale: bool=c.news.clock(c)-r.observed>=c.news.OLD_HOURS*60
  app.label_fit("%s · observed day %d · %s%s" % [c.node(r.town).name,r.observed/1440+1,c.news.age(c,r)," · May be outdated" if stale else ""],Vector2(376,y+39),980,14,UI.GOLD)
  var source: String="Local account" if row.carrier=="" else "Caravan %s from %s · arrived day %d" % [c.world.short_id(row.carrier),c.node(row.via).name,1+row.received/1440]
  app.label_fit(source,Vector2(376,y+55),980,13,UI.MUTED)
 if rows.is_empty(): app.label_at("No reports recorded yet. Ask the people of this town.",Vector2(376,579),17,UI.MUTED)
 _footer(app,view)

func action(app, view, id: String) -> bool:
 sync_market(app,view)
 if not commands.has(id):return false
 var data: Dictionary=commands[id]
 if data.has("market_intent"):return _market_action(app,view,id,data)
 if id==TAVERN_ROUND:return _tavern_action(app,view,data) if data.has("round") else false
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
 return false
