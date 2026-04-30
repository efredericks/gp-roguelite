extends Node
class_name GPSymbolic

# ── Opcodes ────────────────────────────────────────────────────────────────────
enum Op {
	PUSH_CONST,   # followed by a float constant
	PUSH_X,       # push variable x
	ADD, SUB, MUL, DIV,
	SIN, COS, EXP, LOG,
	NEG,
	ABS,
}

const BINARY_OPS  := [Op.ADD, Op.SUB, Op.MUL, Op.DIV]
const UNARY_OPS   := [Op.SIN, Op.COS, Op.EXP, Op.LOG, Op.NEG, Op.ABS]
const TERMINAL_OPS:= [Op.PUSH_CONST, Op.PUSH_X]

# ── Config ─────────────────────────────────────────────────────────────────────
var pop_size       : int   = 500
var max_len        : int   = 40    # max instruction slots
var tournament_k   : int   = 5
var elite_count    : int   = 4
var crossover_rate : float = 0.85
var mutation_rate  : float = 0.15
var const_range    : float = 5.0

# ── State ──────────────────────────────────────────────────────────────────────
var population : Array = []
var fitnesses  : Array = []
var generation : int   = 0
var best_program : Array = []
var best_fitness : float = -INF
var sample_xs  : Array = []
var sample_ys  : Array = []

# ── Rastrigin ──────────────────────────────────────────────────────────────────
static func rastrigin(x: float) -> float:
	return 10.0 + x * x - 10.0 * cos(2.0 * PI * x)

func _build_samples(n: int = 80, lo: float = -5.12, hi: float = 5.12) -> void:
	sample_xs.clear()
	sample_ys.clear()
	for i in range(n):
		var x: float = lo + (hi - lo) * i / float(n - 1)
		sample_xs.append(x)
		sample_ys.append(rastrigin(x))

# ── Program generation ─────────────────────────────────────────────────────────
# A "program" is an Array of Variants: Op enums and float constants interleaved.
# e.g. [Op.PUSH_CONST, 3.14, Op.PUSH_X, Op.MUL]

func _random_program(target_stack_depth: int = 1) -> Array:
	var prog : Array = []
	var stack_depth : int = 0
	var max_iters   : int = max_len * 2

	while stack_depth < target_stack_depth and prog.size() < max_len and max_iters > 0:
		max_iters -= 1
		# Decide whether to emit a terminal or operator
		var can_binary  := stack_depth >= 2
		var can_unary   := stack_depth >= 1
		var want_reduce := stack_depth > 4  # avoid huge stacks

		var choices: Array = TERMINAL_OPS.duplicate()
		if can_unary  and not want_reduce: choices += UNARY_OPS
		if can_binary and not want_reduce: choices += BINARY_OPS
		if want_reduce:
			choices = BINARY_OPS if can_binary else UNARY_OPS

		var op: int = choices[randi() % choices.size()]
		_emit(prog, op)

		if op == Op.PUSH_CONST:
			stack_depth += 1
		elif op == Op.PUSH_X:
			stack_depth += 1
		elif op in UNARY_OPS:
			pass  # pop 1 push 1 → no change
		elif op in BINARY_OPS:
			stack_depth -= 1  # pop 2 push 1

	# Reduce leftover stack with additions
	while stack_depth > 1:
		prog.append(Op.ADD)
		stack_depth -= 1

	return prog

func _emit(prog: Array, op: int) -> void:
	prog.append(op)
	if op == Op.PUSH_CONST:
		prog.append(randf_range(-const_range, const_range))

