extends Control

@onready var anim = $AnimationPlayer

func _ready():
	anim.play("bg_animation")  
	$menu_bgm.play()
