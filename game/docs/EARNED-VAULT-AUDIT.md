# Earned vault hunt audit

Tested with Godot 4.4.1 on Prototype 0.40, Library version 45, plus the separate Boss Tactics, Dungeon Variety and Vault Keys patches. The source archive SHA-256 is `a8a284b519801bea0734e353f6f27d10eadb3e5ab5193ba2ed44acbfa82f22e5`.

This change adds observation, reproducible campaign policies, earned saves and native UI validation. A small presentation fix fits long battle headings before the round counter; visual inspection exposed the overlap. **It changes no production gameplay rules, prices, wages, enemies, rewards, key frequency or starting resources.** It does not merge the separate Expanded Region, Regional Recovery or Fading Tracks work.

## What worked

An ordinary company earned a matching first-floor key on day 10, built up through jobs, trade and small barrows, and reached its vault on day 24. Two assaults cost two mercenaries. After actual return trips, paid replacement hires and repairs, the third assault won on day 25. Six living mercenaries returned to town with 1,034 crowns.

The chest contained 656 crowns, 12 food, 6 tools and 10 ammunition. This particular vault had no named item. Across the three excursions, the company gained 237 net crowns after 15 in wages, 110 in supplies, 291 in equipment and 257 in replacement hires, offset by the chest and 254 in equipment sales. Ordinary trading between those excursions is outside that subtotal. Lost levels and experience are not assigned an invented monetary value: a positive cash result does not establish a good trade for two trained mercenaries.

Keys, opened doors, enemy deaths, damaged guard equipment and looted chests survived actual withdrawal, travel, recovery and JSON Save/Load. Every company crown reconciled, including world caches, dungeon chests, salvage, contracts, cargo, purchases and upkeep. No key changed terrain knowledge or dungeon discovery.

## Fresh-company results

Four fixed seeds start with three founders, 300 crowns, 24 food, 20 tools and the normal medicine/ammunition. Each runs until a successful vault return, a genuine company ending, or a 90-day limit. No run reached that time limit. The same seeds are run under two policies; these are eight runs of four worlds, not eight independent worlds.

| Seed | Baseline end | Baseline keys | Known-garrison policy end | Keys | Vault brought home |
| --- | --- | ---: | --- | ---: | --- |
| 1 | Day 31, wage disbanding | 1 | Day 31, wage disbanding | 1 | No |
| 71 | Day 52, wage disbanding | 4 | Day 52, wage disbanding | 4 | No |
| 592 | Day 41, wage disbanding | 4 | Day 25, 6 alive, 1,034 crowns | 3 | Yes |
| 789 | Day 49, wage disbanding | 3 | Day 49, wage disbanding | 3 | No |

The baseline waits for six people, sufficient protection and a substantial cash reserve before attempting a large vault. Its return decision can become too conservative after casualties. The matched control also permits a return to an already opened first-floor vault when the recorded surviving garrison is outnumbered by at least two, the company is healthy and it can cover the short trip. It uses enemy losses already observed in battle, never a hidden roster or a future roll. All other policy rules are identical.

That single policy change gives **0/4 versus 1/4 vault returns**. The other three final saves are byte-identical between policies. These are automated-policy outcomes, not human success rates or proof that other routes are impossible. The control demonstrates that the retreat loop can rescue a viable expedition; it does not establish broad economic balance.

## Keys and discovery

- First keys appeared on day 1 or 2 through actual overworld victories. Later keys also came from completed world-cache searches.
- The first key named an undiscovered dungeon in seeds 71 and 789. Its recovery changed neither fog nor dungeon knowledge. Seeds 1 and 592 had already seen that entrance during normal travel.
- The runs collected 1–4 keys over 3–11 eligible world loot events. There were no duplicate keys or unusable inventory items. The starting rule remains the first eligible event and every third event thereafter.
- The successful first-floor key came from an overworld battle on day 10. It was held for roughly two weeks before the company could exploit it. Earlier keys could point to deeper floors requiring more preparation.
- Dungeon destinations require a discovered entrance or an earned map. Frontier exploration chooses visible terrain adjoining fog without reading unknown dungeon positions. The policy never invokes burial rumours or the map-discovery function directly; real battle/chest settlement supplies any maps.
- This is still the compact three-town region. Normal trade routes reveal many nearby entrances; these runs do not establish search difficulty on the separate expanded map.

