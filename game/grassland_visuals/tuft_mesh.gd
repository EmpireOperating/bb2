extends "res://prototype/terrain_assets/mesh_builder.gd"
## Seven curved, tapered opaque blades; one accumulator/surface for the field.
## Exactly 21 triangles per tuft. Horizontal extent is below .17 world units.
func tuft(center: Vector3, height: float, phase: float, tint: Color) -> void:
 for i in 7:
  var angle := phase + float(i)*2.399963
  var along := Vector3(cos(angle),0,sin(angle))
  var across := Vector3(-along.z,0,along.x)
  var base := center + along*(.018+float(i%3)*.008)
  var length := height*(.72+float(i%4)*.09)
  var width := .026+float(i%3)*.006
  var knee := base+Vector3.UP*length*.56+along*.028
  var tip := base+Vector3.UP*length+along*(.080+float(i%3)*.013)
  var color := tint.lightened(float(i%3)*.025)
  quad(base-across*width,knee-across*width*.48,knee+across*width*.48,base+across*width,color.darkened(.08))
  var tip_color := color.lerp(Color("a39b68"),.52) if i == 5 else color.lightened(.05)
  triangle(knee-across*width*.48,tip,knee+across*width*.48,tip_color)
