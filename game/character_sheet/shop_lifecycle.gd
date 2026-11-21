extends SceneTree
## Genuine private purchases through both mounted routes, real autosave and cold reader.
## Signal/callback invocation is headless integration, not native input acceptance.
const Offers = preload("res://company_town/equipment_offer.gd")
const Inventory = preload("res://hollow_inventory/appearance.gd")
var checks := 0
var failures: Array = []
func _initialize() -> void: call_deferred("run")
func frames() -> void:
 for i in 4: await process_frame
func check(ok: bool, message: String) -> bool:
 checks += 1
 print("PASS " if ok else "FAIL ",message)
 if not ok: failures.append(message)
 return ok
func finish(app) -> void:
 app.free();await frames()
 print("SHOP_LIFECYCLE checks=",checks," failures=",failures.size())
 quit(int(not failures.is_empty()))
func expose(w, id: String) -> void:
 w.town.page = 0;w.refresh();await frames()
 for page in w.town.services.row_count:
  if w.buttons.has("town_pick_"+id): return
  w.action("town_next");await frames()
func run() -> void:
 root.size = Vector2i(1440,900);root.content_scale_size = root.size
 var app = load("res://next_build/main.tscn").instantiate();root.add_child(app);await frames()
 app.set_process(false);app.world.set_process(false)
 if not check(app.saved_ok and not app.error_panel.visible,"packaged Next Build real checkpoint startup"):await finish(app);return
 var s = app.session;var c = s.campaign;var w = app.world
 if "--reader" in OS.get_cmdline_user_args():
  var oracle: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://shop-lifecycle-oracle.json"))
  check(oracle.pid != OS.get_process_id(),"distinct-process cold reader")
  check(s._canonical(c.snapshot()) == oracle.snapshot,"whole two-route purchased campaign cold equality")
  check(FileAccess.get_file_as_string(app.checkpoint_path) == oracle.checkpoint,"exact real checkpoint bytes retained cold")
  for row: Dictionary in oracle.purchases:
   check(c.items[row.uid] == c.battle.normalize_json_numbers(row.record) and c.owner(row.uid) == -1,"exact owned rolled item remains unassigned cold "+row.uid)
   check(c.purchased_gear.has(row.offer.id),"finite offer consumption persists cold "+row.offer.id)
   var before: String = s._canonical(c.snapshot())
   var refused: String = c.buy_component(row.offer.id) if row.offer.kind == "component" else c.buy_weapon(row.offer.id)
   check(refused.is_empty() and s._canonical(c.snapshot()) == before,"cold sold-out authority cannot buy twice")
  w.action("begin");await frames();w.action("company");await frames()
  var p = app.outfitting;p.market_button.pressed.emit();await frames()
  check(oracle.purchases.all(func(row):return not p.market_buttons.has(row.offer.id)),"cold Company omits genuinely sold offers")
  await finish(app);return
 w.action("begin");await frames();w.action("town_service_equipment");await frames()
 var offers: Array = w.town.services.equipment_offers(c)
 var affordable: Array = offers.filter(func(o):return c.catalog[o.definition].slot == "weapon" and o.price <= c.crowns)
 if not check(not affordable.is_empty(),"actual affordable town weapon without grants"):await finish(app);return
 var offer: Dictionary = affordable[0]
 await expose(w,offer.id)
 var before: String = s._canonical(c.snapshot())
 var base := Offers.lines(offer,c.catalog,c.battle.weapons)
 for i in 3:w.action("town_pick_"+offer.id);await frames()
 check(s._canonical(c.snapshot()) == before,"repeated town selection preserves full snapshot including RNG stock items and gear")
 var ids: Array = c.items.keys();var crowns: int = c.crowns;var people: String = s._canonical(c.soldiers)
 w.action("town_purchase")
 var added: Array = c.items.keys().filter(func(uid):return uid not in ids)
 if not check(added.size() == 1,"town Buy creates exactly one real physical item"):await finish(app);return
 var uid: String = added[0]
 check(c.crowns == crowns-offer.price and offer.id in c.purchased_gear,"town Buy pays exact admitted quote once")
 check(c.owner(uid) == -1 and c.parent_kit(uid).is_empty() and s._canonical(c.soldiers) == people,"town purchase never equips or changes soldiers")
 check(c.Named.valid(c.items[uid],c.catalog) and c.items[uid].has("instance_roll"),"roll exists only on genuinely allocated owned UID")
 check(Offers.lines(offer,c.catalog,c.battle.weapons) == base,"catalogue offer remains base not postpurchase randomized stats")
 var purchases := [{"offer":offer,"uid":uid,"record":c.items[uid].duplicate(true)}]
 print("SHOP_PURCHASE ",JSON.stringify({"route":"town","offer":offer,"uid":uid,"crowns_before":crowns,"crowns_after":c.crowns,"record":c.items[uid],"base":base,"owned_details":Inventory.item_details(c.items[uid],c.catalog)}))
 before = s._canonical(c.snapshot());w.action("town_purchase")
 check(s._canonical(c.snapshot()) == before,"town same-frame duplicate callback is inert")
 await frames();check(app.saved_ok and not app.error_panel.visible,"town actual autosave succeeds")
 check(not w.buttons.town_purchase.enabled and w._painted_labels.values().any(func(text):return "Sold out" in text),"town sold-out selected card remains visible and Buy disabled")
 w.action("town_purchase");check(s._canonical(c.snapshot()) == before,"town sold-out callback after refresh is inert")
 w.action("company");await frames()
 var p = app.outfitting
 if not check(is_instance_valid(p),"ordinary Company route mounts after genuine town purchase"):await finish(app);return
 p.market_button.pressed.emit();await frames()
 affordable = p._market_offers().filter(func(o):return o.kind == "component" and o.price <= c.crowns)
 if not check(not affordable.is_empty(),"actual affordable Company armor component without grants"):await finish(app);return
 offer = affordable[0];before = s._canonical(c.snapshot());base = Offers.lines(offer,c.catalog,c.battle.weapons)
 for i in 3:p.market_buttons[offer.id].pressed.emit();await frames()
 check(s._canonical(c.snapshot()) == before,"repeated Company inspection preserves entire snapshot")
 ids = c.items.keys();crowns = c.crowns;people = s._canonical(c.soldiers)
 p.market_buy_button.pressed.emit()
 added = c.items.keys().filter(func(id):return id not in ids)
 if not check(added.size() == 1,"Company Buy creates exactly one real component"):await finish(app);return
 uid = added[0]
 check(c.crowns == crowns-offer.price and offer.id in c.purchased_gear,"Company Buy pays exact real quote once")
 check(c.owner(uid) == -1 and c.parent_kit(uid).is_empty() and s._canonical(c.soldiers) == people,"Company purchase stays loose in stash, never auto-fits")
 check(c.Named.valid(c.items[uid],c.catalog) and Offers.lines(offer,c.catalog,c.battle.weapons) == base,"owned component has valid actual roll; card still labelled catalogue base")
 purchases.append({"offer":offer,"uid":uid,"record":c.items[uid].duplicate(true)})
 print("SHOP_PURCHASE ",JSON.stringify({"route":"Company","offer":offer,"uid":uid,"crowns_before":crowns,"crowns_after":c.crowns,"record":c.items[uid],"base":base,"owned_details":Inventory.item_details(c.items[uid],c.catalog)}))
 before = s._canonical(c.snapshot());p._buy_market();await frames()
 check(s._canonical(c.snapshot()) == before and p.market_buy_button.disabled and "Sold out" in p.market_buttons[offer.id].text,"Company sold-out duplicate refuses without mutation")
 check(app.saved_ok and not app.error_panel.visible,"Company actual autosave succeeds")
 p.market_close_button.pressed.emit();await frames();p.market_button.pressed.emit();await frames()
 check(s._canonical(c.snapshot()) == before,"warm close/reopen never rerolls or mutates paid stock")
 var file := FileAccess.open("user://shop-lifecycle-oracle.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"pid":OS.get_process_id(),"snapshot":before,"checkpoint":FileAccess.get_file_as_string(app.checkpoint_path),"purchases":purchases}));file.close()
 check(not FileAccess.get_file_as_string(app.checkpoint_path).is_empty(),"writer retains actual filesystem checkpoint for immediate cold reader")
 await finish(app)
