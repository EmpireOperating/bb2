extends "res://iron_oath/inventory_card.gd"
## Same inventory art/skin/card; explicit absence, full rarity and condition lines.
const Rarity = preload("res://hollow_systems/rarity.gd")
var rarity_label: Label
var condition_label: Label
var missing_art: Label
func _init() -> void:
 super()
 rarity_label = _label(12)
 condition_label = _label(12)
 missing_art = _label(12);missing_art.text = "No artwork";missing_art.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
func annotate(tier: String, condition_text: String) -> void:
 rarity_label.text = tier.capitalize() if not tier.is_empty() else "Unrated"
 rarity_label.add_theme_color_override("font_color",Rarity.tier_color(tier))
 condition_label.text = condition_text
 missing_art.visible = art.texture == null
 _layout()
func _layout() -> void:
 super._layout()
 if rarity_label == null:return
 var icon_width := minf(94,size.x*.35)
 var x := icon_width+18;var width := maxf(1,size.x-x-10)
 art.position = Vector2(8,8);art.size = Vector2(icon_width,maxf(8,size.y-16))
 heading.position = Vector2(x,8);heading.size = Vector2(width,42);heading.max_lines_visible = 2
 heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;heading.add_theme_font_size_override("font_size",16)
 rarity_label.position = Vector2(x,52);rarity_label.size = Vector2(width,18)
 condition_label.position = Vector2(x,74);condition_label.size = Vector2(width,18)
 missing_art.position = Vector2(8,size.y/2-12);missing_art.size = Vector2(icon_width,24)
 meter.position = Vector2(x,size.y-10);meter.size = Vector2(width,4)
 caption.hide()
 _clear_badge_title() # Subclass heading geometry must clear the same 28px badge.
