extends Node

# globals + game state variables
var max_rooms_to_generate: int = 10
var current_level: int = 1

var player_base_hp: int = 3
var player_hp: int = player_base_hp
var player_max_hp: int = player_base_hp

var debug_invincible: bool = false
var is_evolver: bool = false

var restart_hold_time: float = 0.0
var restart_hold_duration: float = 2.0  # seconds to hold

# global inputs that aren't movement/shooting
func _process(delta: float) -> void:
	
	# debug
	if Input.is_action_just_pressed("invincible"):
		debug_invincible = not debug_invincible
		GlobalSignals.OnDebug.emit.call_deferred() # modulate player
		
	# hold R to restarts w
	if Input.is_action_pressed("restart"):
		restart_hold_time += delta
		GlobalSignals.OnResetHold.emit.call_deferred(remap(restart_hold_time, 0.0, 2.0, 0.0, 1.0))
		
		if restart_hold_time >= restart_hold_duration:
			_restart()
	else:
		restart_hold_time = 0.0
		GlobalSignals.OnResetHold.emit.call_deferred(0.0) # reset alpha  

	# toggle fullscreen
	if Input.is_action_just_pressed("toggle_fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# new game, but only on main screen
	if Input.is_action_just_pressed("new_game"):
		if get_tree().current_scene.name == "menu":
			new_game(false)
	# new game, but only on main screen
	if Input.is_action_just_pressed("new_game_evolver"):
		if get_tree().current_scene.name == "menu":
			new_game(true)
	
	# quit game with Q on main menu
	if Input.is_action_just_pressed("quit_menu"):
		if get_tree().current_scene.name == "menu":
			get_tree().quit()
		
	# quit game
	if Input.is_action_just_pressed("quit"):
		if get_tree().current_scene.name == "menu":
			get_tree().quit()
		else:
			get_tree().change_scene_to_file("res://scenes/menu.tscn")
		
# reset all global data (also called when dead)
func reset_data() -> void:
	current_level = 1
	restart_hold_time = 0.0
	player_hp = GameState.player_base_hp
	player_max_hp = GameState.player_base_hp
	
func _restart() -> void:
	reset_data()
	get_tree().reload_current_scene()
	
func new_game(evolver: bool = false) -> void:
	GameState.reset_data()
	GameState.is_evolver = evolver
	get_tree().change_scene_to_file("res://scenes/main.tscn")
