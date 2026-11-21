# Fading footprints and scouting

This is a separate overworld feature branch on top of the Regional Recovery integration pack. New preview companies have short-lived bandit footprints and a scouting stance. The main integrated Library build is not replaced by this pack.

## Player behavior

Moving bandit parties leave small clusters of boot prints along the ground. More impressions indicate a larger group. Clicking a nearby cluster gives an approximate size and the direction the party was moving **at that point**, without identifying its camp or current position.

| Age | Appearance and information |
| --- | --- |
| Under one game hour | Clear impressions; rough size and direction are readable. |
| One to two and a half hours | Opacity and detection range decrease continuously. |
| Two and a half to four hours | Faint impressions; group size is no longer reliable. |
| Four hours | Deleted, including the map click target. No permanent trail line or map marker remains. |

Size bands are **1–3**, **4–6**, and **7 or more** people. They describe living members when the marks were made. A party losing members or being defeated later does not rewrite the old prints.

Normal travel notices only nearby impressions. **SCOUT** immediately reduces travel to 70% pace. After **15 minutes of actual surface-world time**, the company can notice prints farther away. Paused toggles cannot give the bonus. Turning scouting off cancels accumulated search effort. Waiting to search is valid, and the prints keep ageing while the company waits. Scouting does not extend their lifetime, reveal terrain, enlarge enemy sight or locate a camp.

Darkness and age reduce readable range. Fresh daytime maximums are 42 world units normally and 72 when scouting is established. Both shrink as the marks fade. These are tuning values for the first pass, not a claim that the hunt difficulty is already balanced.

Wrecks and farm damage can remain as evidence of an attack. In tracking-enabled games, inspecting them no longer grants a camp name, a permanent line to the camp, or a FOLLOW TRACKS TO CAMP button. Search for surviving footprints instead. Ordinary known places, discovery clues and contract targets retain their existing behavior.

## Clock and persistence

The footprint clock advances once per real three-minute overworld simulation step, including rest and background expedition movement. Pausing freezes it. Tactical battles retain the integrated game's frozen campaign time. Fast-forward changes wall-clock pace, not trail lifetime. Inspecting, selecting, changing stance and saving do not refresh a mark. Loading preserves its age and search progress; expired prints cannot return.

Only actual movement emits marks. Stationary raiders do not keep stamping fresh tracks beneath themselves. Position jumps cannot manufacture a connecting trail. Emission is spaced roughly twelve world units apart. Marks have no owning-party or camp reference: their payload contains position, heading, broad group size and creation tick. They show local observed movement, with no automatic pursuit or connected route overlay.

Storage is capped at 512 active clusters, and expiry prunes old marks and emission cursors. All visible marks must be on explored ground and within current inspection range; panning the camera over distant explored land does not reveal its tracks.

## Use the preview

Extract the source ZIP, open `battle-brothers-2/project.godot` in **Godot 4.4.1**, and start **New company**. Use SCOUT below the Save/Load buttons. Approach nearby footprints and click them. Time can be paused to read a trail, but the fifteen-minute scouting search period requires running the world.

Preview save: `user://ashen-company-fading-tracks-preview.json`.

Old saves keep their old capabilities, including their historical evidence rules. They do not silently acquire fading tracks or scouting. Starting a new preview company enables the feature.

## Integration

Base: `25d54b63b3c6011c71f7f60efc6acd22787af7c2` (Regional Recovery). Branch: `world/fading-tracks`.

The recovery preview itself is based on the reconciled expanded-map port over Prototype 0.36. The tracking-only patch expects that source state. Newer main-build economy, goods, contract, dungeon and progression work must be preserved during integration. This preview is a runnable reference, not a replacement for later integrated source.

- `src/footprints.gd` owns emission, opacity, visibility, age, stance and validation. `src/footprint_view.gd` owns the boot glyphs and detail panel.
- `Overworld.step` advances the component and records each living band's actual before/after movement. Both foreground and background paths use that shared step. Background time cannot build surface scouting focus.
- `Overworld.travel_pace()` is shared by movement and ETA. Normal pace remains unchanged. No perks or combat statistics were altered.
- This branch adds optional `fading_tracks` as **argument 14** to `Campaign.setup`, after regional recovery. Merge by the flag's meaning if another branch has appended its own arguments; do not assume positional indices match newer main builds.
- Tracking is enabled before Traffic and Farm setup so they derive the same evidence behavior. It requires living bands and physical trade, but does not require farms, regional recovery, camp renewal or the larger map; the older three-town configuration is explicitly tested.
- The campaign save wrapper is unchanged. **Overworld version 3** adds `tracks_base_version` (1 or 2) and the version-1 `tracks` component. Camp-renewal capability is derived from that base version, not the outer version. If another branch has used overworld version 3, reconcile the schema instead of silently dropping either component.
- Traffic and Farm's `fading_tracks` flags are derived from the restored overworld; they are not independent saved flags. Older saves therefore retain their former evidence rules.
- Component validation rejects expired/future-dated marks, invalid coordinates/headings/groups, malformed counters, unknown cursors, impossible search focus and stray capability fields. Campaign loading remains atomic through temporary objects.
- Changing the hard lifetime in a later release needs an explicit save-compatibility decision for marks saved under the former lifetime.

## Evidence

**829 assertions passed, zero failures, across 12 suite runs.** Current logs and totals are in `tracking-validation/summary.json`. They cover model behavior, native UI and compatibility. Historical recovery and expansion validation remains separately named in the source tree; it is not newly rerun evidence for every feature.

The targeted model checks cover natural emission, continuous fading, lost size information, four-hour deletion, no refresh on inspection, save/load, invalid-save rejection, scouting travel and ETA, the fifteen-minute search requirement, paused-toggle resistance, fast-forward equivalence, old-save behavior and the three-town configuration. Edge checks cover actual freight capture, no permanent wreck/farm lead, background/rest ageing, zero-time battle settlement, broad group categories, stationary parties and position jumps.

Native `fading_tracks_ui.gd` uses real mouse and keyboard events to toggle scouting, click boot prints, save/load fresh and faint trails, watch their expiry, travel while scouting and load an older save. Footprints are produced by normal band movement. Company placement, observer supplies and camp clearance are explicitly declared fixtures to make the same marks easy to inspect as they fade; those are not ordinary new-company resources or a claimed unaided hunt.

A paired seed-1 observation runs from day 1 through day 37 with company survival resources only. With normal travel, removing the new tracking component leaves **exactly the same campaign snapshots** as the tracking-disabled recovery control. Food, councils, NPC decisions and movements therefore remain unchanged in that tested scenario. Marks remain bounded and younger than four hours. The run is one paired seed, not a broad balance survey; it does not resolve the prior recovery economy's shortage findings.

`tracks-native-fresh.png`, `tracks-native-fading.png`, `tracks-native-faint.png` and `tracks-native-gone.png` show the same trail at successive ages. `tracks-native-scout-travel.png` shows the native scouting journey. Expanded-map regression captures use the `tracks-expanded-` prefix. All captures are native Godot rendering.

## Reproduce

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script tests/fading_tracks.gd
godot --headless --path . --script tests/tracking_edges.gd
godot --headless --path . --script tests/tracking_runs.gd
```

Run `tests/fading_tracks_ui.gd` and `tests/expanded_region_ui.gd` on a native display with an isolated `XDG_DATA_HOME`. Their screenshots are written to `docs/`. The validation summary names the compatibility suites; the packaged logs preserve their output with trailing whitespace trimmed.

This first pass covers bandit footprints and scouting. Weather-driven erosion, other species' tracks, camp observation and scouting perks are not implemented here.
