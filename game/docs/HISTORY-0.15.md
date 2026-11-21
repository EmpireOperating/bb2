Historical documentation for 0.15. The current README and COMBAT-BASELINE-0.16.md supersede its combat rules.

# Battle Brothers 2 — armour and damage rebalance 0.15

A playable **30-day mercenary campaign** with individual initiative turns and eight personal combat attributes, 23 weapons across nine families, distinct weapon actions, two carried slots, finite ammunition, recoverable enemy gear and equipment trading. Town supplies and wealth shape weekly stock; enemy role and resources shape their loadouts. Build outfits from 35 armour components for six generated founders and generated weekly recruits. Personal combat tradeoffs, aptitude-driven development, comradeship, grief, scars and real wages make individuals matter. Three autonomous councils fund patrols while actual caravans feed towns and raiders. Company, equipment, relationships and world state survive save/load.

![Region and current road threats](region-map.png)

## Play

1. Extract the archive and import `project.godot` into **Godot 4.4.1**, the tested version.
2. Press **F5** in the editor. You begin in Ashwick or resume your saved company.
   New companies show **First contract** hints; open the guide for the current lesson or hide hints at any time.
3. Open **Councils & Patrols** for treasuries, relationships and threats; **Trade & Road Report** shows actual cargo and food stocks.
4. Accept **Clear Blackwater Ford**. Select the ford on the map, review the travel cost, and travel there.
5. Prepare the company through **Company & Equipment**, then deploy at the contracted site.
6. In battle, the gold portrait acts. **Space** waits, **F** ends that fighter’s activation. Press **4** for the active fighter’s formation order and one-hex advance; **5** explains hit odds; **6** opens weapon actions, carried switches and visible enemy equipment.
7. After victory, open **Company & Equipment → Person & Service** to inspect XP, training, injuries and history. Then check the trade report: seized wagons resume their routes and later traffic can cross safely. Travel to Stonecross to use its recovering market.
8. Open **Company & Equipment → Bonds & Camp** to inspect each soldier's companions, burdens and exact causes. Earned training matters: spend available choices before returning to difficult fights.
9. Open **Company plan** before spending or travelling. Select a soldier there to inspect their equipment and training. The right-hand destination panel previews the actual trip.

**Goal:** finish all 30 days with a surviving company and no unpaid wages, plus **four contracts won OR every raider band destroyed**. NPC patrols can help secure the region. Funding does not itself award a contract win. Escort contracts count only when their cargo reaches the destination. Internally the completed month is day 31; the end screen shows day 30/30.

With Godot on your PATH: `godot --path /path/to/battle-brothers-2`.

This is a **Godot source project**, not a standalone executable. Fonts and game data are bundled. No account, plugin or network connection is needed to play. Native Windows/macOS exports have not been produced or tested.

## Armour and damage — 0.15

Body layers now form **one protection pool** in combat. Padding contributes ordinary armour points; it no longer applies a second, hidden HP reduction. Each physical piece still has its own condition, appearance and repair cost. The assembly editor continues to show current/max protection and separate changes now and at full repair.

Ordinary hits use independent regular-damage and armour-damage rolls. Remaining armour reduces penetrating HP damage; destroying it allows the remaining non-penetrating damage through. Head chance is **25%**, or **30% for a greatsword**. A head hit multiplies **HP damage by 1.5**, without increasing armour wear. A hit can cause armour damage and zero HP damage. Puncture still bypasses and preserves armour; the other authored family actions remain.

Health and equipment were tuned together: generated starting HP is 75% of the previous seeded value, rounded, while all 23 weapon damage/penetration profiles were reviewed. Mail and plate capacities received modest increases; helmet shells received larger increases to suit the new head-hit rule. Weapon AP, fatigue, reach, load, prices and identity remain unchanged. Hammer AI now checks how much extra armour Shatter would actually remove before spending the turn on it.

In battle you see **total armour lost / HP lost**. Individual damaged layers remain available in camp. See [the complete tuning notes](COMBAT-BALANCE-0.15.md) and [validation](VALIDATION.md).

### Existing saves

Campaign schema **14**, battle schema **11**. A saved ongoing battle or aftermath keeps its old health, equipment definitions, RNG and damage rules through settlement. The conversion runs on **Return to camp**. A save already in camp converts on load. Each component keeps its condition fraction, rounded to whole points; broken parts stay broken. Each mercenary keeps their HP fraction relative to their wounded maximum, with a living 1-HP survivor kept alive. Starting HP scales to 75%; earned health-training gains are retained in full. Names, talents, recruits, gear ownership, wounds, wages, XP and history are not rerolled. Conversion happens once and survives save/load. Keep a backup if returning to an older game version; older versions cannot read the new schema.

This release establishes the damage baseline. Growth, morale, fatigue events and next-round Wait penalties are subsequent work; the whole combat system is not yet BB-equivalent.

![Total armour and HP loss from an actual clicked attack](damage-total-feedback.png)

## Eight attributes and individual turns — 0.14

Health, Stamina, Resolve, Initiative, Melee skill, Ranged skill, Melee defence and Ranged defence are the eight trainable attributes. Recovery is no longer trainable. Founders and recruits use the same seeded generator and have two 1–3-star aptitudes. No background locks a role. Profile & Growth shows base and equipped values, talents and exact next-choice gains.

### Shared turn queue

Both sides share one queue. At each round start it is sorted by **base initiative − gear load − accumulated fatigue − temperament penalty**, minimum zero. Equal scores use a deterministic seed/round/identity tie-break, without a permanent player-first advantage or consuming combat RNG. Scores are locked for that round; live initiative changes affect the next round. The sidebar shows both current and queued initiative.

Only the active fighter can spend AP or receive an order. Each fighter receives **9 AP** at their first activation, minus any pending stagger. **Space / Wait** moves them behind the remaining normal activations; multiple waiting fighters resume in the order they waited. Remaining AP, fatigue, guard and weapon stance are retained. A fighter can wait only once per round; returning after waiting grants neither AP nor recovery. **F** ends only the active fighter. Zero AP, death and escape automatically advance the queue. Routed fighters flee on their own activation. A new round and objective scoring occur only after normal and delayed activations finish.

Gold marks the active portrait; blue and red distinguish company/enemy cards. Click another portrait or company member to inspect, without changing turn ownership. Reactions such as Riposte and Spear brace work outside the owner's activation, spend their own fatigue/reaction budget, and never grant ordinary actions. Guard and reaction stances expire at the owner's next first activation, not at a faction-wide boundary. Individual initiative disables simultaneous multi-soldier formation movement; formation bonuses still depend on actual positions.

### Stamina, equipment and recovery

Available fatigue capacity is **Stamina − all equipment load**, minimum 15. Worn body/helmet parts and main hand, shield and ammunition use full load; each carried weapon/shield uses half load rounded up. Damaged equipment retains its load. The same burden reduces initiative. Automatic recovery is **15 once per round at the start of the fighter's activation**; Damaged lung reduces it to 10. Armour no longer increases attack costs or reduces recovery. Ordinary movement uses 2 fatigue per AP; Restless uses 1 and pays 5 extra fatigue to guard. Weapon handling and Aggressive still modify attack fatigue.

Switching can lower capacity below already accumulated fatigue. It does not erase that fatigue: further actions require sufficient room, and Recover or later automatic recovery can restore it. Equipment previews show capacity and fresh initiative. Initiative is timing, not additional AP.

### Accuracy and morale

Melee and ranged attacks use the corresponding skill and defence. Normal hits remain capped at 5–95%. Total defensive skill, shields, guarding, support and Cautious bonuses above 50 contribute at half value. Confident/Wavering/Breaking/Fleeing states multiply underlying attack/defence skill by 1.1/0.9/0.8/0.7 before other modifiers. Fatigue changes initiative and action availability, rather than imposing the former flat -10 accuracy at 75.

Resolve now controls morale checks. Chance is clamped to 5–95%: **Resolve + 20 − event severity + comrade support + 10×morale state − strain − grief + trait/perk bonuses**. Failed negative checks lower morale one state; successful positive checks after a nearby enemy death can raise it. Stoic gives +10 resolve on checks and costs 5 initiative. Steadfast adds +15 resolve. Haunted starts wavering. Fleeing still causes nearby panic and allows victory by routing the opposing company.

