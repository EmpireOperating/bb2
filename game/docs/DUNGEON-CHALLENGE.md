# Dungeon challenge integration for released 0.33

This change adds fixed expedition tiers, three physical undead bosses, distinct crypt battlefields, and persistent room decisions. It is based on the merged Godot 0.33 project, not an earlier prototype. No release number is changed; the integration owner retains control of merging and publishing.

Source archive: `Battle-Brothers-2-Prototype-0.33.zip`, Library version 36, SHA-256 `98e456f18f5674076d8cda08f2c18a966677aa0c4858272db9a92bb0f6a3ffcd`.

## Encounters

| Site | Prepared test fixture | Floors | Patrol / descent guards | Final encounter |
| --- | --- | --- | --- | --- |
| Blackbarrow | Six equipped fighters, about level 4 | 2 | 3 / 4; add one below first floor | Lord of Blackbarrow and five escorts |
| The Fallen Watch | Nine seasoned fighters, about level 6 | 3 | 6 / 7; add one below first floor | Watch Captain and eight escorts |
| King's Sepulchre | Twelve veterans, about level 8, heavy armour | 3 | 9 / 10; add one below first floor | Buried King and eleven escorts |

These describe the supplied test fixtures, not player recommendations or entry restrictions. Enemies do not scale when the company recruits, levels, retreats or returns. Layouts and optional routes can change the number of required fights.

Blackbarrow uses a mace-and-shield lord with infantry around pillars. The Watch Captain fires a heavy crossbow behind guards and spearmen in a gallery with cover. The Buried King uses a greatsword, layered heavy armour and Royal Sentinels; the central wall creates a narrow approach with routes around its ends. All use normal weapons, ammunition, fatigue, armour, line of sight and tactical AI. There are no spells, resurrection or stat potions.

## Room decisions

| Room | Choice | Direct cost | Persistent result |
| --- | --- | --- | --- |
| Trapped vault | Disarm | 2 × tier tools, 1 hour | Chest becomes safe to open |
| Trapped vault | Force | 15 minutes | Chest opens; fixed one-in-three injury risk |
| Collapsed passage | Clear with tools | 4 × tier tools, 1 hour | Permanent two-way shortcut to floor's final chamber |
| Collapsed passage | Dig | Half the living company in food, rounded up, 4 hours | Same permanent shortcut |
| Sealed alcove | Search | Scouting food cost, 2 hours | Hidden supply cache becomes available |

Normal hourly recovery, tools, medicine, wages and daily rations also apply while time passes. Force causes a nonfatal hit of 8 + 4 × tier and a two-day wound to the first active formation member. Normal wound penalties can further cap maximum HP and reduce skill; the journal records the actual immediate HP loss. The risk is chosen during generation, so loading cannot reroll it. A previous longer wound is not shortened.

All obstacles are optional. The original connected route remains available without spending tools. Opening a shortcut reveals its destination and draws a gold connection; it does not defeat the destination's guards. Choices and loot are separate actions. Unresolved traps and alcoves cannot be looted; completed choices cannot be charged twice. Retreat remains available with insufficient supplies.

## Rewards and supplies

| Final chest | Crowns | Food | Tools | Company ammo | Equipment |
| --- | ---: | ---: | ---: | ---: | --- |
| Tier 1 | 600 | 12 | 10 | 18 | One reserved named item |
| Tier 2 | 1,400 | 20 | 18 | 30 | One reserved named item |
| Tier 3 | 2,800 | 30 | 28 | 45 | One reserved named item |

Side vaults provide valuables and supplies, with the existing chance of a named item. Hidden caches provide ordinary supplies. Rewards are generated before entry and claimed once. Enemy equipment recovery and ammunition use the merged production rules.

## Persistence and compatibility

The inner dungeon schema is now version 2. Newly generated expanded-roster campaigns use it. Existing version-1 dungeon saves retain their exact layouts, encounters, loot reservations and enemy wear, including expanded companies saved in released 0.33. Older six-person campaigns continue to generate version-1 dungeons. Start a new expanded company to see all new encounters if a save already contains old dungeons.

