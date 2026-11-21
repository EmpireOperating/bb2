extends Control
## Read-only crop of the actual field actor's composed Texture2D. No identity
## substitution, equipment composition, resource mutation or gameplay owner.
var texture: Texture2D
var source_rect := Rect2()
var _head_rect := Rect2()
var active := false
var inspected := false
var enemy := false
func present(actor: Node, id: int, is_active: bool, is_inspected: bool, is_enemy: bool) -> void:
 set_meta("fighter_id",id)
 texture=actor.preview_texture() if is_instance_valid(actor) and actor.has_method("preview_texture") else null
 active=is_active;inspected=is_inspected;enemy=is_enemy
 source_rect=Rect2()
 if texture!=null and texture.has_meta("engraved_head"):
  texture=preload("res://engraved_people/actors.gd").portrait_for_field(texture)
  if texture!=null:source_rect=Rect2(Vector2.ZERO,texture.get_size())
 elif texture!=null:
  var bounds:=Rect2(Vector2.ZERO,texture.get_size())
  var diagnostics:Dictionary=actor.render_diagnostics() if actor.has_method("render_diagnostics") else {}
  if diagnostics.has("base_origin") and diagnostics.has("foot_pixel"):
   var origin:Vector2=diagnostics.base_origin
   var foot:Vector2=diagnostics.foot_pixel
   # These verified whole plates register body top separately from the raised weapon tip.
   if diagnostics.get("source_kind","")=="static-six-role-whole-paint":
    origin.y+=float(diagnostics.plan.geometry.base_alpha_top)
   var height:float=foot.y-origin.y
   var side:float=height*0.48
   source_rect=Rect2(Vector2(foot.x-side/2,origin.y),Vector2(side,side)).intersection(bounds)
  else:
   var image:=texture.get_image()
   var used:=image.get_used_rect() if image!=null else Rect2i(Vector2i.ZERO,Vector2i(texture.get_size()))
   var side:=float(used.size.y)*0.5
   source_rect=Rect2(Vector2(used.get_center().x-side/2,used.position.y),Vector2(side,side)).intersection(bounds)
 _head_rect=source_rect
 _fit_portrait()
func _fit_portrait() -> void:
 source_rect=_head_rect
 var paint:=Rect2(Vector2.ZERO,size).grow(-3)
 if texture!=null and _head_rect.has_area() and paint.has_area():
  var ratio:=paint.size.x/paint.size.y
  var width:=_head_rect.size.x
  var height:=width/ratio
  if _head_rect.position.y+height>texture.get_height():
   height=texture.get_height()-_head_rect.position.y;width=height*ratio
  source_rect=Rect2(Vector2(clampf(_head_rect.get_center().x-width/2,0,texture.get_width()-width),_head_rect.position.y),Vector2(width,height))
 queue_redraw()
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 resized.connect(_fit_portrait)
func _draw() -> void:
 var rect:=Rect2(Vector2.ZERO,size)
 draw_rect(rect,Color("151b1b"))
 if texture!=null and source_rect.has_area():draw_texture_rect_region(texture,rect.grow(-3),source_rect)
 var brass:=Color("e0bd75") if active else Color("a75446") if enemy else Color("8b7956")
 draw_rect(rect.grow(-1),brass,false,3 if active else 1)
 if inspected:draw_rect(rect.grow(-5),Color("9ec4c7"),false,2)
