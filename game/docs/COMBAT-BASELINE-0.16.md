# Combat baseline — 0.16

This release aligns the ordinary attack/defence calculation and selected fatigue, morale and turn rules with the Battle Brothers baseline. It preserves the prototype's layered armour and authored identities. It does not claim that every weapon action, character range, enemy, map or economy value is identical to BB.

## Accuracy, in calculation order

1. Choose Melee skill/defence or Ranged skill/defence for the attack.
2. Add the action's accuracy and explicit authored personality/perk additions to attack skill. Multiply the combined attack property by morale: confident 1.1, steady 1, wavering 0.9, breaking 0.8, fleeing 0.7. Preserve this fractional result for the roll.
3. Add shield, active Shieldwall, active adjacent-wall support and Cautious to the defence property. Apply defender morale and floor the result.
4. If defence exceeds 50, halve only the excess. A defence property of 65 therefore contributes 57.5, not 65 or 58.
5. For melee only, reduce effective defence by five per additional adjacent melee opponent. Ranged holders and actors more than one height level away do not contribute. Surrounding and zone of control are separate: the pinned reference counts a living fleeing melee opponent for surrounding, while that opponent exerts no zone of control. The prototype has stagger, not a stun status.
6. Subtract effective defence from attack skill. Add +10 for any downhill advantage or −10 per level uphill. Apply the selected ranged action's distance penalty beyond its first hex.
7. Clamp ordinary attacks to 5–95. Roll an integer from 1 through 100. The displayed integer percentage is the exact number of successful outcomes; fractional intermediate values remain visible in the breakdown.

The old free neighbouring-shield bonuses, paid formation combat bonuses, loose-order bonuses and flat +20 against a fleeing target are removed from baseline battles. A fleeing defender already has reduced defence through morale. Formation intent markers cost nothing and do not alter combat properties.

Primary action accuracy: one-handed sword cuts +10, greatsword +5, spear thrusts +20, crossbow bolts +15, other primary attacks zero. Custom targeted specials retain their declared modifiers: stagger −10, shatter −5, puncture −20, hook −10. Split shield is an automatic hit against a legal adjacent intact shield; its authored 24-condition damage and costs remain. This automatic action is an explicit exception to the ordinary 5–95 rule.

### Worked cases

| Situation | Calculation | Successful rolls |
|---|---|---:|
| Axe, neutral ground | 70 skill − 20 defence | 50% |
| Sword, same target | 70 + 10 − 20 | 60% |
| Confident sword vs wavering target | (70 + 10) × 1.1 − floor(20 × 0.9) | 70% |
| Heater shield | 70 − (20 + 20) | 30% |
| Heater plus own wall | 70 − (50 + (60 − 50)/2) | 15% |
| Own wall plus one friendly active wall | 70 − (50 + (65 − 50)/2) | 12% (raw 12.5) |
| Four-hex quick shot | 70 − 20 − 3×4 | 38% |
| Four-hex aimed shot | 70 + 10 − 20 − 3×2 | 54% |
| Four-hex crossbow bolt | 70 + 15 − 20 − 3×3 | 56% |

## Shields and ranged actions

The existing heater grants 20 melee/15 ranged defence while its condition is positive. Shield drill increases each bonus by 25%, rounded down. Shieldwall spends 4 AP and 20 base fatigue, adds the shield bonus again, and persists through attacking and moving until the owner's next first activation. Restless retains its authored +5 fatigue cost. It requires a working shield. Switching equipment cancels it. Adjacent active friendly walls at height difference at most one add five each, up to four, only while the defender is also walling. Formation order does not affect this bonus.

An ordinary shield impact costs one condition. The reference's shield-impact interval is used for a miss: the clamped fractional hit threshold plus twice the unrounded shield bonus, doubled again when walling. Only rolls in this interval wear the shield. Losing the last condition immediately removes its defence. The prototype heater still has 40 condition and load 12; those item values have not been presented as an exact BB heater replica.

All bows use quick shot 4 AP/15 base fatigue or aimed shot 7 AP/20. Quick shot loses four accuracy per hex after the first; aimed adds ten to skill and loses two per extra hex. Aimed multiplies the regular damage roll by 1.1; it does not multiply the independent armour roll. All crossbows use 3 AP/5 base fatigue to shoot, +15 accuracy, and −3 per extra hex; reload is 4 AP/20 base fatigue. Weapon range, damage, penetration and load still distinguish the items. Authored attack-fatigue traits/perks apply to displayed final costs.

