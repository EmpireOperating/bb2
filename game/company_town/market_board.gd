extends RefCounted
## Immediate-mode inventory grid and a single passive inspection pane. No commands or pricing here.
const UI = preload("res://ui_polish/style.gd")
const Economy = preload("res://src/economy.gd")
const InventoryArt = preload("res://iron_oath/inventory_art.gd")
const Forge = preload("res://layer_forge/outfitter.gd")
const Offer = preload("res://company_town/equipment_offer.gd")
const ItemText = preload("res://ui_polish/item_hover_text.gd")
const Rarity = preload("res://hollow_campaign/rarity.gd")
const COLS := 8
const CAPACITY := COLS*5
const PANEL := Rect2(990,282,398,508)
const CANCEL := Rect2(1010,728,106,42)
const CONFIRM := Rect2(1128,728,240,42)
const INK := Color("cfc7ac")
const WELL := Color("171b19")
var _trade_icons := {}
var _equipment_icons := {}

func reset() -> void:
 _equipment_icons.clear()

func _trade_icon(kind: String) -> Dictionary:
 if kind not in Economy.TRADE_GOODS:return {}
 if not _trade_icons.has(kind):
  var path := "res://company_town/assets/market/%s.png" % kind
  var source := FileAccess.open(path,FileAccess.READ)
  if source == null or source.get_length() > 1048576:return {}
  var image := Image.new()
  if image.load_png_from_buffer(source.get_buffer(source.get_length())) != OK or image.is_empty():return {}
  if image.get_width() > 512 or image.get_height() > 512:return {}
  image.generate_mipmaps()
  _trade_icons[kind] = {"texture":ImageTexture.create_from_image(image),"path":path}
 return _trade_icons[kind]

func _icon(row: Dictionary, catalog: Dictionary, supplies: Array) -> Dictionary:
 if row.has("good"):
  var index: int = Economy.SUPPLIES.find(row.good)
  if index < 0:return _trade_icon(row.good)
  var texture: Texture2D = supplies[index+1] # TownView's crown + canonical supply order.
  return {"texture":texture,"path":texture.resource_path}
 var item: Dictionary = row.item
 if item.is_empty():return {}
 var definition: String = item.definition
 var d: Dictionary = catalog.get(definition,{})
 # Cache only immutable art identity, never the UID, condition or quoted value.
 var key: String = definition if not item.has("named") else JSON.stringify([definition,item.named],"",true)
 if not _equipment_icons.has(key):
  var icon := Forge.item_icon(definition,d) if Forge.is_piece(definition,d) else InventoryArt.item_icon(item,catalog,null,"")
  if _equipment_icons.size() >= 64:_equipment_icons.erase(_equipment_icons.keys()[0])
  _prepare_thin_art(icon)
  _equipment_icons[key] = icon
 return _equipment_icons[key]

func _prepare_thin_art(icon: Dictionary) -> void:
 # A full-height pike on a large, almost empty canvas can alias to a few
 # specks at 70px. Trim only transparency; filter the same complete painting
 # once and give it the cell diagonal. No substitute asset or saved pixels.
 var source: Texture2D = icon.get("texture")
 if source == null:return
 var image := source.get_image()
 if image == null or image.is_empty() or image.is_compressed():return
 var used := image.get_used_rect()
 if not used.has_area():return
 var major := maxi(used.size.x,used.size.y)
 var minor := mini(used.size.x,used.size.y)
 if major < 8*minor:return
 var thumb := image.get_region(used)
 thumb.clear_mipmaps()
 var size := Vector2i((Vector2(used.size)*(88.0/major)).round()).max(Vector2i.ONE)
 thumb.resize(size.x,size.y,Image.INTERPOLATE_LANCZOS)
 icon["diagonal"] = ImageTexture.create_from_image(thumb)

func slot(index: int) -> Rect2:
 return Rect2(354+(index%COLS)*78,312+(index/COLS)*78,70,70)

func card(app, row: Dictionary, index: int, catalog: Dictionary, supplies: Array, hot: bool, selected: bool, count: int) -> void:
 var rect := slot(index)
 app.button(row.id,"",rect)
 var field := rect.grow(-4)
 app.draw_rect(field,WELL)
 var icon := _icon(row,catalog,supplies)
 var texture: Texture2D = icon.get("diagonal",icon.get("texture"))
 if texture != null:
  var stage := field.grow(-3)
  var fit := texture.get_size()*minf(stage.size.x/texture.get_width(),stage.size.y/texture.get_height())
  if icon.has("diagonal"):
   fit=texture.get_size()*stage.size.x/((texture.get_width()+texture.get_height())*sqrt(0.5))
   app.draw_set_transform(stage.get_center(),PI/4.0 if texture.get_height()>texture.get_width() else -PI/4.0)
   app.draw_texture_rect(texture,Rect2(-fit/2,fit),false)
   app.draw_set_transform(Vector2.ZERO)
  else:
   app.draw_texture_rect(texture,Rect2(stage.get_center()-fit/2,fit),false)
 else:
  app.centered("?",field.get_center()+Vector2(0,7),20,UI.MUTED,true)
 if app is Node:
  app.buttons[row.id]["market_art"] = icon.get("source_path",icon.get("path",""))
 if count >= 0:
  var text := str(count)
  var width: float = app.font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x+10
  app.draw_rect(Rect2(field.end-Vector2(width,20),Vector2(width,20)),Color("131615e8"))
  app.centered(text,field.end-Vector2(width/2,5),13,UI.TEXT if count>0 else UI.MUTED)
 if row.get("commission",false):app.centered("✦",rect.position+Vector2(13,20),15,UI.GOLD)
 if hot or selected:app.draw_rect(rect.grow(-2),UI.GOLD if selected else UI.MUTED,false,2)

