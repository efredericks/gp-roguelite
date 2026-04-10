class_name GP_main extends Node

"""
var population: Array[Individual]
@export var crossover_rate: float = 0.4
@export var mutation_rate: float = 0.2
@export var num_generations: int = 100
@export var population_size: int = 100

@onready var status_text: Label = $Control/Status
func _ready() -> void:
	for g in range(population_size):
		var indv = Individual.new()
		indv.create_random()
		population.append(indv)
		
	for g in range(num_generations):
		status_text.text = "Generation " + str(g)
	#print(population)
"""
#extends Node

@onready var gp := GPSymbolic.new()

var running   : bool  = false
var max_gens  : int   = 500
var step_delay: float = 0.02   # seconds between generations (0 = as fast as possible)
var _timer    : float = 0.0

func _ready() -> void:
	add_child(gp)
	gp.pop_size       = 300
	gp.max_len        = 50
	gp.tournament_k   = 5
	gp.elite_count    = 5
	gp.crossover_rate = 0.85
	gp.mutation_rate  = 0.20
	gp.const_range    = 10.0
	gp.initialize(42)
	running = true
	print("GP initialized. Population: %d | Samples: %d" % [gp.pop_size, gp.sample_xs.size()])

func _process(delta: float) -> void:
	if not running:
		return
	_timer += delta
	if _timer < step_delay:
		return
	_timer = 0.0

	gp.step()

	if gp.generation % 10 == 0:
		var mse := -gp.best_fitness
		var expr := gp.program_to_string(gp.best_program)
		print("Gen %4d | MSE: %10.4f | %s" % [gp.generation, mse, expr])

	if gp.generation >= max_gens:
		running = false
		_finish()

func _finish() -> void:
	print("\n── Evolution complete ──")
	print("Generations : %d" % gp.generation)
	print("Best MSE    : %.6f" % -gp.best_fitness)
	print("Best expr   : %s" % gp.program_to_string(gp.best_program))
	print("\nSample comparison (x, target, predicted):")
	for i in range(0, gp.sample_xs.size(), 8):
		var x   = gp.sample_xs[i]
		var tgt = gp.sample_ys[i]
		var prd = gp.execute(gp.best_program, gp.sample_xs[i])
		print("  x=%6.3f  target=%8.4f  pred=%8.4f" % [x, tgt, prd])
