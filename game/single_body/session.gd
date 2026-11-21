extends "res://company_banners/session.gd"
func _new_campaign():
 return preload("res://single_body/campaign.gd").new()
func checkpoint_origin() -> String:
 return "ashen-company-engraved"
