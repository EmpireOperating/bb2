# Standalone generic item concepts

`iron_oath/inventory_art.gd::item_icon` is the shared inventory/shop/report art seam. Actor portraits remain fitted actor crops and are not part of this asset set.

## Exact source scope

`manifest.json` explicitly binds the 49 adopted BB2 definition literals to 46 existing standalone PNGs. The namespaced adopted `hollow_campaign:padded_hood` and `hollow_campaign:buckler` are distinct from the unrelated stock IDs. The three exact stock arrow-quiver definitions (`arrows`, `bodkin_quiver`, `deep_quiver`) additionally use their own standalone PNGs through a narrowly validated stock-ammunition binding. All other unknown/stock definitions remain unmapped; no weapon-family or character-fit fallback is permitted.

The retained 49 mapping entries and their PNG bytes are unchanged from sealed Integration05. Their existing manifest metadata distinguishes original donor copies from later transparent derivatives; this quiver update neither re-extracts nor recolours those assets. The earlier adoption's blanket byte-copy wording does not describe every later transparency repair.

## Arrow-quiver additions

The three stock arrow-quiver mappings use separate local transparent paintings: Field (`arrows`, 12 rounds), Bodkin (`bodkin_quiver`, 8 rounds) and Deep (`deep_quiver`, 18 rounds). These are exact definition allowlist entries, not donor aliases. The resolver requires the genuine stock ammo slot and `arrows` ammunition kind without fabricated donor metadata; condition, UID, rarity and character appearance never select the icon.

Field is a byte-exact copy of the user-approved transparent quiver derivative. Bodkin and Deep are user-approved sibling designs from a retained provider image, chroma-keyed into full standalone silhouettes with documented mixed-edge RGB decontamination and no source resampling. Their extraction/provenance receipts are retained under the sibling candidate evidence root. New paintings are not historical donor originals. These additions provide inventory/shop/report/inspection icons, **not fitted worn character layers**; actual actor-art omissions remain truthful.

The authoritative icon-map hash is `eb2ad5b47935de2a8d2af1e90b9f535281d35399ea15b2ffa3bd395d88f940e3`. Its five stale missing rows are resolved only through the exact normalized and canonical-visual bindings recorded in the manifest. Short bow, Iron cap and Breather belt deliberately share the Reedrunner bow, Iron skullcap and Support belt source respectively. Iron cudgel and Ash pike use their exact standalone source receipts and **remain candidates, not newly user-approved art**. Their original status is recorded faithfully.

## Verification

- `item_art/tests/resolver_slice.gd`: chronological actor-to-generic source-contract tracer bullet against the real configured predecessor resolver.
- `item_art/tests/resolver.gd`: exact catalog coverage, source pixels/full canvases, actor-independent shared Texture2D identity, collisions, malformed definitions/catalogs, bounded cache, and real source/manifest removal/corruption in disposable projects.
- `item_art/tests/test_provenance.py`: independent read-only comparison with the archived donor authorities, exact byte identity for every adopted definition, and explicit candidate-status checks. This host-only provenance test needs the historical authority paths, not just the packaged game.

Engine logs and source-bound receipts live outside the game at `/home/quatro/games/battle-brothers-2-generic-item-art-evidence/attempt-01/resolver-*`. Headless contract/pixel-data checks do not establish native visual acceptance or user approval.
