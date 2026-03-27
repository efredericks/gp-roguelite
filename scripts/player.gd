extends CharacterBody2D

@onready var sprite: Sprite2D = $playerSprite
@onready var weapon_origin: Node2D = $weapon
@onready var muzzle: Node2D = $weapon/muzzle

@export var currHP: int = 8
@export var maxHP: int = 8


@export var move_speed: float = 100
@export var shoot_rate: float = 0.4
var last_shoot_time: float

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


func _physics_process(_delta: float) -> void:
	var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	velocity = move_speed * move_input# * delta
	move_and_slide()

func take_damage(amount: int) -> void:
	_damage_flash()
	$DamagedSound.play()

	currHP -= amount
	GlobalSignals.OnPlayerUpdateHealth.emit(currHP, maxHP)
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
