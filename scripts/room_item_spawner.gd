extends Node

@export var item_scenes: Array[PackedScene]

func _ready() -> void:
    var item = item_scenes[randi_range(0, len(item_scenes)-1)].instantiate()
    add_child(item)
