extends ColorRect

func _ready() -> void:
	modulate.a = 0.0
	GlobalSignals.OnResetHold.connect(update_alpha)
	
func update_alpha(alpha: float) -> void:
	modulate.a = alpha
	material.set_shader_parameter("alpha", alpha)
