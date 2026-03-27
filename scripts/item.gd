extends Area2D

enum ItemType {
	HEALTH, SHOOT_RATE, MOVE_SPEED
}

@export var item_type: ItemType
@export var item_value: float

func _ready() -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"): return

	var clear_item = true

	if item_type == ItemType.HEALTH:
		clear_item = body.heal(int(item_value))
	elif item_type == ItemType.SHOOT_RATE:
		body.shoot_rate -= item_value
	elif item_type == ItemType.MOVE_SPEED:
		body.move_speed += item_value

	if clear_item:
		queue_free()
