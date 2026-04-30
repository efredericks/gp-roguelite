class_name RoomGenome extends Resource

# --- Room layout genome ---
# Each cell is a character: ' ', '#', 'f', 'e'
var layout: Array[String] = []
var num_cells: int = 14

# --- Enemy behavior genome ---
# Shared pool of evolved programs that enemies in this room draw from
var enemy_programs: Array = []
var num_enemy_programs: int = 3  # how many distinct behaviors to evolve

# Valid opcodes — must match Enemy's match statement
const OP_CODES: Array[String] = [
	"WAIT_20", "WAIT_40", "AIM", "FIRE_ONE", "FIRE_ALL",
	"RADIAL_4", "RADIAL_8", "RADIAL_16"
]

# Min/max program length for enemy behavior
const MIN_PROG_LEN: int = 3
const MAX_PROG_LEN: int = 16

func randomize_layout() -> void:
	layout.clear()
	for x in range(num_cells):
		for y in range(num_cells):
			var border = (x == 0 or x == num_cells-1 or y == 0 or y == num_cells-1)
			if border:
				layout.append(" ")
			else:
				var r = randf()
				if r > 0.8:   layout.append("#")
				elif r > 0.7: layout.append("f")
				else:         layout.append(" ")

func randomize_enemy_programs() -> void:
	enemy_programs.clear()
	for i in range(num_enemy_programs):
		enemy_programs.append(_random_program())

func _random_program() -> Array:
	var prog = []
	var length = randi_range(MIN_PROG_LEN, MAX_PROG_LEN)
	for i in range(length):
		prog.append(OP_CODES[randi() % OP_CODES.size()])
	return prog

func get_enemy_program(idx: int) -> Array:
	if enemy_programs.is_empty(): return ["WAIT_20", "AIM", "FIRE_ONE"]
	return enemy_programs[idx % enemy_programs.size()]

# --- Mutation ---
func mutate(mutation_rate: float = 0.1) -> RoomGenome:
	var child = RoomGenome.new()
	child.num_cells = num_cells
	child.num_enemy_programs = num_enemy_programs

	# Mutate layout
	child.layout = layout.duplicate()
	for i in range(child.layout.size()):
		if randf() < mutation_rate:
			var x = i % num_cells
			var y = i / num_cells
			var border = (x == 0 or x == num_cells-1 or y == 0 or y == num_cells-1)
			if not border:
				var r = randf()
				if r > 0.8:   child.layout[i] = "#"
				elif r > 0.7: child.layout[i] = "f"
				else:         child.layout[i] = " "

	# Mutate enemy programs
	child.enemy_programs = []
	for prog in enemy_programs:
		var new_prog = prog.duplicate()
		_mutate_program(new_prog, mutation_rate)
		child.enemy_programs.append(new_prog)

	return child

func _mutate_program(prog: Array, rate: float) -> void:
	# Mutate existing opcodes
	for i in range(prog.size()):
		if randf() < rate:
			prog[i] = OP_CODES[randi() % OP_CODES.size()]
	# Insert a random opcode
	if randf() < rate and prog.size() < MAX_PROG_LEN:
		var idx = randi() % prog.size()
		prog.insert(idx, OP_CODES[randi() % OP_CODES.size()])
	# Delete a random opcode
	if randf() < rate and prog.size() > MIN_PROG_LEN:
		prog.remove_at(randi() % prog.size())

# --- Crossover ---
func crossover(other: RoomGenome) -> RoomGenome:
	var child = RoomGenome.new()
	child.num_cells = num_cells
	child.num_enemy_programs = num_enemy_programs

	# Single point crossover on layout
	var split = randi() % layout.size()
	var new_layout: Array[String] = []
	for i in range(layout.size()):
		new_layout.append(layout[i] if i < split else other.layout[i])
	child.layout = new_layout

	# Per-program crossover on enemy behaviors
	var new_programs: Array = []
	for i in range(num_enemy_programs):
		var pa = enemy_programs[i] if i < enemy_programs.size() else _random_program()
		var pb = other.enemy_programs[i] if i < other.enemy_programs.size() else _random_program()
		new_programs.append(_crossover_program(pa, pb))
	child.enemy_programs = new_programs

	return child

