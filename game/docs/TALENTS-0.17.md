# Talents and progression — 0.17

New companies and recruit pools receive three distinct talented attributes. Each chosen attribute has a 60% chance of one star, 30% of two and 10% of three. No background excludes talents: a farmhand can have ranged potential, and a poacher can develop into a front-line fighter. Existing equipment viability rules only change equipment, never reroll the person.

## Growth

| Attribute | No talent | One star | Two stars | Three stars |
|---|---:|---:|---:|---:|
| Health | 2–4 | 3–4 | 4 | 4–5 |
| Stamina | 2–4 | 3–4 | 4 | 4–5 |
| Resolve | 2–4 | 3–4 | 4 | 4–5 |
| Initiative | 3–5 | 4–5 | 5 | 5–6 |
| Melee skill | 1–3 | 2–3 | 3 | 3–4 |
| Ranged skill | 2–4 | 3–4 | 4 | 4–5 |
| Melee defence | 1–3 | 2–3 | 3 | 3–4 |
| Ranged defence | 2–4 | 3–4 | 4 | 4–5 |

All ranges are inclusive, with uniform integer draws. Stars shift the minimum upward; three stars also add one to the maximum. A two-star stat always receives its normal maximum. No stars are needed to select a stat.

The generator pre-rolls ten offers containing all eight gains using an independent deterministic stream. Offers are persisted with identity and validated on load. The population RNG and combat RNG are unaffected by browsing or training. Finishing a level consumes its entire offer, including unselected stats; the next level exposes its next saved offer.

Three distinct picks form one transaction. A partial selection, duplicate attribute, unknown attribute, wrong phase, fallen mercenary or already-spent level is rejected without mutation. Multiple earned levels are trained oldest first. Current and maximum HP both increase by the health gain; old missing HP and wounds remain. No stats or perks are automatically chosen.

At level 11 there are ten earned training levels, up to 30 selected stat gains, and ten earned perk points. The existing four perks consume their own points; the rest remain banked. Expanded personal perk trees and post-11 veteran advancement are separate future work.

## Starting attributes

These inclusive ranges apply only to new generated populations. Starting attributes are rolled independently of talents. Age remains part of identity and starting equipment but no longer adds hidden skill/defence bonuses outside these ranges.

| Background | HP | Stamina | Resolve | Initiative | Melee | Ranged | M. defence | R. defence |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Militia | 50–60 | 93–105 | 33–45 | 100–110 | 52–62 | 38–47 | 2–7 | 2–7 |
| Poacher | 50–60 | 93–100 | 25–45 | 100–110 | 49–57 | 47–49 | 0–5 | 0–5 |
| Woodcutter | 60–70 | 100–115 | 30–40 | 95–105 | 50–60 | 32–42 | 0–5 | 0–5 |
| Deserter | 50–60 | 90–100 | 20–30 | 95–105 | 52–62 | 32–42 | 3–8 | 0–5 |
| Caravan guard | 55–65 | 95–110 | 35–45 | 100–110 | 50–60 | 35–45 | 2–7 | 0–5 |
| Farmhand | 62–70 | 100–120 | 28–37 | 100–110 | 47–57 | 32–42 | 0–5 | 0–5 |
| Gravedigger | 55–65 | 90–105 | 40–50 | 95–110 | 47–57 | 32–42 | 0–5 | 0–5 |
| Outrider | 50–60 | 95–105 | 30–40 | 105–120 | 50–60 | 45–60 | 0–5 | 2–7 |

Militia, Poacher and Farmhand follow the pinned BB background ranges. The other five are authored variations around that baseline. Existing personality modifiers, scars, morale, weapons and shields still modify effective combat properties as described in the combat notes. These ranges do not establish equal recruit value or full commercial-game balance.

## Campaign XP pacing

The thresholds are **0, 40, 100, 180, 280, 400, 550, 730, 940, 1180, 1450 XP** for levels 1–11. The first four thresholds deliberately retain existing earned ranks.

A surviving participant receives 20 battle XP, 10 more for victory, and 5 per kill up to three credited kills. Completing the contract adds 10 XP to its surviving participants. Retreat does not award battle XP. XP ledger keys prevent duplicate settlement or reload rewards. These are the existing prototype awards; they are not BB's kill-value/group-sharing algorithm.

A first won clearing contract gives a survivor **40–55 XP**, enough for level 2 and its first three picks. Two wins give 80–110 XP, reaching level 3 for a productive fighter; three wins guarantee level 3 for a survivor of each. Level 4 needs 180 XP, so four wins with sufficient kill credit or further service. The 30-day scenario is an early-level slice. Level 11 is implemented and tested with declared XP fixtures, not presented as a naturally achieved result from this short campaign.

## Save compatibility

Campaign schema 16 adds `growth_pending`; individual records store `growth_version`, ten `growth_offers`, ten `training` rows and any `legacy_training`. The existing flat development history remains for older health-conversion accounting. Battle schema stays 12; combat calculations are unchanged, and its validator now accepts all four currently defined perks and the higher trained-stat/initiative ranges needed by old high-stat records.

Old camp saves retain XP, stats, HP, previous talents, history and gear. Missing talents are filled to three using identity-derived randomness; existing talents are never removed or rerolled. Older multi-stat migrations that already have more than three talented attributes keep them. Old one-choice levels retain their exact awarded gain, and each can be completed with two different additional stats. Those catch-up rolls follow the new growth rules.

An old ongoing fight or aftermath defers growth adoption. The frozen 0.16 engines and their older dependencies retain old XP/level rules through settlement. Only at camp are future offers and catch-up choices created. Re-saving while pending preserves the same fight and reward result. Frozen 0.16 files match the delivered sources except dependency paths pinned to frozen copies.

## Reference and limits

Original GDScript implements the mechanics; downloaded third-party scripts are not shipped. The numerical reference is the public mirror `ninkjin/Battle-Brothers-Scripts`, commit `162f498ac7c49b4c317bbf54718a595ecef6a65a` (labelled 1.5.2.2), rather than a claim about every current commercial build:

- [Talent distribution, saved rolls, HP increases and offer consumption](https://github.com/ninkjin/Battle-Brothers-Scripts/blob/162f498ac7c49b4c317bbf54718a595ecef6a65a/scripts/entity/tactical/player.nut), `fillTalentValues`, `fillAttributeLevelUpValues` and `setAttributeLevelUpValues`.
- [Attribute gain ranges](https://github.com/ninkjin/Battle-Brothers-Scripts/blob/162f498ac7c49b4c317bbf54718a595ecef6a65a/scripts/config/character.nut), `AttributesLevelUp`.
- [Base background ranges](https://github.com/ninkjin/Battle-Brothers-Scripts/blob/162f498ac7c49b4c317bbf54718a595ecef6a65a/scripts/skills/backgrounds/character_background.nut), plus `militia_background.nut`, `poacher_background.nut` and `farmhand_background.nut` in that directory.

The prototype keeps its own XP curve, background selection, unlimited talent eligibility, personalities, four placeholder perks, campaign length, injuries and economy. Layered armour and the established 0.16 combat rules remain. Full endgame tuning needs a longer campaign and expanded perk choices.
