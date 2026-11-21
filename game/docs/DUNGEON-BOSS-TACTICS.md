# Dungeon boss tactics

Based on Prototype 0.35, Library version 40, with the separately delivered battle-time freeze applied. This change adds decisions to the three existing final encounters. It does not change enemy statistics, squad sizes, equipment, rewards, progression requirements or dungeon generation.

| Encounter | Behavior | Counterplay |
| --- | --- | --- |
| Lord of Blackbarrow | Shield bearers stay close to their lord and spend remaining AP on shieldwall after striking. The lord advances with shield support and uses his existing mace. | Separate or destroy adjacent shields. Normal shieldwall support disappears when its requirements fail. |
| Watch Captain | Spearmen brace against approaching enemies near the captain. His screen avoids blocking firing lanes. An unloaded captain moves to a better lane when he can retain the reload AP, then reloads. Engagement forces a paid sword swap; he can switch back when clear. | Pillars block shots. Closing into melee prevents crossbow reloads and consumes his AP on the swap. |
| Buried King | Royal shields prefer the central approach. The king moves toward guard-supported engagements and prioritizes opponents pinned by his guards. | Spread engagements and turn the flank; isolate targets from the guard's surround support. |

The king uses ordinary single-target greatsword strikes. This patch adds no sweep attack, magic, resurrection, aura, free action, damage bonus or extra random roll. Both sides still use the same attack, movement, shieldwall, brace, recovery, ammo, fatigue and weapon-swap rules. Scoring reads current battlefield state only. Killing the leader releases surviving guards to the existing general AI.

The room panel describes the encounter's tactics. This provides no equipment rating, required roster, level gate or under-equipped warning.

## Save behavior

New version-two dungeon finales opt into these tactics on deployment. Ordinary rooms, overworld fights and version-one dungeon generation retain their AI. Existing active battle saves (versions 22/23) keep their original AI through completion. Starting another version-two finale, including re-engaging after retreat, enables the new tactics.

New boss battles use battle-save version 25 with expanded rosters (24 for the supported six-slot representation). Campaign and dungeon schema versions stay unchanged. The new battle version requires a crypt challenge map, elimination objective and exactly one boss record, including a defeated boss. Older executables cannot load these new active/aftermath boss battles.

No private AI state or extra dungeon state is saved. Choices derive from unit positions, gear, remaining AP/fatigue and existing activation state. Reloading between the captain's movement and reload preserves the next action. Retreat keeps the same enemy casualties, armor and equipment wear as before; living enemies receive no reset or refill on re-entry.

## Time dependency

Validation uses zero campaign time for all battles, including retreats and wipes. Travel, room exploration, searching, leaving and recovery continue to consume their existing time and supplies. Apply the separate battle-time-freeze change before interpreting the progression results here; the released 0.35 build still has its earlier two-hour/day settlement rules.

## Validation and limits

- `tests/dungeon_tactics.gd`: paid actions, real shieldwall support loss, melee reload denial, sword swaps, bracing, captain reposition/reload replay, king target selection, no planning RNG, schema validation and legacy AI selection.
- `tests/dungeon_challenge.gd`: all three full prepared expeditions, real tactical battles, traversal, choices, persistent wear and reserved rewards. Prepared parties receive declared recruits, equipment, supplies and XP; these are mechanics tests, not earned progression.
- `tests/dungeon_tactics_ui.gd`: native full expeditions through all three tiers, real UI controls, active-boss F5/F9, battle-clock assertions and action traces.
- `tests/dungeon_tactics_careers.gd`: nine fresh careers, seeds 71/592/789 against each tier, normal starting company, real earnings, hires, gear purchases, development, wounds and upkeep. Losses are recorded, not turned into passing victory assertions.
- `tests/dungeon_tactics_earned_ui.gd`: native continuation from the exact earned seed-592 Blackbarrow boss checkpoint. Seven enter the boss fight, five return; reserved named reward, F5/F9 and leave/re-entry verified.
- `tests/dungeon_tactics_retreat.gd`: actual combat damage followed by retreat, Save/Load and retracing cleared floors. Enemy wear is identical on redeployment.

The career driver makes one expedition attempt per company after a fixed preparation policy: at least 6/9/12 active mercenaries and day 14/17/19 for tiers 1/2/3, with a last departure on day 27. Those are test-policy choices, never game gates. It does not keep returning to unfinished dungeons until victory. Campaign duration remains thirty days.

All three fresh careers cleared Blackbarrow. None cleared the other tiers; none reached their final bosses. Higher-tier earned clears and boss balance remain unproven. The three-tier prepared expeditions establish playable mechanics, not affordability or optimal difficulty. Detailed career reports and logs accompany the integration pack.
