# Company Loop domain adapter

## Authority and scope

`session.gd` implements the complete `CONTRACT.md` domain API; no existing source/data/tests/art were edited. The campaign remains the existing `src/campaign.gd` implementation. A local `CrossingCampaign` subclass overrides **only enemy spawn equipment**: it calls stock enemy creation/stat setup, then installs actual catalog armor/arms before `Campaign.deploy()` starts individual initiative. There is no Battle subclass, alternate scheduler, damage formula, settlement implementation, or renderer-driven gear.

Initial setup retains Campaign's three generated founders and adds three distinct actual generated recruit candidates through `add_person`, recording their recruit IDs. Only this new demo's initial inventory is replaced with the declared bounded grant; real item allocation stays monotonic. Personal identity, stats, growth and perks are not boosted or copied from another member. Subsequent deployments never refresh company equipment, resurrect casualties or heal members.

Physical authored definitions: linen, red_gambeson, mail, brigandine, nasal, kettle, sword, axe, spear, bow, shield, round_shield; real arrows and the stock body/head assembly containers support those items. Setup also grants one loose spare of each supported physical definition. This is explicit demo content, not a normal-economy start or a recruitment transaction.

## Exact public interface retained

- `signal changed`
- `campaign`: authoritative Campaign-derived instance; its `phase`, `battle`, `soldiers`, `items`, `catalog` are the UI's read-only sources.
- `last_error: String`
- `setup(seed: int = 7391) -> void`
- `preview_unit(sid: int) -> Dictionary`
- `gear_slots(sid: int) -> Array`
- `available_items(sid: int, slot: String) -> Array`
- `equip(sid: int, item_id: String, slot: String) -> bool`
- `unequip(sid: int, slot: String) -> bool`
- `start_battle() -> bool`
- `resolve_battle() -> bool`
- `retreat_battle() -> bool`
- `return_to_camp() -> bool`
- `save_camp(path: String) -> bool`
- `load_camp(path: String) -> bool`

Slot keys are exactly `weapon`, `shield`, `body/base`, `body/mail`, `body/outer`, `head/shell`, plus the supported `ammo` slot. Slot/item row fields match CONTRACT. Missing slots have empty item IDs; zero-maximum weapons have no modeled durability. Invalid member reads return `{}` / `[]`. Dead-member previews retain anatomy identity but do not invent a fallback sword.

Preview uses Campaign's real arms, component and armor helpers without mutating state or RNG. Company `visual_id == company_id == sid`; in battle `id` is the tactical index, `company_id` follows the deployment mapping even after deaths, and enemy `visual_id == 6 + actual battle id`.

Successful setup/equipment/lifecycle/load operations emit `changed`. Refusals set `last_error` and do not emit. **`save_camp` never emits `changed`**, including successful autosaves; it cannot recurse through the parent's camp-only autosave callback. Successful load swaps the Campaign instance only after validation, then emits once. UI must re-read `session.campaign` after load/setup rather than retain the previous instance.

## Equipment and battle behavior

Equipment changes delegate to stock `equip`, `fit_component`, `component_preview`, `unequip`, stash and ownership checks. No already-owned/fitted piece is offered. Removing a weapon remains forbidden; replace it instead. Equipping a bow follows the stock two-handed rule and returns the shield to stores; ammunition must be fitted separately. Removing mail/base/helmet returns that exact item, not a replacement.

Each deployment creates an explicit repeatable **Ruined Crossing** legacy demo contract (`company_loop_<encounters>`, 120-crown pay, threat 2, eliminate objective) at the real `ford` world destination. It positions the company there without travel/day advancement. This is a bounded playable content shortcut, not a new overworld/travel/contract system. The stock opening rules deploy four living foes; empty ranks stay empty. Enemy physical gear is authored and lootable, not cosmetic appearance.

The accepted `prototype/scenario.gd` fixture supplies only terrain and spawn coordinates. Its side-turn rules, comparative loadouts, stats and RNG are not transferred. `Campaign.deploy()` provides current individual initiative, actual company item IDs/condition, and all ordinary combat flags. Consumers must use `battle.active_id`, stock `can_act`, movement, weapon commands, wait/finish and `ai_step`; they must not use the old side-turn UI assumptions.

Real settlement is exactly stock `resolve_battle` / `retreat_from_battle`. Its phase guard prevents duplicate payouts/loot/losses. The source preserves component wear, wounds, casualties, lost fallen equipment on retreat, unpaid contracts, reputation/progression and recovered enemy equipment. Source ammunition accounting/refill spends real reserve ammunition at settlement; return itself does not repair or heal. Routed enemies retain their gear. Armor salvage remains in stock assemblies; this narrow component-slot UI offers only unfitted loose parts, not a new assembly-breaking operation.

