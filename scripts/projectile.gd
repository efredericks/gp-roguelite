extends Area2D

@export var base_speed: float = 100
@export var owner_character: CharacterBody2D



func _process(delta) -> void:
	translate(-transform.y * base_speed * delta)


func _on_body_entered(body: Node2D) -> void:
	if body == owner_character: return  # self bullet
	
	# enemy group bullet
	if body.is_in_group("enemy") and is_in_group("enemy"): return

	if body.has_method("take_damage"):
		body.take_damage(1)

	queue_free()


func _on_timer_timeout() -> void:
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	# enemy group bullet
	if area.is_in_group("enemy") and is_in_group("enemy"): return

	if area.has_method("take_damage"):
		area.take_damage(1)

	queue_free()
