extends RefCounted
## Immutable, right-facing company art. Presentation only; no campaign writes/RNG.
const RingboundMaul = preload("res://engraved_people/ringbound_maul.gd")
const DATA = preload("res://engraved_people/plates.json")
const CUTS := "res://engraved_people/cuts.png"
const StockBolt = preload("res://engraved_people/stock_bolt.gd")
const DrawArt = preload("res://engraved_people/reload_draw.gd")
const ShieldArt = preload("res://engraved_people/shield_contact.gd")
const MeleeSpecial = preload("res://engraved_people/melee_special.gd")
const UtilityPoseArt = preload("res://engraved_people/utility_pose_art.gd")
const Wardrobe = preload("res://layer_forge/wardrobe.gd")
const CANVAS := Vector2i(480,464)
const FOOT := Vector2(240,411)
const WALK_FRAMES := 10
const CYCLE := 0.66
const PORTRAIT := Rect2i(170,32,142,142)
# The highest Forge crest begins at y=12. Keep the old portrait's bottom
# edge and a square crop centered on the same actor; never resize the ink.
const FORGE_PORTRAIT := Rect2i(158,10,164,164)
const BODY_ORDER := ["base","mail","outer"]
const HEAD_ORDER := ["padding","mail","shell"]
const LAB_FINISH := {
 "linen":["body/base","t1-grip","soft"],
 "mail":["body/mail","t1-mail","trail"],
 "breastplate":["body/outer","t1-mail","iron"],
}
const Named = preload("res://src/named_equipment.gd")
const Catalog = preload("res://hollow_campaign/catalog.gd")
static var _catalog := {}
static var _sheet: Image
const Wear = preload("res://engraved_people/named_wear.gd")
static var _textures := {}
const THRUST_WEAPONS := ["weapon/boar","weapon/militia","weapon/heavy"]
const SWING_SWORDS := ["weapon/arming","weapon/falchion","weapon/short","weapon/t1-gatewardens-blade","weapon/t1-heavy-falchion","weapon/t1-narrow-sabre","weapon/t1-short-sword"]
const Motion = preload("res://engraved_people/weapon_motion.gd")
const Bow = preload("res://engraved_people/bow_motion.gd")
const BowHookSpecial = preload("res://engraved_people/bow_hook_special.gd")
static var _strike_sheets: Dictionary = {}
static var _strike_cuts: Dictionary = {}
static var _forge_pose_plates: Dictionary = {}

static func strike_frame(seconds: float,r:Dictionary={}) -> int:
 if r.has("melee_special"):return MeleeSpecial.frame(r.melee_special.kind,seconds,strike_contact(r))
 if r.get("bow_hook_pose","")==BowHookSpecial.AIMED:
  return BowHookSpecial.aimed_frame(seconds,Bow.ENDS if r.weapon==Bow.WEAPON else Motion.ENDS["bow_alt"])
 if r.get("bow_hook_pose","")==BowHookSpecial.FERRY:return BowHookSpecial.ferry_frame(seconds)
 if r.get("weapon","")==Bow.WEAPON:return Bow.frame(seconds)
 var extra:=Motion.style(r)
 if not extra.is_empty():return Motion.frame(extra,seconds)
 for i in 8:
  if seconds < [0.045,0.145,0.182,0.229,0.289,0.337,0.390,0.449][i]:return i
 return -1

static func can_strike(r: Dictionary) -> bool:
 if r.get("weapon","").is_empty() or (r.get("stance","")!="single" and Motion.style(r).is_empty()):return false
 var style := _strike_style(r)
 if style==BowHookSpecial.AIMED:
  var inherited:=r.duplicate();inherited.erase("bow_hook_pose")
  if not is_fitted_bow(inherited):return false
 if style in ["shortbow","bow_alt",BowHookSpecial.AIMED] and not Bow.ready():return false
 if not _strike_sheets.has(style):
  var path := "res://engraved_people/"+style+"-cuts"
  if not FileAccess.file_exists(path+".json"):return false
  var rows: Variant=JSON.parse_string(FileAccess.get_file_as_string(path+".json"))
  var expected: int=Motion.ENDS[style].size() if Motion.ENDS.has(style) else 8
  if style==BowHookSpecial.AIMED:expected=BowHookSpecial.SIGHT_ROW
  if style==BowHookSpecial.FERRY:expected=BowHookSpecial.FERRY_ENDS.size()-1
  if not rows is Array or rows.size()!=expected:return false
  var image:=Image.new()
  if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path+".png"))!=OK:return false
  image.convert(Image.FORMAT_RGBA8)
  _strike_sheets[style]=image;_strike_cuts[style]=rows
 return _strike_cuts[style][0].has(r.weapon)

