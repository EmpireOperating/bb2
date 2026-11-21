extends RefCounted
## Cartographer's signs. None of these strokes registers a target or grants discovery.
const INK := Color("393e33")
const PAPER := Color("e5d9b9")
const BRASS := Color("a88b55")
const KEYS := {"camp":"camp_01", "watchtower":"tower_01", "ruin":"ruin_01", "cave":"cave_01", "tomb":"mound_01", "freight":"wagon_01"}
const TITLES := {"camp":"Encampment", "watchtower":"Signal tower", "ruin":"Wayside ruin", "cave":"Cave mouth", "tomb":"Burial ground", "freight":"Caravan waybill"}
static func fit(tex:Texture2D, box:Rect2)->Rect2:
 var size=tex.get_size()*minf(box.size.x/tex.get_width(),box.size.y/tex.get_height())
 return Rect2(box.get_center()-size*0.5,size)

static func site_mark(cv, kind:String, p:Vector2, tint:Color, selected:bool)->bool:
 var key:String=KEYS.get(kind,"")
 if key.is_empty() or not cv.textures.has(key):return false
 var tex:Texture2D=cv.textures[key]
 var rect:=fit(tex,Rect2(p-Vector2(23,20),Vector2(46,40)))
 # The older glyph remains the fallback at knowledge boundaries. Never paint
 # a larger illustration into undiscovered space, even for a narrative rumour.
 if not cv.painter.rect_discovered(rect.grow(1)):return false
 var memory:bool=p.distance_to(cv.campaign.overworld.position)>cv.campaign.overworld.sight()
 cv.draw_texture_rect(tex,rect,false,Color("c8c8b7") if memory else Color.WHITE)
 # Coloured register preserves the original threat/cleared state without recolouring the image.
 cv.draw_line(Vector2(p.x-6,rect.end.y),Vector2(p.x+6,rect.end.y),INK,2.5,true)
 cv.draw_line(Vector2(p.x-6,rect.end.y),Vector2(p.x+6,rect.end.y),tint,1.1,true)
 if selected:
  for side in [-1,1]:
   var tip=p+Vector2(side*21,14)
   cv.draw_polyline(PackedVector2Array([tip+Vector2(0,-5),tip,tip+Vector2(-side*6,0)]),Color("75552f"),1.4,true)
 return true

static func site_head(app,kind:String)->void:
 # Existing selected detail's blank title strip ends before its Close control.
 var cv=app.region_camera.canvas
 if not cv.has_method("painted_observation") or cv.painter==null:return
 var key:String=KEYS.get(kind,"")
 if not cv.textures.has(key):return
 var box:=Rect2(1008,117,293,60);var tex:Texture2D=cv.textures[key]
 app.draw_rect(box,PAPER);app.draw_rect(box,INK,false,1.0)
 app.draw_texture_rect(tex,fit(tex,Rect2(1015,120,79,54)),false)
 app.draw_line(Vector2(1099,125),Vector2(1099,168),BRASS,1)
 app.draw_string(app.font,Vector2(1111,137),"FIELD ATLAS   /   TRADE" if kind=="freight" else "FIELD ATLAS   /   SITES",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("645e4e"))
 app.draw_string(app.serif,Vector2(1111,162),TITLES[kind],HORIZONTAL_ALIGNMENT_LEFT,-1,19,INK)

## A miniature cut in profile. A reduced 301px three-quarter plate loses both wheels
## at atlas zoom; reserve that plate for the waybill. Cart body carries the native tint.
static func freight_mark(cv,p:Vector2,tint:Color,highlighted:bool)->void:
 var dark:=Color("353427");var canvas:=Color("f3e4be");var ochre:=Color("9e865d")
 var roof:=PackedVector2Array([p+Vector2(-9,-1),p+Vector2(-8,-5),p+Vector2(-6,-8),p+Vector2(2,-8),p+Vector2(5,-7),p+Vector2(7,-4),p+Vector2(7,-1)])
 cv.draw_colored_polygon(roof,canvas);roof.append(roof[0]);cv.draw_polyline(roof,dark,1.3,true)
 cv.draw_line(p+Vector2(-4,-7),p+Vector2(-5,-1),ochre,0.95,true);cv.draw_line(p+Vector2(2,-7),p+Vector2(1,-1),ochre,0.95,true)
 cv.draw_rect(Rect2(p+Vector2(-9,-1),Vector2(17,5)),dark);cv.draw_rect(Rect2(p+Vector2(-8,0),Vector2(15,2.5)),tint)
 cv.draw_line(p+Vector2(7,2),p+Vector2(10,0),dark,1.5,true)
 for x in [-5.5,4.5]:
  var hub:=p+Vector2(x,5);cv.draw_circle(hub,3.05,dark,true,-1,true);cv.draw_arc(hub,1.95,0,TAU,16,ochre,0.9,true);cv.draw_circle(hub,0.7,canvas,true,-1,true)
 if highlighted:cv.draw_arc(p,15,0,TAU,32,Color(0.78,0.70,0.45,0.8),1,true)