This is a BB-inspired foundation, not identical overall tuning. Version 0.15 replaces armour absorption and head-hit calculations as described above. Weapon abilities, formation bonuses, progression, waiting penalties, fatigue events and morale still differ. Direct camp attacks without contracts remain pending.

### Existing companies

The original eight-stat conversion used campaign schema 13 / battle schema 10; current schemas are **14 / 11**. Identities, ownership, wages and history are retained. Version 0.15 changes health and equipment capacities using the migration described above. Existing general skill and defence become both melee/ranged values; resolve converts to `40 + 3×old resolve`, initiative starts at 100, and stamina becomes `100 + 2×(old recovery − 25)`. Recovery aptitude/training becomes stamina aptitude/training; old skill/defence aptitudes carry to both specialisations. Existing training is not refunded or duplicated. Original history text remains intact.

An already-started older battle retains its old mechanics, AP, equipment, RNG and team turns through settlement. In that older fight, Space selects the next available soldier without spending AP; F ends the company turn. The **next deployment** uses the new stats and shared queue. New saves preserve active actor, normal/delayed queue, spent/waited flags, locked initiative scores, AP and RNG exactly.

![Eight attributes with base and equipped values](initiative-founder.png)

![Enemy-first mixed initiative queue](initiative-enemy-first.png)

![A waited fighter keeps their remaining activation](initiative-wait-queue.png)

## Weapon comparisons — new in 0.13.3

Weapons & carried kit now shows the current/reference weapon and proposed weapon side by side, with both portraits, primary action names and nine rows: damage range, minimum/maximum reach, attack AP, this person's attack fatigue, weapon accuracy bonus, armour-damage multiplier, penetration, hand requirement and ammunition. Signed changes distinguish higher costs from benefits. A polearm's longer minimum and maximum range is coloured as a tradeoff. Accuracy is the weapon bonus, not a final hit chance; penetration differences are percentage points.

Both family actions show their names, full rules and this person's AP/fatigue cost, including crossbow reload costs. Action fatigue uses temperament and perks. Gear burden affects stamina capacity and initiative. No estimated attacks-per-turn or overall weapon score hides the tradeoffs.

A main-hand preview compares against the equipped main weapon. An occupied carried weapon slot compares against its own weapon; an empty/non-weapon carried slot labels the main hand as a reference. The notes explain that storing a carried weapon leaves the active main hand unchanged. They also flag shield removal, shield-stow room needed for a later battle switch, missing/mismatched/empty ammunition, and the separate purchase/equip confirmations. Returning from two hands to one does not automatically equip a shield.

Browsing and comparing are read-only. Shops and company stores use the same comparison. The original 0.13.3 comparison release did not change combat, prices, equipment ownership or save schemas; 0.14 adds the stat and burden rules described above.

## Armour readability — new in 0.13.2

The assembly preview now shows **current / maximum** body and helmet armour for equipped and proposed kits. Body armour combines all protective body layers, including padding. In 0.15 that displayed total is also the protection used by the damage calculation.

Every armour comparison separates **change now** from **change at maximum**. Replacing ruined 0/22 quilting while wearing ruined 0/95 mail with fresh 30/30 linen reads **0/117 → 30/125**, **+30 now / +8 max**. Replacing it with identical fresh quilting reads **+22 now / +0 max**. A fresh but weaker item can show a positive current change and a negative maximum change, with separate colours.

Components and assembled kits explicitly distinguish **BROKEN**, **DAMAGED** and **FULL**. Cosmetic parts stay labelled Cosmetic; an assembly with no protective capacity says NO ARMOUR. Stored kits, exchanges, enemy inspection and the battle sidebar use consistent current/max totals. Repair restores current condition without raising maximum capacity. The original 0.13.2 release changed presentation only. Version 0.15 retains those comparisons while adopting pooled body damage.

## Archer hotfix — new in 0.13.1

- Bows and crossbows can fire over an immediately adjacent friendly front rank. This includes aimed shots and both armies. Trees and units farther along the lane still obstruct shots; a living fighting enemy beside the shooter still prevents firing.
- Failed ordinary movement names the actual cause: water, occupied destination, blocked route, insufficient AP, insufficient free fatigue, or an adjacent enemy. The old blanket Withdraw warning was misleading. Allies do not enforce engagement.
- Attack refusals distinguish range, minimum reach, trees, intervening units, engagement, ammo and reload state. The Withdraw keyboard shortcut now follows the same engagement/resource requirements as its button.
- Existing v0.12/v0.13 saves retain people, gear, positions, resources and RNG at load. The fixes apply immediately to their ongoing battles; future shots and battle outcomes can therefore differ from the unpatched version. Save/load within this patch remains deterministic. Pre-v0.12 battles with historical weapon rules retain their original firing rule until the next deployment.
- That release used campaign/battle schemas 12/9; 0.15 uses 14/11.

The archer update was a focused repair release. Broader encounter/AI work and direct camp attacks remain pending after the 0.14 initiative update.

## Equipment progression — new in 0.13

In a town, open **Company & Equipment → Trade & salvage**. Buy local equipment, sell unequipped stock, or repair damaged stored pieces and complete armour kits. The existing weapon and armour editors draw from this same merchant stock; purchases cannot be duplicated between screens.

### Twenty-three weapons

Variants change actual damage, accuracy, AP, fatigue, reach, armour wear, penetration and hands. Each retains its family's second action. Founders and recruits may receive ordinary variants; premium weapons are found through prosperous markets and well-equipped opponents.

| Family | Available weapons |
| --- | --- |
| Sword | Short sword, arming sword, falchion, greatsword |
| Spear | Light militia spear, boar spear, heavy spear |
| Axe | Belt hatchet, bearded axe, two-handed axe |
| Mace | Ironbound club, flanged mace |
| Hammer | War hammer, two-handed maul |
| Dagger | Belt knife, rondel dagger |
| Polearm | Billhook, long glaive |
| Bow | Hunting shortbow, ash longbow, heavy warbow |
| Crossbow | Light crossbow, heavy crossbow |

A short sword costs 3 AP for 22–32 damage and can make three attacks from a full turn. A greatsword costs 6 AP for 85–100 damage, requires both hands and costs 25 base fatigue. The falchion hits harder than the arming sword but loses accuracy and consumes more stamina. The light militia spear is accurate and cheap to sustain; the heavy spear trades speed and handling for penetration. Shortbows have four-hex range; warbows reach seven at greater AP/fatigue cost. The heavy crossbow shoots for 3 AP but needs **6 AP / 18 base fatigue** to reload.

Special-action AP is at least the weapon's primary AP cost. Special fatigue changes with the variant's fatigue relative to its reference family weapon, then applies temperament/perk modifiers. The heavy crossbow has its explicit reload cost above. Costs shown in the weapon editor and battle action panel are the actual costs for that mercenary.

See [the full weapon catalogue](WEAPONS.md) for exact primary-action values.

The underlying family mechanics remain: greatswords riposte, hatchets and two-handed axes split shields, clubs stagger, mauls shatter armour, knives puncture and glaives hook. A larger axe still removes 24 shield condition with Split shield; its advantage is primary damage, not a free stronger special. Two-handed weapons cannot keep a shield equipped. These are authored weapon types, not randomly rolled quality affixes or named weapons.

![Inspecting the short sword before purchase](equipment-market.png)

### Local markets and weekly stock

Equipment stock is fixed on your **first visit to a town that week**. Weeks begin on days 1, 8, 15, 22 and 29. Returning, reopening the shop or reloading cannot reroll it. A new week captures the town's current food, treasury and raid pressure. Food shortage or raid pressure makes a market Strained; ordinary supplies make it Supplied; ample food and public wealth make it Prosperous.

| Market | Conditions at first visit | Equipment | Starting buying purse |
| --- | --- | --- | ---: |
| Strained | Fewer than five days of town food, or active raid pressure | Knives, clubs, hatchets, light spears, shortbows, shields/ammo; armour parts priced up to 45c | 140c |
| Supplied | At least five days of food, no raid pressure | Basic stock, local military specialties, one rotating visiting weapon; armour parts priced up to 115c | 300c |
| Prosperous | At least twelve days of food, at least 90c council treasury, no raid pressure | Supplied stock, two rotating premium local weapons, full armour catalogue | 520c |

Ashwick specializes in militia swords, spears, maces and crossbows. Stonecross favors falchions, axes, hammers, crossbows and daggers. Dunmere favors bows, billhooks, heavy spears, short swords and axes. Each available definition has one item per town/week. A purchase depletes that stock everywhere and replenishes the merchant's buying purse; ammunition refills also replenish it.

