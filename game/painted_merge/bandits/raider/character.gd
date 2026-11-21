extends "res://company_loop/character.gd"
## Raider source-space sprite; inherit motion/picking, never companion paint.
const RaiderAppearance = preload("res://crossbows/art/raider.gd")
static var appearance = RaiderAppearance.new()
var _diagnostics: Dictionary = {}

func refresh(unit: Dictionary, catalog: Dictionary) -> void:
 _alive=int(unit.get("hp",1))>0
 if not _alive:cancel_motion()
 if _illustration==null:
  _illustration=Node3D.new();_illustration.name="Illustration";add_child(_illustration);_create_ground_shadow()
 for child in _illustration.get_children():child.free()
 var result: Dictionary=appearance.describe(unit,catalog)
 _preview=result.texture;_signature=result.signature.duplicate(true)
 _diagnostics={"ok":result.ok,"errors":result.errors.duplicate(),"issues":result.issues.duplicate(true),"plan":result.plan.duplicate(true),"source_kind":"pinned-raider-source-space"}
 get_node("GroundShadow").visible=result.ok
 if not result.ok:cancel_motion();return
 if _motion_kind=="shield" and not _signature.get("shield",{}).get("visible",false):cancel_motion()
 var frame: Dictionary=result.plan.frame
 var geometry: Dictionary=result.plan.geometry
 var canvas:=Vector2(float(frame.size[0]),float(frame.size[1]))
 var origin:=Vector2(float(frame.base_origin[0]),float(frame.base_origin[1]))
 var foot:=Vector2(float(geometry.stance_x)+origin.x,float(frame.stance_anchor[1]))
 var pixel_size:=float(geometry.body_height)/(float(geometry.foot_y)-float(geometry.base_alpha_top))
 var flipped:=int(unit.get("side",0))==1
 var display_foot:=Vector2(canvas.x-foot.x if flipped else foot.x,foot.y)
 _diagnostics.merge({"canvas":canvas,"base_origin":origin,"foot_pixel":foot,"display_foot_pixel":display_foot,"donor_foot_pixel":frame.stance_anchor.duplicate(),"pixel_size":pixel_size,"body_height":geometry.body_height,"stack":result.plan.layers.duplicate(true)})
 _signature.foundation={"definition":"","item":"","asset":result.plan.base.path,"painted":true,"visible":true,"identity":"raider-foundation","condition":0,"maximum":0}
 var sprite:=Sprite3D.new();sprite.name="Composite";sprite.texture=_preview
 sprite.pixel_size=pixel_size;sprite.offset=Vector2(canvas.x/2.0-display_foot.x,display_foot.y-canvas.y/2.0)
 sprite.flip_h=flipped;sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS;sprite.alpha_scissor_threshold=0.12
 sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS;sprite.shaded=false;sprite.double_sided=true;sprite.no_depth_test=false
 sprite.modulate=Color.WHITE;sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var material:=ShaderMaterial.new();material.shader=ColorIdentity;material.set_shader_parameter("source_texture",_preview);sprite.material_override=material
 sprite.set_meta("slot","composite");_illustration.add_child(sprite)
 _sync_billboard_depth();_apply_motion()

func equipment_issues() -> Array:
 return _diagnostics.get("issues",[]).duplicate(true)

func appearance_diagnostics() -> Dictionary:
 return {"treatment":"source_bound_raider_equipment","painted_raider":_diagnostics.get("ok",false),"gear_recolored":false,"limitations":"One painted Raider foundation; literal owned grade2 equipment, static carries. Raised-left Ward Spear is mechanically 2H with no offhand. Accepted warm new hand, wrist fringe and inherited spear-edge coloration remain. No animation or native visual approval."}

func render_diagnostics() -> Dictionary:
 var out:=_diagnostics.duplicate(true);out["appearance"]=appearance_diagnostics();out["motion"]=_motion_kind;return out