## Tiny woodcut for a mobile hostile band. No inferred strength, route or allegiance.
static func band_mark(cv,p:Vector2,highlighted:bool)->void:
 const PRINT=preload("res://engraved_world/marks/road-band.svg")
 cv.draw_texture_rect(PRINT,Rect2(p-Vector2(12,12),Vector2(24,24)),false)
 if highlighted:cv.draw_arc(p,15,0,TAU,32,Color(0.78,0.70,0.45,0.8),1,true)

## Road miniatures share the band print's scale. Status ink stays independent of the art.
static func caravan_mark(cv,p:Vector2,tint:Color,highlighted:bool)->void:
 const PRINT=preload("res://engraved_world/marks/road-caravan.svg")
 cv.draw_texture_rect(PRINT,Rect2(p-Vector2.ONE*14,Vector2.ONE*28),false)
 road_register(cv,p+Vector2(0,12),tint)
 if highlighted:road_ring(cv,p)

static func wreck_mark(cv,p:Vector2,memory:bool,highlighted:bool)->void:
 const PRINT=preload("res://engraved_world/marks/road-wreck.svg")
 cv.draw_texture_rect(PRINT,Rect2(p-Vector2.ONE*15,Vector2.ONE*30),false,Color("c8c8b7") if memory else Color.WHITE)
 if highlighted:road_ring(cv,p)

static func guard_mark(cv,p:Vector2,tint:Color,survivors:int,highlighted:bool)->void:
 const PRINT=preload("res://engraved_world/marks/road-guard.svg")
 cv.draw_texture_rect(PRINT,Rect2(p-Vector2.ONE*13,Vector2.ONE*26),false)
 road_register(cv,p+Vector2(-5,12),tint)
 var chip:=p+Vector2(10,8)
 cv.draw_circle(chip,5.6,INK,true,-1,true)
 cv.draw_circle(chip,4.5,PAPER,true,-1,true)
 cv.centered(str(survivors),chip+Vector2(0,3.1),9,INK)
 if highlighted:road_ring(cv,p)

static func road_register(cv,p:Vector2,tint:Color)->void:
 cv.draw_line(p-Vector2(4,0),p+Vector2(4,0),INK,2.8,true)
 cv.draw_line(p-Vector2(4,0),p+Vector2(4,0),tint,1.45,true)

static func road_ring(cv,p:Vector2)->void:
 cv.draw_arc(p,16,0,TAU,32,Color(0.78,0.70,0.45,0.8),1,true)

static func compass(cv)->void:
 # Fixed marginalia in screen coordinates. Scale divisions remain true to the current zoom.
 var p=Vector2(cv.camera.RECT.size.x-43,50);var pale=Color("e9dcbb")
 cv.draw_circle(p,17,Color("4c5044"));cv.draw_arc(p,18,0,TAU,40,pale,1,true)
 for i in 8:
  var v=Vector2.UP.rotated(i*PI/4);var t=v.orthogonal();var tip=p+v*(24 if i%2==0 else 12)
  cv.draw_colored_polygon(PackedVector2Array([p-t*3,p+v*2,tip]),pale)
  cv.draw_colored_polygon(PackedVector2Array([p+t*3,p+v*2,tip]),Color("ab8d62"))
 cv.draw_circle(p,2.2,INK);cv.draw_string_outline(cv.serif,p+Vector2(-5,-27),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,15,3,INK)
 cv.draw_string(cv.serif,p+Vector2(-5,-27),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,15,pale)
 var a=Vector2(cv.camera.RECT.size.x-25,cv.camera.RECT.size.y-16);var step:float=cv.painter.CELL*cv.camera.zoom
 for i in 4:
  var bar:=Rect2(a-Vector2((4-i)*step,0),Vector2(step,3));cv.draw_rect(bar,pale if i%2==0 else INK);cv.draw_rect(bar,Color("746c53"),false,0.7)
 var caption="4 map cells";var at=a-Vector2(61,4)
 cv.draw_string_outline(cv.serif,at,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12,2,INK);cv.draw_string(cv.serif,at,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12,pale)