Merchant purses are private weekly trading budgets, **not council treasuries**. Public treasury is an indicator of local prosperity, not money withdrawn to fund these shops. Equipment manufacture and merchant trade routes are not simulated. Town food, caravan shipments and council ledgers keep their existing conserved accounting.

### Sell, repair, or keep it

The trade screen lists only unequipped root items. A stored armour assembly is one sale, including every contained component. A child cannot also be sold loose until removed through the armour editor. Equipped and carried gear must first be returned to stores. **Review sale** shows the exact quote; **Confirm sale** commits it. There is no buyback in this milestone.

Sale value depends on the item's catalogue value, condition, market tier and local reputation. Base resale rates are 18% / 22% / 26% for Strained / Supplied / Prosperous, adjusted by one percentage point per ten reputation and bounded to 16–30%. Damaged armour/shields retain a 15% scrap-value floor before that resale percentage; ammunition value follows remaining shots with no scrap floor. Weapons retain their full underlying value because weapon durability is not modeled. Buying then reselling cannot create a profit.

The merchant refuses a sale it cannot afford. Whole kits charge/credit once; selling removes the kit and all children, and repeat clicks cannot award again. Prices and balances persist. Another town or a later week's purse can provide another buyer.

Stored armour and shields can be repaired directly: one tool per twelve missing condition, rounded up across the selected item or complete kit. Ammo cannot be repaired into more rounds. The screen compares sale value, actual repair tools and full replacement list value; that replacement figure does not promise the exact pieces are currently stocked locally. Whether repairing to sell is worthwhile depends on the tool cost and sale increase.

![A damaged kit: sale value, repair cost and replacement comparison](equipment-repair-or-sell.png)

![Confirming sale of the repaired kit and all its components](equipment-kit-confirmation.png)

### Enemy occupation and resources

Ford enemies are toll raiders with militia weapons, maces and crossbows. Woodland raiders favor axes, hunting bows and polearms. Ridge deserters favor military swords, hammers, spears and ranged weapons. Each formation position retains its combat role.

Equipment budget follows band threat, with one extra tier for a captain and another when the camp holds at least 36 food; it is capped at three. Within the selected family, enemies draw from the best affordable tier. Better-funded enemies receive better-maintained armour and heavier protective combinations. Poor equipment begins worn; battle damage then carries through to recovered loot. The enemy panel shows the occupation, supply tier, actual weapon name and remaining equipment condition.

Older saves retain existing items and recruits. An active v0.12 fight keeps its already-generated gear and continuation; its next deployment uses the new enemy loadouts. New markets are initialized when upgrading or arriving. Old purchase depletion remains honored.

## Weapon actions

Open **Company & Equipment → Weapons · carried kit · ammunition**, or click the weapon/shield card. The editor shows the selected weapon's damage, reach, armour wear, penetration and both actions with that mercenary's actual fatigue costs. Inspecting is free; **Equip** commits the change. **Town Weaponsmith** sells the available weekly weapon, shield and ammunition stock for that town. Buying and fitting are separate steps, and the displayed reputation-adjusted price is charged exactly once.

![Compare weapons and carried equipment](weapons-armory.png)

Every family has a primary action and a distinct second action. The table shows **base** costs for the original nine reference weapons; variants adjust these as described above; armour load, Aggressive temperament and Weapon drill change fatigue. The game displays the final cost before use.

| Family | Primary action | Second action | Base AP / fatigue | Tactical purpose |
| --- | --- | --- | --- | --- |
| Sword | Slash | Riposte | 4 / 18 | Counter the first two missed adjacent melee attacks until the next own turn; each counter costs another 6 fatigue |
| Spear | Thrust, reach 1–2 | Spear brace | 4 / 16 | React to two enemies entering adjacency; a hit stops their remaining movement; 6 fatigue per reaction |
| Axe | Chop | Split shield | 5 / 22 | 24 shield damage, no HP damage; 90% base accuracy, +5 against an outnumbered target |
| Mace | Strike | Staggering blow | 5 / 22 | −10 accuracy, 75% damage; a hit removes 2 current AP and 2 next-turn AP; the pending penalty does not stack |
| Hammer | Hammer blow | Shatter armour | 6 / 26 | −5 accuracy, body hit, double armour wear and half flesh damage |
| Dagger | Stab | Puncture | 4 / 18 | −20 accuracy, 80% weapon damage directly to HP; preserves armour, padding and helmet |
| Polearm | Reach strike, exactly 2 hexes | Hook and drag | 5 / 22 | −10 accuracy, 65% damage; pull a hit target into an empty passable adjacent hex |
| Bow | Quick shot | Aimed shot | 6 / 18 | +15 accuracy, 115% damage; one arrow per shot |
| Crossbow | Shoot bolt | Reload | 4 / 10 | Reload an unloaded crossbow; requires a remaining bolt and no adjacent enemy |

Moving, attacking, switching, guarding or recovering cancels a stance. Reaction attacks cannot chain into more ripostes, and cannot occur without sufficient fatigue capacity. Shieldwall/guard remains a separate ordinary order, available on **1**.

**Carried I and II** each hold a weapon or shield. In battle, switching costs **2 AP and 4 fatigue**, swaps the physical items, and ends guard/stance. Equipping a two-handed weapon while holding a shield needs the other carried slot empty to stow that shield. Otherwise the switch is refused without spending anything. Raising a carried shield requires a one-handed main weapon. Camp changes are free; fitting a two-handed main weapon in camp returns the shield to stores. Bows, crossbows, polearms, greatswords, two-handed axes and mauls use both hands. Carried equipment adds no weight penalty in this milestone; worn armour still determines load.

**Ammunition** has its own slot: an arrow quiver holds **12**, a bolt case **8**. Shooting spends one round even on a miss. Crossbows also become unloaded; reloading costs AP/fatigue but does not spend a second bolt. Loaded state follows that physical crossbow through switches and saves, so switching away and back cannot reload it. An equipped crossbow is prepared at deployment if matching ammunition remains. Both can fire over an immediately adjacent ally, while trees and more distant intervening units block shots. Neither ranged weapon can fire while an enemy is adjacent. Ammunition packs cannot be changed during combat; carry slots hold weapons/shields only.

At a town, **Refill ammunition** charges for the actual missing rounds: base **1 crown per arrow, 2 per bolt**, adjusted by reputation. Tools never create ammunition. Shields have **40 condition**; broken shields lose their defence and linked support. Repair includes worn armour and equipped/carried shields, charging once for aggregate missing condition.

**6 · Weapon actions / kit** pauses battle while open. Choose the basic or special action, inspect a target and its visible equipment, then confirm the action. Costs and refusal reasons appear before use. Closing the panel returns to board movement and ordinary attacks. Enemies pay the same action costs, use situational specials, reload, and switch to carried daggers when trapped or out of ammunition.

![Crossbow shot and visible enemy equipment](weapons-crossbow-shot.png)

### What you fight is what you can recover

New battles equip enemies with actual layered body/helmet assemblies, weapons, shields and appropriate carried weapons/ammunition. Inspection shows their current condition. After **victory**, every killed enemy's remaining equipment enters company stores; routed or escaped living enemies retain theirs. There is no random loot roll in this milestone. Body and helmet kits retain every component and its final condition, including destroyed pieces that need repair. The aftermath's **Loot** panel lists the source and recovered items; nothing is awarded twice by reopening or loading it.

Hammering armour apart therefore leaves a repair bill; a successful puncture preserves it. Broken shields can be recovered and repaired. Recovered weapons can be equipped or carried in the next fight. Fallen allies' gear follows the same existing victory/defeat recovery rules. Contract salvage remains a separate reward.

![Actual equipment recovered from killed enemies](weapons-loot.png)

**Existing companies:** an ongoing older battle finishes with its original weapon rules, including its historical ammunition behaviour. Its next deployment uses the new system. Existing weapons/people are retained; carried slots start empty, old shields receive their new full condition, and ranged soldiers receive a matching ammunition pack. New recruits and new companies can use the expanded families. Old ongoing enemies do not retroactively gain lootable kits.

## Layered armour

Open **Company & Equipment**, select a soldier, then click **Body assembly** or **Helmet assembly**. The main inventory keeps each outfit together. Inside the editor, choose a layer and a piece from Company Stores to see both the new appearance and exact protection, total gear load, stamina capacity, initiative, attack cost and recovery. Nothing is fitted until **Confirm component swap**. Escape closes the editor.

