extends SceneTree
## Native engine font/layout measurements only, not rendered/native-input acceptance.
const Offers = preload("res://company_town/equipment_offer.gd")
var checks := 0
var failures: Array = []
func _initialize() -> void: call_deferred("run")
func frames() -> void:
 for i in 4: await process_frame
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures.append(message);print("FAIL ",message)
func run() -> void:
 root.size = Vector2i(1440,900);root.content_scale_size = root.size
 var app = load("res://next_build/main.tscn").instantiate();root.add_child(app);await frames()
 app.set_process(false);app.world.set_process(false)
 var w = app.world;var c = app.session.campaign
 w.action("begin");await frames();w.action("town_service_equipment");await frames()
 var before: String = app.session._canonical(c.snapshot())
 var offers: Array = w.town.services.equipment_offers(c)
 for offer: Dictionary in offers:
  for page in offers.size():
   if w.buttons.has("town_pick_"+offer.id):break
   w.action("town_next");await frames()
  var lines := Offers.lines(offer,c.catalog,c.battle.weapons)
  check(lines.size() <= 2 and Array(lines).all(func(line):return w._painted_labels.values().has(line)),"town paints complete shared properties "+offer.id)
  check(w._painted_labels.values().has(Offers.BASE_NOTE),"town visibly distinguishes bases from actual future rolls")
  check(w._painted_labels.values().any(func(text):return "%d crowns" % offer.price in text),"town preserves actual price "+offer.id)
  w.town.page = 0;w.refresh();await frames()
 # Every real catalogue family, including bows/shields/ammo absent from this shelf.
 for definition: String in c.catalog:
  if c.catalog[definition].get("assembly",false):continue
  for line: String in Offers.lines({"definition":definition},c.catalog,c.battle.weapons):
   check(w.font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x <= 988,definition+" town stats fit unchanged 14px minimum without ellipsis")
 w.action("company");await frames()
 var p = app.outfitting
 check(is_instance_valid(p),"mounted production Company route")
 if is_instance_valid(p):
  p.market_button.pressed.emit();await frames()
  check(Offers.BASE_NOTE in p.market_heading.text,"Company visibly distinguishes bases from actual future rolls, not tooltip-only")
  for viewport: Vector2i in [Vector2i(1440,900),Vector2i(1120,800),Vector2i(1672,940),Vector2i(1440,900)]:
   root.size = viewport;root.content_scale_size = viewport;await frames();p._layout();await frames()
   check(p.market_scroll.size.x <= p.market_panel.size.x and p.market_list.size.x <= p.market_scroll.size.x,"market content does not force horizontal expansion "+str(viewport))
   for offer: Dictionary in offers:
    var button: Button = p.market_buttons[offer.id]
    var lines := Offers.lines(offer,c.catalog,c.battle.weapons)
    check(Array(lines).all(func(line):return line in button.text),"Company preserves exact shared properties "+offer.id+str(viewport))
    check("%d crowns" % offer.price in button.text,"Company preserves literal price "+offer.id)
    var style := button.get_theme_stylebox("normal")
    var width := button.size.x-style.get_margin(SIDE_LEFT)-style.get_margin(SIDE_RIGHT)
    var height := button.size.y-style.get_margin(SIDE_TOP)-style.get_margin(SIDE_BOTTOM)
    var font := button.get_theme_font("font")
    var font_size := button.get_theme_font_size("font_size")
    var text_size := font.get_multiline_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,width,font_size)
    check(font_size >= 17 and text_size.y <= height,"complete native-font offer text fits readable card height "+offer.id+str(viewport))
    print("SHOP_LAYOUT ",JSON.stringify({"viewport":str(viewport),"offer":offer.id,"text":button.text,"font_size":font_size,"card":str(button.get_global_rect()),"content":str(Vector2(width,height)),"text_size":str(text_size)}))
   check(p.market_buy_button.get_global_rect().end.y <= viewport.y and p.market_close_button.get_global_rect().end.y <= viewport.y,"fixed Buy/Back remain within market viewport "+str(viewport))
 check(app.session._canonical(c.snapshot()) == before,"all pagination layouts refresh and resize preserve complete campaign")
 app.free();await frames()
 print("SHOP_LAYOUT checks=",checks," failures=",failures.size())
 quit(int(not failures.is_empty()))
