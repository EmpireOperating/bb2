extends RefCounted
## Shortbow animation data in the unflipped fitted character canvas.
const WEAPON := "weapon/shortbow"
const DEFINITION := "shortbow"
const ARROW_INK := "res://map_visibility/arrow-ink.png"
const TIP := Vector2(153,15)
const NOCK := Vector2(11,15)
const RELEASE := 0.360
const FULL_DRAW := 0.320
const ENDS := [0.058,0.122,0.237,RELEASE,0.412,0.465,0.520,0.571]
static var _ink: Image
static var _flight: ImageTexture

static func frame(t:float) -> int:
 for i in ENDS.size():
  if t<ENDS[i]:return i
 return -1

static func ready() -> bool:
 if _ink!=null:return true
 var im:=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes(ARROW_INK))!=OK:return false
 im.convert(Image.FORMAT_RGBA8);_ink=im
 return true

static func flight_texture() -> Texture2D:
 if not ready():return null
 if _flight==null:
  var mip:=_ink.duplicate();mip.generate_mipmaps();_flight=ImageTexture.create_from_image(mip)
 return _flight

static func stamp(im:Image,nock:Vector2,tip:Vector2) -> void:
 if not ready():return
 var displacement:=tip-nock
 var scale:=displacement.length()/(TIP.x-NOCK.x)
 if scale<0.1:return
 var axis:=displacement.normalized()
 var down:=Vector2(-axis.y,axis.x)
 var basis:=Transform2D(axis*scale,down*scale,nock-axis*scale*NOCK.x-down*scale*NOCK.y)
 var inverse:=basis.affine_inverse()
 var bb:=Rect2(basis*Vector2.ZERO,Vector2.ZERO)
 var size:=Vector2(_ink.get_size())
 for corner:Vector2 in [Vector2(size.x,0),size,Vector2(0,size.y)]:bb=bb.expand(basis*corner)
 var clip:=Rect2i(Vector2i(bb.position.floor()),Vector2i(bb.size.ceil())+Vector2i(2,2)).intersection(Rect2i(Vector2i.ZERO,im.get_size()))
 for y in range(clip.position.y,clip.end.y):
  for x in range(clip.position.x,clip.end.x):
   var sample:=Vector2i((inverse*Vector2(x,y)).round())
   if not Rect2i(Vector2i.ZERO,_ink.get_size()).has_point(sample):continue
   var shade:=_ink.get_pixelv(sample)
   if shade.a>0.0:im.set_pixel(x,y,im.get_pixel(x,y).blend(shade))
