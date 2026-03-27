class_name Room extends StaticBody2D

enum Direction { NORTH, SOUTH, EAST, WEST }

@export var doors_always_open: bool = false
@export var is_boss_room: bool = false

@onready var entrance_north: RoomEntrance = $Entrance_North
@onready var entrance_south: RoomEntrance = $Entrance_South
@onready var entrance_east: RoomEntrance = $Entrance_East
@onready var entrance_west: RoomEntrance = $Entrance_West

var enemies_in_room: int

func _ready() -> void:
	GlobalSignals.OnDefeatEnemy.connect(_on_enemy_defeated)
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
