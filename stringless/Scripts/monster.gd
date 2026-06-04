extends Node2D

@onready var sprite = $AnimatedSprite2D

var base_position : Vector2
var action_tween : Tween

func _ready():
	sprite.play("walk")
	scale = Vector2(6.0, 6.0)
	position = Vector2(
		540,
		1800 
	)
	base_position = position