# ── Execution ──────────────────────────────────────────────────────────────────
func execute(prog: Array, x: float) -> float:
	var stack: Array = []
	var i: int = 0
	while i < prog.size():
		var op: int = prog[i]
		i += 1
		match op:
			Op.PUSH_CONST:
				stack.append(float(prog[i]))
				i += 1
			Op.PUSH_X:
				stack.append(x)
			Op.ADD:
				if stack.size() < 2: return 0.0
				var b = stack.pop_back(); var a = stack.pop_back()
				stack.append(a + b)
			Op.SUB:
				if stack.size() < 2: return 0.0
				var b = stack.pop_back(); var a = stack.pop_back()
				stack.append(a - b)
			Op.MUL:
				if stack.size() < 2: return 0.0
				var b = stack.pop_back(); var a = stack.pop_back()
				stack.append(a * b)
			Op.DIV:
				if stack.size() < 2: return 0.0
				var b = stack.pop_back(); var a = stack.pop_back()
				stack.append(a / b if abs(b) > 1e-6 else 1.0)
			Op.SIN:
				if stack.is_empty(): return 0.0
				stack.append(sin(stack.pop_back()))
			Op.COS:
				if stack.is_empty(): return 0.0
				stack.append(cos(stack.pop_back()))
			Op.EXP:
				if stack.is_empty(): return 0.0
				stack.append(exp(clamp(stack.pop_back(), -20.0, 20.0)))
			Op.LOG:
				if stack.is_empty(): return 0.0
				var v: float = stack.pop_back()
				stack.append(log(abs(v) + 1e-6))
			Op.NEG:
				if stack.is_empty(): return 0.0
				stack.append(-stack.pop_back())
			Op.ABS:
				if stack.is_empty(): return 0.0
				stack.append(abs(stack.pop_back()))
	return stack.back() if not stack.is_empty() else 0.0

# ── Fitness ────────────────────────────────────────────────────────────────────
func evaluate_fitness(prog: Array) -> float:
	var mse: float = 0.0
	for i in range(sample_xs.size()):
		var pred: float = execute(prog, sample_xs[i])
		if is_nan(pred) or is_inf(pred):
			return -1e9
		var diff: float = pred - sample_ys[i]
		mse += diff * diff
	mse /= float(sample_xs.size())
	return -mse  # higher = better

# ── Selection ──────────────────────────────────────────────────────────────────
func _tournament_select() -> Array:
	var best_idx: int = randi() % pop_size
	for _k in range(tournament_k - 1):
		var idx: int = randi() % pop_size
		if fitnesses[idx] > fitnesses[best_idx]:
			best_idx = idx
	return population[best_idx].duplicate()

# ── Crossover ──────────────────────────────────────────────────────────────────
# One-point crossover on the instruction array
func _crossover(parent_a: Array, parent_b: Array) -> Array:
	if parent_a.size() < 2 or parent_b.size() < 2:
		return parent_a.duplicate()
	# Find valid cut points (avoid splitting PUSH_CONST + value pairs)
	var cuts_a := _valid_cut_points(parent_a)
	var cuts_b := _valid_cut_points(parent_b)
	if cuts_a.is_empty() or cuts_b.is_empty():
		return parent_a.duplicate()
	var ca: int = cuts_a[randi() % cuts_a.size()]
	var cb: int = cuts_b[randi() % cuts_b.size()]
	var child: Array = parent_a.slice(0, ca) + parent_b.slice(cb)
	return _trim_to_length(child)

func _valid_cut_points(prog: Array) -> Array:
	var cuts: Array = [0]
	var i: int = 0
	while i < prog.size():
		if prog[i] == Op.PUSH_CONST:
			i += 2
		else:
			i += 1
		cuts.append(i)
	return cuts

func _trim_to_length(prog: Array) -> Array:
	if prog.size() <= max_len:
		return prog
	# Trim to max_len at a valid boundary
	var cuts := _valid_cut_points(prog)
	var keep: int = 0
	for c in cuts:
		if c <= max_len:
			keep = c
	return prog.slice(0, keep)

