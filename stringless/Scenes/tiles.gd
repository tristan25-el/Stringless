extends Node2D 

var speed: float = 0.0
var hit_line_y: float = 540.0 # The Y-coordinate of judgement line
var spawn_y: float = -120.0    # Starts just off-screen at the top

var lane: int = 0
var hit_time: float = 0.0
var already_hit := false
var miss_window := 0.20

func _ready() -> void:
	add_to_group("notes")
	scale = Vector2(0.5, 0.5)
	
# This is the function called by main script's 'new_tile.initialize(data, spawn_lead_time)'
func initialize(data: Dictionary, lead_time: float):
	lane = data.get("lane", 0)
	hit_time = data.get("time", 0.0)
	
	# 1. Get the actual width of the game window
	var window_width = get_viewport_rect().size.x
	
	# 2. Calculate the 3/5 center play area
	var play_area_width = window_width * (3.0 / 5.0)
	var left_margin = window_width * (1.0 / 5.0) # The empty 1/5 space on the left
	
	# 3. Divide the center area into 4 lanes (for A, S, D, F)
	var lane_width = play_area_width / 4.0
	var lane_number = data.get("lane", 0) # Expects 0, 1, 2, or 3
	
	# 4. Position the tile perfectly in the middle of its assigned lane
	position.x = left_margin + (lane_number * lane_width) + (lane_width / 2.0)
	position.y = spawn_y
	
	# 5. Speed calculation (Distance / Time)
	var distance_to_travel = hit_line_y - spawn_y
	speed = distance_to_travel / lead_time

	# Visual check for impostors
	if data.get("is_impostor", false):
		modulate = Color.RED

func _process(delta: float) -> void:
	# Move downwards every frame
	position.y += speed * delta
	
	# Safety cleanup: If the player completely misses the tile, delete it 
	# so it doesn't lag your game forever
	if position.y > hit_line_y + 100 and !already_hit:
		already_hit = true
		get_parent().register_miss()
		queue_free()
		
func hit():
	if already_hit:
		return
	already_hit = true
	queue_free()
	
func can_be_hit(current_time: float) -> bool:
	return abs(current_time - hit_time) <= miss_window
