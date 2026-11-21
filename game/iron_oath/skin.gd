extends RefCounted
## Compatibility seam shared by Company, town/road painters, report and battle HUD.
const Press = preload("res://engraved_ui/press.gd")
static func texture(name: String) -> Texture2D:
 return Press.stock({"panel":"binding","button":"prime","camp":"endpaper"}[name])
static func panel(padding: int = 12, selected: bool = false) -> StyleBoxTexture:
 return Press.box("active" if selected else "binding",maxi(0,padding),maxi(0,padding))
static func button(primary: bool = false, selected: bool = false, disabled: bool = false) -> StyleBoxTexture:
 return Press.box("shut" if disabled else "active" if selected else "prime" if primary else "leaf",12,6)
