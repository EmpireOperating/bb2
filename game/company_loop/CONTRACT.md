# Company loop implementation contract

Base: bdac701 (accepted Equipment Study). Own new company_loop/ only unless coordinator changes root project/README/launcher. Protected src/data/tests/assets/prototype/visual_slice/sprite_study remain byte-identical. Godot 4.4.1. Original and accepted worktrees/saves are untouched.

## Domain: session.gd (RefCounted)

- signal changed
- var campaign (existing src/campaign.gd authoritative instance); var last_error:String
- func setup(seed:int=7391)->void: six living named company members with authentic unique item ownership, bounded visibly supported starting kits and shared spare inventory. No live save access.
- func preview_unit(sid:int)->Dictionary: read-only battle-shaped projection with id=sid, company_id=sid, stable visual_id int for character identity, actual armor_parts and arms/weapon/shield, real stats. No simulation mutation or decorative gear.
- func gear_slots(sid:int)->Array: dictionaries {key,label,item_id,definition,name,condition,maximum}; keys weapon,shield,body/base,body/mail,body/outer,head/shell. Empty slots return empty item_id. Extra modeled slot may be included if completely supported.
- func available_items(sid:int,slot:String)->Array: dictionaries {item_id,definition,name,condition,maximum}; only real unowned/unfitted inventory suitable for this slot. No free grants.
- func equip(sid:int,item_id:String,slot:String)->bool; func unequip(sid:int,slot:String)->bool: delegate existing Campaign fitting/equip/unequip validators; errors named in last_error; no-op/refusal no item duplication/state loss. Campaign's inability to remove weapon is preserved, not silently changed.
- func start_battle()->bool: real campaign deployment and current individual initiative. Use unchanged prototype/scenario.gd tiles/spawn positions as bounded battlefield content, same painted terrain renderer, actual equipment item IDs and condition. All living friendly/enemy gear is from authored subset (actual spawn equipment, not cosmetic proxies). No combat-rule fork. No gameplay rebalance hidden in renderer.
- func resolve_battle()->bool: only real finished battle, existing Campaign settlement, phase aftermath. Exactly once via existing phase guard.
- func retreat_battle()->bool: existing explicit retreat/settlement, preserves casualties/damage and unpaid/loss consequences.
- func return_to_camp()->bool: existing Campaign return; no free repair/reset.
- func save_camp(path:String)->bool; func load_camp(path:String)->bool: atomic wrapper around validated campaign snapshot, CAMP ONLY; source user:// under new custom userdir. Reject corruption without mutating active session. Never serialize/resume bespoke live battlefield. UI labels last camp checkpoint and no midbattle save.
- var campaign.phase is camp/battle/aftermath; campaign.battle is authoritative; campaign.soldiers/campaign.items/campaign.catalog direct read-only UI sources.
- Stable visual_id: sid for company; enemy 6+actual battle id. Attach to deployed units. Identity is anatomy only, never equipment.

## Camp view: camp_panel.gd (Control)

- signal deploy_requested
- func set_session(value)->void: creates/refreshes responsive outfitting UI; refresh() method; bind session.changed once.
- Large preview uses company_loop/character.gd configure(session.preview_unit(selected),catalog), exact preview_texture. Keep preview actors in tree/process-disabled offscreen so resource owned; no second compositor or independent gear.
- Company roster, selected name/real stats; actual equipped slots; select slot then stash item then Equip. Remove via allowed rule. Clear disabled reasons; no fake wardrobe controls. At most six bros/curated inventory, no entire campaign menus.
- Deploy button emits signal; parent calls domain start. No midbattle outfit access.
- observation()->Dictionary includes selected_sid, selected_slot, preview_layers, preview_texture_id; slot/item/roster/action button centers and viewport coordinates. Resource IDs may be negative nonzero.
- Responsive at 1440x900 and 960x600; minimum640x480 no control offscreen, scroll lists where needed.

## Character: character.gd

- Extends accepted sprite renderer, same configure/refresh/preview_texture/layer_signature/render_diagnostics contracts.
- Stable actual visual_id creates a small set of distinct faces/hair/beards; same identity in camp and battle, correct helmet hair suppression; accepted equipment pixels/style unchanged. Real authored gear subset only.
- Optional play_attack(direction:Vector3) and play_hit(kind:String="hit") presentation-only bounded pulses. No actor-root movement or simulation mutation; animation independent from refresh, cancel/reset safely, preserve actual rendered picking. Parent invokes on accepted commands/feedback only.

## Parent integration

Parent owns main.gd/main.tscn, battlefield.gd, project.godot, launch-company-loop.sh, run_checks.py, native external-input driver and final docs/review/package. New main starts camp, uses domain; battle view adapts initiative UI and hides inherited prototype restart/kit shortcuts. Retreat and aftermath return visible. Saves only camp, clearly labeled. No terrain/camera-world-light changes. Native GUI via canonical private Omabox only.

## Acceptance

Equip real owned items, no aliasing; immediate same-identity sprite/stat changes; deployment exact identities/condition; initiative honored; real movement/attacks/enemy actions; real damage/death/shield loss settled once; return state not reset; camp save/reload exact validated state; prior game/terrain preserved; actual native screenshots. Full campaign world UI/export/animation overhaul not in scope.
