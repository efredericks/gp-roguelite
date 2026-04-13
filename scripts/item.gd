extends Area2D

enum ItemType {
	HEALTH, SHOOT_RATE, MOVE_SPEED
}

@export var item_type: ItemType
@export var item_value: float
@onready var light: PointLight2D = $light
@export var min_light: float = 0.1
@export var max_light: float = 1.5
@export var pulse_rate: float = 2.0
var time: float = 0.0

func _ready() -> void:
	pass

func _process(delta) -> void:
	time += delta * pulse_rate
	# Use sin to create a range between 0 and 1, then map to energy range
	var pulse = (sin(time) + 1.0) / 2.0 
	light.energy = lerp(min_light, max_light, pulse)
	
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"): return

	var clear_item = true

	if item_type == ItemType.HEALTH:
		clear_item = body.heal(int(item_value))
	elif item_type == ItemType.SHOOT_RATE:
		body.shoot_rate -= item_value
	elif item_type == ItemType.MOVE_SPEED:
		body.move_speed += item_value

	body.get_node("ItemSound").play()

	if clear_item:
		queue_free()
