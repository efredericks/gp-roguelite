# light: https://medium.com/@merxon22/godot-mastering-2d-lighting-a949320e1f68
extends CharacterBody2D

@onready var sprite: Sprite2D = $playerSprite
@onready var weapon_origin: Node2D = $weapon
@onready var muzzle: Node2D = $weapon/muzzle
@onready var hit_timer: Timer = $HitTimer
@onready var hit_box: Area2D = $Area2D

@export_category("Stats")
@export var currHP: int = GameState.player_hp
@export var maxHP: int = GameState.player_max_hp
@export var bump_damage: int = 1

@export_category("Movement")
@export var max_speed: float = 100.0
@export var acceleration: float = 0.2
@export var braking: float = 0.15

#@export var move_speed: float = 100
@export var shoot_rate: float = 0.4
var last_shoot_time: float
var move_input: Vector2

var projectile_scene: PackedScene = preload("res://scenes/projectiles/projectile.tscn")
var in_room: Room # room player is currently in

func _ready() -> void:
	GlobalSignals.OnPlayerUpdateHealth.emit.call_deferred(currHP, maxHP)
	GlobalSignals.OnDebug.connect(_on_debug)
	
func _process(delta: float) -> void:
	# aim towards mouse
	var mouse_pos: Vector2 = get_global_mouse_position()
	var mouse_dir: Vector2 = (mouse_pos - global_position).normalized()
	weapon_origin.rotation_degrees = rad_to_deg(mouse_dir.angle()) + 90 

	sprite.flip_h = mouse_dir.x < 0   

	# key shoot
	if Input.is_action_pressed("shoot_left"):
		if Time.get_unix_time_from_system() - last_shoot_time > shoot_rate:
			_shoot(Vector2.LEFT)
	if Input.is_action_pressed("shoot_right"):
		if Time.get_unix_time_from_system() - last_shoot_time > shoot_rate:
			_shoot(Vector2.RIGHT)
	if Input.is_action_pressed("shoot_up"):
		if Time.get_unix_time_from_system() - last_shoot_time > shoot_rate:
			_shoot(Vector2.UP)
	if Input.is_action_pressed("shoot_down"):
		if Time.get_unix_time_from_system() - last_shoot_time > shoot_rate:
			_shoot(Vector2.DOWN)
		
	# mouse shoot
	if Input.is_action_pressed("attack"):
		if Time.get_unix_time_from_system() - last_shoot_time > shoot_rate:
			_shoot()

	_move_wobble()

func _physics_process(delta):
	move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if move_input.length() > 0:
		velocity = velocity.lerp(move_input * max_speed, acceleration)
	else:
		velocity = velocity.lerp(Vector2.ZERO, braking)
	move_and_slide()
	
	sprite.flip_h = move_input.x > 0
#func _physics_process(_delta: float) -> void:
	#var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
#
	#velocity = move_speed * move_input# * delta
	#move_and_slide()

func take_damage(amount: int) -> void:
	if not GameState.debug_invincible:
		_damage_flash()
		$DamagedSound.play()

		currHP -= amount
		GlobalSignals.OnPlayerUpdateHealth.emit(currHP, maxHP)
		GameState.player_hp = currHP # update global state
		GameState.hits_taken += 1
		if currHP <= 0:
			die() 

func die() -> void:
	# print out run stats
	GameState.killed_at_difficulty = in_room.difficulty
	GameState.total_run_time = Time.get_unix_time_from_system() - GameState.game_start_time
	GameState.write_run_stats()
	
	# await $DamagedSound.finished # wait for final sound 
	get_tree().change_scene_to_file.call_deferred("res://scenes/menu.tscn")

# returns false if no need for healing
func heal(amount: int) -> bool:
	if currHP >= maxHP: # no need to pickup potion
		return false

	currHP += amount
	if currHP > maxHP: currHP = maxHP
	GameState.player_hp = currHP # update global state
	GlobalSignals.OnPlayerUpdateHealth.emit(currHP, maxHP)
	return true

func _shoot(dir = null) -> void:
	last_shoot_time = Time.get_unix_time_from_system()

	# instantiate projectile
	var proj = projectile_scene.instantiate()
	get_tree().get_root().add_child.call_deferred(proj)
	proj.owner_character = self
	proj.global_position = muzzle.global_position

	if dir == null: # from mouse
		proj.rotation = weapon_origin.rotation
	else:
		proj.rotation_degrees = rad_to_deg(dir.angle()) + 90 

	$ShootSound.play()

func _damage_flash():
	visible = false
	await get_tree().create_timer(0.07).timeout
	visible = true

func _move_wobble():
	if get_real_velocity().length() == 0:
		sprite.rotation_degrees = 0
		return
	
	var t = Time.get_unix_time_from_system()
	var rot = 2 * sin(20 * t)
	sprite.rotation_degrees = rot
	
func _on_debug() -> void:
	if GameState.debug_invincible:
		modulate = Color.RED
	else:
		modulate = Color.WHITE

# enemy walking into player or player sitting on fire (both body and area)
func _on_area_2d_body_entered(body: Node2D) -> void:
	# enemy group bullet
	if body.is_in_group("enemy"):
		take_damage(bump_damage)
		hit_timer.start()
		
# done hitting! (both body and area)
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if hit_box.get_overlapping_bodies().filter(func(b): return b.is_in_group("enemy")).is_empty():
			hit_timer.stop()

# continuous hit every second
func _on_hit_timer_timeout():
	take_damage(bump_damage) # This keeps running every second as long as the timer is active

func setRoom(room: Room) -> void:
	in_room = room
	#addVisited(room)

# NOTE - THIS NEEDS TO ADD A DICTIONARY AS ROOMS ARE FREED!
# player visits a room for the first time
func addVisited(room: Room) -> void:
	var new_room: bool = true
	for _room in GameState.rooms_visited[GameState.current_level-1]:
		if room == _room:
			new_room = false
			break
	if new_room:
		GameState.rooms_visited[GameState.current_level-1].append(room)
