extends "res://hollow_campaign/ui_inspection.gd"
## Passive inventory composition only: no campaign/session or mutation controller.
const Figure = preload("res://iron_oath/inventory_figure.gd")
const Card = preload("res://iron_oath/inventory_card.gd")
const Art = preload("res://iron_oath/inventory_art.gd")
const InventorySkin = preload("res://iron_oath/skin.gd")
static var icon_equipment = Equipment.new()
var inventory_cards := {}
var carry_cards := {}
var carried_grid: GridContainer
var item_notes: Label
var selected_item_slot := ""
var _item_origin: Button
func _ready() -> void:
 super._ready()
 var old:=preview;var holder:=old.get_parent()
 holder.remove_child(old);old.free();preview=Figure.new();holder.add_child(preview)
 var grid:GridContainer=summary_labels.body.get_parent().get_parent().get_parent()
 for child in grid.get_children():grid.remove_child(child);child.free()
 summary_labels.clear()
 for slot:String in Equipment.SLOTS:
  var card:=Card.new();card.custom_minimum_size=Vector2(210,100);grid.add_child(card)
  # Passive selection only; no outfitting or equipment command controller.
  card.pressed.connect(_inspect_item.bind(slot,card))
  inventory_cards[slot]=card;summary_labels[slot]=card.caption
 carried_grid=GridContainer.new();carried_grid.columns=2;carried_grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 carried_grid.add_theme_constant_override("h_separation",10);carried_grid.add_theme_constant_override("v_separation",10)
 carried_label.get_parent().add_child(carried_grid)
 sheet.add_theme_stylebox_override("panel",InventorySkin.panel())
 portrait.add_theme_stylebox_override("panel",InventorySkin.panel(8))
 # The inherited Details trigger is added after its overlay; keep Close on top.
 sheet.move_child(details_panel,sheet.get_child_count()-1)
 item_notes=label(17,UI.TEXT);item_notes.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 person_notes.get_parent().add_child(item_notes);item_notes.hide()
 details.follow_focus=true
 _layout()
func _item_mode(enabled: bool) -> void:
 item_notes.visible=enabled
 for note in [person_notes,carried_notes,art_note]+slot_labels.values():note.visible=not enabled
func _inspect_item(slot: String, card: Button) -> void:
 if not is_visible_in_tree() or details_panel.visible or card.get_meta("physical_item",{}).is_empty():return
 selected_item_slot=slot;_item_origin=card;item_notes.text=card.get_meta("inspection_text","")
 _item_mode(true)
 super._open_details()
func _reset_item_selection() -> void:
 _item_origin=null;selected_item_slot=""
 if is_instance_valid(item_notes):item_notes.text="";_item_mode(false)
func _visibility_changed() -> void:
 if not visible:_reset_item_selection()
 super._visibility_changed()
func _open_details() -> void:
 _reset_item_selection()
 super._open_details()
func _close_details() -> void:
 var origin:=_item_origin
 _reset_item_selection()
 super._close_details()
 if is_instance_valid(origin) and origin.is_visible_in_tree():origin.grab_focus()
static func detached_unit(unit:Dictionary, catalog:Dictionary) -> Dictionary:
 var copy:=unit.duplicate(true)
 # Finalized slots win. Fallback never calls Battle's effect-refreshing projection.
 if copy.get("equipment_slots",{}).is_empty():
  var projected:Dictionary={};var priorities:Dictionary={}
  for part:Dictionary in copy.get("armor_parts",[]):
   var slot:String=part.get("hollow_slot",part.get("group",""))
   if slot not in Equipment.SLOTS:continue
   var priority:int={"outer":6,"mail":5,"base":4,"shell":6,"padding":4}.get(part.get("layer",""),0)
   if priorities.get(slot,-1)>=priority:continue
   priorities[slot]=priority
   var item:=part.duplicate(true);item["id"]=part.get("id",part.get("item",""));projected[slot]=item
  for source:String in ["weapon","shield","ammo"]:
   var item:Dictionary=copy.get("arms",{}).get(source,{})
   if not item.is_empty():projected[{"weapon":"mainhand","shield":"offhand"}.get(source,source)]=item.duplicate(true)
  copy["equipment_slots"]=projected
 return copy
