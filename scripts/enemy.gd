class_name Enemy extends CharacterBody2D

enum ShootPattern {
	TARGET, CROSS, X
}
@export var currHP: int = 4
@export var maxHP: int = 4
#@export var move_speed: float = 20
@export var attack_damage: int = 1
@export var attack_range: float = 10
@export var attack_rate: float = 0.5

@export_category("Movement")
@export var max_speed: float
@export var acceleration: float
@export var drag: float
@export var stop_range: float

@export_category("Shooting")
@export var is_shooter: bool = false
@export var shoot_pattern: ShootPattern
@export var shoot_rate: float = 0.6
@export var projectile_scene: PackedScene
var last_shoot_time: float

@onready var muzzle: Node2D = $muzzle
@onready var sprite: Sprite2D = $Sprite
@onready var avoidance_ray: RayCast2D = $AvoidanceRay

@export_category("Various")
@export var drop_chance: float = 0.2
@export var hp_pot: PackedScene
@export var is_boss: bool = false
@export var heart_pot: PackedScene

var last_attack_time: float
var room: Room
var is_active: bool = false

var player: CharacterBody2D
var player_dir: Vector2
var player_dist: float

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	GlobalSignals.OnPlayerEnterRoom.connect(_on_player_enter_room)

func initialize(in_room: Room):
	is_active = false
	room = in_room

# activate when player enters
func _on_player_enter_room(player_room: Room):
	is_active = player_room == room

func _process(_delta: float) -> void:
	if Time.get_unix_time_from_system() - last_shoot_time > shoot_rate and is_shooter and is_active:
		_shoot()
			
	_move_wobble()

func _physics_process(delta: float) -> void:
	if not is_active or player == null: return

	player_dir = global_position.direction_to(player.global_position)
	player_dist = global_position.distance_to(player.global_position)

	sprite.flip_h = player_dir.x < 0

	if player_dist < attack_range:
		_try_attack()
		return
		
	var local_avoidance = _local_avoidance()
	if local_avoidance.length() > 0:
		player_dir = local_avoidance

	#velocity = player_dir * move_speed
	if velocity.length() < max_speed and player_dist > stop_range:
		velocity += player_dir * acceleration
	else:
		velocity *= drag
		
	move_and_slide()
	# if is_active:


func _try_attack():
	if Time.get_unix_time_from_system() - last_attack_time < attack_rate:
		return

	last_attack_time = Time.get_unix_time_from_system()
	player.take_damage(attack_damage)

func take_damage(damage: int):
	$DamagedSound.play()
	_damage_flash()

	currHP -= damage
	if currHP <= 0:
		die()

func die():
	# await $DamagedSound.finished # wait for final sound 
	GlobalSignals.OnDefeatEnemy.emit(self)
	
	if is_boss:
		var item = heart_pot.instantiate()
		get_tree().get_root().add_child.call_deferred(item)
		item.global_position = global_position
	else:
		if randf() < drop_chance:
			var item = hp_pot.instantiate()
			get_tree().get_root().add_child.call_deferred(item)
			item.global_position = global_position

	queue_free()

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
	
# avoid obstacles when following
func _local_avoidance() -> Vector2:
	avoidance_ray.target_position = to_local(player.global_position).normalized()
	avoidance_ray.target_position *= 20 # only avoid within 80 pixels
	
	if not avoidance_ray.is_colliding():
		return Vector2.ZERO
	
	var obstacle = avoidance_ray.get_collider()
	if obstacle == player:
		return Vector2.ZERO
		
	# hitting an obstacle, so move around
	var obstacle_point = avoidance_ray.get_collision_point()
	var obstacle_dir = global_position.direction_to(obstacle_point)
	return Vector2(-obstacle_dir.y, obstacle_dir.x) # return adjacent 


func _shoot(dir = null) -> void:
	last_shoot_time = Time.get_unix_time_from_system()

	if shoot_pattern == ShootPattern.X:
		var dirs: Array[Vector2] = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]
		for d in dirs:
			# instantiate projectile
			var proj = projectile_scene.instantiate()
			get_tree().get_root().add_child.call_deferred(proj)
			proj.owner_character = self
			proj.global_position = muzzle.global_position
			proj.rotation_degrees = rad_to_deg(d.angle()) + 45
			proj.add_to_group("enemy")
	elif shoot_pattern == ShootPattern.CROSS:
		var dirs: Array[Vector2] = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]
		for d in dirs:
			# instantiate projectile
			var proj = projectile_scene.instantiate()
			get_tree().get_root().add_child.call_deferred(proj)
			proj.owner_character = self
			proj.global_position = muzzle.global_position
			proj.rotation_degrees = rad_to_deg(d.angle()) + 90
			proj.add_to_group("enemy")
		

	#proj.rotation_degrees = rad_to_deg(dir.angle()) + 90 

	#$ShootSound.play()
