extends RefCounted
## Small atlas strokes; authoritative positions and click rectangles remain unchanged.
static func marker_paths(kind: String) -> Array:
 match kind:
  "town":return [PackedVector2Array([Vector2(-7,6),Vector2(-7,-6),Vector2(-3,-6),Vector2(-3,-2),Vector2(3,-2),Vector2(3,-6),Vector2(7,-6),Vector2(7,6),Vector2(-7,6)])]
  "camp":return [PackedVector2Array([Vector2(-8,6),Vector2(0,-8),Vector2(8,6),Vector2(2,6),Vector2(0,1),Vector2(-2,6),Vector2(-8,6)])]
  "farm":return [PackedVector2Array([Vector2(-6,-1),Vector2(-6,7),Vector2(6,7),Vector2(6,-1)]),PackedVector2Array([Vector2(-9,-1),Vector2(0,-8),Vector2(9,-1)]),PackedVector2Array([Vector2(-1,7),Vector2(-1,2),Vector2(2,2),Vector2(2,7)])]
  "tomb":return [PackedVector2Array([Vector2(-7,7),Vector2(-7,-1),Vector2(-5,-6),Vector2(-2,-8),Vector2(2,-8),Vector2(5,-6),Vector2(7,-1),Vector2(7,7)]),PackedVector2Array([Vector2(-2,7),Vector2(-2,-1),Vector2(2,-1),Vector2(2,7)])]
  "watchtower":return [PackedVector2Array([Vector2(-4,8),Vector2(-4,-7),Vector2(4,-7),Vector2(4,8)]),PackedVector2Array([Vector2(-7,-7),Vector2(7,-7)])]
  "cave":return [PackedVector2Array([Vector2(-9,7),Vector2(-4,-6),Vector2(0,-8),Vector2(6,-3),Vector2(9,7),Vector2(3,7),Vector2(2,1),Vector2(-2,1),Vector2(-3,7)])]
  "caravan":return [PackedVector2Array([Vector2(-6,-5),Vector2(6,-5),Vector2(6,3),Vector2(-6,3),Vector2(-6,-5)]),PackedVector2Array([Vector2(-5,6),Vector2(-3,8),Vector2(-1,6)]),PackedVector2Array([Vector2(1,6),Vector2(3,8),Vector2(5,6)])]
  _:return [PackedVector2Array([Vector2(-7,7),Vector2(-7,-3),Vector2(-3,-3),Vector2(-3,7)]),PackedVector2Array([Vector2(2,7),Vector2(2,-7),Vector2(6,-7),Vector2(6,7)])]

static func draw_marker(app,kind: String,at: Vector2,tint: Color,highlighted: bool=false) -> void:
 if kind=="scout":
  preload("res://engraved_world/atlas_ink.gd").band_mark(app,at,highlighted)
  return
 if kind=="caravan":
  preload("res://engraved_world/atlas_ink.gd").caravan_mark(app,at,tint,highlighted)
  return
 for path in marker_paths(kind):
  var points=PackedVector2Array()
  for point in path:points.append(at+point)
  app.draw_polyline(points,Color(0.04,0.06,0.04,0.72),3.4,true)
  app.draw_polyline(points,tint,1.3,true)
 if highlighted:app.draw_arc(at,15,0,TAU,32,Color(0.78,0.70,0.45,0.8),1,true)

