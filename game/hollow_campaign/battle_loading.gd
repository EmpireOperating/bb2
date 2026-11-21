extends CanvasLayer
## Static presentation only; the inherited host retains battle authority.
func _ready() -> void:
 layer = 90
 var surface := LoadingArt.new()
 surface.name = "Surface"
 surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 surface.mouse_filter = Control.MOUSE_FILTER_STOP
 add_child(surface)

class LoadingArt extends Control:
 const SERIF = preload("res://assets/serif.ttf")
 const SANS = preload("res://assets/sans.ttf")
 const LANDSCAPE = preload("res://company_town/assets/town_square.png")
 const MERCENARY = preload("res://hollow_campaign/assets/loading-mercenary.png")
 func _draw() -> void:
  var w := size.x; var h := size.y
  var u := minf(w/1440.0,h/900.0)
  var gold := Color("e5c180")
  draw_rect(Rect2(Vector2.ZERO,size),Color("111414"))
  draw_texture_rect(LANDSCAPE,Rect2(Vector2.ZERO,size),false,Color(.55,.48,.39,1))
  draw_rect(Rect2(Vector2.ZERO,size),Color(.028,.027,.025,.74))
  # Illustrative painted mercenary; not a claim about the selected roster.
  draw_rect(Rect2(w*.055,h*.075,w*.39,h*.84),Color(.04,.035,.03,.43))
  draw_rect(Rect2(w*.055,h*.075,w*.39,h*.84),Color(gold,.35),false,2.0*u)
  var figure_h := h*.89
  var figure_w := figure_h*2.0/3.0
  draw_texture_rect(MERCENARY,Rect2(w*.075,h*.09,figure_w,figure_h),false,Color(.91,.86,.77,1))
  var x := w*.50; var right := w*.93; var content := right-x
  preload("res://engraved_ui/press.gd").impression(self,Rect2(x-22*u,h*.11,content+44*u,h*.78),"binding")
  draw_line(Vector2(x,h*.22),Vector2(right,h*.22),Color(gold,.7),2.0*u)
  var small := maxi(12,int(21*u)); var title := maxi(25,int(58*u)); var body := maxi(12,int(20*u))
  draw_string(SANS,Vector2(x,h*.19),"THE ASHEN COMPANY",HORIZONTAL_ALIGNMENT_LEFT,content,small,gold)
  draw_string(SERIF,Vector2(x,h*.38),"TO THE FIELD",HORIZONTAL_ALIGNMENT_LEFT,content,title,Color("efe3cc"))
  draw_string(SANS,Vector2(x,h*.445),"FIRST MUSTER  /  COMPANY SORTIE",HORIZONTAL_ALIGNMENT_LEFT,content,small,Color("b7ab97"))
  draw_line(Vector2(x,h*.49),Vector2(right,h*.49),Color(gold,.38),1.5*u)
  draw_string(SERIF,Vector2(x,h*.58),"Steel in hand.",HORIZONTAL_ALIGNMENT_LEFT,content,maxi(16,int(30*u)),Color("d5c7aa"))
  draw_string(SERIF,Vector2(x,h*.635),"The company marches together.",HORIZONTAL_ALIGNMENT_LEFT,content,maxi(16,int(30*u)),Color("d5c7aa"))
  draw_string(SANS,Vector2(x,h*.79),"Preparing the battlefield",HORIZONTAL_ALIGNMENT_LEFT,content,body,Color("e3c791"))
  draw_line(Vector2(x,h*.85),Vector2(right,h*.85),Color(gold,.5),1.5*u)
