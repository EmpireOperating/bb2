extends "res://character_sheet/shop_lifecycle.gd"
## All state fixtures are private. Altered quotes/zero money/modal flags are explicit
## synthetic negatives; actual stock consumption and physical departure use domain APIs.
func run() -> void:
 root.size = Vector2i(1440,900);root.content_scale_size = root.size
 var app = load("res://next_build/main.tscn").instantiate();root.add_child(app);await frames()
 app.set_process(false);app.world.set_process(false)
 var s = app.session;var c = s.campaign;var w = app.world
 w.action("begin");await frames();w.action("town_service_equipment");await frames()
 var offers: Array = w.town.services.equipment_offers(c).filter(func(o):return o.price <= c.crowns)
 if not check(not offers.is_empty(),"real affordable shelf for refusal captures"):await finish(app);return
 var offer: Dictionary = offers[0]
 await expose(w,offer.id);w.action("town_pick_"+offer.id);await frames()
 var before: String = s._canonical(c.snapshot())
 # Synthetic corrupted captured quote, not an economy/catalogue edit.
 w.town.services.commands.town_purchase.offer.price += 1
 w.action("town_purchase")
 check(s._canonical(c.snapshot()) == before and "no longer available" in w.notice,"town stale-price capture refuses without mutation")
 w.action("town_purchase");check(s._canonical(c.snapshot()) == before,"refused quote is consumed once before duplicate callback")
 await frames();w.action("town_pick_"+offer.id);await frames()
 # A separate genuine authority purchase consumes the displayed capture first.
 var uid: String = c.buy_component(offer.id) if offer.kind == "component" else c.buy_weapon(offer.id)
 check(not uid.is_empty(),"real authority consumes exact offer while town capture is pending")
 before = s._canonical(c.snapshot());w.action("town_purchase")
 check(s._canonical(c.snapshot()) == before and "no longer available" in w.notice,"town stale sold-offer capture cannot buy another unit")
 s.changed.emit();await frames()
 check(app.saved_ok and not app.error_panel.visible,"real private direct-authority stock consumption checkpoints normally")
 offers = w.town.services.equipment_offers(c)
 if not check(not offers.is_empty(),"remaining actual stock for money refusal"):await finish(app);return
 offer = offers[0];await expose(w,offer.id)
 var money: int = c.crowns;c.crowns = 0 # Explicit private synthetic no-money fixture.
 before = s._canonical(c.snapshot());w.action("town_pick_"+offer.id);await frames()
 check(s._canonical(c.snapshot()) == before and not w.buttons.town_purchase.enabled,"zero-money town inspection remains read-only and visibly refuses Buy")
 w.action("town_purchase");check(s._canonical(c.snapshot()) == before,"town unaffordable Buy changes nothing")
 c.crowns = money;w.refresh();await frames();w.action("company");await frames()
 var p = app.outfitting;p.market_button.pressed.emit();await frames()
 offers = p._market_offers().filter(func(o):return o.price <= c.crowns)
 if not check(not offers.is_empty(),"remaining affordable Company stock"):await finish(app);return
 offer = offers[0];p.market_buttons[offer.id].pressed.emit();await frames()
 c.crowns = 0;before = s._canonical(c.snapshot());p._refresh_market();p._buy_market()
 check(s._canonical(c.snapshot()) == before and p.market_buy_button.disabled and "Not enough crowns" in p.market_reason_label.text,"Company no-money callback visibly refuses with whole snapshot unchanged")
 c.crowns = money;p._refresh_market();before = s._canonical(c.snapshot())
 w.help = true;p._buy_market()
 check(s._canonical(c.snapshot()) == before and "modal" in p._market_buy_reason(),"existing competing-modal admission refuses Company purchase")
 w.help = false;app._show_error("Private synthetic overlay refusal");p._buy_market()
 check(s._canonical(c.snapshot()) == before and "overlay" in p._market_buy_reason(),"existing error-overlay admission refuses Company purchase")
 app.error_panel.hide();p._refresh_market()
 uid = c.buy_component(offer.id) if offer.kind == "component" else c.buy_weapon(offer.id)
 check(not uid.is_empty(),"real authority consumes selected Company stock externally")
 before = s._canonical(c.snapshot());p._buy_market()
 check(s._canonical(c.snapshot()) == before and "Sold out" in p.market_reason_label.text,"Company stale sold selection cannot buy another physical unit")
 s.changed.emit();await frames()
 p.market_close_button.pressed.emit();await frames();p.back_button.pressed.emit();await frames()
 check(c.begin_travel(c.overworld.places.ford,"ford"),"ordinary private campaign travel starts, no teleport")
 for tick in 80:
  if not c.in_town():break
  c.tick_overworld(0.25)
 check(not c.in_town(),"actual movement physically leaves town")
 w.rebind(c);w.action("company");await frames();p = app.outfitting
 if not check(is_instance_valid(p),"Company still reachable outdoors"):await finish(app);return
 before = s._canonical(c.snapshot());p._open_market();p._buy_market()
 check(s._canonical(c.snapshot()) == before and not p.market_panel.visible and p.market_button.disabled,"outdoors Company shop callbacks refuse without mutation")
 # Synthetic display-only missing definition and empty view; never admitted as stock.
 p.market_panel.show();p._market_seen.clear();p._refresh_market()
 check(p.market_buttons.is_empty() and s._canonical(c.snapshot()) == before,"empty unavailable market is safe and read-only")
 p._market_seen["missing"] = {"id":"missing","definition":"missing","price":0,"kind":"weapon"};p._refresh_market()
 check("Properties unavailable." in p.market_buttons.missing.text and s._canonical(c.snapshot()) == before,"missing-definition seen card is safe, unavailable and read-only")
 print("SHOP_REFUSALS private altered quote / zero-money / modal flags explicitly synthetic; stock consumption and departure real")
 await finish(app)
