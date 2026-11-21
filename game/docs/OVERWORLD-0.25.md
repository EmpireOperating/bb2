# The free-roaming Marches — 0.25

First playable region, built on the complete 0.24 game, including the concurrent axe/mace perks. This is a Godot source project. Open `project.godot` in the tested Godot 4.4.1.

## Play

Click any reachable ground to travel; select a landmark and Set course to enter it. Space pauses; 1/2/3 choose 1×/2×/4× speed; right-click stops. The route is visible and can be changed while moving. Roads, plains, hills and forest use different costs; blocked river cells force a crossing. Town services require proximity to the last entered town, so buying and recruiting cannot be done remotely.

The company starts at 08:00, paused. One real second at 1× advances 12 game minutes. Arrivals, first scout sightings and contact pause automatically. Menus suspend travel. Camping advances 24 hours on this same clock; scouts can interrupt it. Battle settlement retains the pre-existing one-day time cost. Food, wages, deadlines and the regional economy advance once per midnight or settled battle day.

Towns and geography are surveyed. Exploration reveals camps; accepting work marks its target. Each camp generation has one finite scout party. Scouts patrol, pursue within detection range, and cannot force contact inside town shelter. The company can evade before contact. Defeated scouts stay defeated; victory does not destroy the main camp. Defeat gives a six-hour disengagement window after tactical settlement. Camp clearing and subsequent reoccupation continue to use the existing world model.

Field encounters currently reuse the originating camp’s tactical map. Contact is a separate saved encounter. It shares tactical combat, equipment damage, casualties, XP, loot and aftermath with contracts. Scout spoils do not award contract wins. An unrelated accepted job remains active unless its normal deadline or world state changes. Uncontracted assaults can clear camps. Escorts move with the company, require their ambush stop and deliver actual cargo before payment.

Wagons and council patrols render continuous paths tied to their existing daily schedules. Their economic interactions still happen at daily boundaries; this release does not implement independent spatial caravan interception or a fully continuous economy. Other future extensions include larger regions, procedural geography, locations with events and more faction behavior.

## Integration

- `src/overworld.gd`: fixed three-minute simulation steps, weighted navigation grid, exploration, scout behavior, route projection and spatial serialization.
- `src/campaign.gd`: clock owner, physical access to town services, encounters and tactical settlement. Existing daily economy and growth providers remain the integration boundaries.
- `src/main.gd`: travel input, pause/speed controls, world map, contact screen and atomic full-precision JSON saving.
- Campaign schema 21 adds `overworld` and `encounter`. Schema-20 imports initialize at the saved landmark and pause. Battle schema remains 18 for new fights; old fights retain their own rules.
- The historical synchronous `travel()` and `rest_day()` helpers remain for older model fixtures and planning. Player travel and rest use `begin_travel()`, `begin_rest()` and `tick_overworld()`.
- Full-day bond support/mediation requires town shelter. Equipment management and progression remain available on the road; no time advances in their menus.

## Validation

`tests/overworld.gd` covers free destinations, all landmark routes, terrain, blocked water, physical town access, paused time, midnight accounting, frame subdivision, speeds, pursuit/evasion, finite scouts, route/contact/battle/aftermath saves, idempotent settlement, unrelated jobs, escort delivery, camp assaults and atomic rejection of corrupt spatial saves.

`tests/overworld_ui.gd` uses native mouse/key input through the actual game. Its journey leaves Ashwick, travels off-road, saves and reloads mid-route, discovers and intercepts scouts, saves a pending contact and a live battle, completes the fight, returns to Ashwick and buys food. The recorded seed-7391 journey ends on day 3 with all six soldiers alive. Time is accelerated by invoking the production process loop; combat uses normal legal AI commands, not a forced result.

The original 0.25 run counts and limitations are preserved in `VALIDATION-v0.25.md`; current integrated results are in `VALIDATION.md`. Screenshots in this folder show the town, moving company, scouts, contact, battle, aftermath and homecoming.
