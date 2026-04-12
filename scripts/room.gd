class_name Room extends StaticBody2D

enum Direction { NORTH, SOUTH, EAST, WEST }

@export var doors_always_open: bool = false
@export var is_boss_room: bool = false
@export var is_pcg_room: bool = false
@export var max_pcg_enemies: int = 6

@onready var entrance_north: RoomEntrance = $Entrance_North
@onready var entrance_south: RoomEntrance = $Entrance_South
@onready var entrance_east: RoomEntrance = $Entrance_East
@onready var entrance_west: RoomEntrance = $Entrance_West

@onready var obstacle: PackedScene = preload("res://scenes/obstacles/obstacle.tscn")
@onready var enemy_bullet_x: PackedScene = preload("res://scenes/enemies/enemy_bullet_x.tscn")
@onready var enemy: PackedScene = preload("res://scenes/enemies/enemy.tscn")

var enemies_in_room: int

# cell slots
var num_cells: int = 14 
var room_grid: Array[String] = []
var tile_size: int = 16

func _ready() -> void:
	GlobalSignals.OnDefeatEnemy.connect(_on_enemy_defeated)

	# place things
	if is_pcg_room:
		for x in range(num_cells):
			for y in range(num_cells):
				var ch = " "

				# leave a border
				if x > 0 and x < num_cells-1 and y > 0 and y < num_cells-1:
					if (randf() > 0.7):
						ch = "#"
				room_grid.append(ch)



		var num_enemies = randi_range(0, max_pcg_enemies)
		for e in range(num_enemies):
			var timeout = 100
			while timeout > 0:
				var idx = randi_range(0, num_cells-1)
				var idy = randi_range(0, num_cells-1)
				if room_grid[idx + idy * num_cells] == " ":
					room_grid[idx + idy * num_cells] = "e"
					break

				timeout -= 1

		var half_map_size: int = (num_cells * tile_size) / 2
		for x in range(0,num_cells):
			for y in range(0,num_cells):
				var _x: int = (x * tile_size) - half_map_size + (tile_size / 2)
				var _y: int = (y * tile_size) - half_map_size + (tile_size / 2)
				if room_grid[x + y * num_cells] == "#":
					var o = obstacle.instantiate()
					o.global_position = Vector2(_x, _y)
					add_child(o)
				elif room_grid[x + y * num_cells] == "e":
					var e
					if randf() > 0.5:
						e = enemy.instantiate()
					else:
						e = enemy_bullet_x.instantiate()
					e.global_position = Vector2(_x, _y)
					add_child(e)


		# for i in randi_range(1, 10):
		# 	var x = randi_range(-120, 120)
		# 	var y = randi_range(-120, 120)
		# 	var o = obstacle.instantiate()
		# 	o.global_position = Vector2(x, y)
		# 	add_child.call_deferred(o)

	for child in get_children():
		if child is Enemy:
			enemies_in_room += 1
			child.initialize(self)


func initialize() -> void:
	open_doors.call_deferred()
	# pass

func set_neighbor(neighbor_direction: Direction, neighbor_room: Room) -> void:
	if neighbor_direction == Direction.NORTH:
		entrance_north.set_neighbor(neighbor_room)
	elif neighbor_direction == Direction.SOUTH:
		entrance_south.set_neighbor(neighbor_room)
	elif neighbor_direction == Direction.EAST:
		entrance_east.set_neighbor(neighbor_room)
	else:
		entrance_west.set_neighbor(neighbor_room)

func player_enter(entry_direction: Direction, player: CharacterBody2D, first_room: bool = false) -> void:
	if entry_direction == Direction.NORTH:
		player.global_position = entrance_north.player_spawn.global_position
	elif entry_direction == Direction.SOUTH:
		player.global_position = entrance_south.player_spawn.global_position
	elif entry_direction == Direction.EAST:
		player.global_position = entrance_east.player_spawn.global_position
	else:
		player.global_position = entrance_west.player_spawn.global_position

	# spawn player in middle
	if first_room:
		player.global_position = global_position
	else:
		$RoomEnterSound.play()

	# emit that player entered the room
	GlobalSignals.OnPlayerEnterRoom.emit(self)

	# handle doors if enemies present/cleared
	if enemies_in_room > 0 and not doors_always_open:
		close_doors()
	else:
		open_doors()

func _on_defeat_enemy(enemy) -> void:
	pass

func open_doors():
	entrance_east.open_door.call_deferred()
	entrance_west.open_door.call_deferred()
	entrance_north.open_door.call_deferred()
	entrance_south.open_door.call_deferred()

func close_doors():
	entrance_east.close_door.call_deferred()
	entrance_west.close_door.call_deferred()
	entrance_north.close_door.call_deferred()
	entrance_south.close_door.call_deferred()

func _on_enemy_defeated(enemy: Enemy):
	if enemy.get_parent() == self:
		enemies_in_room -= 1

		if enemies_in_room <= 0:
			open_doors()
			$RoomEnterSound.play()