func _crossover_program(a: Array, b: Array) -> Array:
	if a.is_empty(): return b.duplicate()
	if b.is_empty(): return a.duplicate()
	var split_a = randi() % a.size()
	var split_b = randi() % b.size()
	var child = []
	for i in range(split_a):
		child.append(a[i])
	for i in range(split_b, b.size()):
		child.append(b[i])
	while child.size() > MAX_PROG_LEN:
		child.remove_at(child.size() - 1)
	while child.size() < MIN_PROG_LEN:
		child.append(OP_CODES[randi() % OP_CODES.size()])
	return child

# --- Fitness (layout only — enemy behavior fitness happens at runtime) ---
func score_connectivity() -> float:
	# BFS from first open inner cell
	var start = Vector2i(-1, -1)
	var total_open = 0
	for x in range(1, num_cells - 1):
		for y in range(1, num_cells - 1):
			if layout[x + y * num_cells] == " ":
				total_open += 1
				if start == Vector2i(-1, -1):
					start = Vector2i(x, y)
	
	if total_open == 0: return -5.0
	
	var visited = 0
	var queue = [start]
	var seen = {start: true}
	var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	while not queue.is_empty():
		var cur = queue.pop_front()
		visited += 1
		for d in dirs:
			var nb = cur + d
			if nb.x > 0 and nb.x < num_cells-1 and nb.y > 0 and nb.y < num_cells-1:
				if layout[nb.x + nb.y * num_cells] == " " and not seen.has(nb):
					seen[nb] = true
					queue.append(nb)
	
	# 1.0 = fully connected, 0.0 = completely fragmented
	return float(visited) / float(total_open)
func score_chokepoints() -> float:
	# Count cells that are open but have exactly 2 open neighbors in a line
	# (horizontally or vertically) — these are corridor/chokepoint cells
	var chokepoints = 0
	var open = 0
	for x in range(1, num_cells - 1):
		for y in range(1, num_cells - 1):
			if layout[x + y * num_cells] != " ": continue
			open += 1
			var h_open = (layout[(x-1) + y * num_cells] == " ") and (layout[(x+1) + y * num_cells] == " ")
			var v_open = (layout[x + (y-1) * num_cells] == " ") and (layout[x + (y+1) * num_cells] == " ")
			var h_blocked = (layout[(x-1) + y * num_cells] == "#") or (layout[(x+1) + y * num_cells] == "#")
			var v_blocked = (layout[x + (y-1) * num_cells] == "#") or (layout[x + (y+1) * num_cells] == "#")
			if (h_open and v_blocked) or (v_open and h_blocked):
				chokepoints += 1
	
	if open == 0: return 0.0
	var ratio = float(chokepoints) / open
	# Want some chokepoints (5-20%) but not a maze
	if ratio < 0.05: return 0.0
	elif ratio < 0.20: return ratio * 5.0   # reward up to ~1.0
	else: return -1.0                        # too corridor-heavy
func score_clustering() -> float:
	# For each obstacle, count how many obstacle neighbors it has
	# High average = clustered (interesting cover), low = scattered (boring)
	var total_obs = 0
	var neighbor_obs = 0
	var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	for x in range(1, num_cells - 1):
		for y in range(1, num_cells - 1):
			if layout[x + y * num_cells] != "#": continue
			total_obs += 1
			for d in dirs:
				var nx = x + d.x
				var ny = y + d.y
				if nx >= 0 and nx < num_cells and ny >= 0 and ny < num_cells:
					if layout[nx + ny * num_cells] == "#":
						neighbor_obs += 1
	
	if total_obs == 0: return 0.0
	var avg_neighbors = float(neighbor_obs) / total_obs
	# 0 = all isolated, 4 = solid block
	# Sweet spot is 1-2: small clusters of 2-4 obstacles
	if avg_neighbors < 0.5: return -1.0    # too scattered
	elif avg_neighbors < 2.0: return 1.0   # nice clusters
	else: return -0.5                       # too blobby
func score_symmetry() -> float:
	# Check horizontal and vertical symmetry separately, reward partial matches
	var h_matches = 0
	var v_matches = 0
	var total = 0
	
	for x in range(1, num_cells - 1):
		for y in range(1, num_cells / 2):
			var cell = layout[x + y * num_cells]
			var mirror_v = layout[x + (num_cells - 1 - y) * num_cells]
			if cell == mirror_v: v_matches += 1
			total += 1
	
	for y in range(1, num_cells - 1):
		for x in range(1, num_cells / 2):
			var cell = layout[x + y * num_cells]
			var mirror_h = layout[(num_cells - 1 - x) + y * num_cells]
			if cell == mirror_h: h_matches += 1
	
	var v_ratio = float(v_matches) / total
	var h_ratio = float(h_matches) / total
	var best = max(v_ratio, h_ratio)
	
	# Partial symmetry (60-85%) feels intentional without being boring
	if best < 0.5:  return 0.0    # basically random
	elif best < 0.6: return 0.3
	elif best < 0.85: return 1.0  # sweet spot
	else: return -0.5             # too perfectly symmetric = sterile
