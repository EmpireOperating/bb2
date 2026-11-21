extends RefCounted
## Sight-admitted human bandits use the shared Engraved renderer.
const EngravedActor = preload("res://single_body/character.gd")
static func refresh_visible(host) -> void:
 for unit: Dictionary in host.battle.units:
  if int(unit.side)!=1 or unit.get("faction","")=="undead" or not str(unit.get("undead_kind","")).is_empty():continue
  if unit.get("name","")=="Empty rank" and not host.battle.living(unit):continue
  var id:=int(unit.id)
  var admitted: bool=host.battle.living(unit) and host.battle.unit_visible(0,id)
  var old=host.actors.get(id)
  if admitted and is_instance_valid(old) and old.get_script()==EngravedActor:continue
  var pose: Transform3D=old.transform if is_instance_valid(old) else Transform3D(Basis.IDENTITY,host.tile_world(host.battle.pos(unit)))
  if host.actor_tweens.has(id):host.actor_tweens[id].kill();host.actor_tweens.erase(id)
  if not admitted and is_instance_valid(old) and old.get_script()==EngravedActor:
   # Details is a copied public snapshot. Retire its visible diagnostic text
   # when an admitted bandit leaves sight.
   if host.help_open and host.combat_help_heading.text=="Encounter details":
    host._toggle_help();host.combat_help_copy.text=""
  if is_instance_valid(old):host.actors.erase(id);host.remove_child(old);old.free()
  if not admitted:host._presented.erase(id);continue
  var actor=EngravedActor.new()
  actor.spearwall_query=host.battle.spearwall_active
  actor.visible=true;actor.transform=pose;host.add_child(actor);host.actors[id]=actor
  # The retained sight refresh now configures it before HUD/portraits are refreshed.
