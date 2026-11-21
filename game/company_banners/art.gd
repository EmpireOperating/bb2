extends RefCounted
const Identity=preload("res://company_banners/identity.gd")
static var _textures:Dictionary={}
static func texture(id:String)->Texture2D:
 if id not in Identity.IDS:return null
 if _textures.has(id):return _textures[id]
 var path:=Identity.path(id)
 if not FileAccess.file_exists(path):return null
 var result:Texture2D
 if FileAccess.file_exists(path+".import"):result=load(path)
 else:
  var image:=Image.new()
  if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK:return null
  image.generate_mipmaps();result=ImageTexture.create_from_image(image)
 if result!=null:_textures[id]=result
 return result
