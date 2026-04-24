extends Control

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_play_button_pressed() -> void:
	#GameState.player_hp = GameState.player_base_hp
	#GameState.player_max_hp = GameState.player_base_hp
	GameState.new_game()
