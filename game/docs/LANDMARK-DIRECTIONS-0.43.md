# Landmark directions — 0.43

The regional-news journal now replaces town search circles with written directions. Reports retain their observation date, hearing date, source and stale status. This slice changes navigation presentation, not economic or combat rules.

## Player flow

Ask for Local Rumours in a town. Open Destinations or a report and choose Read Directions. Directions begin at the town where that destination was first described. They name visible bridges and waystones, followed by general compass bearings toward the next landmark or destination. They remain fixed when the company moves; they are not a live tracking arrow.

Bookmark Directions stores the chosen destination in the existing saved bookmark field. A small map note shows the first instruction, and Lead Journal opens its full text. Bookmarking neither pans the camera nor issues travel orders. Clicking the note cannot accidentally order travel. Remove Bookmark clears it. North is up, indicated on the expanded map.

Landmarks are derived deterministically from the saved geography. Bridges use existing crossing positions and names tied to their nearest town. Animal-named waystones stand on existing roads, away from place markers and other landmarks. Their icons and names appear only inside explored terrain. They grant no vision. Directions follow the connected road graph; they do not claim the road is safe or consult current raider locations.

Long routes show up to four intermediate landmarks and a final destination bearing. Very short connections can refer directly to the departure town. Legacy maps without a stored road graph use a general town-to-town bearing, without inventing a road.

## Compatibility and scope

Save wrapper 34 / regional-news schema 1 are unchanged. Old origin/hearing records produce the new wording. Old town pins become written bookmarks. A restored 0.42 save roundtrips without changing any persisted data. The map is never regenerated or expanded by this feature. No crowns, supplies, jobs, troops, fog, wages, prices or combat statistics are changed.

Scope is the regional-news town leads introduced in 0.42. The older Other Rumours, caravan and dungeon clue systems are not changed here. Other development chats' integration packs have not been merged implicitly. The historical area helper remains for reproducing 0.42 automated career results; no player-facing town-lead action uses it. Those historical results are not evidence of players navigating by the new wording.

## Verification

**1,794 checks passed across seven suites; zero assertion failures.** The native run used software OpenGL and the environment's automatic dummy-audio fallback.

See `directions-0.43/verification.json` and the accompanying logs for this build's exact results. The geography checks cover six seeds, every ordered town pair, route traversal, fixed origin wording, no mutation from reading, and exact save/load. A short road connecting adjacent towns may use its origin town rather than requiring an artificial intermediate monument.

The native Godot UI driver uses actual mouse/keyboard input for journal navigation, bookmarks and F5/F9. It verifies no camera jump, no travel order, no fog change, paused reading, bookmark persistence, old-journal pagination and independently clickable repeated-town reports. A fresh seed-71 company physically follows roads and arrives at Briarmere while paying normal wages. The driver knows the generated road polyline, so this is a functional travel/UI check, not a blind human wayfinding study. No resources, visibility, teleports or forced victories are granted.

Reproduce the model checks:

```sh
godot --headless --path . --script res://tests/landmark_directions.gd
godot --headless --path . --script res://tests/regional_news.gd
```

For native UI checks, use a graphical display and an isolated `XDG_DATA_HOME`, then run `godot --path . --script res://tests/landmark_directions_ui.gd`. Do not use your personal save directory for automated UI tests. The former `regional_news_ui.gd` entry point runs this current suite; its original 0.42 driver is archived with that release's results.

## Screenshots

![Written directions](directions-0.43/road-directions.png)

![Bookmarked words without a target circle](directions-0.43/bookmarked-map.png)

![Destination list](directions-0.43/destinations.png)

![Arrival after paid road travel](directions-0.43/earned-arrival.png)

## Provenance

Based on `Battle-Brothers-2-Prototype-0.42.zip`, SHA-256 `d9453478d01cdd12e6477b19119bd9bec73f7056fc4617a10ddac799df941716`. Historical documentation and fixtures remain in the archive. The changed-source patch is included under `directions-0.43/source-diff.patch`.