#func score_layout() -> float:
	#var score = 0.0
	#var obstacles = 0
	#var pain = 0
	#var open = 0
	#var total_inner = (num_cells - 2) * (num_cells - 2)
#
	#for x in range(1, num_cells - 1):
		#for y in range(1, num_cells - 1):
			#match layout[x + y * num_cells]:
				#"#": obstacles += 1
				#"f": pain += 1
				#" ": open += 1
#
	## Want 10-25% obstacles
	#var obs_ratio = float(obstacles) / total_inner
	#if obs_ratio < 0.10: score -= 2.0
	#elif obs_ratio > 0.25: score -= 2.0
	#else: score += 1.0
#
	## Want some pain tiles but not dominant
	#var pain_ratio = float(pain) / total_inner
	#if pain_ratio > 0.15: score -= 1.0
	#elif pain_ratio > 0.03: score += 0.5
#
	## Reward navigable open space
	#var open_ratio = float(open) / total_inner
	#if open_ratio < 0.5: score -= 2.0
	#else: score += open_ratio
#
	## Reward obstacles not clustered in center (check center 4x4)
	#var center_obstacles = 0
	#for x in range(5, 9):
		#for y in range(5, 9):
			#if layout[x + y * num_cells] == "#":
				#center_obstacles += 1
	#if center_obstacles > 4:
		#score -= 1.0  # don't block the middle completely
#
	## Reward enemy behavior variety — penalize all-same programs
	#if enemy_programs.size() > 1:
		#var all_same = true
		#for i in range(1, enemy_programs.size()):
			#if enemy_programs[i] != enemy_programs[0]:
				#all_same = false
				#break
		#if all_same: score -= 1.0
		#else: score += 0.5
#
	#return score
func score_layout() -> float:
	var score = 0.0
	var obstacles = 0
	var pain = 0
	var open = 0
	var total_inner = (num_cells - 2) * (num_cells - 2)

	for x in range(1, num_cells - 1):
		for y in range(1, num_cells - 1):
			match layout[x + y * num_cells]:
				"#": obstacles += 1
				"f": pain += 1
				" ": open += 1

	var obs_ratio = float(obstacles) / total_inner
	if obs_ratio < 0.10: score -= 2.0
	elif obs_ratio > 0.25: score -= 2.0
	else: score += 1.0

	var pain_ratio = float(pain) / total_inner
	if pain_ratio > 0.15: score -= 1.0
	elif pain_ratio > 0.03: score += 0.5

	var open_ratio = float(open) / total_inner
	if open_ratio < 0.5: score -= 2.0
	else: score += open_ratio

	var center_obstacles = 0
	for x in range(5, 9):
		for y in range(5, 9):
			if layout[x + y * num_cells] == "#":
				center_obstacles += 1
	if center_obstacles > 4:
		score -= 1.0

	if enemy_programs.size() > 1:
		var all_same = true
		for i in range(1, enemy_programs.size()):
			if enemy_programs[i] != enemy_programs[0]:
				all_same = false
				break
		if all_same: score -= 1.0
		else: score += 0.5

	# Shape scores
	score += score_connectivity() * 3.0   # most important — unplayable if fragmented
	score += score_chokepoints()  * 2.0   # interesting combat geometry
	score += score_clustering()   * 1.5   # cover feels intentional
	score += score_symmetry()     * 1.0   # lightest touch — just a nudge

	return score
	
## difficulty
func score_difficulty_space() -> float:
	# Less open space = harder (less room to dodge)
	var open = 0
	var total_inner = (num_cells - 2) * (num_cells - 2)
	for x in range(1, num_cells - 1):
		for y in range(1, num_cells - 1):
			if layout[x + y * num_cells] == " ":
				open += 1
	var open_ratio = float(open) / total_inner
	# invert — less space = more difficulty
	return 1.0 - open_ratio
