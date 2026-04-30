extends Camera2D

@onready var difficulty_text: Label = $"../CanvasLayer/BorderRight/DifficultyLabel"

func _ready() -> void:
	GlobalSignals.OnPlayerEnterRoom.connect(_on_player_enter_room)

func _on_player_enter_room(room: Room) -> void:
	global_position = room.global_position
	
	difficulty_text.text = "Difficulty: %0.2f" % room.difficulty
