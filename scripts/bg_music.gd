extends AudioStreamPlayer

@export var bg_musics = [
	preload("res://assets/audio/Kenney-SciFi/Audio/spaceEngineSmall_000.ogg"),
	preload("res://assets/audio/Kenney-SciFi/Audio/spaceEngineSmall_001.ogg"),
	preload("res://assets/audio/Kenney-SciFi/Audio/spaceEngineSmall_002.ogg"),
	preload("res://assets/audio/Kenney-SciFi/Audio/spaceEngineSmall_003.ogg"),
	preload("res://assets/audio/Kenney-SciFi/Audio/spaceEngineSmall_004.ogg"),
]
var music_idx: int
@onready var player = $"."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_handleNext()

func _handleNext() -> void:
	var idx: int = randi_range(0, len(bg_musics)-1)
	player.stream = bg_musics[idx]
	player.play()

func _on_finished() -> void:
	_handleNext()
