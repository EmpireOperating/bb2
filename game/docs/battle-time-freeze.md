# Battle time freeze

Tactical combat now pauses the campaign clock everywhere, including loaded older battles. Victory, defeat and voluntary retreat settle without adding hours or days, charging upkeep, advancing traffic/raids/patrols, healing soldiers or repairing equipment. Travel, dungeon exploration/search, withdrawal walking, camping and recovery retain their existing time/supply costs. The month deadline still arrives through elapsed campaign time.

Battle consequences still settle immediately: actual rewards, casualties, wounds, XP, equipment wear, loot and ammunition replenishment. An entirely dead company ends immediately and its outstanding job closes. Clearing a camp removes its roaming party, frees cargo and releases guard/farm engagements without waiting for a world tick. This immediate reconciliation was previously hidden inside the removed day advance.

This supersedes the two-hour battle charge in the earlier Earned Dungeon Audit pack. Enemy stats, rewards, combat commands/RNG, world tick rates and campaign length are unchanged. Already-settled saves retain their recorded dates and spending; there is no retroactive refund. Active saves use zero battle time at their next settlement.

## Verification and limits

Godot 4.4.1 native UI: 86 checks passed across two actual AI victories and two real UI retreats, covering both overworld and dungeon combat, F5/F9 during battle/aftermath/return, unchanged date/hour/food/upkeep/recovery clock, and exact reward-only crown changes. These are explicit timing fixtures, not full earned campaigns.

Model timing: 241 checks passed, including three real AI battles (overworld victory, crypt victory, company wipe), retreat, old active crypt saves, unrelated contract handling, final-day fighting, and real midnight upkeep during subsequent rest. A further 25 checks cover immediate camp-clear consequences for a guard confrontation and an actual farm raid; these use explicit victory fixtures to isolate world settlement.

The same clock suite and the three-tier challenge/legacy-save suites pass with the Dungeon Challenge dependency applied. Save-compatibility tests retain exact old saves and tactical outcomes. When comparing historical settlement fixtures, a test-only copy adds back the former day to the expected historical timeline; the live company is checked separately for zero elapsed time. This preserves strict historical comparison without reintroducing a production time charge.

Not all older scripts are green: `company.gd`, `relationships.gd`, and `world.gd` also fail in the untouched 0.34 source. Baseline and changed-build logs are supplied. The world tests' new cargo/escort timing expectations pass; the remaining failures match the baseline market/old-save issues.

An additional native continuation from the released earned day-16 seed-592 save lost a crypt fight. It was not counted as a passing earned-clear test, and no enemies/resources were changed to manufacture a clear. The original `earned_dungeon_ui.gd` is retained as historical evidence; its pinned day-20 clear expectation is obsolete under zero-time combat and it is not a passing acceptance test for this rule. The earlier two-clears-in-six audit used a different clock and must not be presented as a new-clock win rate. Full earned progression/balance needs a fresh audit.