# ── Mutation ───────────────────────────────────────────────────────────────────
func _mutate(prog: Array) -> Array:
	var p: Array = prog.duplicate()
	var r: float = randf()

	if r < 0.33:
		# Point mutation: replace a random op or constant
		if p.is_empty(): return p
		var i: int = randi() % p.size()
		if p[i] is float:
			p[i] = randf_range(-const_range, const_range)
		else:
			var op: int = p[i]
			if op in BINARY_OPS:
				p[i] = BINARY_OPS[randi() % BINARY_OPS.size()]
			elif op in UNARY_OPS:
				p[i] = UNARY_OPS[randi() % UNARY_OPS.size()]
			# terminals stay terminals for safety
	elif r < 0.66:
		# Insert a random sub-program at a valid position
		var cuts := _valid_cut_points(p)
		var pos: int = cuts[randi() % cuts.size()]
		var snippet: Array = _random_program(1)
		p = p.slice(0, pos) + snippet + p.slice(pos)
		p = _trim_to_length(p)
	else:
		# Delete a random valid segment (1–4 instructions)
		var cuts := _valid_cut_points(p)
		if cuts.size() < 3: return p
		var ci: int = randi() % (cuts.size() - 1)
		var end_max = min(ci + 4, cuts.size() - 1)
		var ce: int = ci + 1 + randi() % (end_max - ci)
		var new_p: Array = p.slice(0, cuts[ci]) + p.slice(cuts[ce])
		if not new_p.is_empty():
			p = new_p

	return p

# ── Evolution ──────────────────────────────────────────────────────────────────
func initialize(_seed: int = 0) -> void:
	if _seed != 0:
		seed(_seed)
	_build_samples()
	population.clear()
	fitnesses.clear()
	generation = 0
	best_fitness = -INF
	for _i in range(pop_size):
		var prog := _random_program(1)
		population.append(prog)
		fitnesses.append(evaluate_fitness(prog))
	_update_best()

func step() -> void:
	var new_pop: Array = []

	# Elitism: carry over top individuals
	var sorted_idx := range(pop_size)
	sorted_idx.sort_custom(func(a, b): return fitnesses[a] > fitnesses[b])
	for e in range(elite_count):
		new_pop.append(population[sorted_idx[e]].duplicate())

	# Fill rest with crossover + mutation
	while new_pop.size() < pop_size:
		var child: Array
		if randf() < crossover_rate:
			var pa := _tournament_select()
			var pb := _tournament_select()
			child = _crossover(pa, pb)
		else:
			child = _tournament_select()
		if randf() < mutation_rate:
			child = _mutate(child)
		new_pop.append(child)

	population = new_pop
	fitnesses.clear()
	for prog in population:
		fitnesses.append(evaluate_fitness(prog))
	generation += 1
	_update_best()

func _update_best() -> void:
	for i in range(pop_size):
		if fitnesses[i] > best_fitness:
			best_fitness = fitnesses[i]
			best_program = population[i].duplicate()

# ── Pretty print ───────────────────────────────────────────────────────────────
func program_to_string(prog: Array) -> String:
	var stack: Array = []
	var i: int = 0
	while i < prog.size():
		var op: int = prog[i]; i += 1
		match op:
			Op.PUSH_CONST:
				stack.append("%.3f" % prog[i]); i += 1
			Op.PUSH_X:
				stack.append("x")
			Op.ADD:
				if stack.size() < 2: break
				var b = stack.pop_back(); var a = stack.pop_back()
				stack.append("(%s + %s)" % [a, b])
			Op.SUB:
				if stack.size() < 2: break
				var b = stack.pop_back(); var a = stack.pop_back()
				stack.append("(%s - %s)" % [a, b])
			Op.MUL:
				if stack.size() < 2: break
				var b = stack.pop_back(); var a = stack.pop_back()
				stack.append("(%s * %s)" % [a, b])
			Op.DIV:
				if stack.size() < 2: break
				var b = stack.pop_back(); var a = stack.pop_back()
				stack.append("(%s / %s)" % [a, b])
			Op.SIN:
				if stack.is_empty(): break
				stack.append("sin(%s)" % stack.pop_back())
			Op.COS:
				if stack.is_empty(): break
				stack.append("cos(%s)" % stack.pop_back())
			Op.EXP:
				if stack.is_empty(): break
				stack.append("exp(%s)" % stack.pop_back())
			Op.LOG:
				if stack.is_empty(): break
				stack.append("log(%s)" % stack.pop_back())
			Op.NEG:
				if stack.is_empty(): break
				stack.append("(-%s)" % stack.pop_back())
			Op.ABS:
				if stack.is_empty(): break
				stack.append("abs(%s)" % stack.pop_back())
	return stack.back() if not stack.is_empty() else "?"