| Assembly | Components |
| --- | --- |
| Body | Base garment, mail, outer protection, reinforcement, overclothes, cloak/mantle |
| Helmet | Padding, mail, shell, face protection, decoration |

The 35 components include several padded garments, mail lengths, leather, breastplate, brigandine, scale, shoulder guards, collar, tabards, cloaks, helmet liners, coifs, shells, face plates and decorations. All slots are optional. Overclothes and most decoration are cosmetic; the fur mantle provides a little protection. There are no separate hands, feet or leg slots, and no rings in this build.

Founders and recruits receive seeded combinations when the campaign is created. Their exact components appear in the candidate profile and survive hiring and loading. Visible vector layers compose the portrait and battlefield figure from equipped pieces; these remain prototype drawings, not final character art.

![Compare a reinforcement before fitting it](armor-body-preview.png)

**Town Armourer** offers one of each component available at that town’s weekly market tier. Prices use the town reputation quote. Selecting an item previews the fit and shows the cash remaining after purchase and five days of current wages. **Buy to stores** charges once and leaves the piece loose; fitting it is a separate confirmation. Armour stock depletion is saved. This stock is separate from the regional food economy.

**Whole kits** equips or stores an entire assembled outfit. **Exchange kits** swaps the selected body or helmet with another living company member, including an empty slot. Both soldiers' protection and costs are previewed. Components keep their physical identity and condition. A removed individual component becomes loose company stock; a stored kit keeps its children together. Descriptive kit names and protection/load summaries distinguish stored outfits.

A hinged visor requires a bascinet. Cheek guards fit the iron cap, nasal helm or bascinet. Plumes and crests need a shell. The editor explains incompatible combinations and disables fitting them; remove the conflicting attachment first. Buying an incompatible loose piece remains possible for another outfit.

![A helmet assembled from individual pieces](armor-helmet.png)

### Protection, condition and fatigue

Body armour is one combat pool: the current condition of every protective body component, including the base garment. Helmet armour is a separate location. A body hit resolves once against the combined total, then assigns the resulting wear to mantle, reinforcement, outer protection, mail and finally the base garment. Helmet wear reaches face protection, shell, mail and padding in that order. Cosmetic pieces with no durability absorb nothing. There is no second padding absorption step. Internal component subtotals remain for condition tracking and old-save compatibility. Materials and attack direction do not yet add separate resistances.

Every protective piece retains its own condition through battle, repair, storage, transfer and saving. One repair action restores worn components and equipped/carried shields for one tool per 12 missing condition, rounded up across the outfit. Survivors keep damaged gear. Victory recovers fallen allies' complete kits; defeat or draw loses their kits and component contents. Contract salvage can include new components; killed enemies' modular outfits are also recovered after victory.

Load comes from all worn armour parts, including damaged parts. In 0.14 it combines with weapon, shield, ammunition and carried load to reduce stamina capacity and initiative by one per point. It does not alter automatic recovery or attack costs. The editor shows the actual equipped totals; extra protection therefore changes both endurance and turn timing.

The weapon actions above use these same physical armour pools. Material-specific resistances and directional coverage remain future work.

### Existing companies

Old body, underlayer and helmet items become components of intact assemblies with the same IDs, condition, owners and protection. Historical pieces retain **zero additional armour load**, preserving an ongoing battle's costs and RNG continuation. Newly bought or salvaged components use normal weight. Existing recruits keep their old advertised gear instead of receiving a new random outfit. A fresh company uses the full generated layered system.

## Different people, different companies — new in 0.10

Every fresh launch without a save and every confirmed **New company** rolls a new campaign seed. The confirmation shows that seed: type digits to replay a particular company, or press **R** to roll another. The first company is saved immediately. Loading never generates replacements for your people.

Each new campaign creates **six founders and 30 recruits**: two candidates per town per week across the five weeks touched by the month. The entire population is generated once and saved, including future boards. Names are unique within that population. Looking at a candidate, travelling away, or loading cannot reroll their abilities. Candidates move off the board when the week changes; a hired person remains in the company.

Founders and recruits share one generator:

- **Eight backgrounds:** militia, poacher, woodcutter, deserter, caravan guard, farmhand, gravedigger and outrider. These bias starting attributes and equipment; they never restrict weapons or perks. A poacher can arrive with a spear and strong defensive potential.
- **Age and starting ability:** ages 18–49; older arrivals tend toward more attack skill and defence, with less health, stamina and initiative. All begin at 0 recorded company XP. Age does not advance during this one-month prototype.
- **Personal stats:** Health, Stamina, Resolve, Initiative, Melee skill, Ranged skill, Melee defence and Ranged defence. Resolve controls morale checks; initiative orders activations.
- **Two aptitudes:** each rolled at 1–3 out of 3, with the other attributes at 0. They improve future development gains; they do not silently boost starting stats.
- **Gear, fee and wage:** generated equipment is included in hiring. More capable or better equipped recruits generally cost more. Founders cost 3–6 crowns/day each; later recruits cost 3–8. Starting equipment has at least three shields, two mail coats and at most two ranged weapons, with spare weapons available. Viability is protected without fixing six roles or guaranteeing victory.

Open **Company & Equipment → Person & Service → Profile & Growth** to inspect an individual. On a recruit board, **Profile** shows abilities, aptitude gains, temperament, all included gear and the quoted cost before purchase. An existing full company can still inspect candidates.

![A generated recruit, including unusual strengths and growth potential](generated-recruit.png)

| Temperament | Benefit | Tradeoff |
| --- | --- | --- |
| Aggressive | +5 attack accuracy | Attacks cost 4 more fatigue |
| Cautious | Incoming attacks have −5 accuracy | Own attacks have −4 accuracy |
| Independent | +8 accuracy with no adjacent fighting ally | −4 with an adjacent fighting ally |
| Sociable | +6 accuracy beside a fighting ally | −4 alone |
| Stoic | +10 resolve on morale checks | -5 initiative |
| Restless | Movement costs 1 less fatigue per AP, minimum 1 | Guard costs 5 more fatigue |

These effects operate in the actual command rules and hit breakdown. Movement previews, group-advance costs and reachable hexes use each person's movement rate. Attack/guard costs show the temperament cost. Automatic recovery is 15, or 10 with Damaged lung; Waiting never recovers it a second time. All soldiers still receive 9 AP; temperament does not take control away from you.

At **40, 100 and 180 XP**, earn **one attribute choice plus one perk choice**. In Profile & Growth, choose one attribute to develop. Repeat that attribute at a later rank or broaden the soldier's strengths. Choices are permanent and recorded in the service history.

| Attribute | Gain when chosen (A = aptitude, 0–3) |
| --- | --- |
| Maximum health / Stamina | 4 + A; increasing health does not heal injuries |
| Melee skill / Ranged skill / Resolve | 2 + A |
| Melee defence / Ranged defence | 1 + A |
| Initiative | 3 + A |

A recruit with low starting skill but high skill aptitude can catch up; a strong older fighter may have their best potential in another attribute. You still choose their equipment, perks, position and development. These are small mechanical identities, not authored companion quests or branching classes.

![A survivor spends an earned attribute choice](generated-development.png)

**Existing saves keep their people, gear, history and recruit boards.** See the migration rules above; earlier active battles finish under their saved rules, with health and armour conversion when returning to camp.

## A clearer first campaign

**First contract** follows your actual company: accept a job, inspect the road, deploy, move, link shields, strike and recover. It highlights the relevant visible control. Lessons record successful commands, so they can be practised out of order. Linked shields must actually exist; clicking an unavailable order does not complete the lesson. Opening the whole-company retreat confirmation teaches its consequences; **Keep going** cancels without abandoning work. Individual Withdraw still costs AP, fatigue and opportunity strikes.

The guide is optional and never changes enemy strength, resources, accuracy or action costs. Opening it pauses enemy processing; closing it resumes play. Guidance and its hidden/visible preference survive F5/F9 and restart. Existing saves begin with hints hidden and no invented practice history. The guide remains available through **Field guide** after the first contract.

Combat shows brief labels over the affected soldier: total armour lost and actual HP lost, misses, fatigue recovery, morale, routing, death and broken shield links. Overkill is not reported as extra HP loss, and body-layer losses are combined. **Battle record** opens the latest 100 saved events, newest first; head hits are identified there. Repair detail remains in camp. F9 preserves the record without replaying old popups. An already-started old battle retains its historical feedback until settlement.