## Checkpoint integration requirements

The parent project **must** configure:

```ini
[application]
config/use_custom_user_dir=true
config/custom_user_dir_name="ashen-company-company-loop"
```

Both save and load are CAMP-only. Use a root-level literal filename such as `user://company-camp.json`; the accepted grammar is `user://[A-Za-z0-9][A-Za-z0-9_-]{0,63}.json` (literal dot). Nested directories, normalization/traversal, absolute/resource paths, escaped separators, trailing newline, and symlink/directory targets are refused. No live user-save directory was accessed in the tests.

The private format is a canonical JSON envelope with `format: 1`, a canonical JSON Campaign `payload` string, and its SHA-256 `digest`. JSON numeric normalization uses the stock Battle helper before canonical encoding; Godot parses JSON integers as floats. Canonical comparison rejects duplicate keys and ambiguous hand-edited envelopes. This checksum detects corruption, **not malicious authorship/authentication**.

Save validates the detached snapshot using stock `Campaign.restore`, restricts it to the six-member authored demo/schema 23, checks exact normalized roundtrip, writes and flushes a same-directory temporary file, verifies its bytes, atomically renames it over the target, then reads back the exact target. A refused snapshot cannot overwrite the previous valid checkpoint. Load validates into a new detached Campaign and swaps only on full success. Active contract imports, other schemas/catalogs and all battle/aftermath payloads are refused. `snapshot.battle` is always null; the bespoke live terrain is never serialized or resumed.

Atomic visibility is qualified on the supplied Linux runtime. This is a single-writer local checkpoint, not a multi-process locking protocol, a hostile same-user race defense, an authenticated save format, or a power-failure/directory-fsync guarantee. UI should call it “Last camp checkpoint,” never imply a midbattle save.

## Real headless verification

Runtime: `/home/quatro/games/Battle-Brothers-2-Prototype-0.13/runtime/Godot_v4.4.1-stable_linux.x86_64` (actual output: Godot 4.4.1 stable official 49a5bc7b6).

Evidence: `/home/quatro/games/battle-brothers-2-company-evidence/domain/`.

Final focused run `17-final-focused/engine.log`: **669 checks, 0 failures, process exit 0**.

- Real unmodified victory: 218 AI steps, round 12, 206 accepted commands. Assertions require actual moves and targeted weapon commands by both sides; the test never assigns a result, damage or death.
- Second deployment retains exact settled gear wear. Actual movement exposes a wounded member; enemy commands cause one real casualty by round 5 (78 steps), then explicit retreat settles unpaid and removes that casualty's actual owned gear exactly once.
- Separate full victory uses real Split Shield; observed broken ID `enemy_0_6_shield`, one directed split command, three zero-condition shields after settlement. Its CAMP checkpoint reloads exactly.
- Browsing is read-only; owner/component aliases, two-handed conflicts, invalid IDs/slots, weapon removal, repeat settlement, camp-only saves, corrupted/truncated/duplicate-key JSON, recomputed-digest duplicate ownership, malformed nested data, invalid conditions/paths, symlinks and inherited-userdir refusal are covered.
- Postvictory, postcasualty-retreat and broken-shield camp snapshots reload exactly. Failed writes retain previous file bytes; invalid loads retain the active Campaign instance and snapshot.

Final separate-process run `18-final-cold-reload/engine.log`: **110 checks, 0 failures, process exit 0**. It loads the previous process's real postretreat checkpoint, compares every snapshot field to the retained writer oracle, checks ownership, deploys again under individual initiative and completes another retreat/return. All source runs use a private copied project and private HOME/XDG configuration/data/cache. Logs and receipts retain expected TDD REDs and diagnostic failures, not just final green output.

The earlier failed battle-test expectations were harness issues (modern attack commands are `weapon`, not legacy `attack`; simply waiting behind the ford can stalemate). The corrected casualty journey uses a real move into contact, not injected damage. Persistence diagnosis found Godot JSON numeric representation differences; stock normalization fixed them. A targeted RED also caught the inherited preview's sword fallback for a dead member, and another caught regex `$` accepting a trailing newline. Both are covered by final GREEN tests.

Protected tracked paths `src/`, `data/`, `tests/`, `assets/`, `prototype/`, `visual_slice/`, `sprite_study/` compare unchanged against base `bdac7019aa5860bc9435958e479f26b099be6322`. See evidence manifest for source/runtime hashes. No GUI, staging or commit was performed. No full legacy/world test suite, graphics quality, human balance/fun, platform export, or native UI flow is claimed by these domain tests; those remain the parent integration's responsibility.