static func _strike_style(r: Dictionary) -> String:
 if r.get("bow_hook_pose","")==BowHookSpecial.AIMED:return BowHookSpecial.AIMED
 if r.get("bow_hook_pose","")==BowHookSpecial.FERRY and r.get("weapon","")==BowHookSpecial.FERRY_PART and r.get("stance","")=="haft":return BowHookSpecial.FERRY
 if r.get("weapon","")==Bow.WEAPON:return "shortbow"
 var extra:=Motion.style(r)
 if not extra.is_empty():return extra
 return "thrust" if r.get("weapon","") in THRUST_WEAPONS else "attack"

static func strike_contact(r: Dictionary) -> float:
 if _strike_style(r)==BowHookSpecial.FERRY:return BowHookSpecial.FERRY_CONTACT if can_strike(r) else 0.0
 if r.get("weapon","")==Bow.WEAPON:return Bow.RELEASE if can_strike(r) else 0.0
 var extra:=Motion.style(r)
 if not extra.is_empty():return Motion.contact(extra) if can_strike(r) else 0.0
 # First forward contact pose of each authored atlas, not the end of recovery.
 return (0.229 if _strike_style(r)=="thrust" else 0.182) if can_strike(r) else 0.0

static func bow_handoff_time(r:Dictionary,release:bool) -> float:
 if r.get("weapon","")==Bow.WEAPON:return Bow.RELEASE if release else Bow.FULL_DRAW
 var boundary:=Motion.contact("bow_alt")
 return boundary if release else boundary-0.025

static func is_fitted_bow(r:Dictionary) -> bool:
 return (r.get("weapon","")==Bow.WEAPON or Motion.style(r)=="bow_alt") and can_strike(r)

static func walk_frame(seconds: float) -> int:
 return mini(WALK_FRAMES-1, floori(fposmod(seconds,CYCLE)*WALK_FRAMES/CYCLE))

static func _face(unit: Dictionary) -> int:
 var id = unit.get("company_id")
 var roll = unit.get("companion_roll")
 if unit.get("side",-1) != 0 or not id is int or id < 0 or not roll is Dictionary or not roll.get("seed") is int:return -1
 # An odd stride permutes the eight cuts within each consecutive recruit bag.
 var digest := ("engraved-person-v1/%d/%d" % [roll.seed,id >> 3]).sha256_buffer()
 return ((id % 8) * (2*(digest[0]%4)+1) + digest[1]) % 8

static func _reason(d: Dictionary, slot: String, text: String) -> void:
 var record: Dictionary = d.signature[slot]
 d.issues.append({"slot":slot,"uid":record.item,"definition":record.definition,"reason":text})

static func _read(d: Dictionary, slot: String, channel: String, record: Dictionary) -> void:
 if record.is_empty():return
 var id: String = str(record.get("definition",""))
 var entry := {"definition":id,"item":str(record.get("id",record.get("item",""))),"condition":int(record.get("condition",0)),"maximum":int(record.get("maximum",0)),"visible":false,"painted":false}
 if channel == "shield" and not record.has("maximum"):
  if _catalog.is_empty():_catalog=Catalog.equipment()
  if _catalog.has(id):entry.maximum=int(Named.definition(record,_catalog).get("durability",0))
 d.signature[slot]=entry
 var binding: Dictionary = DATA.data.bindings.get(id,{})
 if channel == "carried":
  _reason(d,slot,"Stowed in a pocket; not worn.");return
 if binding.get("slot","") != channel or binding.is_empty():
  _reason(d,slot,"No registered engraving for this physical definition and slot.");return
 if channel == "shield" and entry.condition <= 0 or entry.maximum > 0 and entry.condition <= 0 and channel not in ["weapon","ammo"]:
  _reason(d,slot,"Broken; no intact plate shown.");return
 var prev: String = d.owners.get(channel,"")
 # A fitted chest shell leaves the underlying sleeves and hem exposed.
 # Retain the underlying garment and its physical owner rather than drawing
 # a second ready-dressed torso that would turn a mail skirt back into linen.
 if channel == "body" and binding.part == "torso/breastplate":
  d.recipe.under_body=d.recipe.body
  d.recipe.under_wear=d.recipe.body_wear
 elif not prev.is_empty():
  if d.recipe.has("named_paint"):
   d.recipe.named_paint.erase(d.recipe.get(channel,""))
   if d.recipe.named_paint.is_empty():d.recipe.erase("named_paint")
  d.signature[prev].visible=false;d.signature[prev].painted=false
  _reason(d,prev,"Covered by a higher physical layer.")
 d.owners[channel]=slot
 d.recipe[channel]=binding.part
 if channel in ["head","shield","body"]:
  d.recipe[channel+"_wear"]="wear/"+channel if entry.maximum > 0 and entry.condition*2 <= entry.maximum else ""
 if channel == "ammo":d.recipe.ammo_fill=clampi(entry.condition,0,4)
 if channel == "weapon":
  d.recipe.stance=binding.stance
  if id=="hm_trial_v1:twohand_maul":d.recipe.tier_one_maul_motion=true
 entry.visible=true;entry.painted=true
 var named_id:=Wear.select(record,slot,channel,binding.part)
 if not named_id.is_empty():
  if not d.recipe.has("named_paint"):d.recipe.named_paint={}
  d.recipe.named_paint[binding.part]=named_id
  entry.asset="named/"+named_id
 elif record.has("named"):
  d.notes.append("%s · base definition shown; Named ornament is not illustrated." % id)


