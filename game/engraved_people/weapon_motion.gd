extends RefCounted
const Hook = preload("res://engraved_people/billhook_hook.gd")
## Keys are fitted sprite parts, not an alternate gameplay weapon catalogue.
const GROUPS := {
 "sword_overhead":{"weapon/t1-two-handed-sword":"sword_pair"},
 "billhook_overhead":{"weapon/t1-billhook":"haft"},
 "greatswing":{"weapon/great":"paired"},
 "heavyswing":{"weapon/great-axe":"paired","weapon/head-maul62":"paired"},
 "haftthrust":{"weapon/t1-ash-pike":"haft","weapon/t1-boar-spear":"haft","weapon/t1-ward-spear":"haft"},
 "haftswing":{"weapon/bill64":"haft","weapon/t1-ferrymans-hook":"haft","weapon/glaive62":"haft"},
 "point":{"weapon/t1-quarry-estoc":"single","weapon/belt-knife":"single","weapon/rondel":"single","weapon/t1-field-knife":"single","weapon/t1-wayfarers-lancet":"single"},
 "blunt":{"weapon/head-mace45":"single","weapon/t1-war-mace":"single","weapon/head-club40":"single","weapon/t1-iron-cudgel":"single","weapon/head-hammer46":"single"},
 "bow_alt":{"weapon/t1-reedrunner-bow":"single","weapon/longbow":"single","weapon/t1-ash-longbow":"single","weapon/warbow":"single","weapon/t1-heavy-hunting-bow":"single"},
}
# Most melee sets meet at cut 3; the Two-Handed Sword has three lead-in cuts.
# Alternate arrow release switches from cut 3 to 4.
const ENDS := {
 "billhook_hook":Hook.ENDS,
 "sword_overhead":[0.064,0.18,0.224,0.27,0.324,0.367,0.402,0.45,0.49,0.535,0.6],
 "billhook_overhead":[0.066,0.164,0.207,0.251,0.303,0.344,0.385,0.434,0.488,0.537,0.602],
 "maul_overhead":[0.077,0.216,0.263,0.309,0.361,0.402,0.444,0.501,0.563,0.625,0.692],
 "greatswing":[0.066,0.166,0.267,0.318,0.391,0.464,0.538,0.621],
 "heavyswing":[0.077,0.186,0.303,0.360,0.435,0.513,0.590,0.692],
 "haftthrust":[0.057,0.140,0.224,0.278,0.349,0.407,0.470,0.553],
 "haftswing":[0.071,0.153,0.242,0.296,0.370,0.438,0.508,0.602],
 "point":[0.040,0.097,0.151,0.188,0.245,0.292,0.343,0.407],
 "blunt":[0.059,0.139,0.218,0.269,0.338,0.412,0.481,0.552],
 "bow_alt":[0.071,0.150,0.274,0.421,0.477,0.544,0.609,0.668],
}

static func style(r:Dictionary) -> String:
 var part:String=r.get("weapon","")
 if r.get("billhook_hook",false)==true and part=="weapon/t1-billhook" and r.get("stance","")=="haft":return Hook.STYLE
 # The active Tier One Maul and legacy compatibility Maul share painted ink.
 if r.get("tier_one_maul_motion",false)==true and part=="weapon/head-maul62" and r.get("stance","")=="paired":return "maul_overhead"
 for key:String in GROUPS:
  if GROUPS[key].get(part,"missing")==r.get("stance",""):return key
 return ""

static func frame(key:String,t:float) -> int:
 var ends:Array=ENDS[key]
 for i in ends.size():
  if t<float(ends[i]):return i
 return -1

static func contact(key:String) -> float:
 if key==Hook.STYLE:return Hook.CONTACT
 if key in ["sword_overhead","billhook_overhead","maul_overhead"]:return float(ENDS[key][5])
 return float(ENDS[key][3 if key=="bow_alt" else 2])
