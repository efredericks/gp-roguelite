extends GridContainer

var room_gen: RoomGeneration
var icons: Array[TextureRect]

var room_texture: Texture = preload("res://assets/minimap_main.tres")
var player_room_texture: Texture = preload("res://assets/minimap_player.tres")
var boss_room_texture: Texture = preload("res://assets/minimap_boss.tres")

func _ready() -> void:
	GlobalSignals.OnPlayerEnterRoom.connect(_on_player_enter_room)

func _on_player_enter_room(room: Room):
	if not room_gen:
		room_gen = get_node("/root/main/RoomGeneration")

		for child in get_children():
			if child is TextureRect:
				icons.append(child)

	for x in range(room_gen.map_size):
		for y in range(room_gen.map_size):
			var r = room_gen.get_room_from_map(x, y)
			var idx = x + y * room_gen.map_size

			# out of range
			if idx > len(icons):
				continue

			if not r: # room doesn't exist
				icons[idx].texture = null
			elif r == room:
				icons[idx].texture = player_room_texture
			elif r.is_boss_room:
				icons[idx].texture = boss_room_texture
			else:
				icons[idx].texture = room_texture

			