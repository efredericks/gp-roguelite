extends Sprite2D

var allowed_sprites: Array[Vector2i] = [
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1),
	Vector2i(4, 1), Vector2i(5, 1), Vector2i(3, 2), Vector2i(4, 2)
]

var cell_w: int = 16

func _ready() -> void:
	var spr = allowed_sprites[randi_range(0, len(allowed_sprites)-1)]
	region_rect = Rect2(spr.x * cell_w, spr.y * cell_w, cell_w, cell_w)
