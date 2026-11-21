# Validation — company ammunition 0.27

44,048 assertions, zero failures in final recorded runs. Counts include repeated assertions, not unique scenarios. Godot 4.4.1 on Linux.

The base is the complete delivered 0.26 source, including the free-roam overworld and all ten weapon groups. The ammunition integration pack was reconciled from its 0.25 base. Conflicting fixture filenames were kept separately so neither set of historical evidence was overwritten.

| Suite | Checks | Evidence |
|---|---:|---|
| `ammunition` | 291 | Five ammo types, paid hits/misses, reload, empty refusal, partial refills, purchases, salvage conservation, retreat, malformed saves, 12 real fights and nine 0.23–0.25 continuations |
| `ammunition_perk_compat` | 81 | Three actually delivered 0.26 careers with live paid hammer/dagger effects: exact imported fields, combat, old settlement, camp adoption and zero-reserve saves |
| `ranged_perks` | 7,513 | Ranged math, careers, physical ammunition, updated refill cost and historical saves |
| `hammer_dagger` | 94 | Both controllers/offhands, exact costs/damage, chain/debuff timing, AI, preview purity and older continuations with explicit ammo adoption |
| `axe_mace` | 73 | Existing perk arithmetic, stagger, AI, live saves and older settlement with explicit ammo adoption |
| `equipment_economy` | 356 | 26 weapons, stock, purchases/sales, merchant accounts, 15 fresh fights, checkpoint replay and old campaigns |
| `overworld` | 1,339 | Routes, terrain, crossings, physical services, pause/clock, pursuit/evasion, encounters, escorts, camps and corrupt saves |
| `perks` | 134 | Shared progression, costs, pools and saves |
| `turns` | 3,607 | 24 ordinary campaign fights, 12 paired map/objective continuations and three old saves |
| `background_generation` | 29,970 | 7,200 people, ten groups, independent stats/stars, 32 earned-point routes and old populations with explicit ammo migration |
| `overworld_perk_compat` | 33 | Three delivered 0.25 spatial companies: original fields, movement and combat preserved, plus documented supply/refill adoption |
| `double_grip` | 445 | Both controllers, all weapons including bolas, damage exceptions and old continuations |
| `ammunition_ui` | 52 | Native purchase, partial refill, five paid ranged attacks, reload, aftermath and exact F5/F9 |
| `hammer_dagger_ui` | 37 | Native perk buying, real travel, paid hammer/dagger actions, comparison and two-AP follow-up after reload |
| `overworld_ui` | 23 | Native free travel, mid-route save, scouts/contact, battle, return to town and resupply |

The ammo model tests include 12 actual campaign battles, nine historical continuations and a captured 0.25 mid-route save. The three additional 0.26 captures use legally trained generated careers and ordinary paid combat commands; each has an actual Swift Stabs chain or Deep Impact effect active. Older battles preserve their original loot/settlement before adopting ammo refill at camp. Current save tests include zero reserves, incomplete bundles and loaded crossbows.

Native tests use real input and the production handlers. Ammo and perk journeys explicitly declare equipment, XP or positioning fixtures. The separate overworld journey uses normal travel/contact and legal combat AI, without forcing victory. Screenshots were inspected at 1440×900 under Mesa; the known unsupported-VSync warning is nonfatal.

Ammo supply, reserve, loot and refill accounting is shared by bows, crossbows and throwing weapons. One-to-one/three-to-one costs, round-robin whole-round partial replenishment, atomic refusals and single settlement are checked. Existing market ledgers stay exact; newly generated markets can stock bolas.

The original `battle.gd`, `perks.gd`, perk catalogue and `overworld.gd` remain byte-for-byte identical to delivered 0.26. Production changes add ammo inventory/economics/UI and the basic bolas definition/drawing. Campaign schema advances to 22; battle 19, overworld 1 and personal pool 5 remain.

The prior 432-fight hammer/dagger matrix was not rerun. Its records remain historical in [0.26 validation](VALIDATION-v0.26.md). Earlier archival company/world test limitations remain as documented there. Current starting reserves, prices and bolas damage are prototype tuning, not established final balance. Bolas do not entangle.

Archive CRC, clean extraction/import and normal-start smoke checks pass. No Godot cache, player saves or temporary tooling is included. This is a Godot source project; native executable exports were not built.
