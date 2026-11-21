# Expanded region preview

An isolated `world/expanded-region` branch, based on living-camps commit `43e7ab894fc7bf76443725131057c2f429facdae`. Start a new company to use the larger region. The preview saves to `ashen-company-expanded-region-preview.json`; it does not replace another build's save.

## Playable changes

The world is 116 × 60 cells, twice the width and height of the earlier 58 × 30 map. Six towns have independent recruit pools, merchant books, food stocks, farms, councils and physical patrols. There are ten to twelve camps: six district camps, two camps on connecting trade roads, and two to four remote wilderness camps. Six ordinary discovery sites reuse the existing exploration actions. The three existing dungeon entrances still generate near the western towns; this slice does not add dungeon content.

The generator combines two independently seeded versions of the existing district generator, connects them with two trade roads, and adds forest/hill wilderness to the north and south. This deliberately retains the proven town and road structure. It is not yet an unconstrained continent generator or a new biome system. Cross-district roads carry four additional directed caravan routes, for ten routes in total. Paths, travel costs, fog, moving parties and contacts use world coordinates throughout.

Left-click ground to travel. Use the mouse wheel or −/+ buttons to zoom from 50% to 150%; middle-drag, WASD, arrows or on-screen arrows pan. Home or COMPANY follows the company again. Space pauses; right-click stops the journey. The map is clipped inside its viewport. Panning and zooming neither advance time nor reveal fog. At 50% the whole region fits; zoom in for names and local activity. Six farm/guard tabs and paged trade/council reports expose the new towns without overflowing the panels. Reports paginate known locations only.

Camps use the existing tactical archetypes through explicit role mappings, preserving the new camp's own identity for contracts, losses and loot. Every occupation keeps its own hidden named-item roll. Direct assaults and camp-clear jobs settle through the existing reward system. Camp expansion is now local: a funded mature camp can repopulate a cleared site only if it is within its saved 480-unit neighbourhood, after the existing quiet period. Destroying camps in one district does not directly remove distant threats.

Wilderness camps have no road leading directly to them. They are at least 300 units from towns and 180 units from other sites when placed. Their field parties roam, hunt, flee and return through the existing bandit AI. The six district bands retain their one-to-one farm assignments; the two connector bands threaten their own caravan routes. Remote bands do not gain a dedicated caravan route or physical farm assignment in this slice. Camp foraging and town-level raids remain the existing abstract activities.

## Integration

The separate pack contains a complete source snapshot, an incremental patch from living camps, a cumulative patch from integrated 0.33, validation logs and native screenshots. Apply only the patch appropriate to the receiving branch. Do not apply the cumulative patch over already integrated hinterlands/living-camps changes.

This branch does **not** include the other chat's 0.34 road contracts or later work. Preserve those changes when resolving shared-file conflicts; the snapshot is a preview/reference, not a replacement main archive. No stats, perks, progression formulas, item catalog or tactical combat rules were redesigned.

- `expanded_region.gd`: immutable generator version 3 and deterministic geometry validation; existing generator versions remain intact.
- `world.gd`: configured town/camp/faction lists, camp archetypes, local expansion neighbourhoods, world snapshot version 3 for expanded maps.
- `campaign.gd`: optional eleventh `setup(..., expanded_region=false)` argument, configured recruits/reputation/markets/contracts, early candidate-geography validation and camp-ID-to-battlefield mapping.
- `overworld.gd`: dimensions from saved geometry, camp archetypes, larger bounded party history. Existing fixed-step time and movement rules are retained.
- `farm.gd`, `market.gd`, `people.gd`: six independent farm layouts, market books and sixty recruit offers. New recruiting follows the same five-week schedule.
- `bandits.gd`, `camp_life.gd`: archetype-aware field parties and distinct deterministic loot seeds for additional camp IDs.
- `region_camera.gd`, `region_canvas.gd`, `procedural_view.gd`, `main.gd`: presentation-only map camera, clipped picking, visible-cell drawing, fixed controls and paged reports.
- `dungeons.gd`: entrance search reads actual map dimensions. Dungeon content and progression remain unchanged.

The campaign wrapper remains version 31. Expanded worlds have geography version 3 and world version 3; farm/guard versions remain 2, renewing overworld version 2, bandits version 3 and camp lifecycle version 1. Old saves keep their original three-town geometry and rules. They are not expanded in place. Save restoration validates against the candidate map before committing any live state; malformed or edited geometry rejects atomically.

## Validation and limits

**5,296 checks across 19 suites passed with zero failures.** Clean import, ordinary startup and legacy combat smoke also passed. See `EXPANDED-REGION-VALIDATION.json` for the suite totals and exact logs. Coverage includes 32 geometry seeds, six-town services, reachable camps and farm paths, deterministic save continuations, new-ID contracts and combat, named rewards, local reoccupation, corrupt-save rejection, old campaign compatibility and native mouse/keyboard controls. Native screenshots named `home`, `overview` and `travel` use ordinary fog. Service-panel and `survey-fixture` screenshots intentionally reveal the map and move the company to exercise all six towns.

Three thirty-day observer runs (seeds 1, 2 and 3) add only company cash/rations. World supplies and councils remain natural. They produced 33 replacement parties, 18 farm raids, 3,582 delivered farm food and ten council patrol parties while food and treasury balances held. Some farms remained raided throughout the month and some councils never financed a patrol. In a separate declared camp-clearance control, all six farms delivered normally. This proves the supply paths work; it does not establish final economic or combat balance. Regional recovery and shortage pacing need a subsequent balance pass.

Extra camp reward branches use explicit victory fixtures. A separate east-crossing fight on seed 27 uses ordinary founders and legal tactical AI commands. Native camera tests exercise wheel zoom, middle drag, Home, on-screen pan, real free-ground travel, six-town tabs, F5/F9, same-seed restart and loading an original fixed-map save. A 120-frame fully revealed overview sample averaged 14.65 ms/frame on this software-rendered test machine; that is a local observation, not a hardware guarantee.

The existing 30-day prototype campaign limit remains. Camera position is presentation state, not part of the save; world location, route, fog, economy and parties are saved. This is the next playable expansion of the overworld, with a larger generator and the existing simulation connected to it.
