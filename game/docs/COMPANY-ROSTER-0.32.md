# Company formation 0.32

## Roster and placement

- Twenty living companions; dead service records do not use capacity. Twelve may be deployed, leaving eight reserves at a full field/company roster. You may bench more, including the entire company, but cannot deploy an empty lineup. With nobody assigned, world time stays paused and travel/rest/assault commands are blocked until a fighter is assigned.
- Eighteen placement positions, in two rows of nine. Default assignment fills from the centre outward; equipped ranged weapons prefer the back row. This is a convenience, never a build restriction.
- Formation stores permanent company IDs. Tactical IDs are assigned in position order at deployment. Equipment, personal stats, perks, relationships, damage and rewards map back through that deployment list.
- New hires fill available field capacity, then reserves. A death clears that position; reserves never join an ongoing battle automatically.
- Editing is available during the overworld/camp phase, outside pending encounters and ended campaigns. Opening Company pauses overworld simulation. Drag-and-drop and select-then-destination use the same validation and autosave.

## Reserves and ambushes

Every living companion contributes to wages and rations and participates in ordinary passive recovery. Only deployed companions receive combat damage, battle records, kills, scars and battle XP. Combat-bound contract participants are refreshed from the deployed group. Peaceful delivery contracts retain their participants from acceptance. Band strength decisions use active fighters, so reserves cannot intimidate an enemy from safety.

When a hunting band contacts the company, combat starts with the deployed party in a compact scattered formation and enemies on opposing sides. The campaign's saved formation remains unchanged. This is a first ambush layout, not a claim of complete Battle Brothers terrain/ambush parity.

## Battle presentation

Expanded battles use a 17-by-11 board and twelve slots per side. Original terrain is retained within the larger board. The initiative strip pages twelve portraits at a time; new activations return it to the current fighter. All twelve allies are available in the bottom roster and inspection selector. Hit-odds/weapon previews support twelve enemy targets. Twelve settlement rows fit without covering the results controls.

The combat damage, hit, defence, shield, AP and fatigue formulas are unchanged. Enemy equipment generation keeps its original authored relative index and seed inputs when tactical IDs move from 6–11 to 12–17. Current campaign groups remain at their original sizes.

## Persistence

Campaign schema 27 requires roster version 1 and eighteen unique-or-empty formation positions; at most twelve may be occupied by living company IDs. Battle schema 21 requires twenty-four tactical records, correct teams, valid dimensions and full-sized initiative/perk references. Invalid saves are rejected without replacing the current state.

Prior saves retain their capabilities and exact snapshots until the player opens Formation & Reserves at camp. An existing battle is never resized mid-fight. The source API's appended capability argument defaults to historical behaviour for older callers; native New Company explicitly enables it.
