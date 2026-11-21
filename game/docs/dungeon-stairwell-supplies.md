# Stairwell supply caches

Newly generated V6 garrisons and royal crypts have one ordinary supply cache at
each non-final floor's guarded descent. The company must clear the guard before
claiming it. It can descend without looting and return for the cache later.

| Site threat | Crowns | Food | Tools | Company ammunition |
| --- | ---: | ---: | ---: | ---: |
| 2 | 120 | 12 | 16 | 16 |
| 3 | 180 | 18 | 24 | 24 |

The payment uses the existing search command and its normal 15 minutes of time,
upkeep, repair and healing. It is not an automatic refill of equipped weapons.
No medicine, named equipment, keys, maps, or new dungeon locations are awarded.
All stairwell crowns combined are below that site's final chest payment.

The map marks an available cache as **SUPPLIES**. Separate **TAKE SUPPLIES** and
**DESCEND** controls let the player choose. Claimed caches show **LOOTED** and
remain empty through Save/Load, withdrawal, paid town recovery, and return.
Taking supplies does not complete the dungeon or unlock a treasury.

## Compatibility

V6 adds loot after the frozen V5 themed generator finishes each floor. It consumes
no random draws. Geometry, terrain, guard rosters, enemy stats, optional vaults,
named rewards, final chests and key assignments are unchanged for the same seed.
Small mounds and the three original landmark dungeons receive no new caches.

V1–V5 saves retain their original generation and loot. Loading an existing V5
campaign does not insert caches or replace rooms. Fresh V6 campaigns receive them;
an explicitly expanded V2 campaign receives them in its newly generated procedural
sites while retaining its three original dungeons. There is no forced save migration.
Immutable reward validation rejects forged cache contents and invalid claims.

## Integration

Built against `Battle-Brothers-2-Prototype-0.43.zip`, Library version 48, with the
previous dungeon packs and earned economy audit integrated locally. The original
archive and release branch are untouched. The separate integration pack contains
the feature delta and optional prerequisite patches for the other merge chat.

## Reproduction

Use Godot 4.4.1 and import the project before native UI tests. Mechanics tests:

```sh
godot --headless --path . --script tests/dungeon_supplies.gd
godot --headless --path . --script tests/dungeon_themes.gd
godot --headless --path . --script tests/vault_keys.gd
godot --headless --path . --script tests/expedition_journal.gd
godot --headless --path . --script tests/dungeon_economy_accounting.gd
```

Fresh career comparisons use the same test driver on separate V5 and V6 source
trees. Never change a saved generation number or insert caches into a V5 save to
simulate a new campaign. Drivers start with the ordinary three founders, 300
crowns, 24 food and 20 tools. They use actual contracts, travel, shops, wages,
food, repair, ammunition, combat outcomes, recruitment, and production Save/Load.
They observe disclosed destinations and room connections, not hidden rooms.

```sh
godot --headless --path . --script tests/dungeon_supplies_careers.gd -- 592 90 cache-v6
godot --headless --path . --script tests/dungeon_supplies_garrison.gd -- 592 90 garrison-v6
godot --headless --path . --script tests/dungeon_supplies_return.gd -- 592 90 return-v6
```

The main driver tolerates one casualty in larger dungeon fights, withdrawing at
two or below 60% of starting HP. The garrison sensitivity driver keeps first-loss
withdrawal in royal crypts. The return sensitivity driver reproduces the prior
conservative opening through day 34 and permits the second loss in garrisons
from day 35, targeting a previously observed earned departure. All three plan a
withdrawal at their first cleared stairwell, then attempt ordinary recovery and
later returns. Their policies, failures and successful claims must be reported
together; these are automated scenarios, not human playtests or general balance
proof. Prepared mechanics fixtures are reported separately from earned careers.

Completed results and native UI evidence are included in the integration pack's
validation report.
