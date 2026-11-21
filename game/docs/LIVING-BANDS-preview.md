# Living bandit parties

This follow-up adds decisions and persistent casualties to the finite roaming parties in the living-trade preview. It remains a separate branch for integration. The full preview is based on 0.27 plus the procedural-map and living-trade packs; it does not contain the other chat's 0.29 changes.

## Player behaviour

- Parties scout a wider mix of road approaches and wilderness, rather than the old four-point circuit within about 80 map units of camp. Reachable wilderness goals are 170 or 230 units away; road approaches can extend to 320.
- They assess visible companies using living headcount, health, skill, defence and current armour. This is a rough strength estimate, not a prediction of tactical victory.
- They hunt vulnerable companies, flee stronger ones, and stop pursuing a company that disappears or reaches town safety. Day/night detection radii are 150/100 map units; no strength checks reveal an unseen company.
- They choose visible, unguarded freight on their camp's existing trade corridor. Cargo value and distance influence selection; a visible company near the wagon deters the attempt. Guarded shipments and protected roads are excluded.
- A strong approaching company can interrupt an attack or make loaded raiders drop their goods. Cargo resumes its actual journey, is protected for the remainder of that shipment, and yields no bounty or company food merely for intimidation.
- After a bloody encounter that the player loses or retreats from, surviving raiders return physically to camp and recover. Dead members stay dead. Subsequent encounters use the survivors' remaining health; absent members generate neither enemies nor fresh corpse loot.
- Ordinary sorties last at most 48 hours before a return and 12-hour rest. A failed pursuit is bounded to four hours; losing contact also sends the party home. Combat losses require 36 hours of rest after reaching camp. Surviving members heal only while resting there.
- Clicking a visible band pursues its moving location. The sidebar shows observed activity and headcount. Pursuit stops when sight is lost; the sidebar then conceals its current activity and position.

The map displays scouting, hunting, raiding, hauling, fleeing, returning and recovering. Camp victory removes that generation's field party; a lost assault leaves an undefeated field party active. A routed party still counts as defeated when the player wins, as in the delivered combat rules.

## Ownership and integration

`bandits.gd` owns decisions, timers and a six-slot health record for each existing party. It derives deterministic scouting circuits from the region without consuming campaign RNG. It does not create extra enemies or replacement troops. `Overworld` still owns position and movement; `Traffic` still owns freight interactions; `World` remains the food and treasury authority.

`Campaign.setup(company_seed, map_seed, live_trade, living_bands)` adds an optional fourth argument, default false. The new preview UI opts in; older model callers retain their original behaviour. After construction and daily updates, synchronise the band component before freight selection. Its order is applied during each existing three-minute world tick. Background travel/rest/battle settlement advances the same bands without moving the company or opening offscreen player battles.

Scout encounters use the threat fixed when that party was created. `Bandits.deploy()` applies the persistent roster after the existing enemy equipment setup, before the first round. `Bandits.settle()` records actual health/deaths once through the normal battle settlement; healthy enemy victories can resume their previous task. The base combat, equipment, perk and progression implementations are unchanged.

The standalone preview uses campaign schema **25** and band component version **1**, with its own `user://ashen-company-bandit-behaviour-preview.json`. **Reconcile schema numbering with the integrating branch; 25 is not a globally reserved version.** Schema-24 trade saves and older map/classic saves load with their previous decisions, without silent conversion. Candidate objects validate the new state before committing a load. Cross-check the encounter threat against the saved band roster.

On the other chat's branch, preserve its starting equipment, passive recovery, weapon switching, fog and any intervening save changes. Review the small hooks in `campaign.gd`, `overworld.gd`, `traffic.gd` and `main.gd`; do not overwrite the main project with this preview.

## Scope limits

This is wider camp-based roaming, not independent armies travelling endlessly between regions. There is still one finite field party per camp generation. New generations follow the existing funded camp reoccupation system. Freight raids stay on the existing camp/corridor ownership model; this slice does not add farms, faction wars, reinforcement recruitment or camp relocation.

The world model's direct town-stock raids remain daily rules. NPC-versus-caravan combat retains the existing four-hour defence timer; player encounters use real tactical combat. Party casualties and health persist, but individual enemy weapons/armour still use the existing encounter equipment generator. Retreat does not add persistent enemy equipment inventories.

Strength thresholds and movement speeds are initial tuning values. The source preview still has the earlier heavily equipped company start, so those companies tend to intimidate small bands. Test the combined early-game balance after integration; these tests establish behaviour and accounting, not final balance.

## Validation

- `tests/bandits.gd`: strength reactions, wider physical scouting, pause, identical JSON continuation, casualties across repeat encounters, no absent-member loot, atomic corrupt-save rejection, older save behaviour, and six 30-day economy simulations. Company supply fixtures in month runs prevent hunger/debt ending the simulation early.
- `tests/bandit_edges.gd`: hidden-company information, night vision, post-battle grace, recovery continuity, dropped cargo delivery, guarded traffic, and real camp outcomes (two victories and one defeat in seeds 1, 7, 8).
- `tests/bandits_ui.gd`: native seed-1 travel, visible-band pursuit, flight from the ordinary company, actual capture, legal tactical victory, readable selected-party panel and F5/F9. No position, health, enemy or victory fixtures.
- `tests/bandit_retreat_ui.gd`: a separate native journey, actual combat casualty, UI retreat, enemy return/recovery and F5/F9. No damage or victory fixtures.

Screenshots named `bandits-*.png` are actual native captures. Existing headless map, overworld, trade, ammunition and perk compatibility checks are also included in the pack's validation logs. Prior native trade scripts assuming a band stays to fight are not claimed to pass unchanged with the new default flight behaviour.

Run headless checks with Godot 4.4.1: `godot --headless --path . --script tests/bandits.gd` and `tests/bandit_edges.gd`. On a native display with isolated user data, run `godot --path . --audio-driver Dummy --script tests/bandits_ui.gd` or `tests/bandit_retreat_ui.gd`.
