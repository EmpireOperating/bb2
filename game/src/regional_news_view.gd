extends RefCounted
static func draw(app) -> void:
 var c=app.campaign;var news=c.news
 app.panel(Rect2(0,0,1440,900),Color(0.02,0.04,0.03,0.97))
 app.label_at("THE COMPANY'S NOTES",Vector2(45,40),12,app.GOLD)
 app.label_at("Reports & destinations",Vector2(45,80),34,app.PAPER,true)
 app.button("news_close","CLOSE / ESC",Rect2(1180,30,215,48),true,true)
 app.button("news_reports","REPORTS",Rect2(45,108,210,40),true,app.news_tab=="reports")
 app.button("news_routes","DESTINATIONS",Rect2(267,108,210,40),true,app.news_tab=="routes")
 app.button("news_ask","ASK LOCALS",Rect2(1000,108,190,40),c.in_town() and c.encounter.is_empty() and not c.over())
 app.button("news_other","OTHER RUMOURS",Rect2(1202,108,193,40),c.in_town() and c.encounter.is_empty() and not c.over())
 if app.news_destination!="" and news.directions.has(app.news_destination):
  draw_directions(app,app.news_destination)
  return
 app.label_at("Ask locals in town. Travelling caravans bring dated reports from elsewhere.",Vector2(45,179),14,app.MUTED)
 var rows=news.rows(c) if app.news_tab=="reports" else news.directions.keys()
 var pages=maxi(1,ceili(rows.size()/4.0));app.news_page=clampi(app.news_page,0,pages-1)
 if rows.is_empty():
  app.label_at("No reports recorded yet. Ask about local news at a town.",Vector2(65,270),22,app.PAPER,true)
 for i in mini(4,rows.size()-app.news_page*4):
  var y=210+i*137;var row=rows[app.news_page*4+i]
  var town:String=row.report.town if app.news_tab=="reports" else row
  app.panel(Rect2(45,y,1350,125),Color("1c291f"),Color("3b4938"))
  app.label_fit(c.node(town).name,Vector2(65,y+30),440,23,app.PAPER,true)
  if app.news_tab=="reports":
   var r:Dictionary=row.report;var stale=news.clock(c)-r.observed>=news.OLD_HOURS*60
   app.label_fit(news.title(c,r),Vector2(530,y+30),830,20,app.GOLD,true)
   app.label_at("Reported day %d · %s%s"%[r.observed/1440+1,news.age(c,r)," · MAY BE OUTDATED" if stale else ""],Vector2(65,y+57),13,app.RED if stale else app.BLUE)
   var source="Local account" if row.carrier=="" else "%s from %s"%[c.world.short_id(row.carrier),c.node(row.via).name]
   app.label_fit("Heard day %d in %s · %s"%[row.heard/1440+1,c.node(row.at).name,source],Vector2(530,y+57),820,13,app.MUTED)
   var detail={"roads":"Ask the local council about work. No contract or payment is guaranteed.","farm":"Farm supplies were disrupted when this report was made.","missing":"The merchant was still waiting. The wagon's present location is unknown.","shortage":"A funded workshop lacked materials. Check demand and prices on arrival.","lean":"There was less than five days’ food in store.","surplus":"Local stores held well above usual stocks after workshop needs.","plenty":"Food reserves were high and the market was prosperous when observed.","quiet":"No pressing road, farm or workshop trouble was reported then."}[r.kind]
   app.label_fit(detail,Vector2(65,y+79),1280,13,app.PAPER)
  else:
   app.label_at("Visited / sighted" if news.sighted(c,town) else "Known by word of mouth · terrain unexplored",Vector2(530,y+30),16,app.BLUE)
   app.label_fit("Directions heard in %s on day %d"%[c.node(news.directions[town].at).name,news.directions[town].heard/1440+1],Vector2(530,y+57),810,14,app.MUTED)
  app.label_fit(news.bearing(c,town),Vector2(65,y+109),1060,14,app.MUTED)
  app.button("news_directions_"+town+"#"+str(app.news_page*4+i),"READ DIRECTIONS",Rect2(1150,y+91,225,26),true,news.pinned==town)
 app.button("news_prev","<",Rect2(45,781,50,34),app.news_page>0)
 app.label_at("%d / %d"%[app.news_page+1,pages],Vector2(116,805),15,app.MUTED)
 app.button("news_next",">",Rect2(215,781,50,34),app.news_page+1<pages)
 app.label_at("Reports are observations, not reserved jobs. Conditions can change before you arrive.",Vector2(45,849),15,app.MUTED)
 app.label_at("Follow named landmarks. Terrain and destinations appear through normal exploration.",Vector2(45,876),12,app.MUTED)
