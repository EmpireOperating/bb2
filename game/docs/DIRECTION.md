# Direction and next milestones

The agreed goal is a living, gritty, low-fantasy mercenary simulator: a company of ordinary people that becomes memorable through survival, losses, choices and history. The full company target is 12–20 soldiers. The first useful campaign target is one region and 30 in-game days.

Keep hex tactics, permanent death, meaningful equipment and hard economic choices. Avoid a chosen-one story, constant spellcasting, disposable filler fights and an endless item-stat treadmill.

Build toward formations, terrain and elevation, contagious morale, layered armour, a mobile camp with specialist roles, relationships, faction wars, local economies, varied contract objectives, surrender/autoresolve and a company history that can outlive individual soldiers.

## Delivery sequence

1. **Combat sandbox — completed in 0.1.** One complete encounter, readable rules, trustworthy save/load and deterministic testing. Continue improving enemy positioning and combat feedback from playtesting.
2. **Persistent soldiers and equipment — completed in 0.2.** Survivors return to camp; deaths, wounds and item damage persist. Layered gear can be swapped, repaired and recovered from fallen allies after victory. The battle → aftermath → roster → save/load → next battle loop has native UI coverage. This became the foundation for the regional campaign.
3. **One-region campaign — completed in 0.3.** Three towns, three battlefields/objectives, weekly contracts and recruits, road travel, food, wages, debt, permanent memorials, and a complete 30-day run. Native tests reach a successful ending and restore it after restart.
4. **Regional trade and road security — completed in 0.4.** Food moves in identifiable caravans; camps seize it; clearance and recovery change town stocks and prices. Contracts arise from active camps, waiting shipments and actual losses. Escorts travel with the company and pay only on delivery. The daily world model is separate from company and battle state.
5. **Faction foundations — completed in 0.5.** Three councils own fixed settlements, tax their economies and fund patrols. Raiders spend real stolen food to recruit, expand and raid towns. Company reputation changes supply prices, commissions and escort access. Removing every band prevents automatic respawns. Territory conquest, faction wars and treaties remain future work.
6. **Company identity — completed in 0.6.** Four earned ranks, four distinct training choices with three available slots, permanent combat scars, and a paginated individual service record retained after death. Native journeys follow a hired recruit through promotion and a second battle, and an injured founder through treatment, another battle and memorial.
7. **Tactical command — completed in 0.7.** Paid shield-line and loose-spacing orders, spear screens, simultaneous one-hex group advances, live support/gap indicators, exact hit arithmetic, shared enemy targets and weapon roles. Native tests form, advance and break a line, restore it, inspect hit odds and finish the battle.
8. **Company relationships — completed in 0.8.** Shared survival and threatened line duty earn bonds; nearby comrades steady morale. Death creates temporary grief, hunger and unpaid wages cause strain and friction, and meals, support and mediation cost actual company resources. Dated causes and memorial bonds survive saves. A native journey follows two comrades through earned trust, natural death, a later deployment and paid support. Ridge enemies also apply stronger objective pressure.
9. **Playability — completed in 0.9.** Optional first-contract lessons follow legal actions; visible damage, morale causes and broken links accompany a paginated battle record. A company plan exposes treatment, repairs, training and wage reserves. Travel and rest forecasts use the actual daily simulation on a separate copy, including escort income and NPC resolution. Paired balance experiments are documented: a simple line nerf did little for the dominant forest policy, while more cautious spending reduced but did not eliminate unpaid disbands. Combat stats remain unchanged pending better play evidence.
10. **Generated people — completed in 0.10.** Every new company starts with six generated founders; town boards contain generated recruits from the same saved population. Eight backgrounds bias ability and gear, six temperaments create actual combat tradeoffs, and two personal aptitudes affect chosen growth. Profiles disclose costs and potential before hiring. Earned promotions fund separate perk and attribute choices. Seed entry supports exact replay; old saves retain their existing people and recruit boards.
11. **Human playtest and iteration — next.** Watch a new player complete the opening without explanation, then attempt the month. Identify confusion, repetitive decisions and unfair losses from that session. Revisit objective and stance balance with more than one tactical policy. The automated guide journey is functional evidence, not proof of fun. Keep the 30-day, six-soldier limit until that feedback is addressed.

## Engineering rules

- Simulation first: presentation does not decide outcomes.
- Seeded and reproducible results; save RNG state.
- Player and AI share legality checks.
- Test invariants and full journeys, not just isolated source files.
- Native interaction evidence matters. A parsed script or passing simulation is not proof that a player can complete the flow.
- Prefer explicit, documented boundaries over speculative systems. No networking, service backend or unnecessary framework at this milestone.

## Current choices to revisit

Company-side turns remain the control model. Individual initiative, facing, rotational formations and multi-turn group paths remain future design work. Current group movement translates selected soldiers one hex, with no automatic rearrangement. Ordered shield support is omnidirectional. Armour is a first damage model, not the final equipment and injury simulation. The six-unit opening is an onboarding-scale fight rather than the final company size.