![Actual combat damage and morale feedback](combat-damage.png)

### Plan the costs before committing

**Company plan** shows food and wage reserves, existing debt, a five-day upkeep budget, and each living soldier's wounds, missing HP, repair tools, unspent training and reduced starting morale. Select a name to open their company entry. The one-day rest forecast shows remaining crowns, rations, debt, medicine consumed and each survivor's resulting condition. **Rest 1 day** performs that ordinary paid rest.

Selecting a connected destination previews the actual travel result: day, remaining cash and food, unpaid wages, contract status and any company ending. It also handles escort payment before arrival upkeep, deadlines and independent patrol resolution. A two-day journey that disbands the company after the first day shows its last camp rather than promising arrival. Illegal escort detours are unavailable.

These forecasts advance a separate copy of the complete current campaign. Viewing them consumes nothing and does not alter RNG, saves or the world. They assume no additional intervention before the displayed action; they do not predict combat victories or unearned contract income. Travel heals only two HP on fed days and does not treat deep wounds. Hunger, unpaid wages and ending the month remain possible choices, with warnings.

Recruit cards show how much money would remain after the hire and **five days of the enlarged company's wages**, including current arrears. This is a wage reserve only; food, repairs and medicine still need funding. Warnings do not prevent deliberate risk-taking.

![Readiness and the actual cost of another rest day](survivor-plan.png)

### Balance review

The following is a historical v0.9 balance review. Armour, fatigue, weapons and enemy equipment have since changed in v0.11–0.12. A paired experiment reducing ordered shield support from +5 to +3 per neighbour barely changed the dominant forest-line result: **20/20 to 19/20** wins, and it changed enemy defences too. Ridge outcomes were unchanged in that sample. That experiment is retained only in the test suite.

In the v0.9 fixed-founder comparison, across 30 matched month seeds, an automated policy that preserved more wage reserves and stopped optional spending once the region was secure reduced unpaid disbands from **9 to 5**, with successful months rising from **15 to 17**. That policy changes several spending decisions; it does not establish a single optimal reserve or human difficulty. The planning screens expose those costs to the player. Forest stance balance and ridge defence still need human playtesting.

## Bonds, grief and camp life

Relationships belong to named soldiers, including the fallen. New recruits begin with no inherited bonds. The **Bonds & Camp** screen shows trust, its dated causes, active grief, strain and the actual next-deployment morale. Companion lists and event histories are paginated; Personal History opens the soldier's service record.

| Event | Consequence |
| --- | --- |
| Two deployed soldiers survive a completed battle | +1 trust |
| They also hold an ordered line under threat for a full round | +2 total trust for that battle |
| Voluntary retreat | −1 trust among deployed survivors; no battle XP or grief recovery |
| Trust reaches 3 | They become comrades; trust is capped at 6 |
| Two or more consecutive days of hunger or unpaid wages | −1 trust per bad day between living soldiers, minimum −3 |

Line credit requires adjacent, fighting soldiers with Line order, at least one shield, and an active enemy within three hexes of either soldier at the end of the enemy turn. A pair earns it once per battle; safe staging does not count. Trust 1–2 is Familiar, zero is Unproven, and negative trust is Strained.

Each fighting comrade within two hexes reduces a soldier's morale loss by **2**, capped at **4**. Loss is at least one; Steadfast applies its ordinary 40% reduction afterward. A comrade's death within the ordinary three-hex death-shock radius adds **8** to the usual 24 shock. Dead or routed companions provide no support.

A surviving deployed soldier who loses an established comrade carries **three further completed battles of grief**. Each active loss reduces starting morale by **4**, capped at **8**. A completed survived battle removes one remaining battle; a voluntary retreat does not. New grief is recorded after existing grief ages. A remembered bond and its history remain after grief ends.

Each hungry day adds **1 strain**; each unpaid day adds another **1**, capped at **6**. Each strain reduces starting morale by **2**, capped at **12**. A fully fed and paid rest day removes one strain. Base starting morale is 85, or 75 with Haunted; strain and grief subtract from that base. The sidebar displays actual morale, nearby support and both starting penalties.

| Camp decision | Cost | Effect |
| --- | --- | --- |
| Extra meal | 6 additional rations; no time | Remove up to 2 strain; once per soldier per day |
| Support grief | One fully fed and paid company rest day | Ease the selected soldier's oldest active loss; keep the bond and history |
| Mediate dispute | One fully fed and paid company rest day | Add 2 trust to the selected strained pair, stopping at neutral |

Support and mediation require enough money for wages **including arrears** and enough rations for everyone. Ordinary rest also advances the world, healing and wound treatment; it consumes any medicine used. It can expire a contract or reach the month's end. Refused decisions charge nothing. Meals cannot be bought without strain, support without grief, or mediation without a living strained pair. Mediation cannot purchase comradeship.

![A remembered comrade and the cost of support](bonds-grief.png)

## Formation orders and tactical command

Press **4** or click **Formation orders**. In new battles only the active fighter is selectable. An order changes each selected soldier's stance; it does not move them into a preset arrangement. You still choose their positions.

Each change costs **2 AP and 4 fatigue per soldier** and lowers any active guard. Orders persist across turns and saves. A routed soldier drops back to Free order. If any selected member is ineligible, already has that order, lacks resources, or cannot act, nobody changes or pays. Use Clear to make a fresh selection.

| Order | Benefit | Cost or condition |
| --- | --- | --- |
| Shield line | Each adjacent shield with the same order adds another +5 defence, maximum +10; this stacks with normal adjacent-shield support | Requires a shield or spear; every normal movement step costs +1 AP, plus that soldier’s movement fatigue for the extra AP |
| Spear in the shield line | +10 attack accuracy on a two-hex thrust with an active, ordered friendly shield on an intermediate hex | Both soldiers must retain the line order; the actual shield must remain in position |
| Loose order | Enemy bow accuracy falls by 12 when no active friendly soldier is adjacent | No shield support received or provided; enemies gain +5 melee accuracy, even when crowding cancels the arrow benefit |
| Free order | Ordinary movement and passive adjacent-shield support | No ordered-line or spacing bonus |

Normal shield support remains +5 per adjacent active shield, maximum +10. Thus a properly linked line can provide **+20 total support**, before equipment and the separate Guard action. Guard still costs its normal 4 AP and fatigue; adopting a line order never grants a free shieldwall action.

Blue links show the company's ordered shield connections; red links show enemy ones. **GAP** marks a shield with the line order but no ordered shield neighbor. **L** marks active loose spacing, and **L!** means an adjacent ally has cancelled its arrow benefit. Support updates immediately after movement, routing or death. Shield links protect in every direction in this prototype; there is no facing or directional shield arc.

### Advance the active fighter

The command screen previews one-hex moves in all six directions for the active fighter, including terrain, elevation, fatigue and line-order costs. No other soldier can be moved during that activation. Occupied hexes, enemy engagement, water and insufficient resources refuse without charge. Use Withdraw to leave enemy control. Historical ongoing battles retain their original group movement until settled.

### Read the fight

The sidebar shows actual shield support, line gaps or loose spacing, terrain/height, hex coordinates, and movement cost including the line surcharge. Hover an enemy for the current hit chance. Press **5** or click **Hit odds & positioning** to choose an enemy and inspect every nonzero modifier: skill, gear, elevation, adjacent shields, ordered line, spear screen, guard, spacing, outnumbering, distance, morale and high-defence diminishing returns. The report also states why an attack is currently illegal. The sum is clamped to 5–95%, exactly as in the combat roll.

### Coordinated enemies

Enemies choose a shared pressure target each turn from visible positions, injuries, equipment and objective pressure. Shield troops screen archers and support one another. Spears prefer a second rank behind shields. An unshielded axeman tries to reach a vulnerable target around the opposing line; archers seek clear shots and attempt an ordinary paid withdrawal when engaged. Enemy line orders, movement, attacks, guards and withdrawals use the same costs and legality rules as player commands. Their current role and focus can be inspected in the sidebar.

On ridge and wagon defence, enemies put pressure on the objective and its defenders. They delay costly line orders while far away and prioritize reaching the banner. They receive no extra troops, damage or free actions. In the historical, pre-initiative paired 40-seed ridge comparison, defenders won 33 times, down from 40 with the previous AI. Those seven losses were combat defeats; a separate abandoned-ridge check verified actual capture. This benchmark does not establish balance for 0.14.

