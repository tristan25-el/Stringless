extends Node2D

# =========================================================================
# CONFIGURATION - MUST MATCH YOUR NOTE SCRIPT EXACTLY!
# =========================================================================
var spawn_y: float = 485.0        # Top horizon line
var hit_line_y: float = 1350.0     # Bottom judgment line

func _ready() -> void:
	# Keep the working troubleshooting positions
	position = Vector2.ZERO
	scale = Vector2.ONE
	
	# Force this node to behave globally so parent scales/positions don't hide it
	top_level = true
	
	# Force it to render on top of the background layout where it successfully draws
	z_index = 1 

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var window_width = get_viewport_rect().size.x
	
	# 1. Calculate Bottom Layout (Hitline)
	var play_area_width = window_width * 0.95
	var left_margin = (window_width - play_area_width) / 2.0
	var lane_width = play_area_width / 4.0
	
	# 2. Calculate Top Layout (Horizon)
	var top_play_width = window_width * 0.20 
	var top_left_margin = (window_width - top_play_width) / 2.0
	var top_lane_width = top_play_width / 4.0
	
	# 3. FIXED: THE CLEAN VISUAL OVERLAY TWEAK
	# We keep the working Z-index, but we reduce the alpha visibility down to 25% (0.25).
	# This lets the dark colors of your highway background bleed straight through the lines, 
	# making it look like it sits perfectly beneath your hitline graphics without hiding.
	var line_color = Color(1.0, 1.0, 1.0, 0.25)  
	var line_thickness = 4.0      
	
	# 4. Draw the 5 divider lanes
	for i in range(5):
		var spawn_x = top_left_margin + (i * top_lane_width)
		var final_x = left_margin + (i * lane_width)
		
		var start_point = Vector2(spawn_x, spawn_y)
		var end_point = Vector2(final_x, hit_line_y)
		
		draw_line(start_point, end_point, line_color, line_thickness, true)