static func draw_directions(app,town: String) -> void:
 var c=app.campaign;var news=c.news;var entry:Dictionary=news.directions[town]
 app.label_at("DIRECTIONS TO "+c.node(town).name.to_upper(),Vector2(65,205),27,app.PAPER,true)
 app.label_at("Heard in %s on day %d"%[c.node(entry.at).name,entry.heard/1440+1],Vector2(65,239),15,app.MUTED)
 var notes=news.route_notes(c,town)
 for i in notes.size():
  var y=274+i*79
  app.panel(Rect2(65,y,1310,68),Color("1c291f"),Color("3b4938"))
  app.label_at(str(i+1)+".",Vector2(85,y+39),22,app.GOLD,true)
  var lines=app.wrapped_lines(notes[i],1190,19,2)
  for j in lines.size():app.label_at(lines[j],Vector2(130,y+28+j*25),19,app.PAPER)
 app.label_at("Look for named bridges and animal waystones as the road comes into view.",Vector2(65,715),16,app.BLUE)
 app.label_at("North is up. Bearings are general; roads can bend or branch, and travel may be dangerous.",Vector2(65,746),14,app.MUTED)
 app.button("news_back","BACK TO NOTES",Rect2(65,784,245,43))
 app.button("news_bookmark","REMOVE BOOKMARK" if news.pinned==town else "BOOKMARK DIRECTIONS",Rect2(1015,784,360,43),true,news.pinned==town)
 app.label_at("A bookmark keeps these words handy. Discover the destination by travelling.",Vector2(65,865),14,app.MUTED)
static func map_note(app) -> void:
 var c=app.campaign;var news=c.news
 if not news.enabled or not news.directions.has(news.pinned):return
 app.panel(Rect2(52,625,904,62),Color(0.04,0.07,0.05,0.94),Color("5b6146"))
 app.label_fit("BOOKMARK · "+c.node(news.pinned).name+" · Read the full directions in Lead Journal",Vector2(65,646),875,12,app.GOLD)
 app.label_fit(news.bearing(c,news.pinned),Vector2(65,672),875,14,app.PAPER)
static func draw_landmarks(app) -> void:
 var c=app.campaign
 for mark in c.news.navigation.visible(c):
  var p:Vector2=mark.position
  if mark.kind=="waystone":
   _draw_waystone(app,p)
  var width:float=app.font.get_string_size(mark.name,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
  if not app.has_method("draw_labels"): app.draw_rect(Rect2(p+Vector2(-width/2-4,14),Vector2(width+8,17)),Color(0.04,0.07,0.05,0.93))
  app.centered(mark.name,p+Vector2(0,27),11,app.GOLD)

static func _draw_waystone(app,p:Vector2) -> void:
 # Carved roadside stone in the atlas' ink-and-paper palette. A shallow cut
 # and shaded facet read at map scale without making this a map button.
 var ink := Color("393e33")
 app.draw_colored_polygon(PackedVector2Array([p+Vector2(-7,7),p+Vector2(-4,5),p+Vector2(6,5),p+Vector2(8,8),p+Vector2(-4,9)]),Color("675d49"))
 var face := PackedVector2Array([p+Vector2(-5,7),p+Vector2(-5,-5),p+Vector2(-2,-10),p+Vector2(2,-12),p+Vector2(6,-7),p+Vector2(6,6),p+Vector2(3,8)])
 app.draw_colored_polygon(face,Color("d4c6a4"))
 app.draw_colored_polygon(PackedVector2Array([p+Vector2(2,-12),p+Vector2(6,-7),p+Vector2(6,6),p+Vector2(3,8),p+Vector2(3,-6)]),Color("938770"))
 face.append(face[0]);app.draw_polyline(face,ink,1.2,true)
 app.draw_line(p+Vector2(-3,-4),p+Vector2(2,-4),ink,1.1,true)
 app.draw_line(p+Vector2(-2,-4),p+Vector2(-1,1),ink,1.1,true)
 app.draw_line(p+Vector2(-3,3),p+Vector2(1,2),Color("9f8e67"),1,true)
