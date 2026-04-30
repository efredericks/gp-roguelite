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
@onready var obstacle_pain: PackedScene = preload("res://scenes/obstacles/obstacle_pain.tscn")
@onready var enemy_bullet_x: PackedScene = preload("res://scenes/enemies/enemy_bullet_x.tscn")
@onready var enemy_bullet_plus: PackedScene = preload("res://scenes/enemies/enemy_bullet_plus.tscn")
@onready var enemy: PackedScene = preload("res://scenes/enemies/enemy.tscn")

var enemies_in_room: int

# cell slots (mirrored in RoomGenome)
var num_cells: int = 14 
var room_grid: Array[String] = []
var tile_size: int = 16


#############################################################
const POP_SIZE = 50
const GENERATIONS = 150
var best_genome: RoomGenome = null
var difficulty = 0.5
	

#func _evolve() -> RoomGenome:
func _evolve(target_difficulty: float = 0.5) -> RoomGenome:
	var population: Array[RoomGenome] = []

	# Seed population
	for i in range(POP_SIZE):
		var g = RoomGenome.new()
		g.randomize_layout()
		g.randomize_enemy_programs()
		population.append(g)

	var best: RoomGenome = population[0]
	var best_score = -INF
	var stagnation = 0

	for gen in range(GENERATIONS):
		# Score all
		var scored = []
		for g in population:
			var layout_score = g.score_layout()
			var diff_score = g.estimate_difficulty()
			var diff_penalty = abs(diff_score - target_difficulty) * 5.0
			scored.append({genome=g, score=layout_score - diff_penalty, difficulty=g.estimate_difficulty()})
			#scored.append({genome=g, score=g.score_layout()})
		scored.sort_custom(func(a, b):
			if is_nan(a.score): return false
			if is_nan(b.score): return true
			return a.score > b.score
		)

		print("Gen %d | best: %.2f | difficulty: %.2f" % [gen, scored[0].score, scored[0].difficulty])

		if scored[0].score > best_score:
			best_score = scored[0].score
			best = scored[0].genome
			stagnation = 0
		else:
			stagnation += 1
			if stagnation >= 4:
				print("Early stop at gen %d" % gen)
				break

		# Next generation
		var next: Array[RoomGenome] = []
		# Elitism - keep top 25%
		for i in range(POP_SIZE / 4):
			next.append(scored[i].genome)
		# Fill with crossover + mutation
		var pop_only = scored.map(func(s): return s.genome)
		while next.size() < POP_SIZE:
			var pa = pop_only[randi() % (POP_SIZE / 2)]
			var pb = pop_only[randi() % (POP_SIZE / 2)]
			var child = pa.crossover(pb)
			child = child.mutate(0.12)
			next.append(child)
		population = next

	return best

func _spawn_room(genome: RoomGenome) -> void:
	# Place layout tiles
	var half = (genome.num_cells * 16) / 2
	for x in range(genome.num_cells):
		for y in range(genome.num_cells):
			var ch = genome.layout[x + y * genome.num_cells]
			var wx = x * 16 - half + 8
			var wy = y * 16 - half + 8
			match ch:
				"#":
					var o = obstacle.instantiate()
					o.global_position = Vector2(wx, wy)
					add_child(o)
				"f":
					var o = obstacle_pain.instantiate()
					o.global_position = Vector2(wx, wy)
					add_child(o)

	# Place enemies with evolved programs
	var enemy_idx = 0
	var num_enemies = randi_range(1, max_pcg_enemies)
	for i in range(num_enemies):
		var timeout = 100
		while timeout > 0:
			var rx = randi_range(1, genome.num_cells - 2)
			var ry = randi_range(1, genome.num_cells - 2)
			if genome.layout[rx + ry * genome.num_cells] == " ":
				genome.layout[rx + ry * genome.num_cells] = "e"
				var e = _pick_enemy()
				e.global_position = Vector2(rx * 16 - half + 8, ry * 16 - half + 8)
				# Give each enemy an evolved program from the genome
				e.program = genome.get_enemy_program(enemy_idx)
				enemy_idx += 1
				add_child(e)
				e.initialize(self)
				enemies_in_room += 1
				break
			timeout -= 1

func _pick_enemy() -> Enemy:
	var r = randf()
	if r < 0.6:   return enemy.instantiate()
	elif r < 0.8: return enemy_bullet_plus.instantiate()
	else:         return enemy_bullet_x.instantiate()
###################################################################


func _ready() -> void:
	GlobalSignals.OnDefeatEnemy.connect(_on_enemy_defeated)

	if GameState.is_evolver:
		best_genome = _evolve()   # comment this out to freeze
		# best_genome = _load_saved_genome()  # load a saved one instead
		_spawn_room(best_genome)
		difficulty = best_genome.estimate_difficulty()
	else:
		####
		# move this stuff over to room_generation!!
		
		# place things
		if is_pcg_room:
			for x in range(num_cells):
				for y in range(num_cells):
					var ch = " "
					var r = randf()
					# leave a border
					if x > 0 and x < num_cells-1 and y > 0 and y < num_cells-1:
						if (r > 0.8):
							ch = "#"
						elif (r > 0.7):
							ch = "f"
							
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
					elif room_grid[x + y * num_cells] == "f":
						var o = obstacle_pain.instantiate()
						o.global_position = Vector2(_x, _y)
						add_child(o)
					elif room_grid[x + y * num_cells] == "e":
						var e
						var r = randf()
						if r < 0.6:
							e = enemy.instantiate()
						elif r < 0.8:
							e = enemy_bullet_plus.instantiate()
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

		# calculate difficulty

# called from room_generation - good point to include the genome being passed in...
func initialize(rg: RoomGenome) -> void:
	open_doors.call_deferred()
	
	"""
	# this was all in room.gd
	# place things
	if is_pcg_room:
		for x in range(num_cells):
			for y in range(num_cells):
				var ch = " "
				var r = randf()
				# leave a border
				if x > 0 and x < num_cells-1 and y > 0 and y < num_cells-1:
					if (r > 0.8):
						ch = "#"
					elif (r > 0.7):
						ch = "f"
						
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
				elif room_grid[x + y * num_cells] == "f":
					var o = obstacle_pain.instantiate()
					o.global_position = Vector2(_x, _y)
					add_child(o)
				elif room_grid[x + y * num_cells] == "e":
					var e
					var r = randf()
					if r < 0.6:
						e = enemy.instantiate()
					elif r < 0.8:
						e = enemy_bullet_plus.instantiate()
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
	"""
	pass

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
