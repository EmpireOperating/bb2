# Validation — turn shortcuts 0.14.1

This patch changes keyboard bindings, visible instructions and version labels. Combat formulas, stat ranges, AI, turn ordering and save schemas are unchanged.

Space now waits once per round, retaining AP and fatigue; F ends the active fighter's activation. W remains an unadvertised compatibility alias for Wait. Enter no longer finishes an individual activation. In an already-started legacy team-turn battle, Space selects the next available soldier without spending AP, and F ends the company turn; Enter remains its legacy end-turn alias. The mouse Finish soldier button remains available in those old fights.

The existing `tests/turns_ui.gd` native journey was updated to press Space and F and rerun: **37 checks, 0 failures**, native exit 0. It confirms Space places the active fighter in the delayed queue without finishing them, spending their AP or changing their fatigue. F marks only the active fighter finished. Save/load preserves the waiting queue. The same journey completes a real contract battle in victory and checks settlement and earned Initiative development. Founder/recruit profiles and equipment comparisons are covered by this existing journey as well.

Godot 4.4.1 imported the source without script errors. The native run used a 1440×900 Linux window, Mesa software rendering and an isolated save directory. Updated battle-button labels and footer were visually inspected. The deliverable ZIP passed CRC checks and excludes Godot caches/player saves. No standalone platform exports were produced.

The 4,533-check implementation validation remains historical evidence in `VALIDATION-v0.14.md`; those model suites were not rerun for this keyboard/UI-only patch. Neither report establishes numerical balance against Battle Brothers. Armour/penetration, weapon values, progression, morale and encounter tuning still contain custom rules.

![Space waits and F ends the activation](initiative-wait-queue.png)
