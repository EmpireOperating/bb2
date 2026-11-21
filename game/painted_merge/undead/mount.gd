extends RefCounted
## Bounded candidate seam: only admitted undead gain new art/diagnostics.
const Actor = preload("res://painted_merge/undead/character.gd")
static func refresh_visible(host) -> void:
 for unit: Dictionary in host.battle.units:
  if int(unit.side)==0 or (unit.get("faction","")!="undead" and str(unit.get("undead_kind","")).is_empty()):continue
  var id:=int(unit.id)
  var admitted: bool=host.battle.living(unit) and host.battle.unit_visible(0,id)
  var old=host.actors.get(id)
  if admitted and is_instance_valid(old) and old.get_script()==Actor:continue
  var pose: Transform3D=old.transform if is_instance_valid(old) else Transform3D(Basis.IDENTITY,host.tile_world(host.battle.pos(unit)))
  if host.actor_tweens.has(id):host.actor_tweens[id].kill();host.actor_tweens.erase(id)
  if not admitted and is_instance_valid(old) and old.get_script()==Actor:
   # Details is a copied public snapshot. Retire its visible diagnostic text
   # when an admitted skeletal identity leaves sight; no UI/layout redesign.
   if host.help_open and host.combat_help_heading.text=="Encounter details":
    host._toggle_help();host.combat_help_copy.text=""
  if is_instance_valid(old):host.actors.erase(id);host.remove_child(old);old.free()
  if not admitted:host._presented.erase(id);continue
  var actor=Actor.new()
  actor.visible=true;actor.transform=pose;host.add_child(actor);host.actors[id]=actor
  # The retained sight refresh now configures it before HUD/portraits are refreshed.