func _line(app, text: String, y: float, color: Color = INK, text_size: int = 16) -> float:
 for line in app.wrapped_lines(text,PANEL.size.x-40,text_size,5):
  app.label_at(line,Vector2(PANEL.position.x+20,y),text_size,color)
  y += 21
 return y

func _name(app, name_text: String, caption: String) -> void:
 app.label_fit(name_text,Vector2(1010,362),358,28,UI.TEXT,true)
 _line(app,caption,390,UI.MUTED,14)
 app.draw_line(Vector2(1010,410),Vector2(1368,410),UI.LINE)

func _price(app, verb: String, quote: Dictionary, y: float, neutral: int = -1) -> float:
 var suffix := ""
 var ink := UI.TEXT
 if neutral >= 0 and quote.amount == 1:
  var delta: int = quote.price-neutral
  suffix = " · at neutral" if delta==0 else " · %d %s neutral" % [absi(delta),"below" if delta<0 else "above"]
  if delta != 0:ink = UI.HEALTH if delta<0 else UI.GOLD
 if quote.amount <= 0:return _line(app,verb+" unavailable",y,UI.MUTED)
 y = _line(app,"%s %d · %d crowns%s" % [verb,quote.amount,quote.price,suffix],y,ink)
 if not quote.reason.is_empty():y = _line(app,quote.reason,y,UI.DANGER,14)
 return y

func inspector(app, c, row: Dictionary, detail: Dictionary, mode: String, reviewed: bool, stale: bool) -> void:
 app.draw_rect(PANEL,Color("191f1c"))
 app.draw_rect(PANEL,UI.LINE,false,1)
 _line(app,"REVIEW" if reviewed else "LIVE MARKET QUOTE",321,UI.GOLD,13)
 if row.is_empty():
  _name(app,"Inspect an item","Local stock and company stores")
  _line(app,"Hover or focus an icon for its live quote. Select it to review a trade.",443)
  return
 if row.has("good"):
  var kind: String = row.good
  var neutral: int = Economy.BASE[kind] if kind in Economy.TRADE_GOODS else -1
  _name(app,Economy.NAMES[kind],"Trade goods" if neutral >= 0 else "Company supplies")
  var y := _line(app,"Local stock: %s   ·   Company stores: %d" % [str(detail.stock) if detail.stock>=0 else "available",detail.owned],439)
  if neutral >= 0:y = _line(app,"Neutral: %d crowns per unit" % neutral,y,UI.MUTED,14)
  y = _price(app,"Buy",detail.buy,y+10,neutral)
  y = _price(app,"Sell",detail.sell,y+10,neutral)
  if neutral >= 0:
   var use: String = Economy.Industry.USES[kind]
   if kind == "grain":
    var bread: Dictionary = Economy.Industry.RECIPES.bread
    use = "%d grain makes %d rations at the mill and bakery when its work is funded." % [bread.inputs.grain,bread.outputs.food]
   _line(app,use+" Live quotes may differ from older reports.",y+16,UI.MUTED,14)
  elif kind == "ammo":
   _line(app,"Buying refills carried packs first. Refill need: %d supply (arrows/bolts 1 per round; throwing 3)." % detail.refill,y+16,UI.MUTED,14)
  elif kind == "food":
   _line(app,"Local food stock sets the live ration price. The mill and bakery can add to that stock when it has grain and funds.",y+16,UI.MUTED,14)
 else:
  var item: Dictionary = row.item
  var definition: Dictionary = c.catalog.get(item.get("definition",""),{})
  var info: Dictionary = ItemText.item(item,c.catalog,{},null,{},"Market") if not item.is_empty() else {}
  _name(app,info.get("title",c.catalog.get(row.get("offer",{}).get("definition",""),{}).get("name","Unknown item")), "Opening smith’s commission · one piece" if row.get("commission",false) else Offer.armor_lab_role(definition))
  var y := _line(app,"%s · %d crowns" % ["Buy 1" if mode=="buy" else "Sell 1",detail.quote.price],439,UI.TEXT,17)
  y = _line(app,"Local stock: 1 · Item %s" % item.get("id","unavailable") if mode=="buy" else "Company stores: 1 · Item %s" % row.uid,y,UI.MUTED,14)
  if not detail.quote.reason.is_empty():y = _line(app,detail.quote.reason,y,UI.DANGER,14)
  if not str(info.get("class","")).is_empty():y = _line(app,info["class"],y+9,Rarity.tier_color(info.tier),15)
  for line: String in str(info.get("stats","Effective stats unavailable.")).split("\n"):
   # The stash formatter also reports selected-fighter bolt counts. Here no
   # fighter is selected; retain the physical loaded state, not a loadout claim.
   if line.contains("no bolt case equipped"):line = line.get_slice(" · Bolts",0)
   if y > 674:break
   y = _line(app,line,y,INK,15)
  if mode=="sell" and reviewed:_line(app,"Confirms permanent removal from stores.",694,UI.MUTED,14)
 if stale:_line(app,"Quote changed. Select the item again.",716,UI.DANGER,14)
