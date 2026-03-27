extends GridContainer

var full_heart: Texture = preload("res://assets/player_heart.tres")
var empty_heart: Texture = preload("res://assets/player_heart_empty.tres")
var heart_icons: Array[TextureRect]

func _init() -> void:
	GlobalSignals.OnPlayerUpdateHealth.connect(_update_ui)

func _ready() -> void:
	for child in get_children():
		if child is TextureRect:
			heart_icons.append(child)

func _update_ui(currHP: int, maxHP: int) -> void:
	for idx in len(heart_icons):
		if idx >= maxHP:
			heart_icons[idx].visible = false
			continue

		heart_icons[idx].visible = true
		if idx < currHP:
			heart_icons[idx].texture = full_heart
		else:
			heart_icons[idx].texture = empty_heart

