extends "res://local_markets/session.gd"
func checkpoint_origin() -> String:
 return "ashen-company-combat-ux"
func save_camp(path: String = "user://combat-ux-camp.json") -> bool:
 return super.save_camp(path)
func load_camp(path: String = "user://combat-ux-camp.json") -> bool:
 return super.load_camp(path)
