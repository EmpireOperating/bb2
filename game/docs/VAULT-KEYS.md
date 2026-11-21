# World-found vault keys

Keys name a dungeon and its vault floor. They never mark an entrance, expose terrain, reveal rooms, or provide a travel target. Dungeon maps retain their existing job: revealing entrances. The Keys & Vaults journal connects a carried key, a discovered entrance and an inspected locked door when each becomes known.

## Player rules

- The guarded side treasury on each floor of the three procedural burial complexes now has its own matching key. The dungeon name plus floor distinguishes keys for different vaults in the same complex.
- Keys come only from victorious overworld battles and successfully searched world discovery caches. Dungeon battles, dungeon chests, retreat and defeat do not produce them.
- The first eligible external loot event yields a key, then every third eligible event does so while any eligible keys remain. The source seed picks among unowned keys for unopened vaults. There are no duplicates; repeated world work can supply the complete finite set. This is an initial pacing choice, not a tested difficulty optimum.
- Key first: the company keyring records its name; the entrance remains unknown until a map, rumour or exploration reveals it.
- Vault first: click its sealed door to record it. The party stays outside. Continue on the main route or leave and return after finding the matching world key.
- Unlock & Enter requires that exact key and pays ordinary room scouting food/time. The door stays open permanently. Guards still need to be fought and trapped chests still need to be resolved.
- Keys are company keyring entries, separate from equipment and trade cargo. They cannot be equipped, sold or salvaged. They remain carried after use, including through retreat and Save/Load.
- The journal shows key possession, lock status and whether the entrance is known. View Entrance appears only for an already-known location and only when outside a dungeon; it selects the map marker without moving the party.
- Stairs, exits, main-route fights, final chambers, small-barrow caches and the original three landmark dungeons retain their access rules. No magic, new enemy faction or party scaling.

## Save compatibility

New supported companies use dungeon rules version 4. Version 1, 2 and 3 saves still load unchanged. Safe town burial rumours add the previous variety expansion to version 2 companies and adopt keys for version 3 companies. Previously entered vault rooms are grandfathered open; no visited room, claimed chest, enemy wound or named reward gets reset. Adoption refuses an active dungeon or pending encounter.

The keyring is stored inside the dungeon snapshot, not in the equipment inventory or economy schema. Its IDs are derived from the unchanged procedural site/floor/room identities. Validation rejects missing or invented records, mismatched possession/source fields, unsupported unlocked doors, impossible discovery state and invalid counters. Older builds cannot load version 4 dungeon saves.

## Implementation

`vault_keys.gd` owns finite key rewards, matching locks and keyring validation. `dungeons.gd` owns adoption and snapshot integration. Campaign commands control inspection, entry, world victory awards and refusal cases. `exploration.gd` awards a key opportunity only after marking a completed world cache spent. `vault_journal_view.gd`, `dungeon_view.gd` and the small main UI integration present those rules.

No dungeon geometry, enemy stats, ordinary/named loot rolls, prices, wages or world supply/recovery rules were changed by the key patch. Repeated settlement/search guards remain in the production callers. Keys do not enter the existing map discovery function.

## Integration basis

Baseline: `Battle-Brothers-2-Prototype-0.38.zip`, main file version 43, SHA-256 `1456a3538ca05692649233e33e1e84c3c164b00135c9d54b43c84bc54feab6f1` (73,760,802 bytes). This was the latest main retrieved at the start of this work. Its local baseline commit is `1945b41`.

The earlier Boss Tactics and Dungeon Variety packs were not present in that main archive. They were applied in a separate working tree. Variety's battle-settlement hunk was adapted to preserve 0.38's economy spoils handling. The pack includes both prerequisite patches and the separate vault-key patch; do not reapply prerequisites already integrated by the other chat. The final combined code was tested against 0.38. The main archive was not replaced or merged.

See `VAULT-KEYS-VALIDATION.md` for the exact results and fixture limitations.
