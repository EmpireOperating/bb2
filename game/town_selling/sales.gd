extends RefCounted
## Town-only presentation/command adapter. Campaign owns all valuation and sales.
const UI = preload("res://ui_polish/style.gd")
const InventoryArt = preload("res://iron_oath/inventory_art.gd")
const Equipment = preload("res://hollow_campaign/appearance.gd")
var mode := "buy"
var pending := {}
var commands := {}
var _paint := {}
func retire() -> void:
 pending={};commands.clear();_paint.clear()
func reset() -> void:
 mode="buy";retire()
func _available(app, view) -> bool:
 return app.is_visible_in_tree() and app.can_process() and not app.blocked() and app.host!=null and app.host.world==app and app.host.session.campaign==app.campaign and app.world_view and app.town_is_open() and app._clear_surface() and app._surface()=="town" and view.section=="equipment"
func _paint_current(app, view) -> bool:
 return not _paint.is_empty() and _available(app,view) and _paint.campaign==app.campaign and _paint.site==view.site and _paint.mode==mode and _paint.page==view.page
func _capture(c, view, uid: String) -> Dictionary:
 return {"uid":uid,"campaign":c,"site":view.site,"market":c.market_key(),"cash":c.market().cash,"record_ref":c.items[uid],"record":c.items[uid].duplicate(true),"quote":c.sale_quote(uid).duplicate(true),"name":c.item_name(uid)}
func _current(app, view, token: Dictionary) -> bool:
 if token.is_empty() or not _paint_current(app,view) or mode!="sell":return false
 var c=app.campaign;var uid: String=token.uid
 if token.campaign!=c or token.site!=view.site or token.market!=c.market_key() or token.cash!=c.market().get("cash",-1):return false
 if not c.items.has(uid) or not is_same(c.items[uid],token.record_ref) or c.items[uid]!=token.record or uid not in rows(c):return false
 var q: Dictionary=c.sale_quote(uid)
 return q.reason.is_empty() and q==token.quote
func sync(app, view) -> void:
 if (not _paint.is_empty() and not _paint_current(app,view)) or (not pending.is_empty() and not _current(app,view,pending)):
  retire();app.refresh() # Refusal refreshes presentation only; never emits changed.


func handles(id: String) -> bool:
 return id.begins_with("town_equipment_") or id.begins_with("town_sell_review_") or id.begins_with("town_sell_confirm_") or id in ["town_sell_confirm","town_sell_cancel"]
func control(app, id: String, title: String, rect: Rect2, data: Dictionary, enabled := true) -> void:
 app.button(id,title,rect,enabled)
 if app.buttons.get(id,{}).get("enabled",false):
  commands[id]=data.duplicate()
  commands[id].control=app.buttons[id]
func tabs(app, view) -> void:
 sync(app,view);commands.clear()
 _paint={"campaign":app.campaign,"site":view.site,"mode":mode,"page":view.page}
 control(app,"town_equipment_buy","Buy",Rect2(850,217,144,44),{"mode":"buy"})
 control(app,"town_equipment_sell","Sell",Rect2(1006,217,144,44),{"mode":"sell"})
 # Restrained brass underline keeps the active mode legible with painted skins.
 app.draw_rect(Rect2(862 if mode=="buy" else 1018,254,120,2),UI.GOLD)
func rows(c) -> Array:
 return c.sale_items().filter(func(uid):return not c.item_def(uid).get("assembly",false))
