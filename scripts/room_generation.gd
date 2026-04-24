class_name RoomGeneration extends Node

# room procgen config
@export var map_size: int = 7
@export var rooms_to_generate: int # defined in GlobalSignals = 12
var room_count: int = 0
var game_map: Array[bool]
var rooms: Array[Room]
var room_position_offset: float = 320#256 #160# Vector2 = Vector2(288, 160) # room gap  - was 160 int

# starting room
var first_room_x: int = 3
var first_room_y: int = 3
var first_room: Room

var room_scene: PackedScene = preload("res://scenes/rooms/room_template.tscn")

@export var first_room_scene: PackedScene
@export var room_scenes: Array[PackedScene]
@export var boss_room: PackedScene
@export var player: CharacterBody2D

@onready var level_text: Label = $"../CanvasLayer/BorderLeft/LevelInfo"

func _ready() -> void:
	rooms_to_generate = GameState.max_rooms_to_generate
	
	print("Rooms to generate: " + str(rooms_to_generate))
	level_text.text = "Level %d" % GameState.current_level
	_generate()
	
	#player.currHP = GameState.player_base_hp
	#player.maxHP = GameState.player_base_hp
	#GameState.player_hp = GameState.player_base_hp
	#GameState.player_max_hp = GameState.player_base_hp

	# debug
	# for x in range(map_size):
	#     var s: String = ""
	#     for y in range(map_size):
	#         s += "#" if _get_map(x, y) else "."
	#         s += " "
	#     print(s)

# generate layout
func _generate() -> void:
	game_map.resize(map_size * map_size)
	room_count = 0

	_check_room(first_room_x, first_room_y, Vector2.ZERO, true)
	_instantiate_rooms()


func _check_room(x: int, y: int, desired_direction: Vector2, is_first_room: bool = false):
	# too many
	if room_count >= rooms_to_generate: 
		return  

	# out of bounds
	if x < 0 or x > map_size - 1 or y < 0 or y > map_size-1: 
		return 

	# already exists
	if _get_map(x, y):
		return

	# room valid
	room_count += 1
	_set_map(x, y, true)

	# pick directions
	var go_north: bool = randf() > (0.2 if desired_direction == Vector2.UP else 0.8)
	var go_south: bool = randf() > (0.2 if desired_direction == Vector2.DOWN else 0.8)
	var go_east: bool = randf() > (0.2 if desired_direction == Vector2.RIGHT else 0.8)
	var go_west: bool = randf() > (0.2 if desired_direction == Vector2.LEFT else 0.8)

	# recurse until done
	if go_north or is_first_room:
		_check_room(x, y - 1, Vector2.UP if is_first_room else desired_direction)

	if go_south or is_first_room:
		_check_room(x, y + 1, Vector2.DOWN if is_first_room else desired_direction)

	if go_east or is_first_room:
		_check_room(x + 1, y, Vector2.RIGHT if is_first_room else desired_direction)

	if go_west or is_first_room:
		_check_room(x - 1, y, Vector2.LEFT if is_first_room else desired_direction)


func _instantiate_rooms() -> void:
	var boss_room_pos: Vector2 = _decide_boss_room()

	for x in range(map_size):
		for y in range(map_size):
			if not _get_map(x, y):
				continue
			
			var room: Room# = room_scene.instantiate()
			var is_first_room: bool = first_room_x == x and first_room_y == y

			if is_first_room:
				room = room_scene.instantiate()
			elif x == boss_room_pos.x and y == boss_room_pos.y:
				room = boss_room.instantiate()
			else:
				room = room_scenes[randi_range(0, len(room_scenes)-1)].instantiate()

			get_tree().get_root().get_node("/root/main").add_child.call_deferred(room)
			rooms.append(room)

			room.global_position = Vector2(x, y) * room_position_offset

			if is_first_room:
				first_room = room
			room.initialize()
	
	for room in rooms:
		var map_pos: Vector2 = _get_map_index(room)
		var x = map_pos.x
		var y = map_pos.y

		# check neighbors
		if y > 0 and _get_map(x, y - 1):
			room.set_neighbor.call_deferred(Room.Direction.NORTH, get_room_from_map(x, y - 1))
		if y < map_size - 1 and _get_map(x, y + 1):
			room.set_neighbor.call_deferred(Room.Direction.SOUTH, get_room_from_map(x, y + 1))
		if x < map_size - 1 and _get_map(x + 1, y):
			room.set_neighbor.call_deferred(Room.Direction.EAST, get_room_from_map(x + 1, y))
		if x > 0 and _get_map(x - 1, y):
		#if y > 0 and _get_map(x - 1, y):
			room.set_neighbor.call_deferred(Room.Direction.WEST, get_room_from_map(x - 1, y))

	first_room.player_enter.call_deferred(Room.Direction.NORTH, player, true)

# distance based
func _decide_boss_room() -> Vector2:
	var candidates: Array[Vector2] = []
	#var farthest_pos := Vector2(first_room_x, first_room_y)
	var max_dist := 0.0

	for x in range(map_size):
		for y in range(map_size):
			if not _get_map(x, y):
				continue
			if x == first_room_x and y == first_room_y:
				continue
			
			var dist = abs(x - first_room_x) + abs(y - first_room_y)  # manhattan distance
			#if dist > max_dist:
				#max_dist = dist
				#farthest_pos = Vector2(x, y)
			if dist > max_dist:
				max_dist = dist
				candidates = [Vector2(x, y)]
			elif dist == max_dist:
				candidates.append(Vector2(x, y))

	return candidates[randi_range(0, candidates.size() - 1)]
	#return farthest_pos
# old
#func _decide_boss_room() -> Vector2:
	##var i = 0
	##while i < 100:
	#for i in range(100):
		#var x = randi_range(0, map_size - 1)
		#var y = randi_range(0, map_size - 1)
#
		#if first_room_x == x and first_room_y == y:
			#continue
		#if _get_map(x, y):
			#return Vector2(x, y)
	#return Vector2.ZERO

# map helper functions
func get_room_from_map(x: int, y: int) -> Room:
	for room in rooms:
		var pos = _get_map_index(room)
		if pos.x != x or pos.y != y:
			continue

		return room
	return null

func _get_map_index(room: Room) -> Vector2i:
	return Vector2i(room.global_position / room_position_offset)

func _get_map(x: int, y: int) -> bool:
	return game_map[x + y * map_size]

func _set_map(x: int, y: int, val: bool) -> void:
	game_map[x + y * map_size] = val