func score_difficulty_chokepoints() -> float:
	var chokepoints = 0
	var open = 0
	for x in range(1, num_cells - 1):
		for y in range(1, num_cells - 1):
			if layout[x + y * num_cells] != " ": continue
			open += 1
			var h_open = layout[(x-1) + y * num_cells] == " " and layout[(x+1) + y * num_cells] == " "
			var h_blocked = layout[(x-1) + y * num_cells] == "#" or layout[(x+1) + y * num_cells] == "#"
			var v_open = layout[x + (y-1) * num_cells] == " " and layout[x + (y+1) * num_cells] == " "
			var v_blocked = layout[x + (y-1) * num_cells] == "#" or layout[x + (y+1) * num_cells] == "#"
			if (h_open and v_blocked) or (v_open and h_blocked):
				chokepoints += 1
	if open == 0: return 0.0
	return float(chokepoints) / open
func score_difficulty_aggression() -> float:
	if enemy_programs.is_empty(): return 0.0
	
	var aggressive_ops = ["FIRE_ONE", "FIRE_ALL", "RADIAL_4", "RADIAL_8", "RADIAL_16"]
	var passive_ops = ["WAIT_20", "WAIT_40"]
	
	var total_aggressive = 0
	var total_passive = 0
	var total_ops = 0
	
	for prog in enemy_programs:
		for op in prog:
			total_ops += 1
			if op in aggressive_ops: total_aggressive += 1
			elif op in passive_ops: total_passive += 1
	
	if total_ops == 0: return 0.0
	return float(total_aggressive) / total_ops
func score_difficulty_complexity() -> float:
	if enemy_programs.is_empty(): return 0.0
	
	var total_score = 0.0
	for prog in enemy_programs:
		# Length contributes — longer programs are harder to predict
		var length_score = clampf(float(prog.size()) / MAX_PROG_LEN, 0.0, 1.0)
		
		# Variety contributes — more unique opcodes = less predictable
		var unique_ops = {}
		for op in prog:
			unique_ops[op] = true
		var variety_score = clampf(float(unique_ops.size()) / OP_CODES.size(), 0.0, 1.0)
		
		total_score += (length_score + variety_score) / 2.0
	
	return total_score / enemy_programs.size()
func score_difficulty_center_pressure() -> float:
	# Obstacles near center are worse for the player than near walls
	var weighted_obstacles = 0.0
	var max_weight = 0.0
	var cx = num_cells / 2.0
	var cy = num_cells / 2.0
	var max_dist = Vector2(cx, cy).length()
	
	for x in range(1, num_cells - 1):
		for y in range(1, num_cells - 1):
			var dist = Vector2(x - cx, y - cy).length()
			var centrality = 1.0 - (dist / max_dist)  # 1.0 at center, 0.0 at edge
			max_weight += centrality
			if layout[x + y * num_cells] == "#":
				weighted_obstacles += centrality
	
	if max_weight == 0.0: return 0.0
	return weighted_obstacles / max_weight
func score_difficulty_hazards() -> float:
	var pain = 0
	var open = 0
	for x in range(1, num_cells - 1):
		for y in range(1, num_cells - 1):
			match layout[x + y * num_cells]:
				"f": pain += 1
				" ": open += 1
	if open + pain == 0: return 0.0
	return float(pain) / float(pain + open)
func estimate_difficulty() -> float:
	var d = 0.0
	d += score_difficulty_space()          * 0.25
	d += score_difficulty_hazards()        * 0.15
	d += score_difficulty_chokepoints()    * 0.20
	d += score_difficulty_aggression()     * 0.25
	d += score_difficulty_complexity()     * 0.10
	d += score_difficulty_center_pressure() * 0.05
	return clampf(d, 0.0, 1.0)