This is deterministic tactical scoring with a shared target, not a long-range strategic planner. Objectives still matter, and automated field results remain uneven. Saved active plans and RNG continue exactly under their saved turn mode; the firing hotfix remains included. An ongoing older fight retains its historical weapon rules; subsequent deployments use current equipment and actions.

![Exact hit-chance explanation](hit-breakdown.png)

## Experience, training and scars

Each soldier has a separate XP ledger, learned perks, scars and service record. Founders and newly hired recruits start at **0 XP**. Replacements have new identities; equipping a dead soldier's gear does not transfer training or experience.

| Rank | Total XP required | Total training choices earned |
| --- | ---: | ---: |
| Recruit · level 1 | 0 | 0 |
| Blooded · level 2 | 40 | 1 |
| Seasoned · level 3 | 100 | 2 |
| Veteran · level 4 | 180 | 3 |

A surviving deployed soldier receives **20 XP after a completed battle**, plus **10 for victory** and **5 per kill**, capped at three kill bonuses per battle. A voluntary retreat gives no battle XP. Dead soldiers retain previous XP and their final battle record but receive no new settlement XP.

A successful contract adds **10 XP to living members recorded on the roll when it was accepted**. Later hires do not receive that completion bonus. Escort defence grants battle XP immediately; the contract bonus waits for delivery. An escort crossing protected by patrols can finish without combat and grants only contract XP. NPC resolution, abandoned work and exhausted cargo grant no completion XP.

Awards are keyed to individual battles and contracts. Repeating settlement, reloading an aftermath, or choosing a perk twice cannot grant another reward. XP continues to be recorded above 180, but level 4 is the current rank cap. Levels themselves add no hidden stat bonuses.

Open **Person & Service** from the company screen, choose a soldier, and select one of the available training cards. Each choice is permanent for that company; there is no respec. You can learn three of the four perks, once each, only while alive and in camp before the campaign ends.

| Perk | Actual combat effect |
| --- | --- |
| Shield drill | With a shield, guarding costs 10 fatigue instead of 15; shieldwall defence rises from 20 to 30. Unshielded bracing is unchanged. |
| Weapon handling | +5 attack accuracy; weapon attacks cost four less fatigue, minimum one. Applies to all weapons. |
| Second wind | Recover removes 50 fatigue instead of 35; it still requires 4 AP and ends the soldier's turn. |
| Steadfast | +15 resolve on morale checks. Older ongoing battles retain their historical effect. |

![A newly hired soldier earns and selects training](service-trained.png)

A survivor who loses **at least 30 actual HP in that battle** and finishes at **one quarter of their deployed maximum HP or less** can acquire a permanent scar. The greatest flesh hit and routing state determine which one. Old wounds or arriving at low HP alone cannot produce a scar. There are at most two distinct scars; the same scar cannot be stacked.

| Scar | Trigger within a critical-survival case | Lasting effect |
| --- | --- | --- |
| Clouded eye | Greatest flesh hit was to the head | −4 melee and ranged skill |
| Haunted | Otherwise, the soldier routed or escaped | Starts wavering; strain and grief affect resolve checks |
| Damaged lung | Otherwise | Automatic fatigue recovery per turn is reduced by 5 |

Scars are separate from the existing three-day deep wound. Rest and medicine remove that temporary wound; **scars remain**. Their effects apply on the next deployment, and scar names are visible in battle field notes. No scar treatment or removal is available in this build.

The service record lists recruitment, battles and their actual outcomes, XP awards, ranks, chosen training, severe injuries, completed wound treatment, first kills, multi-kill deeds, holding the marked ground at victory, and death. It also records bonds, grief, hardship and camp decisions. It is paginated and remains readable for fallen soldiers. Detailed service history begins in v0.6 and relationships in v0.8; migration never invents past events.

![A treated wound leaves a permanent scar](scar-after-treatment.png)

## What the world now does

Every day of travel, rest or battle advances the company and region together. Opening screens, equipping, repairing, shopping or accepting work does not pass time.

| Town | Daily food production | Daily consumption | Base price for 24 rations |
| --- | ---: | ---: | ---: |
| Ashwick | 24 | 6 | 24 crowns |
| Stonecross | 0 | 8 | 30 crowns |
| Dunmere | 6 | 6 | 30 crowns |

The neutral food price is **base price + ceil(max(0, 120 − current stock) / 3)**. Your council reputation then adjusts it: **round(neutral price × (100 − clamp(reputation, −20, 20)) / 100)**, minimum one crown. The same reputation adjustment applies to tool and medicine purchases. Buying removes 24 food from that town and uses the price shown before the purchase. A market with fewer than 24 food cannot sell a pack. Towns consume only food they actually have; shortages are recorded in their saved state.

| Caravan route | Load | Normal dispatch interval | Travel time |
| --- | ---: | ---: | ---: |
| Ashwick → Blackwater Ford → Stonecross | 48 food | 4 days | 2 days |
| Ashwick → Cairn Ridge → Dunmere | 36 food | 6 days | 3 days |
| Dunmere → Brackenwood → Stonecross | 30 food | 6 days | 3 days |

Loading deducts the cargo from the origin immediately. Dispatch requires enough food for the load plus a 24-food reserve; otherwise the merchant tries again next day. A newly loaded wagon waits until the next day, giving you a chance to accept its escort job. Caravans follow these wagon roads; your company can also use the map's shorter foot trails.

An unprotected caravan reaching an active camp is seized unless stationed patrols provide enough coverage. Its cargo remains unavailable to the destination market, and raiders can spend it. Recovery returns **only the unspent food**. A depleted wagon remains in the ledger as **PLUNDERED**, with no recovery job. Deliveries transfer cargo once; the destination council also receives one treasury crown per two delivered food.

**There is no respawn timer.** Clearing a band releases its remaining wagon cargo and destroys any loose raider stores. Only another strong band can pay to reoccupy that road. Destroying every band keeps the region clear for the rest of the month.

Each active band consumes one stored food daily when available. It can spend **36 food to recruit**, raising threat from 1 to 2 to 3 (four to six tactical enemies). A strength-3 band can spend **36 food to found a new strength-1 band** at an empty, unpatrolled site. A new generation creates a new clearance contract.

A strength-3 band can also spend **12 food to raid its adjacent town**, at most once every five days, when patrol coverage is insufficient and there is food to steal. It takes up to 18 food into its own stores and destroys up to 24 council crowns. Raid pressure halves tax income and fades when neighboring roads are no longer threatened by uncontained strength-3 bands. The raid targets are Stonecross from the ford, Dunmere from the forest, and Ashwick from the ridge.

The trade report shows every wagon's identity, load, route, position and outcome. Map wagon icons are clickable. Completed, seized and plundered shipments remain in the ledger; use its page controls to inspect older entries.

![Later deliveries after clearing the ford](trade-after.png)

## Councils, patrols and reputation

| Council | Settlement | Starting treasury | Healthy daily tax | Commercial rival |
| --- | --- | ---: | ---: | --- |
| Ashwick Wardens | Ashwick | 60 crowns | 18 crowns | Stonecross Guild |
| Stonecross Guild | Stonecross | 20 crowns | 12 crowns | Ashwick Wardens |
| Dunmere Compact | Dunmere | 35 crowns | 12 crowns | Stonecross Guild |

Towns have fixed council ownership in this build. After daily production and consumption, stock below three days' demand halves taxes; below one day's demand stops them. Raid pressure applies another halving. Delivery tolls and your patronage also add money. Treasury income, patrol spending and raid losses are accounted separately.

A council with **90 crowns** and no active patrol buys a strength-2 patrol. It chooses an adjacent road based on threats, existing coverage and the road threatening its own town. The patrol travels for the road's actual one or two days, then holds station for four days. Its council pays **6 crowns per active day**, including travel; an unpaid patrol withdraws.

Stationed patrol strengths combine. Superior strength destroys a camp and frees its cargo; equal strength protects shipments while the band remains; inferior strength is defeated. Stationed patrols also deter reoccupation. Travel does not provide remote protection, and a returning/defeated patrol cannot protect a road.

In a town, use **Councils & Patrols → 90c · Next patrol to…** to transfer company money and choose the council's next patrol destination. It dispatches on a later daily tick when no patrol is active. One order may be queued; the buttons cannot overwrite it with another payment. You are buying dispatch priority, not guaranteed victory.