static func describe(unit: Dictionary) -> Dictionary:
 var d:=describe_with_face(unit,_face(unit))
 if d.ok and ProjectSettings.get_setting("application/config/use_custom_user_dir",false) and ProjectSettings.get_setting("application/config/custom_user_dir_name","")=="ashen-company-armor-lab":
  _finish_lab_outfit(d)
 return d

static func _finish_lab_outfit(d: Dictionary) -> void:
 # The visible physical owner chooses existing hand and gait cuts, not new
 # items. Keep genuinely occupied support slots (including omitted ones).
 var slot: String=d.owners.get("body","")
 var owner: Dictionary=d.signature.get(slot,{})
 var finish: Array=LAB_FINISH.get(owner.get("definition",""),[])
 if finish.is_empty() or finish[0]!=slot or owner.item.is_empty():return
 # If an intact upper physical layer has no exact cut, an ostensibly
 # complete lower outfit would misrepresent it. Broken layers reveal below.
 for index in range(BODY_ORDER.find(slot.get_slice("/",1))+1,BODY_ORDER.size()):
  var upper: Dictionary=d.signature.get("body/"+BODY_ORDER[index],{})
  if not upper.is_empty() and (upper.maximum<=0 or upper.condition>0):return
 if not d.signature.has("body/hands"):d.recipe.hands=finish[1]
 if not d.signature.has("body/feet"):d.recipe.feet=finish[2]

## Neutral shared fittings. The caller supplies its own stable face, never a forged companion record.
static func describe_with_face(unit:Dictionary,face:int)->Dictionary:
 var d := {"ok":face >= 0,"signature":{},"issues":[],"notes":[],"owners":{},"recipe":{}}
 if face < 0:return d
 d.recipe={"face":face,"stance":"single","body":"torso/linen","head":"","cloak":"","belt":"","hands":"","feet":"plain","weapon":"","shield":"","head_wear":"","body_wear":"","shield_wear":""}
 var arms: Dictionary = unit.get("arms",{})
 for slot: String in arms:
  _read(d,slot,slot if slot in ["weapon","shield","ammo"] else "carried",arms[slot])
 var equipped:Dictionary=arms.get("weapon",{})
 if StockBolt.fitted(d.recipe) and d.recipe.weapon==StockBolt.DEFINITIONS.get(equipped.get("definition"),"") and equipped.get("loaded",false)==true:
  d.recipe.seated_bolt=true
 if Wardrobe.applies(unit):
  var claim = unit.get("forge_named_mail_uid")
  Wardrobe.bind(d,unit.get("armor_parts",[]),claim if unit.get("side",-1) == 0 and claim is String else "")
  return d
 # Layer order is independent of dictionary serialization or inspection order.
 var parts: Array = unit.get("armor_parts",[]).duplicate()
 parts.sort_custom(func(a,b):return _order(a) < _order(b))
 for part: Dictionary in parts:
  var group := str(part.get("group",""));var layer := str(part.get("layer",""))
  var channel := layer if group == "body" and layer in ["belt","cloak","hands","feet"] else group if (group == "body" and layer in BODY_ORDER or group == "head" and layer in HEAD_ORDER) else "unfitted"
  _read(d,group+"/"+layer,channel,part)
 return d

