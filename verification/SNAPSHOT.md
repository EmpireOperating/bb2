# Snapshot provenance

The active `BB2-Playtest-Fixes/PLAY` entry point resolved to the `procedural-daylight-v6` successor of the Living Roads — Road Unseen game archive on 2026-11-21. This recovery tree contains the effective file bytes, not an overlay that depends on that installation.

| Input | SHA-256 |
| --- | --- |
| `Living-Roads-Road-Unseen.zip` (source of unchanged game files, not included here) | `3e9d399e61690a30d30d106dfb6765a9e1b9189d0d2136688e292f8f5f1c07a4` |
| [`procedural-daylight-v6.overlay.json`](procedural-daylight-v6.overlay.json) (manifest for the 47 replacements/additions flattened into `game/`) | `5e33cec3fb7cb83e4897da806d2dc7033fa14c2b8ed73147e38912a5ca0140dd` |
| Previously bundled Linux engine (not required from the original installation) | `54215149d52efb1d653a3dec39d0993587bdf5daa2c56e787b5ee88417fb1339` |

The original Godot configuration and default scene (`res://single_body/main.tscn`) are unchanged. The snapshot keeps artwork provenance and the shipped donor-art resources used by the appearance resolver. Authored Godot resource metadata present in the source archive is retained; the generated `.godot/` directory is rebuilt by the editor. Historical QA, simulation checkpoints, logs, packed executables, and local-only launchers are outside the recovery scope.

## Recovery check

Tested with Godot `4.4.1.stable.official.49a5bc7b6` on Linux: import the freshly extracted source into an empty profile, then mount its actual configured game scene. The retained smoke test checks independent travel/battle music controls, travel stream playback, and preference reload. Use a fresh disposable profile, not a playtest profile. From the repository root, after importing assets:

```sh
godot --headless --path game --script "$PWD/verification/music_settings.gd"
```

Expected completion marker: `MUSIC SETTINGS failures=0`. This is a recovery smoke check, not a full playthrough or a platform export test.
