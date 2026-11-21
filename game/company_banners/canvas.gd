extends "res://campaign_overworld/canvas.gd"
const Identity=preload("res://company_banners/identity.gd")
const Art=preload("res://company_banners/art.gd")
const MAP_SIZE:=Vector2(32,64)
const POLE_FOOT:=Vector2(16,62.4) # Source foot (160,624) at 0.1 world scale.
var _last_player_paint:Dictionary={}
func _banner_id()->String:
 if host!=null and host.host!=null:return host.host.session.company_identity.banner
 return Identity.DEFAULT.banner
func party_paint_rect()->Rect2:
 return Rect2(rendered_party_position()-POLE_FOOT,MAP_SIZE)
func draw_player_party(p:Vector2)->void:
 var id:=_banner_id();var painting:Texture2D=Art.texture(id)
 var rect:=party_paint_rect()
 if painting!=null:draw_texture_rect(painting,rect,false)
 # Keep the established position/selection cue, never the wagon or old mast.
 for i in 4:
  draw_arc(p+Vector2(0,3),24,i*PI*0.5+0.08,i*PI*0.5+0.9,10,Color(0.84,0.78,0.53,0.72),1.3,true)
 _last_player_paint={"banner":id,"texture":Identity.path(id),"painted":painting!=null,"player_wagon":false,"legacy_mast":false,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"pole_foot":[p.x,p.y]}
func player_banner_observation()->Dictionary:
 return _last_player_paint.duplicate(true)
