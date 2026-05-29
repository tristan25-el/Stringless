extends Node2D

var lane: int = 0
var hit_time: float = 0.0
var already_hit := false
var miss_window := 0.20

# PERSPECTIVE CONFIGURATION
var initial_lead_time: float = 2.0
var spawn_y: float = 485.0       # The top horizon line where notes appear tiny
var hit_line_y: float = 1350.0    # The bottom judgment line where notes are hit

func _ready() -> void:
	add_to_group("notes")
	visible = false
	
func initialize(data: Dictionary, lead_time: float):
	lane = data.get("lane", 0)
	hit_time = data.get("time", 0.0)
	initial_lead_time = lead_time		

	if data.get("is_impostor", false):
		modulate = Color.RED
		
	# Instantly calculate its initial position on the horizon line before the first frame draws
	update_perspective()

func _process(delta: float) -> void:
	update_perspective()
	
	var main_node = get_parent()
	if main_node and "current_game_time" in main_node:
		var spawn_time = hit_time - initial_lead_time
		var progress = (main_node.current_game_time - spawn_time) / initial_lead_time
		
		if progress >= 1.15 and !already_hit:
			already_hit = true
			main_node.register_miss()
			queue_free()

# UNIFIED PERSPECTIVE POSITIONING
func update_perspective() -> void:
	var main_node = get_parent()
	if not main_node or not("current_game_time" in main_node):
		return	
		
	var current_time = main_node.current_game_time
	
	# Calculate precise timeline progress
	var spawn_time = hit_time - initial_lead_time
	var progress = (current_time - spawn_time) / initial_lead_time
	progress = clamp(progress, 0.0, 2.0)
	

	var visual_progress = pow(progress, 2.5)
	
	# Calculate Positions based on Window Width
	var window_width = get_viewport_rect().size.x
	
	# THE BOTTOM (Hitline Lane Layout)
	var play_area_width = window_width * 0.95
	var left_margin = (window_width - play_area_width) / 2.0
	var lane_width = play_area_width / 4.0
	var final_x = left_margin + (lane * lane_width) + (lane_width / 2.0)
	
	# THE TOP (Horizon Spawn Lane Layout)
	# Tweak 0.20 to change how dramatically the lanes slant outward
	var top_play_width = window_width * 0.20 
	var top_left_margin = (window_width - top_play_width) / 2.0
	var top_lane_width = top_play_width / 4.0
	var spawn_x = top_left_margin + (lane * top_lane_width) + (top_lane_width / 2.0)
	
	# Update positions down their unique individual track lines
	position.y = lerp(spawn_y, hit_line_y, visual_progress)
	position.x = lerp(spawn_x, final_x, visual_progress)
	
	# Perspective Scaling
	var min_scale = 0.05
	var max_scale = 0.60
	var current_scale = lerp(min_scale, max_scale, visual_progress)
	scale = Vector2(current_scale, current_scale)
	
	visible = true

func hit():
	if already_hit:
		return
	already_hit = true
	queue_free()
	
func can_be_hit(current_time: float) -> bool:
	return abs(current_time - hit_time) <= miss_window
