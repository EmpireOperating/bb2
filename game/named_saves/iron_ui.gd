extends "res://ui_polish/iron_ui.gd"
## Replace only the Menu copy; preserve every other painted route.
func action(app, id: String) -> bool:
 if id == "save_quit":
  if sheet == "menu" and app.buttons.get(id, {}).get("enabled", false) and app.host != null and app.host.has_method("_save_and_quit"):
   app.host._save_and_quit(app)
  return true
 if id in ["audio_travel", "audio_fight"]:
  if sheet == "menu" and app.buttons.get(id, {}).get("enabled", false) and app.host != null and app.host.has_method("toggle_music"):
   app.host.toggle_music(id.trim_prefix("audio_"))
  return true
 return super.action(app, id)

func draw_sheet(app) -> void:
 if sheet!="menu":super.draw_sheet(app);return
 app.buttons.clear()
 app.draw_rect(Rect2(0,0,1440,900),UI.BG) # The modal is a leaf, not a second, ghosted HUD.
 app.panel(Rect2(220,108,1000,684),UI.SURFACE,UI.LINE)
 app.label_at("FIRST MUSTER   /   CAMPAIGN",Vector2(420,167),13,UI.GOLD)
 app.label_at("Menu",Vector2(260,173),36,UI.TEXT,true)
 app.button("iron_close","Close · Esc",Rect2(1028,138,152,40))
 app.draw_line(Vector2(260,199),Vector2(1180,199),UI.LINE)
 var rows=[["save","Save checkpoint · F5"],["save_as","Save As… · named company"],["load","Load a saved company… · F9"],["help","Controls & rules"],["guide","Field guide"],["new_top","New company…"]]
 var can_quit: bool = app.host != null and app.host.has_method("_save_and_quit")
 var row_tops := [244,302,360,470,528,635]
 if can_quit:
  rows.insert(3,["save_quit","Save & Quit"])
  row_tops = [244,302,360,418,504,562,655]
 app.label_at("CHECKPOINTS",Vector2(260,231),13,UI.GOLD)
 app.label_at("REFERENCE",Vector2(260,491 if can_quit else 457),13,UI.GOLD)
 app.label_at("COMPANY FOUNDATION",Vector2(260,642 if can_quit else 622),13,UI.GOLD)
 for i in rows.size():
  var is_exit: bool = rows[i][0] == "save_quit"
  app.button(rows[i][0],rows[i][1],Rect2(260,row_tops[i],430,50),not is_exit or app.host._can_save_and_quit(app))
 UI.Press.impression(app,Rect2(720,228,460,467),"paper")
 if app is CanvasItem:app.draw_texture_rect(UI.Press.stock("colophon"),Rect2(1040,598,114,75),false)
 app.label_at("YOUR COMPANY",Vector2(746,265),13,UI.Press.PAPER_NOTE)
 app.label_at("Keep your own save branches",Vector2(746,308),23,UI.Press.PAPER_INK,true)
 var lines=["SAVED" if app.host != null and app.host.saved_ok else "UNSAVED · Save / F5 to checkpoint.","Nothing auto-saves, including on exit.","Save As creates a separate named branch.","Loading never rewrites either save.","CAMP only — return from battle first."]
 if can_quit: lines[1] = "Save & Quit writes the checkpoint, then exits."
 for i in lines.size():app.label_at(lines[i],Vector2(746,352+i*31),15,UI.Press.PAPER_NOTE)
 if app.host != null and app.host.has_method("toggle_music"):
  app.label_at("MUSIC",Vector2(746,512),13,UI.Press.PAPER_INK)
  app.button("audio_travel","Travel music: " + ("On" if app.host.travel_music_enabled else "Off"),Rect2(746,522,201,42))
  app.button("audio_fight","Fight music: " + ("On" if app.host.fight_music_enabled else "Off"),Rect2(957,522,201,42))
  if app.host.music_settings_error:app.label_at("Could not save music settings.",Vector2(746,582),14,UI.Press.PAPER_INK)
 app.button("iron_about","About ▾" if about else "About ▸",Rect2(746,590,180,38))
 if about:
  app.label_at("The Ashen Company · Campaign",Vector2(746,650),17,UI.Press.PAPER_INK)
  app.label_at("World seed %d" % app.campaign.seed_value,Vector2(746,675),15,UI.Press.PAPER_NOTE)