The previously repaired adjacent-friendly-rank firing rule remains. Trees and other intervening bodies still block the shot outright. BB projectile diversion, cover scattering, and allied stray hits are not implemented; there is no claim of complete ranged-system parity.

## Fatigue, timing and morale

Hits add five fatigue to the defender even when armour prevents HP loss; misses add two. Received fatigue is capped by the defender's capacity. A hit to a shield through the authored Split shield action also adds five. Automatic activation recovery is `max(0, min(capacity−15, accumulated−recovery))`, with recovery normally 15 and Damaged lung 10. It happens only once per round, so waiting never creates another recovery.

Live initiative is base initiative minus equipment load, accumulated fatigue and the authored Stoic penalty. Negative scores remain negative. A fighter who waited in the previous round gets their next score multiplied by 0.75, or divided by 0.75 if negative, then floored. Fleeing contributes −1000 to turn order. Scores are locked when the new round is built, before activation recovery. Equal scores retain the prototype's deterministic identity/seed/round tie-break; delayed fighters still return in wait order. These scheduling choices are disclosed rather than described as the commercial implementation's full scheduler.

Second wind now unlocks Recover: it requires nine AP and halves accumulated fatigue, rounded down, consuming the activation. It cannot be used after spending AP. AI checks whether it can actually recover before choosing that action, so an exhausted actor without the perk can still finish normally.

Effective Resolve includes the prototype's trait/perk/bond additions and strain/grief deductions. Negative morale multiplies it by 0.9/0.8/0.7; confidence does not raise Resolve. A check's ceiling is 95, with no 5% success floor. Adjacent non-fleeing opponents subtract three; adjacent non-fleeing allies add three only for negative checks. Failed negative checks drop one state; successful positive checks raise one state.

HP damage at least 15 triggers a negative check with difficulty `−40 × (1 − remainingHP/maxHP)`. Death and fleeing reactions use the reference's distance equations, adapted to a uniform prototype humanoid encounter value of 200 (separate from campaign XP):

- Ally death: `20 − value×0.035 + distance^2.4`.
- Enemy death: `−30 + value×0.04 − distance^3`, with +15 for the killer.
- Ally fleeing: `30 − value×0.035 + distance^3`.

An unengaged fleeing fighter gets a rally check at the start of their activation, with +2 difficulty per prior fleeing round, and rallies to wavering on success. Edge escape and victory by routing the whole enemy company remain prototype rules. There is no banner/rally skill, BB enemy-specific XP/threat catalogue, or full morale perk system yet.

## Compatibility and scope

Campaign schema 15/battle schema 12 add explicit `combat_pending`/`core_rules` flags. Old active fights and aftermaths retain the frozen 0.15 weapon catalogue and old calculations. Adoption occurs in camp, after settlement, without changing identity, items, health, money or training. Older damage migration remains independently deferred and validated. Malformed flags, turn scores and fleeing counters are rejected without mutating the live company.

The following remain authored or incomplete: layered armour capacities and whole-point rounding; personality/perk values; several melee costs/reaches; reaction and targeted special mechanics; terrain movement and withdrawal; strict firing lanes; background stat ranges; four-rank/two-talent/single-stat growth; wounds/scars; enemy composition and AI; campaign economy. The separate dynamic perk-tree work is not assumed to be integrated. Formula fixtures and simulation outcomes are evidence of implementation correctness, not proof of final build balance or parity with a commercial executable.

## Reference record

Implementation is original GDScript. No third-party scripts are included in the deliverable. Numerical equations were checked against the community-hosted game-script reference labelled 1.5.2.2, pinned at commit `162f498ac7c49b4c317bbf54718a595ecef6a65a` in [ninkjin/Battle-Brothers-Scripts](https://github.com/ninkjin/Battle-Brothers-Scripts/tree/162f498ac7c49b4c317bbf54718a595ecef6a65a): actor defence/surrounding/initiative/morale methods; skill attack and shield-impact resolution; character combat/morale constants; Shieldwall effect; quick shot, aimed shot, shoot bolt and reload actions; Recover perk/skill. The reference is a public mirror, not an official statement that every current game version has identical code.

Official corroboration: [Update 1.4](https://battlebrothersgame.com/update-1-4/) excludes stunned and ranged-armed opponents from surrounding; [Dev Blog 81](https://battlebrothersgame.com/dev-blog-81-progress-update-improvements/) describes ordinary shield-impact wear and melee-only surrounding. The prototype's stagger is distinct from a stun.
