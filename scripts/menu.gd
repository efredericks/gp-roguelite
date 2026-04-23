extends Control

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_play_button_pressed() -> void:
	#GameState.player_hp = GameState.player_base_hp
	#GameState.player_max_hp = GameState.player_base_hp
	GameState.reset_data()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
