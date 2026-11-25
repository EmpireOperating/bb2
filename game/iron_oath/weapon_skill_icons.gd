extends RefCounted
## Pictures for the two existing weapon buttons, not an action registry.
const Arsenal = preload("res://src/arsenal.gd")
const SHEET := "res://iron_oath/weapon_skill_icons.png"
const CELL := Vector2i(216,148)
const GRID := Vector2i(6,4)
const WORK_SHEET := "res://iron_oath/terrain_skill_icons.png"
# Side-wall stones and fort masonry share the same Breach composition.
const WORK_CELLS := {"wood":0,"plank":1,"stone":2,"wall":2}
# Coordinates of the basic composition. Its special is the next cell to the right.
const PAIRS := {
 "sword":Vector2i(0,0), "spear":Vector2i(2,0), "axe":Vector2i(4,0),
 "mace":Vector2i(0,1), "hammer":Vector2i(2,1), "dagger":Vector2i(4,1),
 "polearm":Vector2i(0,2), "bow":Vector2i(2,2), "crossbow":Vector2i(4,2),
 "javelins":Vector2i(0,3), "throwing_axes":Vector2i(2,3), "bolas":Vector2i(4,3),
}
static var _sheet: Image
static var _attempted_sheet := false
static var _tiles: Dictionary[Vector2i, Texture2D] = {}
static var _work_attempted := false
static var _work_icons: Array[Texture2D] = []

static func texture(action: String, weapon: String) -> Texture2D:
 if action not in ["basic","special"] or not Arsenal.FAMILIES.has(weapon):return null
 var family := Arsenal.family(weapon)
 # The three bundles share verbs but not silhouettes.
 var pair := weapon if family=="throwing" else family
 if not PAIRS.has(pair):return null
 var cell: Vector2i = PAIRS[pair]
 if action=="special":cell.x+=1
 if _tiles.has(cell):return _tiles[cell]
 if not _attempted_sheet:
  _attempted_sheet=true
  # The playable source ZIP carries raw art, so no editor .import is required.
  if FileAccess.file_exists(SHEET):
   var image := Image.new()
   if image.load_png_from_buffer(FileAccess.get_file_as_bytes(SHEET))==OK and image.get_size()==CELL*GRID:
    _sheet=image
 if _sheet==null:return null
 # Independent images keep the sampler/mips from bleeding into adjacent skills.
 var icon := _cut(_sheet,cell)
 _tiles[cell]=icon
 return icon

static func terrain_texture(kind: String) -> Texture2D:
 var column: int = WORK_CELLS.get(kind,-1)
 if column<0:return null
 if not _work_attempted:
  _work_attempted=true
  if FileAccess.file_exists(WORK_SHEET):
   var image := Image.new()
   if image.load_png_from_buffer(FileAccess.get_file_as_bytes(WORK_SHEET))==OK and image.get_size()==CELL*Vector2i(3,1):
    for i in 3:_work_icons.append(_cut(image,Vector2i(i,0)))
 return _work_icons[column] if column<_work_icons.size() else null

static func _cut(image: Image, cell: Vector2i) -> Texture2D:
 var tile := image.get_region(Rect2i(cell*CELL,CELL))
 tile.generate_mipmaps()
 return ImageTexture.create_from_image(tile)
