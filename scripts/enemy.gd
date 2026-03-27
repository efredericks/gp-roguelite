class_name Enemy extends CharacterBody2D

@export var currHP: int = 4
@export var maxHP: int = 4
@export var move_speed: float = 20
@export var attack_damage: int = 1
@export var attack_range: float = 10
@export var attack_rate: float = 0.5

@onready var sprite: Sprite2D = $Sprite

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

func _physics_process(delta: float) -> void:
	if not is_active or player == null: return

	player_dir = global_position.direction_to(player.global_position)
	player_dist = global_position.distance_to(player.global_position)

	sprite.flip_h = player_dir.x < 0

	if player_dist < attack_range:
		_try_attack()
		return

	velocity = player_dir * move_speed
	move_and_slide()
	# if is_active:


func _try_attack():
	if Time.get_unix_time_from_system() - last_attack_time < attack_rate:
		return

	last_attack_time = Time.get_unix_time_from_system()
	player.take_damage(attack_damage)

func take_damage(damage: int):
	currHP -= damage
	if currHP <= 0:
		die()

func die():
	GlobalSignals.OnDefeatEnemy.emit(self)
	queue_free()