static func _order(part: Dictionary) -> int:
 var order: Array = BODY_ORDER if part.get("group") == "body" else HEAD_ORDER
 return order.find(part.get("layer"))

static func _ready_sheet() -> bool:
 if _sheet != null:return true
 if FileAccess.file_exists(CUTS):
  var image := Image.new()
  if image.load_png_from_buffer(FileAccess.get_file_as_bytes(CUTS)) == OK:_sheet=image
 elif ResourceLoader.exists(CUTS):
  var imported: Texture2D = load(CUTS)
  if imported != null:_sheet=imported.get_image()
 if _sheet == null:return false
 _sheet.convert(Image.FORMAT_RGBA8)
 return true

static func _head_recipe(r: Dictionary) -> Dictionary:
 var head := Wear.head_recipe(r)
 if r.has("forge_head"):head.forge_head=r.get("forge_head",[])
 return head

static func _cuts(r: Dictionary, head_only: bool) -> Array:
 var face := "face/%d/%s" % [r.face,"hair" if r.head == "" else "shorn"]
 if head_only:
  if r.has("forge_head"):return [Wardrobe.BACK,face,r.head,r.head_wear]
  return [face,r.head,r.head_wear]
 var under: String = r.get("under_body","")
 var sleeve_body: String = r.body if under.is_empty() else under
 var sleeve: String = DATA.data.body_sleeves.get(sleeve_body,"mail" if sleeve_body in ["torso/mail","torso/banded"] else "cloth")
 var pose: String = r.stance
 var glove: String = "" if r.hands == "" else "/"+r.hands
 var hand := "hand/"+pose+"/"
 var arm := "sleeve/"+pose+"/"
 if pose == "single":
  # Right is the near, screen-left shoulder. Only a carried bow uses the left weapon grip.
  var bow: bool = r.weapon in DATA.data.single_left_bows
  var left := "single/left/"+("shield" if r.shield != "" else "bow" if bow else "idle")+"/"
  var right := "single/right/"+("grip" if r.weapon != "" and not bow else "idle")+"/"
  # The shield face belongs to the foreground, not the far-arm stack.
  # Retain that depth at rest and in motion so the lowering rim cannot pop behind the coat.
  if r.has("forge_body"):
   # Coat and hat go behind the live grip/weapon, even when they cross the chest.
   return [left+"sleeve/"+sleeve,r.body,face,r.head,r.head_wear,(r.weapon if bow else ""),left+"hand"+glove,right+"sleeve/"+sleeve,("" if bow else r.weapon),right+"hand"+glove,r.shield,r.shield_wear]
  return [left+"sleeve/"+sleeve,(r.weapon if bow else ""),left+"hand"+glove,under,r.get("under_wear",""),r.body,r.body_wear,r.belt,face,r.head,r.head_wear,right+"sleeve/"+sleeve,("" if bow else r.weapon),right+"hand"+glove,r.shield,r.shield_wear]
 var cuts := [arm+"back/"+sleeve,under,r.get("under_wear",""),r.body,r.body_wear,r.belt,face,r.head,r.head_wear,arm+"front/"+sleeve,("palm/haft"+glove if pose == "haft" else ""),r.weapon,hand+"back"+glove,hand+"front"+glove,r.shield,r.shield_wear]
 # Right sleeve crosses the coat and belt to meet the rear grip. Its shoulder
 # stays under hoods, and the stock and both gloves keep their original sockets.
 if pose == "stock":
  cuts.erase(arm+"back/"+sleeve)
  cuts.insert(cuts.find(face),arm+"back/"+sleeve)
 # Sword-only: the pommel arm crosses the chest AND belt, beneath the guard arm.
 if pose == "sword_pair" or (pose == "paired" and r.weapon == "weapon/head-maul62"):
  cuts.erase(arm+"back/"+sleeve)
  cuts.insert(cuts.find(face),arm+"back/"+sleeve)
 return cuts

static func _stamp(im: Image, key: String, shift: Vector2i) -> void:
 if key.is_empty():return
 var p: Array = DATA.data.cuts[key]
 im.blend_rect(_sheet,Rect2i(int(p[2]),int(p[3]),int(p[4]),int(p[5])),Vector2i(int(p[0]),int(p[1]))+shift)