There is no evidence here for increasing key drops or reducing dungeon strength. The limiting factors were casualties, replacement spending, available paid work and policy choices. Keep key pacing for now; test the larger integrated region before making global economic changes.

## Native validation

The native earned journey passed **38 checks, zero failures and two actual battles**. One mercenary died in the withdrawal; the five survivors then returned through the real controls, recovered, cleared the vault and reached town on day 31 with 882 crowns. The late continuation has different decisions from the day-25 successful cohort run and is reported separately. Screenshots of recovery, the wounded garrison, the empty chest and the returned company accompany the evidence. The subsequent heading-only presentation fix passed a four-check native run and visual inspection; the long title now fits beside the round counter.

The native source is an exact earned baseline seed-592 day-29 save before its second vault fight: six mercenaries, 296 crowns, an unlocked door and the surviving garrison from the first attempt. It is reproduced by the baseline command below. No resources, equipment, XP, victories, positions or knowledge are added to prepare the UI run. This is a native continuation of an earned campaign, not a claim that all 29 earlier days were played through UI controls.

The native test performs the battle and retreat, travels to town, buys repair tools, rests for an actual day, returns to the dungeon, fights the remaining guards, opens the chest and carries the loot home. F5/F9 covers the active battle, retreat, paid recovery, reward and return. Actual input selects controls; legal production AI commands automate tactical turns. A wagon can overlap a town marker, so the driver selects an exposed part of that marker rather than its centre.

## Policy and evidence limits

The trade benchmark knows town positions and current remote market prices, as in the 0.40 economy audit. It pays all actual costs and cannot foresee future prices, NPC events or random combat results. This is optimistic economic planning, not proof that a first-time player can discover profitable trading routes unaided. Tactical play uses production AI, a casualty/health retreat rule on the player's turn, legal development/perk spending, actual purchases, recruitment and salvage. Readiness thresholds exist only in the test driver.

The frozen policy was established after exploratory runs exposed driver mistakes: failing to collect an already accessible chest, keeping weak recruit weapons indefinitely, not revisiting an already unlocked door, and testing retreat before the UI allowed a player turn. Exploratory runs are excluded from the table. Final runs and the known-garrison control use the same frozen implementation.

A separate declared continuation starts from the exact earned day-29 retreat save. Five survivors defeat the three remaining wounded archers and return to town. It is a diagnostic continuation, not another independent fresh-company result. Its financial report starts from that save's real balance.

## Reproduce

After applying the dungeon prerequisites and this audit patch, run from the Godot project root:

```sh
godot --headless --path . --import
godot --headless --path . --script tests/earned_vault_hunt.gd -- 592 90 baseline
godot --headless --path . --script tests/earned_vault_hunt.gd -- 592 90 adaptive --known-garrison
godot --headless --path . --script tests/earned_vault_return.gd
godot --headless --path . --script tests/vault_keys.gd
```

Repeat the first two campaign commands for seeds `1`, `71` and `789`. Reports, transactions, decisions, events and earned snapshots are written to `docs/vault-hunt/<policy>/<seed>/`.

The native test requires a display and an isolated `XDG_DATA_HOME` to protect player saves:

```sh
godot --path . --audio-driver Dummy --script tests/earned_vault_ui.gd
godot --path . --audio-driver Dummy --script tests/earned_vault_ui.gd -- --header-only
```

The two bundled native/continuation fixtures must exactly match the baseline outputs:

| Fixture | Baseline output | SHA-256 |
| --- | --- | --- |
| `tests/fixtures/earned-vault-door-592.json` | `baseline/592/vault-door-day-29.json` | `a9a6894fe89a660d37a373ed1402081bc4318633be3614a67423b41054885d0c` |
| `tests/fixtures/earned-vault-retreat-592.json` | `baseline/592/vault-retreat-day-29.json` | `82bb94041e7acd5cb79de486bd5409a4ef721a725057e4ee4b1523077dcb6528` |

The eight final campaign runs passed 2,022 checks with zero failures. The diagnostic earned continuation passed 26 checks; the existing key suite passed 102. All three non-completing seeds produced byte-identical final saves between policies, and seed 592 has an identical earned first-key checkpoint before its policies diverge. The final native journey passed 38 checks. Full final logs and saved states are included; aborted exploratory drivers are not validation evidence.
