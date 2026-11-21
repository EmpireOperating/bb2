extends SceneTree
## Real packaged Next Build host and retained read-only offer routes; no GUI input.
var checks := 0
var failures: Array = []
func _initialize() -> void: call_deferred("run")
func frames() -> void:
 for i in 4: await process_frame
func check(ok: bool, message: String) -> void:
 checks += 1
 print("PASS " if ok else "FAIL ",message)
 if not ok: failures.append(message)
func run() -> void:
 root.size = Vector2i(1440,900);root.content_scale_size = root.size
 var app = load("res://next_build/main.tscn").instantiate()
 root.add_child(app);await frames();app.set_process(false);app.world.set_process(false)
 check(app.saved_ok and not app.error_panel.visible,"packaged current host starts with real checkpoint I/O")
 var w = app.world;var c = app.session.campaign
 w.action("begin");await frames();w.action("town_service_equipment");await frames()
 var offers: Array = w.town.services.equipment_offers(c)
 var weapons: Array = offers.filter(func(o):return c.catalog[o.definition].get("slot") == "weapon")
 check(not weapons.is_empty(),"real current finite shelf contains a weapon")
 if not weapons.is_empty():
  var offer: Dictionary = weapons[0]
  var profile: Dictionary = c.battle.weapons[c.catalog[offer.definition].weapon]
  var damage := "Base damage %d–%d" % [profile.min,profile.max]
  var before: String = app.session._canonical(c.snapshot())
  for page in offers.size():
   if w.buttons.has("town_pick_"+offer.id): break
   w.action("town_next");await frames()
  check(w.buttons.has("town_pick_"+offer.id),"real weapon reachable through town pagination")
  check(w._painted_labels.values().any(func(text):return damage in text),"town real-schema weapon min–max properties are actually painted")
  w.action("town_pick_"+offer.id);await frames();w.action("town_pick_"+offer.id);await frames()
  check(app.session._canonical(c.snapshot()) == before,"repeated town inspection does not buy equip or reroll")
  w.action("company");await frames()
  var panel = app.outfitting
  check(is_instance_valid(panel),"ordinary town Company route mounts production inventory")
  if is_instance_valid(panel):
   panel.market_button.pressed.emit();await frames()
   check(panel.market_panel.visible and panel.market_buttons.has(offer.id),"Company market exposes same exact real shelf offer")
   if panel.market_buttons.has(offer.id):
    check(damage in panel.market_buttons[offer.id].text,"Company real-schema weapon min–max properties are visible on offer card")
    panel.market_buttons[offer.id].pressed.emit();await frames()
    panel.market_buttons[offer.id].pressed.emit();await frames()
   check(app.session._canonical(c.snapshot()) == before,"Company open refresh repeated inspection does not buy equip or reroll")
   print("SHOP_OFFER ",JSON.stringify({"offer":offer,"equipment":c.catalog[offer.definition],"profile":profile,"text":panel.market_buttons[offer.id].text}))
 app.free();await frames()
 print("SHOP_PRESENTATION checks=",checks," failures=",failures.size())
 quit(int(not failures.is_empty()))
