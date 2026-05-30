extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var current_lane: int = 1
var hit_line_y: float = 1350.0 

var move_tween: Tween
var anim_tween: Tween

func _ready() -> void:
	sprite.play("idle")
	# snap to starting lane on spawn without playing animations
	jump_to_lane(1, true) 

func jump_to_lane(target_lane: int, instant: bool = false) -> void:
	# calculate screen positions matching the bottom of the note highway
	var window_width = get_viewport_rect().size.x
	var play_area_width = window_width * 0.95
	var left_margin = (window_width - play_area_width) / 2.0
	var lane_width = play_area_width / 4.0
	var target_x = left_margin + (target_lane * lane_width) + (lane_width / 2.0)
	
	if instant:
		current_lane = target_lane
		position = Vector2(target_x, hit_line_y)
		return

	# ignore inputs if we're already in the requested lane
	if target_lane == current_lane:
		return

	# update sprite direction based on movement
	if target_lane > current_lane:
		sprite.play("dash_right")
	else:
		sprite.play("dash_left")

	current_lane = target_lane

	# smooth movement tween
	if move_tween:
		move_tween.kill()
		
	move_tween = create_tween()
	move_tween.tween_property(self, "position", Vector2(target_x, hit_line_y), 0.07)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	# hold the dash animation briefly so it's readable before returning to idle
	if anim_tween:
		anim_tween.kill()
		
	anim_tween = create_tween()
	anim_tween.tween_interval(0.2)
	anim_tween.tween_callback(func(): sprite.play("idle"))