func _card(card, slot:String, item:Dictionary, catalog:Dictionary, actor) -> void:
 var tier:=Equipment.item_tier(item,catalog)
 var d:Dictionary=Named.definition(item,catalog) if not item.is_empty() and tier!="invalid" else {}
 var icon:Dictionary=Art.item_icon(item,catalog)
 var maximum:int=int(item.get("maximum",d.get("durability",0))) if tier!="invalid" else 0
 var condition:int=int(item.get("condition",maximum))
 var identity:String=("Rounds" if Equipment.is_round_supply(d) else "Condition")+" %d/%d"%[condition,maximum] if maximum>0 else "No durability" if not item.is_empty() else "Empty"
 var classification:="Named craftsmanship" if tier=="named" else "Invalid metadata" if tier=="invalid" else tier.capitalize() if not tier.is_empty() else "Unrated"
 card.present(slot.capitalize()+" · "+str(d.get("name","Invalid equipment" if tier=="invalid" else "Empty")),classification+"\n"+identity if not item.is_empty() else identity,icon.get("texture"),str(item.get("id",item.get("item",""))),tier,condition,maximum)
 card.custom_minimum_size.y=100
 card.caption.max_lines_visible=2;card.caption.custom_minimum_size.y=36
 card.tooltip_text=Equipment.item_details(item,catalog)
 card.set_meta("physical_item",item.duplicate(true));card.set_meta("icon_source",icon)
 card.disabled=item.is_empty()
 card.focus_mode=Control.FOCUS_NONE if item.is_empty() else Control.FOCUS_ALL
 card.mouse_filter=Control.MOUSE_FILTER_IGNORE if item.is_empty() else Control.MOUSE_FILTER_STOP
 card.set_meta("inspection_text",Presentation.summary(item,catalog)+"\n\n"+Equipment.item_details(item,catalog))
func present(unit:Dictionary, catalog:Dictionary, actor, battle) -> void:
 _reset_item_selection()
 var detached:=detached_unit(unit,catalog)
 super.present(detached,catalog,actor,battle)
 # Parent assigns TextureRect.texture directly; initialize the figure painter too.
 preview.texture=null;preview.present(actor.preview_texture())
 identity_label.text=("ENEMY" if unit.side!=0 else "YOUR COMPANY")+" · READ-ONLY · BATTLE PAUSED"
 stats_label.text+="\nMorale %d · Resolve %d"%[unit.get("morale",0),unit.get("resolve",0)]
 for slot:String in inventory_cards:_card(inventory_cards[slot],slot,slots.get(slot,{}),catalog,actor)
 for child in carried_grid.get_children():carried_grid.remove_child(child);child.free()
 carry_cards.clear()
 for slot:String in Arsenal.bag_slots(detached):
  var card:=Card.new();card.custom_minimum_size=Vector2(210,100)
  card.pressed.connect(_inspect_item.bind(slot,card))
  carried_grid.add_child(card);carry_cards[slot]=card
  _card(card,slot,detached.get("arms",{}).get(slot,{}),catalog,actor)
 var layers:=PackedStringArray()
 for part:Dictionary in unit.get("armor_parts",[]):layers.append(Equipment.item_details(part,catalog))
 if not layers.is_empty():carried_notes.text+="\n\nALL PHYSICAL ARMOR LAYERS\n"+"\n\n".join(layers)
 hint.text="Read-only combat equipment. Pictured gear is not recovered; encounter loot is independent." if unit.side!=0 else "Read-only · Battle paused. Change equipment after returning to camp."
 if unit.has("human_kit_identity"):hint.text="Read-only · This fighter’s current gear. Broken armor cannot be salvaged."
 load("res://crossbows/ui.gd").present_inspector(self,unit,catalog,battle)
func observation() -> Dictionary:
 var out:=super.observation()
 out["selected_item_slot"]=selected_item_slot if visible and details_panel.visible else ""
 out["selected_item_text"]=item_notes.text if visible and details_panel.visible else ""
 out["inventory_like"]=true;out["read_only"]=true;out["commands"]=[]
 if not visible:
  out["cards"]={};out["summary_cards"]={};out["details_text"]=""
 return out
