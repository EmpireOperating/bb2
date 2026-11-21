# Equipment-owned full outfits

## Scope

An isolated successor to accepted Company Outfitting commit `ff184def1016bfcb4a523da484b71ae1ef4868a7`. Original source artworks, predecessor worktrees, terrain and combat rules remain unchanged.

The existing supported visible body layer owns coordinated torso, legs, boots and gloves. No new mechanical slots, items or protection stats are invented. Priority is outer armor, then mail, then base garment. Removing an outer outfit reveals the actual underlying outfit; removing all supported body gear restores the original ordinary clothes and original bare-hand foregrounds. Condition/wear follows the physical owning item. Unsupported catalogue art remains explicitly unsupported rather than silently acquiring a substitute.

- Cloth family: light trousers, simple boots and leather gloves.
- Mail: painted ring-mail leg protection and mail-backed protective gloves.
- Brigandine: coordinated heavy leg protection, reinforced boots and gauntlets.

The same final Texture2D is used for camp and field inspection/battle. Shared anatomy, fist registration, foot anchor, stable identities and the accepted color material remain fixed. This is a static-pose equipment proof, not a separate glove inventory system or new animation rig.

## Launch and save behavior

Run `./launch-company-loop.sh` from the project root, or import `project.godot` in Godot 4.4.1. The retained window title is Company Outfitting. The predecessor checkpoint format and directory remain unchanged; do not run both builds against the same company checkpoint. All automated/native qualification used fresh private state, never the user's active checkpoint.

## Production records

- `outfits/ART.md`: leg/boot source paintings, extraction, masks and reproducible rebuild evidence.
- `OUTFITS-RENDERING.md`: historical leg/boot-stage runtime evidence, followed by the combined glove stage.
- `gloves/ART.md`: three glove sources, registration, source-bound masks, held-stack reviews and fitting disclosures.
- `GLOVES-RENDERING.md`: combined runtime contract and real-asset RED/GREEN results.
- `OUTFITS-CONTRACT.md` and `GLOVES-CONTRACT.md`: bounded scope and ownership.

Original bare-hand foreground RGB is not drawn through equipped gloves. The glove pair draws below the unchanged weapon; that same glove clipped by the original grip alpha draws above the weapon; shields retain their original foreground order. Missing required outfit, glove, mask or grip art refuses the whole figure instead of rendering a misleading partial loadout.

## Verified combined candidate

Native source tree: `4d0bd271637f7566d9a0faf3bcc6204950d6fc44`. Final delivery adds documentation and inert evidence only to that exact tested runtime/art tree. Freeze/review/package receipts are retained outside the repository at `/home/quatro/games/battle-brothers-2-full-outfits-evidence/`.

### Automated

The complete final runner executed **40,055 Godot checks and 43 Python tests**, all passing, across 30 commands including a cold import. It preserves predecessor presentation/domain/UI gates and adds outfit, glove, provenance and runner-copying checks. Focused production results include 535 outfit checks, 574 glove checks, 245 current company character checks and 204 camp panel checks.

There is one known inherited warning in the old sprite-study test about filesystem image loading on export. No new errors/warnings were accepted. This is source-project qualification, not a packaged executable export. Historical legacy armor/weapons/tactical-AI failures remain documented and are not claimed fixed or green.

The initial aggregate attempt failed because its cold-copy helper excluded all directories named `evidence`, removing manifest-bound art proof inputs. The helper was corrected with a real regression test; no provenance assertion was weakened. The failed attempt remains in `all-gates-01`; final successful results are in `all-gates-final`.

### Native gameplay and pixels

Canonical private Omabox run `144b327b61a5` passed **55 observation checkpoints**, captured **17 actual game screenshots**, and exercised **two native engine lifetimes**:

- Real owned-item mail, cloth and brigandine swaps/removals; exact underlying outfit and ordinary-clothes restoration.
- Sword, axe, spear and bow carry contexts, identities and matching glove support.
- Actual deployment with unchanged camp/battle equipment signatures; field inspector uses the same figure.
- Real bridge movement, attacks, enemy activations and physical armor/shield wear.
- Withdrawal cancel/confirm, unpaid settlement, return to camp, then exact cold reload of company/inventory/encounters and conditions.

Both executed copies matched the stage's source/art bytes; generated import metadata was recorded separately. Engine lifetimes exited cleanly without errors/warnings, and canonical cleanup verified the private desktop, HOME and owned processes were removed. Software-renderer acceptance is not a target-GPU performance claim.

The first native attempt `1252561044cb` is retained: equipment/field checks passed, but a too-short combat witness stopped after misses/shield blocks before body damage. The second controller played further genuine attacks/activations; it did not change game code, RNG, health or equipment to manufacture a result.

Parent visual inspection covered the actual cloth/mail/brigandine camp captures, field inspector, battle overview and cold reload. Outfit materials and lower protection are clearly distinct; no obvious stale boots, bare-grip leakage or broken wrist/waist joins were visible in those captures. Small tactical details still diminish with zoom.

See `evidence/full-outfits/` for complete selected screenshots, native acceptance/report, aggregate summary, preservation receipt and a labeled 1:1 native-crop comparison. Offline source sheets under `outfits/` and `gloves/` are explicitly separate from these engine captures.

## Limits and preservation

- Three fixed-pose outfit families; not full catalogue coverage, separate glove/boot slots, articulated fingers or new combat animations.
- Fine mail/glove details are less visible at battlefield overview scale than in the equipment panel.
- Glove fitting preserves original hand geometry/alpha. Small contour-edge gaps use bounded nearest genuine source paint: 1009/492/382 pixels for cloth/mail/brigandine, maximum 8.944px at the leather lower cuff. This is disclosed fitting, not pixel-exact extraction of every glove RGB value.
- Accepted upper artwork remains protected except explicitly owned glove support; all original source art remains byte-identical. Parent preservation checked 1,992 protected existing files with no drift.
- The company loop remains one repeatable authored crossing with camp-only saving and the predecessor's documented campaign/UI limitations.
