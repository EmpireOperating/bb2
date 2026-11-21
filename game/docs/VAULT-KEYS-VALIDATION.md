# Vault key validation

Godot 4.4.1 stable, Linux, Prototype 0.38 plus the included dungeon prerequisites. Native tests run the actual 1440×900 application with isolated saves. The software renderer emits an unsupported VSync warning; final validation must contain no script errors or failed checks.

## Model and integration tests

| Suite | Checks | Failures |
| --- | ---: | ---: |
| vault_keys | 102 | 0 |
| dungeon_variety | 3,699 | 0 |
| dungeon_variety_journeys | 263 | 0 |
| dungeon_challenge | 2,166 | 0 |
| dungeon_challenge_compat | 22 | 0 |
| dungeon_tactics | 153 | 0 |
| battle_clock | 241 | 0 |
| battle_clock_world | 25 | 0 |
| procedural | 15,100 across 128 seeds | 0 |
| economy | 211 | 0 |
| recovery | 21 | 0 |
| career_edges | 17 | 0 |

Key checks cover key-first and vault-first knowledge, fog and marker preservation, independent maps, wrong keys, all-key availability without duplicates, actual world search completion, actual world battle/replay/settlement, no key on world retreat, real treasury fighting and retreat, enemy wear, chest traps/rewards, exact Save/Load and old-save adoption. All restore rejection checks require atomic failure.

Prepared headless journeys explicitly supply keys alongside their existing supplies, equipment and XP, then traverse, unlock, fight and loot normally. They complete a barrow and two complexes with twelve actual dungeon battles. These prepared fixtures are functionality checks, not economic progression evidence.

## Native UI

The complete native run passed 59 checks with zero failures and three actual battles (two overworld battles and one treasury garrison). The separate full-keyring journal run passed five checks with zero failures.

The vault-first scenario begins with a declared prepared company at the dungeon entrance. It inspects a locked door, records the missing key, saves/loads, leaves, travels through the normal UI to take an actual overworld contract, wins the matching key, returns to the dungeon, unlocks the door, fights the guards and opens the chest. It then saves/loads and revisits the emptied vault.

The key-first scenario begins with another prepared company in town, travels and wins an actual overworld battle, and checks that its named key does not reveal the dungeon or offer a journal navigation shortcut. A separately declared map-acquisition fixture calls the existing production discovery function to verify journal linking, fog preservation and continued door locking. This last map is a UI fixture, not a claimed earned map drop; actual map-battle settlement/replay is covered by `dungeon_variety_journeys`.

The small journal UI run explicitly fills the keyring to test page navigation and absence of shortcuts to unknown entrances. The journal and door inspection both close with Escape. The renderer was visually inspected for text fit and control placement.

## Limits and corrections

No fresh, unassisted multi-week key economy audit was run. Reward pacing (first eligible event, then every third) remains a design starting point. Existing dungeon difficulty and long-career results from the earlier Variety pack must not be presented as new key-system balance evidence. The full repository suite was not run.

An initial world-cache test stopped at the normal scout-sighting pause; the corrected driver resumes time before continuing the search. An initial native test unnecessarily selected/tried to travel to its current town and then could not reach the contract controls; the corrected driver skips travel when already there and fails immediately if the expected battle did not occur. Only completed, error-free final runs are included as validation.

All three patches applied in order to an untouched 0.38 checkout. All nineteen key-patch files matched the working source byte-for-byte. A cold Godot import reported no errors, and the clean tree independently passed the key suite (102 checks) and full prepared dungeon journeys (263 checks).

## Reproduce

From the Godot project root:

```sh
godot --headless --path . --import
godot --headless --path . --script tests/vault_keys.gd
godot --headless --path . --script tests/dungeon_variety.gd
godot --headless --path . --script tests/dungeon_variety_journeys.gd
```

Native checks require a display and a separate `XDG_DATA_HOME` so they cannot overwrite the player's save:

```sh
godot --path . --audio-driver Dummy --script tests/vault_keys_ui.gd
godot --path . --audio-driver Dummy --script tests/vault_keys_ui.gd -- --journal-only
```
