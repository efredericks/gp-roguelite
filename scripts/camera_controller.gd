extends Camera2D

func _ready() -> void:
	GlobalSignals.OnPlayerEnterRoom.connect(_on_player_enter_room)

func _on_player_enter_room(room: Room) -> void:
	global_position = room.global_position