| Company action | Client reputation | Client's rival |
| --- | ---: | ---: |
| Complete a contract, including delivered escort | +8 | −2 |
| Fund a patrol | +4 | −1 |
| Lose, abandon or expire a contract | −6 | No change |
| NPC resolves your target, or captured food is exhausted | No change | No change |

Reputation is capped at −30 to +60. Positive reputation discounts supplies (up to 20%); negative reputation adds up to 20%. Contract quotes gain half a percent per reputation point, rounded up in crowns. Accepted payment stays fixed. At **−12 or below**, that council refuses escort work; clearance and recovery remain available to rebuild trust. **+12** is labeled Trusted. Rival reactions represent competition between councils, not a war declaration.

![Councils after a funded patrol clears the ford](patrol-victory.png)

## Work comes from actual problems

The old weekly contract templates have been replaced. Recruit candidates still refresh weekly.

| Contract | Why it exists | Result |
| --- | --- | --- |
| Clear a camp | An active band threatens a road next to the issuing town | Destroys the band, frees remaining wagon cargo, protects future traffic |
| Recover a shipment | A particular wagon belonging to or supplying that town has been seized | Defeats its guards and sends the unspent load onward; the wider camp remains |
| Escort a shipment | A loaded wagon is waiting at your town and its route is threatened | Reserves its cargo, travels with your company, and pays when delivered |

Use the board's page arrows when more than two jobs are available. You can accept one job at a time. An accepted job has a fixed deadline; later offers cannot extend it. Abandoning, expiring or losing a job spends its identity, so it cannot be repeatedly accepted for rewards. A new raider generation or a new wagon creates distinct work.

Neutral clear jobs pay **380–580 crowns** according to threat. Recovery jobs pay 200 plus the remaining load at acceptance. Escorts pay 400 plus the load size. Reputation adjusts these quotes; successful recovery honors the accepted quote even if some cargo has since been spent. Completing a contract also grants 12 tools, 4 medicine and one piece of salvage.

If patrols resolve your accepted clearance, or another action frees/empties your recovery target, the contract is withdrawn with **no pay and no reputation penalty**. It does not count as a completed contract. Threat and remaining cargo are refreshed while you travel; a band can recruit before you arrive.

### Escorts

After accepting, use the **Escort to…** button or select the next stop on the map. The wagon waits when you rest; it does not move independently. You must follow its route. At a threatened crossing without adequate patrol coverage, onward travel is blocked until you win the defence battle. A cleared or sufficiently guarded crossing allows passage without combat.

The tactical objective is to protect the wagon circle for eight full rounds, or kill/rout the enemy. Three consecutive uncontested enemy capture rounds lose the defence. The circle is a control objective: the wagon is not a separately moving unit with its own HP.

Winning that battle preserves the shipment but pays **zero** immediately. Return to the map and continue to the destination town. Delivery then transfers the cargo, pays the contract and counts toward the month's goal. An escort does not clear the road for future unprotected caravans.

Abandoning or missing the deadline releases the reserved wagon. At an undefeated ambush, that means seizure. Retreating from the defence also loses the load and pays nothing.

![Native escort defence](escort-battle.png)

## Company costs and recovery

You still manage six living soldiers. Recruits fill vacancies; every fallen veteran keeps a permanent memorial entry. The eventual 12–20-soldier roster is future work.

| Rule | Effect |
| --- | --- |
| Daily wages | Generated founders cost 3–6 crowns each; generated recruits cost 3–8 |
| Daily food | One ration per living soldier |
| Unpaid wages | Accumulate as arrears; later daily payments clear the debt first |
| Three consecutive unpaid days | Company disbands and releases any reserved escort |
| Not enough food for everyone | Each living soldier loses 8 HP, to a minimum of 1; no healing or treatment that day |
| Fed travel | Heals 2 HP daily; does not treat deep wounds |
| Fed rest with medicine | Each injured soldier uses one medicine, heals 18 HP and removes one wound day |
| Rest without medicine | Heals 6 HP; deep wounds remain |
| Deep wound | −12 maximum HP and −10 skill until three treatment days are completed |
| Repair | One tool per 12 missing durability, rounded up across worn armour and equipped/carried shields |
| Tools / medicine | Neutral prices: 12 tools for 36 crowns; 6 medicine for 30 crowns; council reputation adjusts both |

Battle-day wages and rations count survivors. Battle pay and escort delivery pay are added before the corresponding daily upkeep. Tools and medicine retain unlimited town supply in this milestone; only food has regional stocks. Contract payouts are secured commissions, separate from the council patrol treasury; this is not a complete monetary economy.

Choose a soldier and gear slot. Weapons, shields, carried equipment and ammunition use the loadout editor; body and helmet cards open the assembly editor. Swapping cannot repair or duplicate it. Bows, crossbows and billhooks use both hands and return shields to stores when fitted in camp. Victory recovers fallen allies' gear; defeat or a draw loses it. Survivors retain actual health, wounds and equipment condition. Routed soldiers return alive.

Backgrounds bias randomly rolled stats, equipment and wages. Those biases are included in displayed stats. Weapons use either melee or ranged skill and the corresponding target defence. Aptitudes and temperament add the individual decisions described above.

## Combat controls

| Input | Order |
| --- | --- |
| Click soldier / roster card | Select |
| Click highlighted empty hex | Move |
| Hover hex / enemy | Inspect terrain, costs and legal hit odds |
| Click enemy | Attack if range, line of sight, AP and fatigue permit |
| 1 | Shieldwall / guard: 4 AP; 15 fatigue, or 10 with Shield drill and a shield |
| 2 | Recover: needs 4 AP, sheds 35 fatigue (50 with Second wind), ends the turn |
| 3, then adjacent empty hex | Withdraw: 4 AP, 12 fatigue; each adjacent enemy gets a strike |
| 4 | Active fighter’s formation order and one-hex advance preview |
| 5 | Exact hit-chance breakdown and attack legality |
| 6 | Weapon actions, carried switches and enemy equipment inspection |
| Space (W also works) | Wait once this round, retaining remaining AP and fatigue |
| Tab | Return inspection to the active fighter |
| F | End only the active fighter’s activation |
| F5 / F9 | Save / load the entire campaign |
| H | Contextual help |
| N | Confirm a new company, replacing the save |
| Escape in any report or service record | Close the report |

Every soldier receives 9 AP. Player and enemy commands use the same legality rules. Combat retains terrain/elevation, zones of control, obstructed arrows, spears reaching through allies, adjacent shield support, layered armour and contagious morale.

Ford clearance uses three uncontested capture rounds; forest clearance and shipment recovery require killing/routing all opponents; ridge clearance and escort defence require eight full rounds of defence. All can also end by breaking the enemy. Unresolved battles end after 30 rounds.

## Saving and upgrades

Company, region and active battle are one save: town stocks, production/consumption totals, shipments, departure schedules, cargo ownership, road security, band resources and generations, council accounts, patrol positions and orders, reputation, contracts, recruits, soldiers, equipment, wounds, XP ledgers, perks, scars, service records, memorials, bonds and their causes, grief, strain, paid camp decisions, formation orders, shared-line credit, active enemy plan, and recent journals.

Generated population, aptitudes, temperament, development choices, every weekly recruit board, assembled component references, individual condition and purchased armour/weapon stock, carried item identities, shield condition, ammunition, crossbow loaded state, reactions, stagger recovered loot, weekly market inventories, merchant purses and the sale ledger are included. Optional guide progress is saved alongside the campaign. Forecasts, open overlays and transient combat labels are not gameplay state and are not replayed on load.

First launch, new companies, world actions and camp changes auto-save. During a battle, use **F5** for an explicit checkpoint. **F9** reloads; startup automatically resumes. Writes use a temporary file and rename. Invalid saves are rejected without altering the live company. This is not an ironman system.

The path remains `user://ashen-company-save.json` under Godot's user-data directory for **Battle Brothers 2 — The Ashen Company**.

