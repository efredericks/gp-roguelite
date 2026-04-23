
class_name ObstaclePain extends Area2D

@onready var sprite = $Sprite2D
@onready var parent = $".."
@export var destructible: bool = false
@export_category("Light")
@export var light: bool = false
@export var point_light: PointLight2D
@export var speed: float = 2.0
@export var min_energy: float = 0.5
@export var max_energy: float = 1.5

@export var currHP: int = 3
@export var maxHP: int = 3

var time: float = 0.0
var offset: float


func _ready() -> void:
	offset = randf_range(-2.0, 2.0)
	#GlobalSignals.OnDefeatObstacle.connect(_on_obstacle_defeated)

func _process(delta: float) -> void:
	if light and point_light:
		time += delta
		point_light.energy = lerp(min_energy, max_energy, (sin(time * speed * offset) + 1.0) / 2.0)
		_move_wobble()
		
func _move_wobble():
	sprite.rotation = deg_to_rad(sin(time * 5.0 * offset) * 10.0)
	#rotation = rot


func _on_body_entered(body: Node2D) -> void:
	#if body == owner_character: return  # self bullet
	
	# enemy group bullet
	if body.is_in_group("enemy") and is_in_group("enemy"): return

	if body.has_method("take_damage"):
		body.take_damage(1)
		
func take_damage(damage: int):
	#$DamagedSound.play()
	_damage_flash()

	currHP -= damage
	if currHP <= 0:
		die()

func die():
	# await $DamagedSound.finished # wait for final sound 
	#GlobalSignals.OnDefeatObstacle.emit(self)
	#if randf() < drop_chance:
		#var item = hp_pot.instantiate()
		#get_tree().get_root().add_child.call_deferred(item)
		#item.global_position = global_position

	parent.queue_free()

func _damage_flash():
	visible = false
	await get_tree().create_timer(0.07).timeout
	visible = true
