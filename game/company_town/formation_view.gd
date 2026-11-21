extends "res://src/company_formation_view.gd"
## Figure-only adapter. All layout, commands, drag/drop and saving stay inherited.
const Character = preload("res://engraved_people/preview.gd")
const InventoryFigure = preload("res://iron_oath/inventory_figure.gd")
var _portraits: Dictionary = {}
var _painted: Dictionary = {}
var _owner: Array = []
var _catalog: Dictionary = {}
func draw(m) -> void:
 # Strong references for the current living company only. The shared compositor
 # remains bounded at16; keeping up to20 genuine textures here prevents its LRU
 # from thrashing on each Formation frame. Inventory may reconstruct an evicted
 # recipe later: identical pixels/physical signature, not the same resource ID.
 var owner: Array=[m.host.session.get_instance_id(),m.campaign.get_instance_id()]
 if owner != _owner or _catalog != m.campaign.catalog:
  _portraits.clear()
  _owner=owner
  _catalog=m.campaign.catalog.duplicate(true)
 var living: Array=m.campaign.soldiers.filter(func(person):return person.alive).map(func(person):return person.id)
 for sid in _portraits.keys():
  if sid not in living:_portraits.erase(sid)
 _painted.clear()
 super.draw(m)
func painted_cards() -> Dictionary:
 return _painted.duplicate(true)
func _portrait(m, sid: int) -> Dictionary:
 # Snapshot only this person's actual physical owners, including nested assembly
 # parts and carried arms. No preview projection/compositor on unchanged draws.
 var person: Dictionary=m.campaign.soldiers[sid]
 var items:=_owned_items(m.campaign,person)
 var inputs:={"person":person,"items":items}
 if not _portraits.has(sid) or _portraits[sid].inputs != inputs:
  var actor=Character.new()
  actor.configure(m.host.session.preview_unit(sid),m.campaign.catalog)
  var figure=InventoryFigure.new()
  figure.present(actor.preview_texture())
  _portraits[sid]={"inputs":inputs.duplicate(true),"texture":actor.preview_texture(),"source_region":figure.artwork.source_region,"signature":actor.layer_signature(),"diagnostics":actor.render_diagnostics()}
  figure.free();actor.free()
 return _portraits[sid]
func _owned_items(c, person: Dictionary) -> Dictionary:
 var out: Dictionary={}
 for uid: String in person.gear.values():
  if not c.items.has(uid):continue
  out[uid]=c.items[uid]
  for part: String in c.items[uid].get("parts",{}).values():
   if c.items.has(part):out[part]=c.items[part]
 return out
func card(m,key:String,id:int,rect:Rect2,empty_label:String) -> void:
 m.panel(rect,Color("303927") if id==selected and id>=0 else Color("1a251d"),m.GOLD if id==selected and id>=0 else Color("48513b"))
 m.buttons[key]={"rect":rect,"enabled":true}
 if id<0:
  m.centered(empty_label+" · Empty",Vector2(rect.get_center().x,rect.position.y+60),14,m.MUTED);return
 var s=m.campaign.soldiers[id]
 var portrait:=_portrait(m,id)
 # Stay left of Lv/weapon and above name/HP; no hit rectangle or label moves.
 var figure_rect:=Rect2(rect.position+Vector2(5,5),Vector2(55,rect.size.y-48))
 var region: Rect2=portrait.source_region
 var destination:=Rect2()
 if portrait.texture != null and region.has_area():
  var scale_value:=minf(figure_rect.size.x/region.size.x,figure_rect.size.y/region.size.y)
  var extent:=region.size*scale_value
  destination=Rect2(figure_rect.position+(figure_rect.size-extent)/2,extent)
  m.draw_texture_rect_region(portrait.texture,destination,region)
 _painted[key]={"sid":id,"texture":portrait.texture,"source_region":region,"destination":destination,"figure_rect":figure_rect,"card_rect":rect,"signature":portrait.signature,"diagnostics":portrait.diagnostics}
 m.label_at(s.name.left(12),rect.position+Vector2(9,rect.size.y-25),17,m.PAPER,true)
 m.label_at("%d / %d HP"%[s.hp,m.campaign.max_hp(s)],rect.position+Vector2(9,rect.size.y-8),11,m.BLUE if s.wound_days==0 else m.RED)
 m.label_at("Lv %d"%m.Progression.level(s),rect.position+Vector2(66,27),12,m.GOLD)
 m.label_at(m.campaign.item_def(s.gear.weapon).get("weapon","").left(10),rect.position+Vector2(66,46),10,m.MUTED)
