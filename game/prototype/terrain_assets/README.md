# Ruined-crossing terrain renderer

`prototype/terrain.gd` is a read-only `Node3D` presentation layer. It has no physics bodies, navigation data, combat commands, save access, lights, camera, or units.

```gdscript
var terrain = preload("res://prototype/terrain.gd").new()
add_child(terrain)
terrain.build(battle)
# Supply world-space FOOT positions. Do not add Vector3.UP at the call site.
terrain.update_occlusion(camera, living_unit_world_feet)
```

## Contract

- Input is an object or dictionary with `tiles`, keyed by the combat engine's literal `"q,r"` strings. Each tile supplies `terrain` and `height`.
- All tile centers use the shared `hex_layout.gd.world(cell, height)`. Land tops are exactly local y=0 with radius 1.0; no presentation elevation is substituted for a rule height.
- Water is intentionally inset: stream surface -0.42 and stream bed -0.82 relative to that tile's height. The ford at **(6,4)** gets a thin deck and an actual open, segmented stone arch only when its authoritative terrain is `ford`. Water also continues beneath that bridge.
- Only `wall` cells receive tall masonry. Only `forest` cells receive oak trunks/crowns. Trees leave the standing center clear. Neither category changes the engine's movement or LOS rules.
- Stone/ford terrain gets soft weathered paving; other terrain uses seamless, seeded pigment washes. The small mipmapped pigment texture is generated once in memory. No downloaded textures or global RNG calls are used.
- Rubble, low grasses and leaf litter remain at tile edges, with a maximum static height of 0.18; three mesh batches serve the whole board. Water and foliage use restrained shader motion.
- Repeated `build()` replaces only the renderer's generated root, clears references, and leaves external siblings/children and the battle unchanged.

## Occlusion

`occluders` explicitly records each wall/tree's root, tile, local bounds, meshes, materials and faded state. `faded_occluders` contains the roots currently affected. Camera projection generates correct rays for both perspective and orthographic views. The rays test oriented bounds against knee/torso/helmet samples above the supplied feet. The implementation respects transformed terrain roots and restores opacity when units move, disappear, or the camera is absent.

The fade uses an opaque shader dither (23% coverage), not `GeometryInstance3D.transparency`, which is unsuitable for Compatibility rendering. A faded object's shadows are disabled and restored with its opacity. This is a conservative bounding-volume test, not a per-pixel visibility solver; sparse foliage gaps can therefore cause an early fade. There is no temporal fade tween.

## Verification

Run the native script with Godot 4.4.1, `--headless --single-threaded-scene --script res://prototype/tests/terrain_test.gd`, using isolated `HOME` and `XDG_DATA_HOME`. The test covers exact geometry/elevation, deterministic and seamless pigments, rebuild cleanup, the single bridge, actual tile-driven walls/trees, safe batched dressing, projection-aware fade/restore, unchanged real battle snapshots and geometry budgets.

Headless import/run is **not visual acceptance**, shader-motion observation, GPU timing, or software-OpenGL frame-rate evidence. Native Omabox capture remains required. A scenario without `forest` tiles deliberately displays no trees; adding scenic blockers on clear cells would misrepresent the combat map.

Procedural source asset: `mesh_builder.gd` combines chipped masonry, arch voussoirs, branches, irregular leaf clusters and low dressing into indexed meshes. All geometry is authored here; the reference image is guidance, not a runtime backdrop.
