## Manager of all things GP - autoload singleton that tracks data across runs
#class_name GPManager extends Node
#
## evolutionary consts
#const POPULATION_SIZE: int = 100
#const ELITE_COUNT: int = 5
#const MUTATION_RATE: float = 0.2
#const CROSSOVER_RATE: float = 0.4
#const TOURNAMENT_SIZE: int = 5
#const SAVE_PATH: String = "user://gp_roguelite.data.tres"
#
## GP variables
#var population: Array[RoomGenome] = []
#var curr_generation: int = 0
#
## genome info
#const MIN_ENEMIES_PER_ROOM: int = 0
#const MAX_ENEMIES_PER_ROOM: int = 6
#const MIN_OBSTACLE_DENSITY: float = 0.0
#const MAX_OBSTACLE_DENSITY: float = 1.0
#const ROOM_TYPE_COUNT: int = 5 				# empty, normal, elite, trap, boss
#const ENEMY_TYPES: Array[String] = ["knight", "wizard", "boss"]
#
#func _ready() -> void:
	#_load_init_population() # load population if it is written to disk, else create a new one
#
## GP population management
#func _init_random_population() -> void:
	#population.clear()
	#for i in range(POPULATION_SIZE):
		#population.append(_random_genome())
	#print(population)
#
## instantiate a random RoomGenome
#func _random_genome() -> RoomGenome:
	#var g := RoomGenome.new()
	#g.enemy_count      = randi_range(MIN_ENEMIES_PER_ROOM, MAX_ENEMIES_PER_ROOM)
	#g.obstacle_density = randf()
	#g.room_type        = randi() % ROOM_TYPE_COUNT
	#g.layout_seed      = randi()
	#g.difficulty_weight = randf()
	#g.enemy_types = []
	#var type_count := randi_range(1, ENEMY_TYPES.size())
	#for i in range(type_count):
		#g.enemy_types.append(ENEMY_TYPES[randi() % ENEMY_TYPES.size()])
	#g.fitness = 0.0
	#return g
	#
#func _load_init_population() -> void:
	#if ResourceLoader.exists(SAVE_PATH):
		#var saved = ResourceLoader.load(SAVE_PATH)
		#if saved and saved.has_method("get_population"):
			#population = saved.get_population()
			#print("GPManager: loaded generation [%d]" % curr_generation)
			#return
			#
	#_init_random_population()
	#
## GP operators
