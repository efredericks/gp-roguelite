extends Area2D

@export var boss: CharacterBody2D
@export var next_level: PackedScene
@export var rotation_speed: float = 0.5

func _ready() -> void:
	GlobalSignals.OnDefeatEnemy.connect(_on_defeat_enemy)
	visible = false
	$CollisionShape2D.disabled = true

# rotate every frame
func _process(delta: float) -> void:
	rotate(rotation_speed * delta)

func _on_defeat_enemy(enemy: Enemy):
	if enemy != boss:
		return

	visible = true
	# $CollisionShape2D.disabled = false
	$CollisionShape2D.set_deferred("disabled", false)


func _on_body_entered(body: Node2D) -> void:
	print("i'm ready")
	if not body.is_in_group("Player"): return

	get_tree().change_scene_to_packed.call_deferred(next_level)
