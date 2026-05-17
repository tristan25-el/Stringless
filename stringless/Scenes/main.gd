extends Node2D

const TILE = preload("res://Scenes/tiles.tscn")

# We will store our 4 specific X coordinates here
var spawn_points: Array[float] = []

func _ready() -> void:
	randomize()
	calculate_spawn_points()

func calculate_spawn_points() -> void:
	var vpr: Rect2 = get_viewport_rect()
	var screen_width = vpr.size.x
	
	# This divides your screen into 4 even columns/lanes
	# Adjust the padding (e.g., 50 or 100) depending on how wide your tiles are
	var padding = 60.0 
	var lane_width = (screen_width - (padding * 2)) / 3
	
	for i in range(4):
		var x_pos = padding + (i * lane_width)
		spawn_points.append(x_pos)

func spawnEnemy() -> void:
	# 1. Check if we have any free spawn points left 
	# (Prevents crashing if you try to spawn more than 4 at once)
	var active_tiles = get_tree().get_nodes_in_group("tiles")
	
	# Create a list of currently occupied X positions
	var occupied_x: Array[float] = []
	for tile in active_tiles:
		occupied_x.append(tile.position.x)
	
	# Filter our 4 spawn points to find which ones are currently empty
	var available_points: Array[float] = []
	for point in spawn_points:
		# Using a small buffer (like 5 pixels) in case of minor floating point math differences
		var is_occupied = false
		for occ_x in occupied_x:
			if abs(occ_x - point) < 5.0:
				is_occupied = true
				break
		if not is_occupied:
			available_points.append(point)
			
	# 2. If all 4 lanes are full, don't spawn anything yet
	if available_points.is_empty():
		return
		
	# 3. Pick one of the available lanes at random
	var random_x = available_points.pick_random()
	
	# 4. Instantiate and setup
	var new_tile : Tiles = TILE.instantiate()
	new_tile.position = Vector2(random_x, get_viewport_rect().position.y)
	
	# CRITICAL: Add the tile to a group so the script can track it
	new_tile.add_to_group("tiles")
	
	get_tree().current_scene.add_child(new_tile)

# This function runs automatically every time the Timer finishes counting down
func _on_timer_timeout() -> void:
	spawnEnemy()


func _on_dissapear_timeout() -> void:
	pass # Replace with function body.
