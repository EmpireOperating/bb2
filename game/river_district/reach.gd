extends "res://src/map_generator.gd"
## Western v3 constituent, river recipe 1. Work in the constituent's local grid;
## the outer generator alone translates points into regional coordinates.
enum Reach {STONE, FEN, SPRINGS}
const HOME_LORE = [
 "Two stone spans serve the march. The market road crosses at the tollhouse; the quarry wagons use the lower bridge.",
 "The market stands beyond seven lengths of reed causeway. A shorter span serves the quarries downstream.",
 "The market road skirts the springs on dry land. Ore wagons cross the river farther down, at Hammer Bridge."
]
const CAMP_NAMES = ["Broken Tollhouse", "Reed Gate Outlaws", "Packhorse Cut"]
const TOWERS = ["Spanwarden's Beacon", "Reed Pilot's Loft", "Surveyor's Cairn"]
const RUINS = ["Lower Bridge Granary", "Flood Store", "Abandoned Ore Scale"]
var centre: Array[int] = []
var radius: Array[int] = []

func bank(row: int, offset: int) -> Vector2i:
 return Vector2i(centre[row]+offset,row)

func cross_at(row: int) -> void:
 for dx in range(-radius[row]-1,radius[row]+2):
  put(bank(row,dx),5 if absi(dx)<=radius[row] else 4)
 bridges.append({"position":packed(point(bank(row,0))),"vertical":false})

func compose(small: Dictionary, seed_number: int) -> void:
 # Keep the original town identities, loot rolls, camp roles and trade contracts.
 # Replace the geography *before* any regional roads, farms or sites are placed.
 rng.seed = seed_number ^ 0x72adc9
 var style := posmod(seed_number,3)
 var upper := rng.randi_range(8,10); var lower := rng.randi_range(21,23)
 var axis := rng.randi_range(25,31); var phase := rng.randf_range(0,TAU)
 var head := upper-1 if style==Reach.SPRINGS else 0
 cells.resize(W*H); cells.fill(0)
 for y in H:
  var bend := roundi(2.5*sin(y*0.17+phase)+1.5*cos(y*0.11-phase))
  centre.append(axis+bend)
  # A widening fen, not a scaled-up sprite. The actual cart deck is seven cells.
  radius.append(1+maxi(0,2-absi(y-upper)/4) if style==Reach.FEN else 1)
  for x in W:
   var delta := absi(x-centre[y]); var at := Vector2i(x,y)
   var fold := sin(x*0.22+phase)*0.8 + cos(y*0.33+x*0.05)
   if delta>4: put(at,2 if fold< -0.85 else 1 if fold>0.75 else 0)
   if y>=head and delta<=radius[y]: put(at,3)
  if y>=head: river.append(packed(point(bank(y,0))))
 if style!=Reach.SPRINGS: cross_at(upper)
 cross_at(lower)
 var home := bank(upper,-7); var market := bank(upper,14)
 var ambush := bank(upper,5); var quarry := bank(lower,13)
 var ridge := bank(lower,-7); var thicket := bank(lower-5,17)
 if style==Reach.FEN:
  home=bank(upper,-10); ambush=bank(upper,-5)
 elif style==Reach.SPRINGS:
  home=bank(head-3,-7); ambush=bank(head-3,4); market=bank(head-2,14)
 var beacony := home.y+4
 var sites := {"ashwick":home,"stonecross":market,"dunmere":quarry,"ford":ambush,"forest":thicket,"ridge":ridge,
  "discovery_0":bank(beacony,-7),"discovery_1":bank(lower+3,4),"discovery_2":bank(lower+2,-13)}
 for p in small.locations:
  var at: Vector2i=sites[p.id]; var pos:=point(at); p.x=int(pos.x);p.y=int(pos.y)
  if p.kind=="town": put(at,0)
  match p.id:
   "ashwick": p.description += " "+HOME_LORE[style]
   "ford": p.name=CAMP_NAMES[style]; p.description=["The toll chain is down. Outlaws hold the far approach to the stone span.","Reed cutters have barricaded the dry approach where wagons queue to cross.","Bandits lie in wait along the pack trail above the springs."][style]
   "discovery_0": p.name=TOWERS[style];p.description="Climb the old survey platform for a view of both banks."
   "discovery_1": p.name=RUINS[style];p.description="The carters stored dry rations here above the flood line. The store cellar still stands."
   "discovery_2": p.name="Boatmen's Cache";p.description="The deserters have hidden stores in a hollow above the lower crossing."
  if p.kind=="discovery":
   var hint := pos+Vector2(rng.randi_range(-28,28),rng.randi_range(-28,28))
   p.rumour=packed(hint if walkable(cell(hint)) else pos+Vector2(5,5))
 reset_graph()
 for edge in small.roads:
  add_road(edge[0],edge[1],sites[edge[0]],sites[edge[1]])
  reset_graph()
 small.terrain=cells;small.river=river;small.bridges=bridges
 small.roads=road_edges;small.road_paths=road_paths;small.world_config=economy(small)