The campaign's composed roster/named/dungeon/farm/patrol save wrappers remain unchanged. Existing crypt terrain remains unchanged. The new battlefield IDs are `crypt_barrow`, `crypt_gallery` and `crypt_throne`. Restoring version-2 dungeons requires expanded roster support. Older executables will not understand new dungeon saves. Changes to generated rosters, loot, obstacles or fixed enemy templates after this release need an explicit compatibility/version plan; these fields are reconstructed during restore.

Save validation reconstructs the correct generation and checks geometry, obstacles, resolution, loot, named rewards and enemy wear. Expanded validation uses the proper player/enemy slot counts rather than a six-enemy template. Retreat retains actual HP, armour, shields, ammo and carried weapons. Equipment identity remains stable across return visits.

## Validation and limitations

`tests/dungeon_challenge.gd` exercises seeded generation, fixed threats, reachable rooms, all decision branches, insufficient-resource rejection, both trap outcomes, replay determinism, invalid-save rejection, expanded battle positions, retreat/reengagement and full clears of all three tiers with actual tactical AI.

`tests/dungeon_challenge_compat.gd` loads fixtures exported by untouched released 0.33 code: active battle, retreat aftermath and outside camp. It verifies exact normalized snapshots and continuation. The fixtures are declared prepared companies; they are not user saves.

`tests/dungeon_challenge_ui.gd` uses native mouse/key input for travel, rooms, decisions, battles, rest, leave/return, treasure and F5/F9. Player battle decisions use the normal legal AI, and the application's normal loop settles combat. F9 is tested after changing crowns to prove that loading actually restored the saved state. `tests/dungeons_ui.gd` also covers native voluntary retreat after real damage and reengagement with the same enemies.

`tests/dungeon_choice_ui.gd` additionally exercises the force and dig buttons, disabled tool choices and native reloads with explicitly isolated room-arrival fixtures.

The expedition fixture supplies generated recruits, ordinary equipment and a provisioning budget. XP is granted in legal increments, then spent through normal growth/perk rules to reach levels 4/6/8. It does not edit combat stats, rolls, enemy HP, victory flags or rewards. Model trials place the company at the entrance to isolate dungeon difficulty; native journeys travel from town. These fixtures do not prove that the full recruitment/equipment/XP budget can be earned within the existing 30-day campaign.

The nine initial model trials (seeds 1, 2, 3 at each tier) cleared 8/9. Tier 1 cleared 3/3 with 4–6 survivors; tier 2 cleared 3/3 with 6–8; tier 3 cleared 2/3 with 6–7 survivors, and one expedition was wiped out after continuing through accumulated losses. Successful runs consumed net 52–99 / 128–205 / 200–242 food and 9–33 / 48–94 / 86–94 tools respectively. Net crowns rose 505–549 / 1,196–1,271 / 2,566–2,615, excluding equipment value and replacement/recruitment costs. This is an initial automated balance sample, not a measured human win rate. Raw fight and supply results are in `docs/dungeon-challenge-trials.json`.

Run with Godot 4.4.1:

```sh
godot --headless --path . --import
godot --headless --path . --script tests/dungeon_challenge.gd
godot --headless --path . --script tests/dungeon_challenge_compat.gd
godot --headless --path . --script tests/dungeon_challenge_trials.gd
# Native display; use a separate XDG_DATA_HOME to protect local saves:
godot --path . --audio-driver Dummy --script tests/dungeon_challenge_ui.gd
```

Inspect logs for `SCRIPT ERROR` or `ERROR:` as well as exit status. Existing merged-system regressions include `dungeons`, `combined_integration`, `named_integration`, `v032_integration`, `company_roster`, `roster_edges`, `roster_compat`, `ammunition`, `ammunition_perk_compat`, `farm_edges`, and `guards_edges`.
