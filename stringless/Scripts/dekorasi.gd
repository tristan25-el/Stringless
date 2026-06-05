extends Sprite2D

var hit_time: float = 0.0
var initial_lead_time: float = 2.0
var lane: float = 0.0

var spawn_y: float = 485.0       
var hit_line_y: float = 1350.0   

func initialize(t_hit_time: float, t_lead_time: float, t_lane: float):
	hit_time = t_hit_time
	initial_lead_time = t_lead_time
	lane = t_lane
	update_perspective()

func _process(_delta: float) -> void:
	update_perspective()
	var main_node = get_parent()
	if main_node and "current_game_time" in main_node:
		var spawn_time = hit_time - initial_lead_time
		var progress = (main_node.current_game_time - spawn_time) / initial_lead_time
		if progress >= 1.5: 
			queue_free()

func update_perspective() -> void:
	var main_node = get_parent()
	if not main_node or not("current_game_time" in main_node):
		return	
		
	var current_time = main_node.current_game_time
	var spawn_time = hit_time - initial_lead_time
	var progress = (current_time - spawn_time) / initial_lead_time
	progress = clamp(progress, 0.0, 2.0)
	
	var visual_progress = pow(progress, 2.5)
	var window_width = get_viewport_rect().size.x
	
	var play_area_width = window_width * 0.95
	var left_margin = (window_width - play_area_width) / 2.0
	var lane_width = play_area_width / 4.0
	var final_x = left_margin + (lane * lane_width) + (lane_width / 2.0)
	
	var top_play_width = window_width * 0.20 
	var top_left_margin = (window_width - top_play_width) / 2.0
	var top_lane_width = top_play_width / 4.0
	var spawn_x = top_left_margin + (lane * top_lane_width) + (top_lane_width / 2.0)
	
	position.y = lerp(spawn_y, hit_line_y, visual_progress)
	position.x = lerp(spawn_x, final_x, visual_progress)
	
	var min_scale = 0.1
	var max_scale = 1.2
	var current_scale = lerp(min_scale, max_scale, visual_progress)
	
	# Memutar gambar jika berada di sebelah kanan
	var flip_sign = -1.0 if lane > 1.5 else 1.0
	scale = Vector2(current_scale * flip_sign, current_scale)
	
	# Efek Pudar saat muncul di cakrawala
	if progress < 0.2:
		modulate.a = lerp(0.0, 1.0, progress / 0.2)
	else:
		modulate.a = 1.0
	
	if texture:
		centered = true
		offset = Vector2(0, -texture.get_height() * 0.4)
