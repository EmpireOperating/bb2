extends "res://hollow_campaign/session.gd"
func _new_campaign():
 return preload("res://local_markets/campaign.gd").new()
func checkpoint_origin() -> String:
 return "ashen-company-local-markets"
func save_camp(path: String = "user://local-markets-camp.json") -> bool:
 return super.save_camp(path)
func load_camp(path: String = "user://local-markets-camp.json") -> bool:
 return super.load_camp(path)
