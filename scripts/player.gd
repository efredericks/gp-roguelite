# light: https://medium.com/@merxon22/godot-mastering-2d-lighting-a949320e1f68
extends CharacterBody2D

@onready var sprite: Sprite2D = $playerSprite
@onready var weapon_origin: Node2D = $weapon
@onready var muzzle: Node2D = $weapon/muzzle

@export_category("Stats")
@export var currHP: int = GameState.player_hp
@export var maxHP: int = GameState.player_max_hp

@export_category("Movement")
@export var max_speed: float = 100.0
@export var acceleration: float = 0.2
@export var braking: float = 0.15

#@export var move_speed: float = 100
@export var shoot_rate: float = 0.4
var last_shoot_time: float
var move_input: Vector2

var projectile_scene: PackedScene = preload("res://scenes/projectiles/projectile.tscn")

func _ready() -> void:
	GlobalSignals.OnPlayerUpdateHealth.emit.call_deferred(currHP, maxHP)

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
	_damage_flash()
	$DamagedSound.play()

	currHP -= amount
	GlobalSignals.OnPlayerUpdateHealth.emit(currHP, maxHP)
	GameState.player_hp = currHP # update global state
	if currHP <= 0:
		die() 

func die() -> void:
	# await $DamagedSound.finished # wait for final sound 
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

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
