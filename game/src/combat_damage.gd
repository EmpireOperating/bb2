extends RefCounted
## Ordinary hit baseline: independent regular/armour rolls, direct mitigation,
## overflow on destruction, then the head multiplier on HP only.
## This prototype stores whole durability points: armour wear rounds once here.
static func resolve_hit(regular: float, armour_damage: float, penetration: float, protection: int, head: bool = false) -> Dictionary:
	var bypass = penetration >= 1.0
	var loss = 0 if bypass else mini(protection,maxi(0,roundi(armour_damage)))
	var remaining = protection-loss
	var hp = maxf(0.0,regular*penetration-(0.0 if bypass else remaining*0.1))
	if remaining == 0 or bypass:
		hp += maxf(0.0,regular*maxf(0.0,1.0-penetration)-loss)
	return {"armor":loss,"hp":maxi(0,roundi(hp*(1.5 if head else 1.0)))}

# Current personal-perk path. Explicit context/rolls; no Battle, RNG or wear writes.
# Kept separate from resolve_hit: penetration=1 is NOT Puncture in this path.
static func current_head(c: Dictionary, head_roll: int, king_roll: int) -> bool:
	var head = head_roll <= c.head_chance
	if c.forced_head: head = true
	if c.body_only: head = false
	if c.king and king_roll <= 50 and c.helmet != c.body: head = c.helmet < c.body
	return head

static func resolve_current(c: Dictionary, regular_roll: int, armor_roll: int, head: bool) -> Dictionary:
	var regular = regular_roll*c.factor*(1.0+c.bonus)*c.grip*c.weakened
	var armor_damage = armor_roll*c.armor_special*c.weapon_armor*(1.0+c.bonus)*c.grip*c.weakened*c.hammer_factor
	if c.shatter: armor_damage *= 2
	if c.heavy_throw: armor_damage *= 1.2
	var protection: int = c.helmet if head else c.body
	var loss = 0 if c.bypass else mini(protection,maxi(0,roundi(armor_damage*c.armor_factor)))
	var remaining = protection-loss
	var hp = regular if c.bypass else maxf(0,regular*c.penetration-remaining*0.1)
	if not c.bypass and remaining == 0: hp += maxf(0,regular*(1-c.penetration)-loss)
	if head and not c.steel_brow: hp *= 1.5
	if head and c.advantage: hp *= 1.1
	if c.shatter: hp *= 0.5
	hp *= c.hp_factor
	hp *= c.ribs_factor
	return {"armor":loss,"hp":maxi(0,roundi(hp))}