static func draw_map(app) -> void:
 var c=app.campaign;var ow=c.overworld;var r: Dictionary=c.region
 for id in c.exploration.sites:
  var state: Dictionary=c.exploration.sites[id];var p: Dictionary=c.node(id)
  if not state.rumour or state.searched or ow.discovered(Vector2(p.x,p.y)):continue
  var centre=Vector2(p.rumour[0],p.rumour[1])
  app.draw_arc(centre,62,0,TAU,40,Color(0.84,0.71,0.43,0.65),1.5,true)
  app.centered("RUMOURED SITE",centre+Vector2(0,5),10,app.GOLD)
 # Draw only explored sections; a planned route must not reveal unseen roads.
 var from=ow.position
 for to in ow.path:
  if ow.discovered(from) and ow.discovered(to):app.draw_line(from,to,app.GOLD,2,true)
  from=to
 if not ow.path.is_empty() and ow.discovered(ow.path.back()):app.draw_arc(ow.path.back(),8,0,TAU,20,app.GOLD,2,true)
 for place in r.locations:
  var p=Vector2(place.x,place.y)
  if not (ow.discovered(p) or c.traffic.camp_known(place.id)):continue
  var selected: bool=app.marker_highlighted("place_"+place.id)
  var painted: Rect2=app.landmark_rect(place.id)
  var tint=app.PAPER if place.kind=="town" else app.RED if place.kind=="camp" and c.world.camps[place.id].active else app.MUTED
  if not painted.has_area():
   var sign_kind:String=place.kind if place.kind in ["town","camp"] else place.feature
   if not preload("res://engraved_world/atlas_ink.gd").site_mark(app,sign_kind,p,tint,selected):draw_marker(app,sign_kind,p,tint,selected)
  elif selected:
   var foot=Vector2(painted.get_center().x,painted.end.y+3)
   app.draw_line(foot-Vector2(22,0),foot+Vector2(22,0),Color(0.78,0.70,0.45,0.8),1,true)
  var label_at=Vector2(p.x,painted.end.y+20) if painted.has_area() else p+Vector2(0,37)
  app.centered(place.name,label_at,15 if place.kind=="town" else 13,app.PAPER,true)
  var status: String=place.role if place.kind=="town" else c.camp_label(place.id) if place.kind=="camp" else "SEARCHED" if c.exploration.sites[place.id].searched else "SCOUTED" if c.exploration.sites[place.id].scouted else "UNEXPLORED"
  if selected:app.centered(status,p+Vector2(0,50),10,tint)
  app.buttons["place_"+place.id]={"rect":painted if painted.has_area() else Rect2(p-Vector2(23,20),Vector2(46,40)),"enabled":true,"map_kind":place.kind}
  if c.active.get("target")==place.id:
   app.draw_line(p+Vector2(20,-9),p+Vector2(20,-34),app.GOLD,2)
   app.draw_colored_polygon(PackedVector2Array([p+Vector2(20,-34),p+Vector2(36,-29),p+Vector2(20,-24)]),app.GOLD)

static func draw_farms(app) -> void:
 var c=app.campaign;var ow=c.overworld
 if not c.farm.enabled:return
 for f in c.farm.all():
  var previous: Vector2=f.position
  for p in ow.route(f.position,ow.places[f.town]):
   if ow.discovered(previous) and ow.discovered(p):app.draw_dashed_line(previous,p,app.MUTED,1.5,4,true)
   previous=p
  if ow.discovered(f.position) or f.report.day>0:
   var p: Vector2=f.position
   var painted: Rect2=app.landmark_rect("farm:"+f.town)
   var damaged: bool=f.damage>0 if not f.regional or preload("res://src/farm_view.gd").visible(c,f) else f.report.damaged
   var tint=app.RED if damaged else app.GOLD
   var key: String="farm_open_"+f.town if f.regional else "farm_open"
   var highlighted: bool=app.marker_highlighted(key)
   if not painted.has_area():draw_marker(app,"farm",p,tint,highlighted)
   if damaged or highlighted:app.centered("Raided farm" if damaged else "Farm",p+Vector2(0,28) if painted.has_area() else p+Vector2(0,-23),12,tint,true)
   app.buttons[key]={"rect":painted if painted.has_area() else Rect2(p-Vector2(18,18),Vector2(36,36)),"enabled":true}
  for cart in f.carts.values():
   if cart.status!="transit" or cart.position.distance_to(ow.position)>ow.sight():continue
   draw_marker(app,"caravan",cart.position,app.GOLD)
   app.centered("HARVEST",cart.position+Vector2(0,-12),9,app.GOLD)
 app.button("farm_report","FARM SUPPLY",Rect2(52,185,130,25),true)

static func draw_sites(app) -> void:
 # Preserve the stock visibility, rumour and completed-state semantics exactly.
 var c=app.campaign
 for id in c.dungeons.sites:
  var site: Dictionary=c.dungeons.sites[id];var p=Vector2(site.place.x,site.place.y)
  var visible: bool=c.overworld.discovered(p)
  # Narrative rumours/maps never grant a spatial target through canonical fog.
  if not visible:continue
  var tint: Color=app.BLUE if site.completed else app.GOLD if site.rumour and not visible else app.PAPER
  var highlighted: bool=app.marker_highlighted("place_"+id)
  if not preload("res://engraved_world/atlas_ink.gd").site_mark(app,"tomb",p,tint,highlighted):draw_marker(app,"tomb",p,tint,highlighted)
  app.centered(site.place.name,p+Vector2(0,35),13,tint,true)
  if highlighted:app.centered("CLEARED" if site.completed else ("RECOVERED MAP" if site.get("discovery","")=="map" else "RUMOURED TOMB") if not visible else "UNDEAD · TIER %d" % site.tier,p+Vector2(0,49),10,tint)
  app.buttons["place_"+id]={"rect":Rect2(p-Vector2(23,20),Vector2(46,40)),"enabled":true}