static func _stamp_ground(im: Image, key: String, shift: Vector2i, r: Dictionary) -> void:
 if not r.has("forge_body"):
  _stamp(im,key,shift)
  return
 var suffix := "_legs_"+key.get_file()
 # Replace the neutral cut only when this exact foundation frame has ink.
 # VI always lies over the foundation (or neutral fallback), below the coat.
 if not Wardrobe.stamp_accessory(im,r,"base",suffix,shift):_stamp(im,key,shift)
 Wardrobe.stamp_accessory(im,r,"reinforce",suffix,shift)

# Keep a single paint choice at the original z-order in every consumer.
static func _stamp_wear(im: Image, key: String, shift: Vector2i, r: Dictionary, sleeves: int = 0) -> void:
 if r.has("forge_body") and key.begins_with("legs/"):
  _stamp_ground(im,key,shift,r)
  return
 if Wardrobe.stamp(im,key,shift,r,sleeves):return
 if not Wear.stamp(im,key,shift,r):_stamp(im,key,shift)

static func shield_plate(part:String,worn:bool) -> Image:
 if not _ready_sheet() or not part.begins_with("shield/") or not DATA.data.cuts.has(part):return null
 var p:Array=DATA.data.cuts[part]
 var plate:=Image.create_empty(p[4],p[5],false,Image.FORMAT_RGBA8)
 _stamp(plate,part,-Vector2i(p[0],p[1]))
 if worn:_stamp(plate,"wear/shield",-Vector2i(p[0],p[1]))
 return plate

static func _forge_sleeve_fit(r: Dictionary, strike: int, draw: int, block: int) -> int:
 if not r.has("forge_body") or r.stance!="single" or draw>=0 or block>=0 or r.weapon in DATA.data.single_left_bows:return 0
 # The authored cuffs match the sword carry and the neutral far sleeve, not
 # a generic silhouette in every weapon/arm family. The legs remain grounded.
 var near_fit: int=Wardrobe.NEAR if strike<0 and not r.weapon.is_empty() else 0
 var far_fit: int=Wardrobe.FAR if r.shield.is_empty() else 0
 return near_fit|far_fit

