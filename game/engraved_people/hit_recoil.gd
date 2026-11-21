extends RefCounted
## Registered 480 × 464 fitted art: shoulder checks back, head dips, hips settle.
## Remap existing ink rows so the current face, sleeves, gear and wear travel together.
const LEAN := [9, 22, 30, 24, 15, 7]
const DIP := [2, 5, 8, 8, 5, 2]
const ENDS := [0.030, 0.053, 0.085, 0.119, 0.158, 0.202]
const PIVOT := 301
var elapsed := -1.0
var side := 1
var _base: Texture2D
var _ink: Image
var _cuts: Dictionary = {}

func begin(direction:Vector3,camera:Camera3D,flipped:bool) -> void:
 var screen_right:=camera.global_basis.x if camera!=null else Vector3.RIGHT
 var horizontal:=screen_right.dot(direction.normalized())
 var away:=(1 if flipped else -1) if absf(horizontal)<0.08 else (1 if horizontal>0.0 else -1)
 # Stroke direction is in screen space; the image will be flipped at draw time.
 side=away*(-1 if flipped else 1)
 elapsed=0.0

func advance(delta:float,allowed:bool) -> void:
 if not allowed:clear();return
 elapsed+=maxf(0.0,delta)
 if elapsed>=ENDS[-1]:clear()

func clear() -> void:
 elapsed=-1.0
 _base=null;_ink=null;_cuts.clear()

func stamp(current:Texture2D) -> Texture2D:
 if elapsed<0.0 or current==null or current.get_size()!=Vector2(480,464):return current
 if current!=_base:
  _base=current;_cuts.clear();_ink=current.get_image();_ink.clear_mipmaps()
 var frame:=0
 while frame+1<ENDS.size() and elapsed>=ENDS[frame]:frame+=1
 var key:=side*(frame+1)
 if _cuts.has(key):return _cuts[key]
 var im:=Image.create_empty(480,464,false,Image.FORMAT_RGBA8)
 # Pixel-exact legs, hips and footing; no Sprite3D offset or physical tween.
 im.blit_rect(_ink,Rect2i(0,PIVOT,480,464-PIVOT),Vector2i(0,PIVOT))
 for y in range(PIVOT):
  var weight:=smoothstep(0.0,1.0,clampf(float(PIVOT-y)/190.0,0.0,1.0))
  var dx:=side*roundi(float(LEAN[frame])*weight)
  var sy:=y-roundi(float(DIP[frame])*weight)
  if sy<0:continue
  im.blit_rect(_ink,Rect2i(maxi(0,-dx),sy,480-absi(dx),1),Vector2i(maxi(0,dx),y))
 im.generate_mipmaps()
 var tex:=ImageTexture.create_from_image(im)
 for k:StringName in current.get_meta_list():tex.set_meta(k,current.get_meta(k))
 _cuts[key]=tex
 return tex