- **0.13 saves migrate automatically.** People receive the eight-stat conversion described above without rerolling equipment or identities. An ongoing old battle retains team turns; the next deployment uses individual initiative. Current company schema is **14**, battle schema **11**. The 0.15 health and armour conversion runs after the old battle settles.
- **0.12 saves migrate automatically.** Existing gear, advertised recruits and active battle equipment are retained. Market books and sale history initialize without retroactive trades. The old active fight continues exactly; later deployments use role/resource-based enemy loadouts and individual turns.
- **0.11 saves migrate automatically.** Existing identities and equipment remain intact. Old shields receive 40 condition; ranged soldiers receive matching ammunition; carried slots start empty. An ongoing old battle retains its weapon rules and RNG continuation until settled; the next deployment uses current rules.
- **0.10 saves migrate automatically.** Personal generation and development remain intact. Original armour pieces are packed into assemblies without changing protection, condition or old battle costs.
- **0.8–0.9 saves migrate automatically.** Names, gear, wounds, XP, social state, recruit schedules, active battle and RNG remain. Personal fields start neutral with no fabricated history. Optional guide progress is retained where present.
- **0.7 saves migrate automatically.** Company, progression, world, orders, active battle and RNG are retained. Relationships begin neutral, with no invented earlier bonds, grief or hardship. Subsequent AI decisions use the current rules. New social events and active tactical comrades persist after re-saving.
- **0.6 saves also migrate.** Company, progression, world, active battle and RNG are retained. Soldiers begin in Free order with no invented formation or enemy plan, then receive neutral social state.
- **0.5 saves also migrate.** Existing company, world, accepted work and active battles remain. Each soldier receives 20 XP per previously recorded battle plus 5 per recorded kill, in one explicit earlier-service credit. Perks remain unchosen, and no retrospective scars or detailed deeds are invented. Re-saving prevents credit from repeating.
- **0.4 saves also migrate**, preserving stocks, cargo, company resources, accepted contracts, reserved escorts and active battles. Councils start with their configured treasuries and neutral reputation on the saved day. Old fixed camp return dates are discarded.
- **0.3 saves also migrate.** Company resources, day, roster, gear and accepted work remain. The trade simulation starts on that saved day; it does not retroactively replay earlier days. A legacy contract retains its original battle and payment.
- **0.2 saves also migrate**, retaining the earlier upgrade's 400-crown / 90-ration provision grant. Re-saving prevents that grant repeating.
- **0.1 battle-only saves remain separate.**

The company journal keeps its latest 60 entries, regional news 200 entries, and all shipment, patrol and fallen-soldier records remain saved for the month. Save/load preserves subsequent autonomous decisions and patrol IDs, not only the current screen.

## Scope and balance

This is a playable regional prototype with vector placeholder art. Routes, production and decision rules are authored and deterministic; outcomes respond to resources and intervention. Councils own fixed settlements and compete for patronage. There is no territory conquest, inter-council warfare, treaty negotiation, regional civilian population model, procedural roads, random travel ambushes, player cargo trading, reserve roster, branching class trees, authored companion dialogue, final animation or audio yet. Patrols use strength comparisons, while company battles use the tactical simulation.

Escort defence can be costly. The enemy AI uses weapon roles, a shared pressure target and local position scoring rather than a full strategic planner. Automated month tests produce both wins and failures; those are verification results, not proof of final human balance.

## Source and checks

| File | Responsibility |
| --- | --- |
| `src/world.gd` | Food and treasury ledgers, caravans, raider spending/expansion/raids, council patrols, regional snapshots |
| `src/campaign.gd` | Company, reputation, sponsorship, contracts, daily accounting, settlement, save validation |
| `src/market.gd` | Prosperity thresholds, weekly stock, merchant purse and sale-ledger validation |
| `src/arsenal.gd` | Weapon families, action definitions, equipment slots and armament validation |
| `src/combat_damage.gd` | Pooled armour loss, penetration, overflow and HP-only head multiplier |
| `src/armor.gd` | Layer definitions, compatibility, totals, seeded outfits and component damage |
| `src/people.gd` | Seeded population, backgrounds, temperament, aptitudes, personal costs and validation |
| `src/progression.gd` | Ranks, XP ledger, perk/scar definitions, service records and validation |
| `src/relationships.gd` | Pair trust and causes, grief, hardship, settlement/upkeep ledgers and validation |
| `src/playability.gd` | Read-only travel/rest forecasts, readiness summaries and optional guide metadata |
| `src/battle.gd` | Individual initiative queue, hex tactics, formation support, enemy plan, hit arithmetic, morale, perks and injuries |
| `src/main.gd` | Native region, council/road reports, company, battle and aftermath UI |
| `data/world.json` | Production, markets, routes, council budgets and political action costs |
| `data/region.json` | Map locations and roads |
| `src/legacy_*.gd`, `data/legacy_*.json` | Earlier state validation and migration; frozen v0.7 battle engine for the paired ridge benchmark |

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/turns.gd
godot --headless --path . --script res://tests/turns_combat.gd
godot --headless --path . --script res://tests/run.gd -- --battles=200
godot --headless --path . --script res://tests/fields.gd
godot --headless --path . --script res://tests/world.gd
godot --headless --path . --script res://tests/company.gd
godot --headless --path . --script res://tests/progression.gd
godot --headless --path . --script res://tests/formations.gd
godot --headless --path . --script res://tests/relationships.gd
godot --headless --path . --script res://tests/playability.gd
godot --headless --path . --script res://tests/people.gd
godot --headless --path . --script res://tests/armor.gd
godot --headless --path . --script res://tests/weapons.gd
godot --headless --path . --script res://tests/equipment_economy.gd
godot --headless --path . --script res://tests/archer_rules.gd
godot --headless --path . -- --smoke
```

Smoke mode never reads or writes the player's save. Native tests need a display and an isolated data directory because they create and reset test companies. `turns_ui.gd` exercises eight-stat profiles, gear previews, enemy-first activation, inspection without control, Wait, save/load, a full actual contract battle and earned Initiative development. See `docs/VALIDATION.md` for the exact checks rerun in 0.15. The other commands below are historical suites, some intentionally using frozen earlier rules; they were not all rerun for this release. `people_ui.gd` uses generated people and real seed controls. `armor_ui.gd` tests equipment previews, purchases, transfers, damage and repair. `weapons_ui.gd` exercises paid weapon actions, ammunition, shopping and recovered gear. `weapons_compat_ui.gd` continues a frozen v0.11 fight and then deploys under later rules. The archer journey uses declared positioning fixtures and real UI input followed by an unmodified battle:

```sh
XDG_DATA_HOME="$(mktemp -d)" godot --path . --script res://tests/turns_ui.gd
XDG_DATA_HOME="$(mktemp -d)" godot --path . --script res://tests/weapon_compare_ui.gd
XDG_DATA_HOME="$(mktemp -d)" godot --path . --script res://tests/armor_readability_ui.gd
XDG_DATA_HOME="$(mktemp -d)" godot --path . --script res://tests/archer_ui.gd
XDG_DATA_HOME="$(mktemp -d)" godot --path . --script res://tests/equipment_economy_ui.gd
XDG_DATA_HOME="$(mktemp -d)" godot --path . --script res://tests/equipment_compat_ui.gd
XDG_DATA_HOME="$(mktemp -d)" godot --path . --script res://tests/weapons_ui.gd
XDG_DATA_HOME="$(mktemp -d)" godot --path . --script res://tests/weapons_compat_ui.gd
XDG_DATA_HOME="$(mktemp -d)" godot --path . --script res://tests/armor_ui.gd
XDG_DATA_HOME="$(mktemp -d)" godot --path . --script res://tests/people_ui.gd
XDG_DATA_HOME="$(mktemp -d)" godot --path . --script res://tests/ui_flow.gd
XDG_DATA_HOME="$(mktemp -d)" godot --path . --script res://tests/tour.gd
XDG_DATA_HOME="$(mktemp -d)" godot --path . --script res://tests/politics_ui.gd
XDG_DATA_HOME="$(mktemp -d)" godot --path . --script res://tests/progression_ui.gd
XDG_DATA_HOME="$(mktemp -d)" godot --path . --script res://tests/scars_ui.gd
XDG_DATA_HOME="$(mktemp -d)" godot --path . --script res://tests/formations_ui.gd
XDG_DATA_HOME="$(mktemp -d)" godot --path . --script res://tests/relationships_ui.gd
XDG_DATA_HOME="$(mktemp -d)" godot --path . --script res://tests/playability_ui.gd
```

See `docs/VALIDATION.md` for measured results. The game code and geometry are original. Bundled DejaVu fonts retain their license in `assets/FONT-LICENSE.txt`; no Battle Brothers game assets are included.