static func _render(r: Dictionary, frame: int, head_only: bool, strike: int = -1, draw: int = -1, block: int = -1, ranged_block:bool=false) -> Texture2D:
 if r.is_empty() or frame < -1 or frame >= WALK_FRAMES or not _ready_sheet():return null
 if head_only and r.has("forge_head"):r=_head_recipe(r)
 if strike>=0 and not head_only and draw<0 and block<0 and r.has("melee_special"):
  var gear:=r.duplicate()
  gear.erase("melee_special")
  return _pose_head(MeleeSpecial.compose(gear,r.melee_special,strike,DATA.data,_cuts,_stamp_wear.bind(gear,0)),gear)
 var style:=_strike_style(r) if strike>=0 else ""
 var count: int=Motion.ENDS[style].size() if Motion.ENDS.has(style) else 8
 var ferry:=style==BowHookSpecial.FERRY
 if ferry:count=BowHookSpecial.FERRY_ENDS.size()
 if strike>=0 and (head_only or strike>=count or not can_strike(r)):return null
 if draw>=0 and (head_only or strike>=0 or not StockBolt.fitted(r) or not DrawArt.ready()):return null
 if block>=0 and (head_only or strike>=0 or draw>=0 or r.get("stance")!="single" or r.get("shield","").is_empty() or not ShieldArt.ready()):return null
 var key := "portrait/"+JSON.stringify(_head_recipe(r)) if head_only else JSON.stringify([r,frame])
 if strike>=0:key+="/strike/%d" % strike
 if draw>=0:key+="/reload/%d" % draw
 if block>=0:key+="/shield/%d" % block
 if block>=0 and ranged_block:key+="/ranged"
 if _textures.has(key):return _textures[key]
 var bill:bool=not head_only and r.get("stance","")=="haft" and r.get("weapon","")=="weapon/t1-billhook" and can_strike(r)
 if ferry and strike==count-1:
  var carry:=r.duplicate();carry.erase("bow_hook_pose")
  return _render(carry,-1,false)
 var hooked:bool=style==Motion.Hook.STYLE
 if hooked and strike==count-1:
  var carry:=r.duplicate();carry.erase("billhook_hook")
  return _render(carry,-1,false)
 var side_pad: int=Motion.Hook.SIDE_PAD[strike] if hooked else 96 if bill else 0
 var portrait_crop := FORGE_PORTRAIT if r.has("forge_head") else PORTRAIT
 var size := portrait_crop.size if head_only else CANVAS
 # Signed paint destinations are foot-relative; pad only those motion cuts.
 var top_pad: int=192 if style=="sword_overhead" and strike in [1,2,3,4] else 0
 if hooked:top_pad=Motion.Hook.TOP_PAD if strike in Motion.Hook.TOP_ROWS else 0
 elif bill and strike in [1, 2, 3, 4]:top_pad=256
 if style=="maul_overhead" and strike in [1, 2]:top_pad=192
 var im := Image.create_empty(size.x+side_pad*2,size.y+top_pad,false,Image.FORMAT_RGBA8)
 var shift := -portrait_crop.position if head_only else Vector2i(side_pad,top_pad+int(DATA.data.hip_y[frame+1]))
 if not head_only:
  # The mantle follows the shoulder; its hem hangs behind both walking legs.
  if r.has("forge_body"):_stamp_wear(im,r.cloak,shift,r)
  else:_stamp(im,r.cloak,shift)
  # The carrier rides outside the cloak but behind the wearer's arms and legs.
  if r.has("ammo"):
   _stamp(im,r.ammo,shift)
   if r.ammo_fill>0:_stamp(im,r.ammo+"/"+str(r.ammo_fill),shift)
  _stamp_ground(im,"legs/%s/%d" % [r.feet,frame],Vector2i(side_pad,top_pad),r)
 # The Billhook fit uses the same carry at settle, idle and gait.
 var ink_style:="billhook_overhead" if bill and not hooked else style
 # Exact prior art from final sight through empty release and lowering.
 if style==BowHookSpecial.AIMED and strike>=BowHookSpecial.SIGHT_ROW:
  ink_style="shortbow" if r.weapon==Bow.WEAPON else "bow_alt"
 var ink_row:int=Motion.ENDS["billhook_overhead"].size()-1 if bill and strike<0 else strike
 var pose: Dictionary=_strike_cuts[ink_style][ink_row] if ink_row>=0 else {}
 var socket:=Vector2i.ZERO
 var bow_tip:=Vector2.ZERO;var bow_nock:=Vector2.ZERO
 var seated:=false
 var shield_lane:=ShieldArt.profile(r.shield) if block>=0 else 0
 # At projectile contact hold the plate in its last displayed position for
 # one cut, with new wear. The following cuts carry the bracing recoil.
 var moved_shield:=block>=0 and not (ranged_block and block==0)
 var cuts:=_cuts(r,head_only)
 var sleeves:=_forge_sleeve_fit(r,strike,draw,block)
 if (sleeves&Wardrobe.NEAR)!=0:
  # Show the fitted near cuff over the neutral sleeve at carry only. The
  # existing grip stays over both; strikes use the original moving sleeve.
  var sleeve:="single/right/grip/sleeve/cloth"
  if cuts.has(sleeve):
   cuts.erase(sleeve)
   cuts.insert(cuts.find(r.body),sleeve)
 var overhead_front:bool=(style=="sword_overhead" and strike in range(9)) or (style in ["billhook_overhead","maul_overhead"] and strike in [1,2])
 if overhead_front or (hooked and strike in Motion.Hook.FRONT_ROWS):
  # The crossing sleeve belongs above face, headgear and their wear layers.
  # Keep the lead sleeve and both fitted hands in their original relative order.
  for cut: String in cuts:
   if cut.begins_with("sleeve/"+r.stance+"/back/"):
    cuts.erase(cut)
    for lead: String in cuts:
     if lead.begins_with("sleeve/"+r.stance+"/front/"):
      cuts.insert(cuts.find(lead),cut)
      break
    break
 if (bill and not (overhead_front or (hooked and strike in Motion.Hook.FRONT_ROWS))) or (strike in range(7) and style in ["greatswing","heavyswing","haftthrust","haftswing"] and r.stance in ["paired","haft"]):
  # The moving near sleeve stays over the torso, but beneath the face.
  for arm_cut:String in cuts:
   if arm_cut.begins_with("sleeve/"+r.stance+"/back/"):
    var index:=cuts.find(arm_cut)
    cuts.remove_at(index);cuts.insert(5,arm_cut)
    break
 if ferry:
  # The aft sleeve crosses the coat; the under-palm stays below its shaft.
  for sleeve:String in cuts:
   if sleeve.begins_with("sleeve/haft/back/"):
    cuts.erase(sleeve);cuts.insert(5,sleeve);break
 if strike in range(7) and style in ["point","blunt"] and not r.shield.is_empty():
  cuts.erase(r.shield)
  if not r.shield_wear.is_empty():cuts.erase(r.shield_wear)
  for arm_cut:String in cuts:
   if arm_cut.begins_with("single/right/grip/sleeve/"):
    var index:=cuts.find(arm_cut)
    cuts.insert(index,r.shield)
    if not r.shield_wear.is_empty():cuts.insert(index+1,r.shield_wear)
    break
 if style in ["shortbow","bow_alt",BowHookSpecial.AIMED] and strike<7:
  # The bent string crosses the chest in the draw. Keep both grip cuts
  # above the bow and its nocked arrow instead of painting behind the torso.
  var bow_hand:String="single/left/bow/hand"+("/"+r.hands if not r.hands.is_empty() else "")
  var draw_hand:String="single/right/idle/hand"+("/"+r.hands if not r.hands.is_empty() else "")
  if cuts.has(bow_hand) and cuts.has(draw_hand):
   cuts.erase(r.weapon);cuts.erase(bow_hand)
   var bow_index:=cuts.find(draw_hand)
   cuts.insert(bow_index,r.weapon);cuts.insert(bow_index+1,bow_hand)
 if strike>=0 and r.weapon in SWING_SWORDS and not r.shield.is_empty() and pose.has(r.weapon):
  # Keep the plate over the body, but under the moving sword and its grip.
  # Idle and the high brace still use their own unchanged foreground order.
  cuts.erase(r.shield)
  if not r.shield_wear.is_empty():cuts.erase(r.shield_wear)
  var blade_index:=cuts.find(r.weapon)
  cuts.insert(blade_index,r.shield)
  if not r.shield_wear.is_empty():cuts.insert(blade_index+1,r.shield_wear)
 # Carry shares the two registered hand cuts across its gait. Moving gloves
 # are opt-in only at the stock arming-sword Contact 3, never from carry ink.
 var contact_gloves: bool=ink_style=="attack" and ink_row==3 and r.weapon=="weapon/arming" and pose.has(r.weapon) and pose.has("single/right/grip/hand")
 var glove_fit: bool=not head_only and r.has("forge_body") and r.stance=="single" and r.weapon not in DATA.data.single_left_bows and draw<0 and block<0 and (strike<0 or contact_gloves)
 for cut: String in cuts:
  if moved_shield and ShieldArt.stamp_sleeve(im,cut,shift,block,shield_lane):pass
  elif moved_shield and not cut.is_empty() and (cut==r.shield or cut==r.shield_wear or cut.begins_with("single/left/shield/hand")):_stamp(im,cut,shift+ShieldArt.offset(block,shield_lane))
  elif draw>=0 and DrawArt.stamp_sleeve(im,cut,shift,draw):pass
  elif draw>=0 and cut.begins_with("hand/stock/front"):_stamp(im,cut,shift+DrawArt.hand_offset(draw))
  elif not head_only and cut==r.weapon and RingboundMaul.stamp(im,r,"maul_overhead" if ink_style=="maul_overhead" else "carry",strike if ink_style=="maul_overhead" else 0,shift):pass
  elif pose.has(cut):
   if Wear.stamp(im,cut,shift,r,"%s/%d" % [ink_style,ink_row]):
    pass # Same rectangle/role as stock weapon ink. Bolt and arrow stamps still run below.
   else:
    var p: Array=pose[cut]
    im.blend_rect(_strike_sheets[ink_style],Rect2i(int(p[2]),int(p[3]),int(p[4]),int(p[5])),Vector2i(int(p[0]),int(p[1]))+shift)
  else:_stamp_wear(im,cut,shift,r,sleeves)
  if glove_fit:
   # Coat each exact bare palm in place: far before the weapon, near over
   # the hilt. An alternate grip (including shield) matches neither key.
   var glove := "_glove_near" if cut=="single/right/grip/hand" else "_glove_far" if cut=="single/left/idle/hand" else ""
   if not glove.is_empty():
    if contact_gloves:glove+="_contact"
    for layer: String in ["base","reinforce"]:Wardrobe.stamp_accessory(im,r,layer,glove,shift)
  # Stamp next to the stock, before the two fitted gloves and other foreground cuts.
  if not head_only and cut==r.weapon and StockBolt.fitted(r):
   socket=StockBolt.TIPS[cut]+shift
   if r.get("seated_bolt",false) and (draw<0 or draw>=DrawArt.SEAT_FRAME):seated=StockBolt.stamp(im,socket)
  var ar:Array=pose.get("arrow",[]) if ink_style=="shortbow" else pose.get("arrow_by_weapon",{}).get(r.weapon,[]) if (ink_style=="bow_alt" or style==BowHookSpecial.AIMED) else []
  if ar.size()==4 and cut==r.weapon:
   var row:Array=ar
   bow_nock=Vector2(float(row[0]),float(row[1]))+Vector2(shift)
   bow_tip=Vector2(float(row[2]),float(row[3]))+Vector2(shift)
   Bow.stamp(im,bow_nock,bow_tip)
 im.generate_mipmaps()
 var texture := ImageTexture.create_from_image(im)
 if not head_only:texture.set_meta("engraved_head",_head_recipe(r))
 if top_pad>0:texture.set_meta("painted_top_pad",top_pad)
 if side_pad>0:texture.set_meta("painted_side_pad",side_pad)
 if socket!=Vector2i.ZERO:texture.set_meta("stock_bolt_socket",Vector2(socket))
 if seated:texture.set_meta("stock_bolt_tip",Vector2(socket))
 if style in ["shortbow","bow_alt",BowHookSpecial.AIMED]:texture.set_meta("shortbow_pose",strike)
 if style==BowHookSpecial.AIMED:
  texture.set_meta("bow_hook_special",{"style":style,"frame":strike,"part":r.weapon,"beat":BowHookSpecial.AIMED_BEATS[strike]})
 elif ferry:
  texture.set_meta("bow_hook_special",{"style":style,"frame":strike,"part":r.weapon,"beat":BowHookSpecial.FERRY_BEATS[strike]})
 if strike>=0 and Motion.ENDS.has(style):texture.set_meta("extended_strike",{"style":style,"part":r.weapon,"frame":strike})
 if bow_tip!=Vector2.ZERO:
  texture.set_meta("shortbow_tip",bow_tip);texture.set_meta("shortbow_nock",bow_nock)
 if draw>=0:texture.set_meta("reload_hand",Vector2(322,210)+Vector2(shift+DrawArt.hand_offset(draw)))
 if block>=0:texture.set_meta("shield_pose",{"frame":block,"wear":not r.shield_wear.is_empty()})
 if not head_only and r.stance=="single" and strike<0 and draw<0 and not r.shield.is_empty():
  var plate:Array=DATA.data.cuts[r.shield]
  var plate_shift:=shift+(ShieldArt.offset(block,shield_lane) if moved_shield else Vector2i.ZERO)
  texture.set_meta("fitted_shield",{"part":r.shield,"center":Vector2(plate[0],plate[1])+Vector2(plate[4],plate[5])*0.5+Vector2(plate_shift),"worn":not r.shield_wear.is_empty()})
 if _textures.size() >= 64:_textures.erase(_textures.keys()[0])
 _textures[key]=texture
 return texture