func draw(app, view, services) -> void:
 var c=app.campaign
 app.label_fit("Unequipped stores only · Merchant purse: %d crowns" % c.market().get("cash",0),Vector2(354,277),1034,14,UI.MUTED)
 var visible_rows: Array=services._rows(view,rows(c))
 for i in visible_rows.size():
  var uid: String=visible_rows[i];services.row_ids.append(uid)
  var item: Dictionary=c.items[uid];var d: Dictionary=c.item_def(uid);var q: Dictionary=c.sale_quote(uid)
  var y:=294+i*128
  app.panel(Rect2(354,y,1034,114),UI.SURFACE,UI.GOLD if pending.get("uid","")==uid else UI.LINE)
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
  app.label_fit(c.item_name(uid),Vector2(476,y+28),670,23,UI.TEXT,true)
  var tier: String=Equipment.item_tier(item,c.catalog)
  var condition: String="Condition %d / %d" % [item.condition,d.get("durability",0)] if d.get("durability",0)>0 else "Condition not tracked"
  app.label_fit("%s%s · %s · Offer %d crowns" % [str(d.get("slot","equipment")).capitalize()," · "+tier.capitalize() if not tier.is_empty() else "",condition,q.price],Vector2(476,y+53),670,16,UI.GOLD)
  app.label_fit(q.reason if not q.reason.is_empty() else "Review the exact item and quote before confirming. Fitting stays in Company.",Vector2(476,y+81),888,14,UI.MUTED)
  app.label_fit("Item "+uid,Vector2(476,y+103),888,12,UI.MUTED)
  if pending.get("uid","")==uid:
   # UID-specific confirmation cannot fall through to the next row after removal.
   control(app,"town_sell_confirm_"+uid,"Confirm sale · %dc" % pending.quote.price,Rect2(1174,y+10,196,46),{"confirm":pending})
  else:
   control(app,"town_sell_review_"+uid,"Review sale",Rect2(1174,y+10,196,46),{"review":_capture(c,view,uid)},q.reason.is_empty() and pending.is_empty())
 if visible_rows.is_empty():
  app.label_at("No loose equipment in company stores.",Vector2(376,337),21,UI.TEXT,true)
  app.label_fit("Unequip unwanted gear in Company first. Worn gear, carried reserves and intact armour assemblies are not listed.",Vector2(376,376),988,16,UI.MUTED)
 if pending.is_empty():
  app.label_fit("Select Review sale. Nothing is sold until you confirm.",Vector2(354,707),690,15,UI.MUTED)
 else:
  app.label_fit("Sell %s · %d crowns?" % [c.item_name(pending.uid),pending.quote.price],Vector2(354,699),530,18,UI.GOLD,true)
  app.label_fit("Item %s · Removed permanently from company stores" % pending.uid,Vector2(354,725),530,13,UI.MUTED)
  control(app,"town_sell_cancel","Cancel",Rect2(902,680,160,46),{"cancel":true})

 services._footer(app,view)
func action(app, view, id: String) -> bool:
 sync(app,view)
 if not commands.has(id) or not _paint_current(app,view) or not app.buttons.get(id,{}).get("enabled",false):return false
 var data: Dictionary=commands[id]
 if not is_same(app.buttons[id],data.control) or not app.buttons[id].rect.has_area():return false
 commands.clear();view.services.commands.clear()
 if data.has("mode"):
  mode=data.mode;pending.clear();view.page=0;app.refresh();return true
 if data.has("cancel"):
  pending.clear();app.refresh();return true
 var c=app.campaign
 if data.has("review"):
  if _current(app,view,data.review):pending=data.review
  else:app.tell("The item or quote changed. Review the current offer.")
  app.refresh();return true
 if data.has("confirm") and not pending.is_empty():
  if not is_same(data.confirm,pending):return false
  var sale: Dictionary=pending
  var current:=_current(app,view,sale)
  retire() # Consume before domain callbacks and the canonical checkpoint writer.
  if not current:return false
  if c.sell_item(sale.uid,sale.quote.price):
   app.tell("Sold %s for %d crowns · %d crowns remain in the merchant's purse." % [sale.name,sale.quote.price,c.market().cash])
   if app.host!=null:app.host.session.changed.emit()
  else:app.tell("Sale refused. Review the current item and merchant quote.")
  app.refresh();return true
 return false
