extends Sprite2D

func _ready():

	var viewport_size = get_viewport_rect().size
	var texture_size = texture.get_size()

	scale.x = viewport_size.x / texture_size.x
	scale.y = 1.0
