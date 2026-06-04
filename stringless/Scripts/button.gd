extends TextureButton
@export var id: String = ""

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)

func _on_mouse_entered():
	# Create Tween
	var tween = create_tween()
	# Set Easing
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	# Set Property
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.67)

func _on_mouse_exited():
	# Create Tween
	var tween = create_tween()
	# Set Easing
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	# Set Property
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.67)

func _on_pressed():
	if id == "start":
		GameManager.start_game()
	elif id == "exit":
		get_tree().quit()
	else:
		printerr("ID NOT FOUND!")
