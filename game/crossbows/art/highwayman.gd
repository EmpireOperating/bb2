extends "res://painted_merge/bandits/appearance.gd"
const CrossbowFits = preload("res://crossbows/art/binding.gd")
const Original = preload("res://painted_merge/bandits/appearance.gd")
var _original=Original.new()
var _crossbows=CrossbowFits.new()
func describe(unit: Dictionary, catalog: Dictionary) -> Dictionary:
 var arms: Dictionary=unit.get("arms",{})
 if arms.get("weapon",{}).get("definition","") in CrossbowFits.WEAPONS or arms.get("ammo",{}).get("definition","")=="bolts":
  return _crossbows.present_enemy(_original,unit,catalog,"highwayman")
 return super.describe(unit,catalog)
