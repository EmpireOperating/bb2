# The Ashen Company (BB2)

An in-development tactical mercenary game. This repository contains the editable Godot project for the **Layer Forge** playtest: GDScript, scenes, campaign data, art, animation, and audio.

Open [`game/project.godot`](game/project.godot) to play or inspect the source.

## Restore and play

1. Clone this repository (or download its source ZIP from GitHub).
2. Install [Godot 4.4.1 stable](https://github.com/godotengine/godot-builds/releases/tag/4.4.1-stable), standard edition. This project uses the Compatibility renderer.
3. On a fresh machine, import `game/project.godot` in the editor, wait for assets to import, and press **F5** to run the game. Use **New Company** to start a campaign. No previous installation, game archive, or save is needed.

On Linux, to run with a separate save profile (recommended if another Ashen Company build is already installed), run these commands from the repository root. Replace `godot` with the path to your Godot binary if needed:

```sh
profile="$HOME/.local/share/bb2-recovered"
mkdir -p "$profile"/{data,config,cache,library}
export XDG_DATA_HOME="$profile/data" XDG_CONFIG_HOME="$profile/config"
export XDG_CACHE_HOME="$profile/cache" BB2_SAVE_LIBRARY="$profile/library"
godot --headless --path game --import
godot --path game
```

## Scope and notices

This is an editable playtest snapshot, not a standalone binary or an open-source license grant. The current snapshot excludes player saves, settings, logs, generated Godot caches, and the experimental world-history generator. Godot is downloaded separately. Product runtime assets and their existing notices are included; see [`game/assets/FONT-LICENSE.txt`](game/assets/FONT-LICENSE.txt) for the bundled fonts.

See [Layer Forge verification](verification/LAYER-FORGE.md) for the current snapshot, and [Living Roads provenance](verification/SNAPSHOT.md) for the preceding snapshot. Older documents in `game/` describe historical prototypes and are not launch instructions.
