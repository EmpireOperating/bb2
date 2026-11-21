extends RefCounted
## Only show physical manifests entrusted to the company. No entry in the lot list means no desk.
const PAGE_SIZE := 4
var page := 0
var commands := {}
var owner
var site := ""
func clear() -> void:
 commands.clear();owner=null;site="";page=0
func draw(app,c,town:String,lots:Array) -> void:
 commands.clear()
 if c!=owner or site!=town:page=0
 owner=c;site=town
 if lots.is_empty():page=0;return
 page=clampi(page,0,(lots.size()-1)/PAGE_SIZE)
 app.panel(Rect2(332,248,1040,432),Color("252823"))
 app.label_at("THE RECEIVING YARD",Vector2(360,286),20,app.GOLD,true)
 app.label_fit("The wagon marks name the buyer. Return their goods here, or seek another market.",Vector2(360,322),940,17,app.PAPER)
 var start:int=page*PAGE_SIZE
 for n in range(start,mini(start+PAGE_SIZE,lots.size())):
  var lot:Dictionary=lots[n];var y:=349+65*(n-start);var mine:bool=town==lot.destination
  app.label_fit(lot.description,Vector2(360,y+18),558,18,app.PAPER,true)
  app.label_fit("Consigned to "+str(c.node(lot.destination).name),Vector2(360,y+40),558,14,app.MUTED)
  var verb:="return" if mine else "sell";var id:="town_manifest_"+verb+":"+str(lot.id)
  var signed:=bool(lot.get("signed",false));var funded:=int(lot.get("sale_crowns",-1))
  var admitted:=mine or (not signed and funded!=0)
  var text:="Return to the buyer" if mine else "Reserved for the buyer" if signed else "No local buyer" if funded==0 else "Sell here · %dc"%funded if funded>0 else "Sell to this market"
  app.button(id,text,Rect2(960,y,380,47),admitted,mine)
  if admitted:commands[id]={"id":lot.id,"action":verb,"quote":lot.duplicate(true)}
 if page>0:app.button("town_manifest_prev","Previous",Rect2(978,624,156,38))
 if start+PAGE_SIZE<lots.size():app.button("town_manifest_next","More lots",Rect2(1160,624,156,38))
func dispatch(app,id:String) -> void:
 var c=app.campaign
 if owner!=c or not app.is_visible_in_tree() or not app.can_process() or app.blocked() or app.host==null or app.host.world!=app or app.host.session.campaign!=c:return
 if c.phase!="camp" or c.over() or app._surface()!="town" or not app._clear_surface() or not app.town_is_open() or app.town.section!="home" or app._town_location()!=site or app.town.site!=site:return
 if not app.buttons.get(id,{}).get("enabled",false):return
 if id=="town_manifest_next" or id=="town_manifest_prev":page+=1 if id.ends_with("next") else -1;app.refresh();return
 if not commands.has(id):return
 var row:Dictionary=commands[id];commands.erase(id)
 var f=c.economy.freight
 if not f.held_manifests(c).has(row.quote):app.tell("The buyer or the consignment has changed.");app.refresh();return
 if f.settle_manifest(c,row.id,row.action):
  app.tell("Consignment returned to its buyer." if row.action=="return" else "The local merchant has bought the consignment.");app.host.session.changed.emit()
 else:app.tell("This market cannot receive that consignment now.")
 app.refresh()
