# Camp reconnaissance and finite camp defenders

Isolated branch `world/camp-reconnaissance`, based on fading-tracks commit `342b249cfca496c010e0b1adcef1318bd95d78cb`. This is a separate integration slice. It does not replace the main build or merge the other chats' later economy, contracts, progression, perks or dungeon work.

## Player behavior

Select a discovered camp and move within sight, at most 160 world units away. **Watch camp** stops travel and advances the ordinary world clock. It does not grant stealth: normal bandit vision, pursuit and contact still apply. Night sight is shorter and can end the watch. Escorting prevents a watch.

- After 30 game minutes, the report estimates no defenders, 1–3, or 4–6. It never exposes a precise camp counter.
- After one game hour, it identifies the enemy grades actually present: thugs, outlaws, raiders and/or veteran deserters. Counts and types have separate observation times.
- Continued observation refreshes the report every further half-hour.
- Physical departures and arrivals visible from the watch position receive dated, approximate-size messages. A newly recruited party assembling at camp has a distinct message. A party fighting guards at camp is still physically present; that is not reported as a departure.
- Stop watching, travel, rest, enter an encounter or dungeon, or lose sight, and information stops updating. Old reports persist, including across unseen clearance and reoccupation; a new watch must establish the new situation.
- Pause grants no progress. Save/load preserves partial observation, report timestamps and last witnessed movement. Background rest/expedition time ages information but cannot perform a watch. Tactical battles retain the existing frozen campaign clock.

No extra watch fee or ration deduction was invented. Ordinary midnight wages/rations and elapsed world time are the cost. The footprint scouting stance remains independent: it still slows travel to 70%, has its own 15-minute search period, and cannot preserve footprints beyond their four-hour lifetime.

Camp map labels, clear-contract danger summaries and council/trade camp summaries use dated knowledge instead of a live camp defender/store readout. Generic trade/security news and the existing visibility of roaming bands remain in place; this is not a replacement for the entire information system.

## Actual battle membership

The previous camp encounter roster and its field party were separate generated forces. With this capability enabled, the existing full-camp population is divided into permanent residents and the actual field band. Residents equal the original camp count minus its field-party capacity. A fresh ford camp therefore has one resident plus its two real roaming bandits; it is a three-enemy fight only while they are home. Stronger camp roles retain more residents.

A living field party physically within 10 world units of its own camp joins its defenses, except while already fighting town guards. A departing party is absent from the camp battle. A returning party brings only its living members and current wounds. Residents and field members retain their respective existing enemy grades. The tactical limit remains six enemies; no combat formulas or player abilities were changed.

Both direct assaults and clear-camp contracts use this shared roster and the eliminate/rout objective. Road bounties, escort encounters, recover-cargo contracts, dungeon battles and earlier-save camp rules keep their existing paths. An empty but uncleared camp can be claimed without manufacturing defenders.

Camp-battle retreat settles resident casualties and field-party wounds/deaths back into those exact rosters. Dead residents do not respawn on the next assault. Dead field members remain in the band's fallen record; the existing paid training system can supply new identities/replacement parties. Existing food-funded camp threat growth may add resident slots, preserving previous losses. Reoccupation creates a new resident roster for the new occupation.

Camp loot and named-item chances still use the existing occupation-specific reward promise. Watching, leaving, returning or saving cannot reroll it. Named-drop and duplicate-reward regressions remain covered by the living-camp tests.

### Deliberate first-pass limits

- No new concealment, suspicion meter, weather, ranged observation perks, ambush deployment, siege or mid-battle reinforcement system.
- The world clock is frozen during combat, so an away party cannot return during that tactical battle.
- Camp destruction retains the existing dispersal/removal of its away party. Those away members are not spawned as tactical kills or loot; persistent homeless bands are a future feature.
- Resident casualties persist, but residents have no new healing/replacement service. Existing paid field-party care/recruitment remains unchanged.
- The weaker windows are intentional. Tests establish mechanics and persistence, not final difficulty or economic balance.

## Integration and save contract

`Campaign.setup` adds the optional fifteenth argument `camp_reconnaissance=false`, immediately after this branch's `fading_tracks`. Enable only after camp lifecycle setup. The feature requires living camps, fading tracks and progression version 1. Merge by argument meaning if the destination branch has added other flags; do not blindly append by position.

New component: `camp_recon`, version 1. The campaign wrapper remains version 33 and the overworld wrapper remains version 3 in this preview. It contains:

- `garrisons`: occupation-keyed resident strength and persistent health fractions.
- `reports`: separately dated approximate counts, enemy grades, witnessed movement and last observed occupation.
- `watch`: target occupation, accumulated time, previous physical home party and latest known party identity.
- `engagement`: the exact resident/field slot mapping frozen for an active camp battle.

Restore validates candidate components before assigning campaign state. It checks occupancy records, health/capacity, report bounds/times/grades, watch context and camp battle membership. Older saves lacking this component retain their previous camp rules; they do not silently adopt reconnaissance.

Main integration hooks are in `campaign.gd`, `bandits.gd`, `overworld.gd`, `campaign_balance.gd` and `main.gd`. `CampaignBalance.equip` has optional source-index/source-kind arguments so a field member retains its field grade while occupying a camp battle slot. Its default path is unchanged.

Preview save: `user://ashen-company-camp-recon-preview.json`. Choose the integrated release's title and save policy during the merge. Start a new company to enable this slice in the standalone preview.

### Small existing patrol fix

The paired observer exposed a pre-existing instant-rest ordering error in `regional_recovery.gd`: a new incoming shipment could be queried before its physical wagon was synchronized. `patrol_goal` now ignores that shipment until its wagon exists. The same error appeared in both feature and control runs before the fix. A targeted regression and the repeated long run cover the correction. Preserve an equivalent fix if the destination branch already has one.

## Validation and evidence limits

See `recon-validation/summary.json` for exact final suite results and logs. Runtime: Godot 4.4.1 stable. The targeted suites exercise timed estimates, types from actual rosters, witnessed departures/returns, partial observation saves, remote stale reports, home/away tactical counts, retreat losses, contract/direct settlement, empty camps, paid replacement parties, reoccupation, day/night visibility, guard engagement, old-save preservation and malformed-save rejection.

Three paired observer seeds (1, 7, 27) run through day 16. Only company survival crowns/rations are supplied. With no reconnaissance or combat actions, removing the new component yields the exact tracking-only campaign snapshot each day; food and council accounting also hold. This establishes passive isolation, not world balance. `recon-observation.json` records the runs.

The native UI journey uses ordinary seed-1 founders and gear. It declares an initial company approach position and home-rest fixture to make the watch reproducible. Actual button/mouse/keyboard input starts/stops observation, saves/loads mid-watch, watches a real AI departure, physically approaches the camp, deploys against its one remaining resident, completes a legal tactical-AI victory and reloads the clearance. No tactical result is injected in that UI journey. Damage/outcome fixtures used in model-only casualty tests are explicitly marked in their source.

Reproduction:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/camp_recon.gd
godot --headless --path . --script tests/recon_transitions.gd
godot --headless --path . --script tests/recon_edges.gd
# Requires a real native display or Xvfb, with isolated user data:
godot --path . --script tests/camp_recon_ui.gd
```
