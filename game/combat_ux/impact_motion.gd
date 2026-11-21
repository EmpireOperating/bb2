extends RefCounted
## Finite, presentation-only impulse. The standing root and camera never move.
var actor: Node3D
var illustration: Node3D
var tween: Tween
var baseline := Vector3.ZERO
func _init(owner: Node3D) -> void:
 actor=owner
func play(world_offset: Vector3, peak: float, duration: float) -> void:
 cancel()
 illustration=actor.get_node_or_null("Illustration")
 if not is_instance_valid(illustration) or not actor.is_inside_tree() or not actor.is_visible_in_tree():return
 baseline=illustration.position
 tween=actor.create_tween();tween.pause()
 tween.tween_property(illustration,"position",baseline+actor.global_basis.inverse()*world_offset,peak).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
 tween.tween_property(illustration,"position",baseline,duration-peak).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
 tween.tween_callback(cancel)
func advance(delta: float) -> void:
 if tween==null:return
 if not actor.is_inside_tree() or not actor.is_visible_in_tree() or not is_instance_valid(illustration) or illustration.get_child_count()==0:
  cancel();return
 if is_finite(delta):tween.custom_step(maxf(delta,0.0))
func cancel() -> void:
 if tween!=null:tween.kill();tween=null
 if is_instance_valid(illustration):illustration.position=baseline
