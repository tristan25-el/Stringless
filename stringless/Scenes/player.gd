extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var slide_speed: float = 0.08 #dash speed, change if too slow/fast
var dash_visual_duration: float = 0.22 #visual duration, change if animation too slow/fast
var current_lane: int = 1
var hit_line_y: float = 1350.0 
var move_tween: Tween

var base_anim: String = "idle"

func _ready() -> void:
	sprite.play(base_anim)
	# position player instantly on spawn without sliding
	jump_to_lane(1, true) 

func set_base_animation(anim_name: String) -> void:
	base_anim = anim_name
	# Langsung ganti animasi asalkan player tidak sedang nge-dash
	if sprite.animation != "dash_right" and sprite.animation != "dash_left":
		sprite.play(base_anim)

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
		
	# MODIFIED: Only play dash animations if we are in the normal "idle" state!
	if target_lane > current_lane:
		if base_anim == "idle":
			sprite.play("dash_right")
	
	elif target_lane < current_lane:
		if base_anim == "idle":
			sprite.play("dash_left")
		
	current_lane = target_lane
	
	if move_tween:
		move_tween.kill()
		
	move_tween = create_tween()
	
	move_tween.tween_property(self, "position", Vector2(target_x, hit_line_y), slide_speed)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	var visual_hold_time = max(0.0, dash_visual_duration - slide_speed)
	move_tween.tween_interval(visual_hold_time)
		
	# Return to base_anim (idle, idle_2, or idle_3)
	move_tween.tween_callback(func(): sprite.play(base_anim))
