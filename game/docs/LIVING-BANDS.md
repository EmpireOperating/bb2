# Living bands in 0.31

The separate Living Bands pack is integrated into the 0.30 campaign. New native companies enable both physical trade and band decisions. See [the original pack specification](LIVING-BANDS-preview.md) for the decision states, scouting circuits, vision ranges and timers; the following differences supersede its preview setup, save and starting-party instructions.

`Campaign.setup(company_seed, map_seed, progression=false, live_trade=false, living_bands=false)` preserves the established third argument. The native UI calls all three capabilities with true on new generated games. Historical callers retain their previous behavior. The ordinary save remains `user://ashen-company-save.json`.

New rosters use band version 2 and the actual enemy count for the site's progression rules. Six health slots store percentages in thousandths, with absent ranks at zero. Saved capacity and per-member strength rating are validated against the retained rules; no extra empty rank can be revived during deployment. Basic strength ratings are 78 for thugs, 92 for outlaws, 112 for raiders and 138 for veterans; a mixed party averages these. Health scales the total. These are estimates for world decisions only. Party health and casualties persist through repeat fights, not individual weapon/armour inventories.

The source preview's minimum freight-raiding strength of 260 assumed four to six raiders. Version 2 uses 100 so intact two-person parties can raid. Other visibility, pursuit, flight, sortie and recovery thresholds are retained. Version-1 preview parties retain their original size, rating and raiding threshold. New versions never scale enemies to player level or equipment.

Campaign schema 26 unifies the capability flags with 0.30 progression and recovery. Standalone previews' colliding schema numbers are distinguished by their complete field profile. Mixed or malformed states are rejected before mutation. Actual captured original saves verify both combat and world continuation; passive recovery follows the existing older-save migration at camp.

The sidebar shows observed troops, activity and living headcount. Map captions are shortened to avoid unnecessary overlap. Clicks on small moving markers have priority over site selection areas, while interface/modal controls keep priority. Leaving sight conceals current activity and stops pursuit.

Current checks and limitations are in [VALIDATION.md](VALIDATION.md). The source preview's heavily equipped native journeys and older assertion totals are historical evidence, not this release's results.