#class_name RoomGenome extends Resource
#
## params should match GPManager
#var num_cells: int = 14 
#var room_grid: Array[String] = []
#
### enemy genes per room
#@export var enemy_count: int = 3
#@export var enemy_types: Array[String] = []
## 0.0 - spread evenly, 1.0 - tight grouping
#@export_range(0.0, 1.0) var enemy_clustering: float = 0.5
## 0.0 - near entrance (ambush), 1.0 - far end (space to breathe)
#@export_range(0.0, 1.0) var enemy_placement_bias: float = 0.5
## % enemies that patrol/idle vs follow
#@export_range(0.0, 1.0) var patrol_ratio: float = 0.5
## % to scale enemy power and HP
#@export_range(0.5, 2.0) var enemy_stat_scaling: float = 1.0
#@export var has_elite_enemy: bool = false
#@export var has_item: bool = false
#
### obstacle genes per room
## % tiles covered by obstacles
#@export_range(0.0, 0.85) var obstacle_density: float = 0.25
## eligible obstacles per room
#@export var obstacle_types: Array[String] = []
## % clustering of obstacles
#@export_range(0.0, 1.0) var obstacle_clustering: float = 0.3
#@export var has_destructible_obstacles: bool = false
#@export var has_hazard_tile: bool = false
#
### room layout genes
#@export var layout_seed: int = 0
#
## room shape
## 0 = open (few obstacles, clear sight lines)
## 1 = corridor (forced chokepoint)
## 2 = split (two sub-arenas connected by a gap)
## 3 = ring (walkable perimeter, blocked centre)
## 4 = random
#@export_range(0, 4) var room_shape: int = 0
#
## Categorical type used to select base visual theme and
## which encounter rules apply (chest room, trap room, etc.)
## 0 = standard, 1 = elite, 2 = trap, 3 = reward
#@export_range(0, 3) var room_type: int = 0
#
## Used externally by RoomGeneration to sort genomes by
## intended difficulty slot. Higher = placed further from start.
## Evolved separately so hard rooms don't just mean "more enemies".
#@export_range(0.0, 1.0) var difficulty_weight: float = 0.5
#
## Whether this room has a locked door requiring a prior clear.
## A structural gene — affects progression feel, not combat.
##@export var has_lock: bool = false
#
## Whether an interactable (chest, shrine, merchant) spawns here.
## Kept independent of room_type so reward moments can appear
## in otherwise normal rooms for surprise variety.
#@export var has_interactable: bool = false
#
#
#var fitness: float = 0.0	# fitness score
#var generation: int = 0 	# generation this was created
#
#
## -------------------------------------------------------
## HELPERS
## -------------------------------------------------------
#
## Computed difficulty estimate — useful for sorting and logging.
## Not a gene itself; derived so it stays consistent.
#func estimated_difficulty() -> float:
	#var d := 0.0
	#d += (float(enemy_count) / 8.0) * 0.35
	#d += enemy_stat_scaling * 0.2
	#d += obstacle_density * 0.15
	#d += enemy_clustering * 0.1
	#d += (1.0 - enemy_placement_bias) * 0.1  # ambush = harder
	#d += (1.0 if has_elite_enemy else 0.0) * 0.1
	#return clampf(d, 0.0, 1.0)
#
#
## Human-readable summary for debug labels / level editor overlays.
#func describe() -> String:
	#return "[Gen %d | type:%d shape:%d | enemies:%d×%.1f | obs:%.0f%% | fit:%.1f]" % [
		#generation, room_type, room_shape,
		#enemy_count, enemy_stat_scaling,
		#obstacle_density * 100.0,
		#fitness
	#]
#
#"""
#func _assign_enemies() -> void:
	#var enemy_locations: Array[Dictionary] = []
	#for e in range(enemy_count):
		#var timeout := 1000
		#while timeout > 0:
			#var c = randi_range(1, num_cells-2)
			#var r = randi_range(1, num_cells-2)
			#
			#if room_grid[c + r * num_cells] == " ":
				#enemy_locations.append({'c':c, 'r':r, 'type':"e"})
				#break
			#timeout -= 1
		#
	## drop a boss 
	#if has_elite_enemy:
		#var eid = randi_range(0, len(enemy_locations)-1)
		#enemy_locations[eid]['type'] = 'b'
		#
	## assign to grid
	#for i in range(len(enemy_locations)-1):
		#room_grid[enemy_locations[i]['c'] + enemy_locations[i]['r'] * num_cells] = enemy_locations[i]['type']
	#
#func _assign_obstacles() -> void:
	#pass
#"""
##func _init() -> void:
	##var num_remaining_cells = num_cells * 2 # free slots left
	##room_grid.resize(num_remaining_cells)
	##room_grid.fill(" ")
			##
	##if randf() > 0.5:
		##_assign_enemies()
		##_assign_obstacles()
	##else:
		##_assign_obstacles()
		##_assign_enemies()
		##
	##
	##print(room_grid)
#"""
#var obstacles: Array
#var enemies: Array
#var room: Room
#
#enum Functions {
	#PLACE_OBSTACLE, PLACE_ENEMY, PLACE_ITEM,
#}
#enum Terminals {
	#OBSTACLE_BLOCKING, OBSTACLE_PASSTHRU, OBSTACLE_HARM,
	#ENEMY_FOLLOW, ENEMY	
#}
#"""
