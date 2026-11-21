# The Ashen Company (BB2)

Private source backup of the current **Living Roads** playtest, with the procedural Forest/Ridge layouts and outdoor daylight art. The full editable Godot project is in [`game/`](game/project.godot), including GDScript, scenes, campaign data, fonts, art, animation, sound effects, **The Road Unseen** (travel), and **Iron Cadence** (battle).

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

## What is (and isn't) backed up

This is a source snapshot of the active playtest, not the previous prototypes' Git history or the original packed Linux distribution. Player saves, settings, QA campaign captures, logs, and generated Godot caches are not included. The engine is downloaded separately. Older documents below `game/` describe historical prototypes and are not the launch instructions for this snapshot.

See [snapshot provenance and verification](verification/SNAPSHOT.md). This private backup is not a public release or a grant of rights to redistribute bundled assets.
