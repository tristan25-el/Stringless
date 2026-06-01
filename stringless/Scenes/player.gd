extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var current_lane: int = 1
var hit_line_y: float = 1350.0 
var move_tween: Tween

func _ready() -> void:
	sprite.play("idle")
	# position player instantly on spawn without sliding
	jump_to_lane(1, true) 

func jump_to_lane(target_lane: int, instant: bool = false) -> void:
	# calculate lane positions to match the track width layout
	var window_width = get_viewport_rect().size.x
	var play_area_width = window_width * 0.95
	var left_margin = (window_width - play_area_width) / 2.0
	var lane_width = play_area_width / 4.0
	var target_x = left_margin + (target_lane * lane_width) + (lane_width / 2.0)
	
	if instant:
		current_lane = target_lane
		position = Vector2(target_x, hit_line_y)
		return

	# block duplicate inputs if player is already in the target lane
	if target_lane == current_lane:
		return

	current_lane = target_lane

	# interrupt active movement if a new key is pressed mid-slide
	if move_tween:
		move_tween.kill()
		
	# slide player horizontally to the new lane
	move_tween = create_tween()
	move_tween.tween_property(self, "position", Vector2(target_x, hit_line_y), 0.07)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
