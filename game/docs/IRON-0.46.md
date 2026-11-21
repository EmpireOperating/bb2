# Iron interface 0.46

## Scope

Based on the exact unified 0.45 source archive (Library version 50). Changes were made in an isolated working tree on `ui/iron`. Campaign rules and saved world geometry are unchanged. This is the first interface pass, not the separate battlefield graphics prototype or a painted-world asset upgrade.

The generated regional map now occupies 1440 × 788 logical pixels, up from 928 × 480. A 64-pixel resource header and 48-pixel navigation footer replace the tall title, persistent reports, hints and sidebar. Town services open on selection; contextual details can be dismissed. Inventory, Journal, Camp and Menu are modal hubs. Empty clicks inside them cannot issue movement, and reading them suspends world ticking. Critical food, wages, empty-party and encounter states remain visible. First-contract callouts default off for new companies; the field guide remains accessible.

The camera follows the company at map edges without altering world coordinates. Map labels are laid out without overlapping each other or selectable icons, prioritizing named navigation landmarks. Repeated minor status captions move to context panels. Internal wagon names are replaced by Caravan. Icons retain their original hit areas. Camera panning and zooming are blocked beneath context panels. Dark neutral panel surfaces and restrained gold accents carry through the existing management screens; Company no longer exposes a permanent new-game button.

The town service interiors, detailed character/equipment layouts, tactical battlefield and dungeon navigation are still the existing systems. Original fixed-map saves keep their earlier map layout. No concept image was used as a fake playable background.

## Validation of this release

- Native `tests/iron_ui.gd`: **84 checks, zero failures** on Godot 4.4.1 with software OpenGL, 1440 × 900. Real mouse/keyboard input for navigation, panels, purchasing, recruitment, travel and save/load. Combat uses the existing legal AI commands.
- Verified normal seed-1 resources, four hubs, modal click isolation/time suspension, Escape, equipment/cargo/report/recovery links, map zoom, context scroll isolation, non-overlapping labels and retention of visible named landmarks.
- Fresh-company journey: market food purchase, paid fourth recruit, signed camp contract, physical travel, earned victory, return and tool purchase; ended day 1, four survivors, 323 crowns. Exact save/load comparisons at contract, active battle, aftermath and recovery. No money, recruits, outcomes or explored terrain injected. The travel driver knows destination coordinates; this is not a human wayfinding or balance test.
- Four model suites: unified_campaign 35, integrated_compat 18, landmark_directions 1219, regional_news 66; **1,338 checks, zero failures**. These are the suites run for this release, not a repeat of all historical tests.
- Import completed; changed scripts parsed and ran without script errors. Initial parallel import crashed in the host runtime; single-CPU import succeeded. Native display reports the expected unsupported VSync warning.
- Screenshots reviewed: map, selected town, hubs, company and journey. The runtime still uses prototype terrain/sprites. The concept landscape is not part of this delivery.

Evidence: `iron-0.46/native/iron_ui.log`, `iron-0.46/native/summary-iron_ui.json`, `iron-0.46/checks/summary.json`. Older test scripts and reports remain historical; scripts that expect formerly permanent buttons must be adapted to the new menus.

## Reproduce

Use isolated user data for tests, because the native journey writes its test save:

```sh
godot --headless --path . --import
XDG_DATA_HOME=/tmp/ashen-iron-test godot --path . --audio-driver Dummy --script res://tests/iron_ui.gd
godot --headless --path . --script res://tests/unified_campaign.gd
```

The native test needs a display. The source patch `iron-0.46/source.patch` applies to unified 0.45 and contains presentation changes plus the native test; it is included to help the separate battlefield work integrate without replacing its branch.

![Iron exploration interface](iron-0.46/fresh-start.png)

![Selected settlement services](iron-0.46/town.png)

![Inventory hub](iron-0.46/inventory.png)
