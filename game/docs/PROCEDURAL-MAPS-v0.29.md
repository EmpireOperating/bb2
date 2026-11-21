# Generated marches — merged 0.29

The isolated procedural-map pack was built on 0.27. Its generator, exploration, renderer, world and navigation changes are now reconciled onto delivered 0.28. The 0.28 combat, people, perk catalogue, weapon/armour catalogue, inventory and recovery modules remain unchanged. The campaign and UI combine both branches.

## Play

New company accepts a numerical seed; R rolls another. New games generate three towns, three camps and three discoveries on a 58×30 navigation grid. Terrain, town names/positions, roads, a river and two crossings vary by seed. Existing economy role IDs remain internal adapters; this is not an arbitrary-town-count generator.

Three modestly equipped founders start in the generated farming town. Recruit up to six living companions. The first job is Crossing Outlaws, with the 0.28 bandit-thug rules and 190-crown initial base payout. Generator version 2 places that camp earlier along the home-town trade route; saved version-one regions retain their original positions. Visible scout labels include enemy type/count, allowing the player to judge threats before contact. Opening placement bounds the actual road length as well as straight-line separation. Diagonal road corners use road cost for both movement and ETA, rather than accidentally sampling an adjoining rough tile. Opening placement bounds the actual road length as well as straight-line separation. Diagonal road corners use road cost for both movement and ETA, rather than accidentally sampling an adjoining rough tile.

Explore by clicking ground. Unknown roads, terrain, camps and towns remain covered by opaque fog. Contracts give a bearing without adding explored cells or revealing unknown camp icons. A nearby camp may already be visible through normal starting sight. Once a site is visible, select its icon and Set course to enter it.

Local rumours identify approximate search areas. Watchtowers reveal terrain when surveyed. Scouting costs one hour; searching costs two to four, depending on the site. Travel, supplies, recovery and nearby parties continue during this work. Contact cancels incomplete work without awarding loot. Completed caches cannot be harvested again after saving, reloading or camp reoccupation. The guarded cache requires its controlling camp to be cleared.

Clearing a camp protects its road for at least four calendar days. Reoccupation then requires another surviving, funded band to spend stolen food; stationed patrols still deter it. Destroying every band prevents further reoccupation in this slice. Physical caravan interception and external invading bands remain future work.

## Opening balance evidence

The current 32-policy sample uses 16 matching seeds with two approaches: three founders moving directly to the first job, or an affordable fourth hire plus a return to town for 24 hours of recovery after scouting fights. Both use real world-clock movement and legal combat AI, then return for supplies and attempt to buy/fit short mail with earnings. Survivors provision and rest through the end of day ten. No outcomes, damage, XP or money are injected. Route endpoints are known to the test policy; it does not measure human wayfinding.

| Policy | Contract wins | Company wipes | Survivors | Mail purchases |
|---|---:|---:|---:|---:|
| Three founders, direct assault | 12 / 16 | 3 | 31 / 48 | 12 |
| Fourth hire, town recovery | 13 / 16 | 1 | 42 / 64 | 13 |

Initial paths in this sample take 6.67–7.77 game hours. No surviving company has unpaid wages at the checkpoint. Death and failed contracts remain possible. The two policies change both party size and preparation, so their difference does not isolate one mechanic. This is a first-job/recovery/equipment-purchase loop followed by ten-day upkeep, not proof of multiple-contract progression or month-long balance. [Raw policy rows](opening-routes-0.29.json).

The native journey completes two actual battles, wins the camp contract, returns, purchases/fits mail, recovers, surveys/searches the watchtower and saves/reloads by day five. Map movement, hires, contracts, exploration and saves use real UI input. The mail purchase and fit invoke the production campaign methods. No stat/resource bonuses or forced wins are used.

![Earned layered mail upgrade](merged-upgrade.png)

![A searched discovery and the cleared opening camp](merged-discovery.png)

## Compatibility

Generated campaigns use schema 24 and generator definition 2; classic campaigns keep schema 23. Battle 20, personal pool 6, world economy 2 and overworld 1 remain. The reader distinguishes the delivered 0.28 schema-23 format from the isolated preview’s schema-23 format by its stored region, then validates every subsystem before committing state. Preview imports keep their original six-person roster, gear, geography and old ongoing-battle rules; recovery is adopted at camp. They do not become new three-founder games.

Normal saves retain `user://ashen-company-save.json`; the preview’s separate file is not automatically selected. Original 0.28 saves load through the usual F9 control. A new company is required for generated geography and the revised opening placement. Stored region definitions are loaded directly, never regenerated from seeds. Old saved battles continue with identical commands/RNG/casualties and settlement in the captured compatibility tests.

A newly exposed low-tier enemy case was fixed: families without a tier-one weapon select their lowest available tier before applying the thug loadout override. No encounter is left partly equipped. Saved ongoing battles are unaffected.

The original isolated design and evidence remain in [preview notes](PROCEDURAL-MAPS-PREVIEW.md); their version numbers, six-person starts and contract-marker behavior are historical. [Current validation](VALIDATION.md) lists only checks actually rerun on the combined build.
