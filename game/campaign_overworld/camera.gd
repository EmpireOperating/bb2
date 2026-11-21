extends "res://src/region_camera.gd"
## Preserve inherited transforms/input; retire exactly the legacy presentation.
func reset(c) -> void:
 super.reset(c)
 canvas.reset_travel_presentation()
 zoom = 1.5
func setup(app) -> void:
 super.setup(app)
 var retired = canvas
 viewport.remove_child(retired)
 retired.free()
 canvas = preload("res://campaign_overworld/canvas.gd").new()
 canvas.host = app; canvas.camera = self
 viewport.add_child(canvas)

func draw(app) -> void:
 var c = app.campaign
 if region_seed != c.region.seed: reset(c)
 if follow: center = canvas.rendered_party_position()
 bound(c)
 viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
 canvas.queue_redraw()
 app.draw_texture_rect(viewport.get_texture(),RECT,false)
 for id in canvas.buttons:
  var row: Dictionary = canvas.buttons[id]
  var r: Rect2 = row.rect
  var transformed = Rect2(world_to_screen(r.position),r.size*zoom).intersection(RECT)
  if transformed.has_area(): app.buttons[id] = {"rect":transformed,"enabled":row.enabled,"map_target":true,"map_kind":row.get("map_kind","")}

func input(app,event: InputEvent) -> bool:
 if event is InputEventMouseMotion and not dragging:
  var key: String=""
  if app.world_controls_available() and app.world_view and not app.iron.blocks_map(app,event.position):
   key=canvas.hover_marker_at(app.get_global_mouse_position())
  if key!=canvas.hovered_marker:
   canvas.hovered_marker=key
   app.refresh()
 return super.input(app,event)

