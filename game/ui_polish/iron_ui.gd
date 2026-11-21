extends "res://src/iron_ui.gd"
const UI = preload("res://ui_polish/style.gd")
var about := false

func action(app, id: String) -> bool:
 if id == "iron_records": sheet="records"; return true
 if id in ["tracks_scout","world_stop"] and sheet=="journal":
  # These are retained overworld commands, not a replacement Camp hub.
  sheet=""; app.action(id); sheet="journal"; return true
 if id == "iron_about": about = not about; return true
 if id.begins_with("iron_") and id != "iron_close": about = false
 return super.action(app,id)

func draw_sheet(app) -> void:
 if sheet in ["journal","records"]:
  _draw_journal(app); return
 if sheet != "menu":
  super.draw_sheet(app); return
 app.buttons.clear()
 app.draw_rect(Rect2(0,0,1440,900),Color(0.025,0.035,0.03,0.94))
 app.panel(Rect2(220,108,1000,684),UI.SURFACE,UI.LINE)
 app.label_at("Menu",Vector2(260,173),36,UI.TEXT,true)
 app.button("iron_close","Close · Esc",Rect2(1028,138,152,40))
 app.draw_line(Vector2(260,199),Vector2(1180,199),UI.LINE)
 var rows = [["save","Save checkpoint · F5"],["load","Load checkpoint · F9"],["help","Controls & rules"],["guide","Field guide"],["new_top","New company…"]]
 for i in rows.size(): app.button(rows[i][0],rows[i][1],Rect2(260,235+i*82,430,52),rows[i][0] != "load" or (app.host != null and FileAccess.file_exists(app.host.checkpoint_path)))
 app.label_at("YOUR COMPANY",Vector2(746,265),13,UI.MUTED)
 app.label_at("Between-battle saves",Vector2(746,308),25,UI.TEXT,true)
 var lines = ["SAVED" if app.host.saved_ok else "UNSAVED · use Save / F5 to checkpoint.","Nothing auto-saves, including on exit.","Load rolls back to the last checkpoint.","Save after returning to keep battle outcomes."]
 for i in lines.size(): app.label_at(lines[i],Vector2(746,352+i*31),15,UI.MUTED)
 app.button("iron_about","About ▾" if about else "About ▸",Rect2(746,524,180,38))
 if about:
  app.label_at("The Ashen Company · Campaign",Vector2(746,603),17,UI.TEXT)
  app.label_at("World seed %d" % app.campaign.seed_value,Vector2(746,637),15,UI.MUTED)
  app.label_at("Iron UI foundation · 0.46",Vector2(746,670),14,UI.MUTED)

func draw_world(app) -> void:
 super.draw_world(app)
 if not detail and app.campaign.has_method("payment_direction") and not app.campaign.payment_pending.is_empty():
  app.panel(Rect2(1008,650,408,98),SURFACE,EDGE)
  app._draw_job_reminder(1030,685)
 for id in ["company","iron_inventory","iron_journal","iron_camp"]: app.buttons.erase(id)
 app.panel(Rect2(0,852,830,48),SURFACE,EDGE)
 app.button("company","Company",Rect2(18,858,172,36))
 app.button("iron_journal","Journal",Rect2(204,858,172,36))
 app.label_at("SAVED" if app.host != null and app.host.saved_ok else "UNSAVED · Save / F5 to checkpoint",Vector2(400,891),13,UI.MUTED)

func _draw_journal(app) -> void:
 app.buttons.clear()
 app.draw_rect(Rect2(0,0,1440,900),Color(0.025,0.03,0.035,0.97))
 app.panel(Rect2(40,44,1360,812),UI.SURFACE,UI.LINE)
 app.label_at("Journal" if sheet=="journal" else "Company records",Vector2(72,105),34,UI.TEXT,true)
 app.button("iron_close","Close · Esc",Rect2(1190,70,178,44))
 app.draw_line(Vector2(72,132),Vector2(1368,132),UI.LINE)
 var c=app.campaign
 if sheet=="records":
  app.label_at("Equipment records and the people behind them",Vector2(72,185),20,UI.MUTED)
  var rows=[["service","Service history"],["bonds","Companions & bonds"],["salvage_open","Stored gear · salvage & sales"],["iron_armour","Layered armour · advanced"],["record","Battle record"]]
  for i in rows.size(): app.button(rows[i][0],rows[i][1],Rect2(72,223+i*94,570,56))
  app.label_at("Recovery happens as time passes",Vector2(718,258),25,UI.TEXT,true)
  var lines=app.wrapped_lines("Food supports health recovery. Injuries need medicine; repairs consume tools. Review each companion in Company, and buy supplies from a town. Temple care speeds injury recovery but does not remove scars.",612,18,9)
  for i in lines.size(): app.label_at(lines[i],Vector2(718,307+i*29),18,UI.MUTED)
  app.button("iron_journal","Return to Journal",Rect2(72,770,292,48))
  return
 var rows=[["news_journal","Reports & directions"],["vault_journal","Expeditions"],["trade","Trade & roads"],["politics","Councils"],["farm_report","Farms"],["guard_report","Town guards"],["iron_records","Company records"]]
 for i in rows.size(): app.button(rows[i][0],rows[i][1],Rect2(72,164+i*71,292,48))
 app.label_at("Company chronicle",Vector2(406,194),26,UI.TEXT,true)
 var known=c.journal.filter(app.known_news)
 var pages=maxi(1,ceili(known.size()/6.0)); journal_page=clampi(journal_page,0,pages-1)
 var end=maxi(0,known.size()-journal_page*6)
 var recent=known.slice(maxi(0,end-6),end)
 for i in recent.size():
  var lines=app.wrapped_lines(str(recent[i]),932,16,2)
  for j in lines.size(): app.label_at(lines[j],Vector2(406,239+i*67+j*22),16,UI.TEXT if i==recent.size()-1 else UI.MUTED)
 app.button("iron_log_prev","Newer",Rect2(406,672,150,42),journal_page>0)
 app.button("iron_log_next","Older",Rect2(572,672,150,42),journal_page+1<pages)
 app.label_at("ROAD ACTIVITY",Vector2(72,747),12,UI.GOLD)
 app.button("tracks_scout","Stop scouting" if c.overworld.tracks.scouting else "Scout tracks · 70% travel pace",Rect2(72,770,530,48),c.overworld.tracks.enabled and not c.over())
 app.button("world_stop","Stop travel / activity",Rect2(620,770,374,48))
 app.label_at("Time waits while browsing.",Vector2(1024,798),14,UI.MUTED)