static func _pose_head(texture: Texture2D, recipe: Dictionary) -> Texture2D:
 if texture != null and recipe.has("forge_head"):texture.set_meta("engraved_head",_head_recipe(recipe))
 return texture

## Art-only overlay on an idle registration. The caller owns action semantics.
static func utility_pose(recipe: Dictionary, kind: String, frame: int) -> Texture2D:
 if not _ready_sheet():return null
 var plates: Dictionary=DATA.data
 if recipe.has("forge_body"):
  # Utility only checks these virtual cuts for membership; its existing stamp
  # callback handles them. Do not register them as real legacy atlas rectangles.
  if _forge_pose_plates.is_empty():
   _forge_pose_plates=plates.duplicate()
   _forge_pose_plates.cuts=plates.cuts.duplicate()
   for key: String in [Wardrobe.BACK,Wardrobe.BODY_FRONT,Wardrobe.HEAD_FRONT]:
    _forge_pose_plates.cuts[key]=[]
  plates=_forge_pose_plates
 return _pose_head(UtilityPoseArt.compose(recipe,kind,frame,plates,_cuts,_stamp_wear.bind(recipe,0)),recipe)

static func field(unit: Dictionary, frame: int = -1) -> Texture2D:
 return _render(describe(unit).recipe,frame,false)

static func portrait_for_field(texture: Texture2D) -> Texture2D:
 return _render(texture.get_meta("engraved_head",{}),-1,true) if texture != null else null

static func portrait(unit: Dictionary) -> Texture2D:
 return _render(describe(unit).recipe,-1,true)
