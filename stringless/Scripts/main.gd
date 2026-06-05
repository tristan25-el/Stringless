extends Node2D

#NEW VARIABLES ADDED HERE
@export var tile_scene: PackedScene 
@onready var music_player: AudioStreamPlayer = $AudioStreamPlayer 
@export var global_offset := 0.0
@onready var judge_feedback = $CanvasLayer/JudgeFeedback
@onready var player_character = $Player as Node2D
@onready var jumpscare = $CanvasLayer/Jumpscare
@onready var string_label = $CanvasLayer/StringLabel
@onready var combo_label = $CanvasLayer/ComboLabel
@onready var hearts = [
	$CanvasLayer/HeartsContainer/Heart1,
	$CanvasLayer/HeartsContainer/Heart2,
	$CanvasLayer/HeartsContainer/Heart3
]
@onready var game_over_panel = $CanvasLayer/GameOverPanel
@onready var monster = $Monster
@export var decoration_scene: PackedScene
@export var decor_textures: Array[Texture2D] = []
@export var decor_spawn_min := 0.8 # Minimum delay for a wall object to spawn
@export var decor_spawn_max := 2.5 # Maximum delay for a wall object to spawn

var decor_timer_left := 0.0
var decor_timer_right := 0.0
var next_spawn_left := 0.0
var next_spawn_right := 0.0
const JUMPSCARE_TEXTURE = preload("res://Aset/Gameplay/Manekin jumpscare Ver.3.png")
var current_game_time: float = 0.0
var original_judge_position

var current_note_index: int = 0 # Tracks which note is next in line to spawn
var spawn_lead_time: float = 2.0 # How many seconds BEFORE the hit-time the tile should spawn
var intro_time: float = 0.0
var music_started: bool = false
var perfect_texture = preload("res://UI/PERFECT.png")
var good_texture = preload("res://UI/GOOD.png")
var bad_texture = preload("res://UI/BAD.png")
var miss_texture = preload("res://UI/MISS.png")

var beat_map: Array = []

var perfect_window := 0.05
var good_window := 0.10
var miss_window := 0.18
var score := 0
var combo := 0
var judge_tween: Tween
var max_health := 3
var current_health := 3
var current_strings := 0
var current_string_tier := 0
var full_heart = preload("res://UI/heart full.png")
var empty_heart = preload("res://UI/heart emptyl.png")
var is_game_over := false

func load_beat_map(file_path: String):
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close() 
		
		# Mengubah string JSON menjadi Array of Dictionaries
		var parsed_data = JSON.parse_string(json_string)
		
		if parsed_data != null:
			beat_map = parsed_data
		else:
			print("Gagal membaca format JSON.")
	else:
		print("File beats.json tidak ditemukan!")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_beat_map("res://Aset/Gameplay/beats.json")
	print("Data Beat Map siap! Jumlah note: ", beat_map.size())
	judge_feedback.visible = false
	
	# REMOVED DELAY: Play the music immediately on startup
	if music_player:
		music_player.play()
		music_started = true
	
	jumpscare.pivot_offset = jumpscare.size / 2
	update_hearts()
	update_strings()
	combo_label.pivot_offset = combo_label.size / 2
	game_over_panel.visible = false
	update_player_animation()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if beat_map.size() == 0:
		return
		
	# REMOVED DELAY TRACKER: Skip loop if the music isn't actively playing
	if not music_player.playing:
		return
		
	current_game_time = get_song_time() # Track song position cleanly here
	
	# SPAWNING LOOP (uses current_game_time)
	while current_note_index < beat_map.size():
		var note_data = beat_map[current_note_index]
		var hit_time = note_data["time"] 
		
		if current_game_time >= (hit_time - spawn_lead_time):
			spawn_tile(note_data)
			current_note_index += 1 
		else:
			break
			
	decor_timer_left += delta
	if decor_timer_left >= next_spawn_left:
		decor_timer_left = 0.0
		next_spawn_left = randf_range(decor_spawn_min, decor_spawn_max)
		spawn_single_decor_node(current_game_time + spawn_lead_time, -0.85)

	decor_timer_right += delta
	if decor_timer_right >= next_spawn_right:
		decor_timer_right = 0.0
		next_spawn_right = randf_range(decor_spawn_min, decor_spawn_max)
		spawn_single_decor_node(current_game_time + spawn_lead_time, 3.85)
	
func pre_populate_decorations():
	var steps_left = randi_range(2, 4) 
	for i in range(1, steps_left):
		var target_progress = float(i) / float(steps_left)
		var random_offset = randf_range(-0.3, 0.3)
		var waktu_jatuh = intro_time + spawn_lead_time - (target_progress * spawn_lead_time) + random_offset
		spawn_single_decor_node(waktu_jatuh, -0.85)

	var steps_right = randi_range(2, 4) 
	for i in range(1, steps_right):
		var target_progress = float(i) / float(steps_right)
		var random_offset = randf_range(-0.3, 0.3)
		var waktu_jatuh = intro_time + spawn_lead_time - (target_progress * spawn_lead_time) + random_offset
		spawn_single_decor_node(waktu_jatuh, 3.85)

func spawn_single_decor_node(waktu_jatuh: float, lane_bayangan: float):
	if decoration_scene == null or decor_textures.is_empty():
		return
		
	var new_decor = decoration_scene.instantiate()
	add_child(new_decor)
	
	new_decor.texture = decor_textures.pick_random()
	
	if new_decor.has_method("initialize"):
		new_decor.initialize(waktu_jatuh, spawn_lead_time, lane_bayangan)

# spawn tiles
func spawn_tile(data: Dictionary):
	if tile_scene == null:
		print("Warning: No tile scene assigned to PackedScene!")
		return
		
	var new_tile = tile_scene.instantiate()
	add_child(new_tile)
	
	if new_tile.has_method("initialize"):
		new_tile.initialize(data, spawn_lead_time)
# ------------------------------------------------


# Accurate song time
func get_song_time() -> float:
	# Fallback handling to ensure safe timing evaluations during the negative countdown phase
	if not music_started:
		return current_game_time
		
	return music_player.get_playback_position() \
	+ AudioServer.get_time_since_last_mix() \
	- AudioServer.get_output_latency() \
	+ global_offset

# Input checker
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and !event.echo:
		var target_lane: int = -1
		
		match event.keycode:
			KEY_A: target_lane = 0
			KEY_S: target_lane = 1
			KEY_D: target_lane = 2
			KEY_F: target_lane = 3
			
		
		# INTEGRATION: PROCESS DASH MOVEMENT AND HIT VERIFICATION
		if target_lane != -1:
			# 1. Instantly trigger the player character animation dash to lane
			if player_character and player_character.has_method("jump_to_lane"):
				player_character.jump_to_lane(target_lane)
				
			# 2. Fire your standard note score scoring checker system
			check_hit(target_lane)

# HIT DETECTION
func check_hit(lane: int):
	var current_time = get_song_time()
	var closest_note = null
	var closest_diff = INF
	for child in get_tree().get_nodes_in_group("notes"): #Agar yang diperiksa hanya tiles-nya saja
		if child.has_method("hit"):
			if child.lane != lane:
				continue
			if child.already_hit:
				continue
			if !child.can_be_hit(current_time): # Penerapan active window
				continue
			var diff = abs(current_time - child.hit_time)
			if diff < closest_diff:
				closest_diff = diff
				closest_note = child
				
	if closest_note == null:
		print("MISS")
		combo = 0
		return

	if "is_impostor" in closest_note and closest_note.is_impostor:
		combo = 0
		damage_player(1)
		closest_note.hit()
		return

	# JUDGEMENT
	if closest_diff <= perfect_window:
		show_judgement(perfect_texture)
		score += 300
		combo += 1
		closest_note.hit()
		add_string()
		update_combo()
	elif closest_diff <= good_window:
		show_judgement(good_texture)
		score += 100
		combo += 1
		closest_note.hit()
		add_string()
		update_combo()
	elif closest_diff <= miss_window:
		show_judgement(bad_texture)
		score += 50
		combo = 0
		closest_note.hit()
		add_string()
		update_combo()
	else:
		register_miss()
		
	print("Score: ", score)
	print("Combo: ", combo)
	
func show_judgement(texture):
	judge_feedback.texture = texture
	if texture != perfect_texture:
		judge_feedback.custom_minimum_size = Vector2(400,400)
	judge_feedback.visible = true
	
	if original_judge_position == null:
		original_judge_position = judge_feedback.position
		
	if judge_tween:
		judge_tween.kill()
		
	judge_feedback.position = original_judge_position
	judge_feedback.modulate.a = 0.5 #Ini ngatur Opacity
	judge_tween = create_tween()
	# POP hanya selain MISS
	if texture != miss_texture:
		judge_feedback.scale = Vector2(0.7, 0.7)
		judge_tween.parallel().tween_property(
			judge_feedback,
			"scale",
			Vector2(1.0, 1.0),
			0.06
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		judge_tween.parallel().tween_property(judge_feedback, "position:x", original_judge_position.x - 25.0, 0.03)
	else:
		judge_feedback.scale = Vector2(1.0, 1.0)
		judge_tween.tween_property(judge_feedback, "position:x", original_judge_position.x - 25.0, 0.03)
		
	judge_tween.chain().tween_property(judge_feedback, "position:x", original_judge_position.x + 25.0, 0.03)
	judge_tween.tween_property(judge_feedback, "position:x", original_judge_position.x - 15.0, 0.03)
	judge_tween.tween_property(judge_feedback, "position:x", original_judge_position.x + 15.0, 0.03)
	judge_tween.tween_property(judge_feedback, "position:x", original_judge_position.x, 0.03)
	
	judge_tween.tween_interval(0.25)
	judge_tween.tween_property(
		judge_feedback,
		"modulate:a",
		0.0,
		0.15
	)
	await judge_tween.finished
	judge_feedback.visible = false
	
# AUTO MISS
func register_miss():
	if combo > 0:
		combo = 0
	current_strings -= 1
	update_strings()
	update_combo()
	update_player_animation()
	if current_strings <= 0:
		game_over()
	show_judgement(miss_texture)
	
func show_jumpscare(world_pos: Vector2):
	jumpscare.texture = JUMPSCARE_TEXTURE
	jumpscare.visible = true
	jumpscare.position = world_pos
	jumpscare.scale = Vector2(0.2, 0.2)
	jumpscare.modulate.a = 0.7 #opacitynya
	var tween = create_tween()
	tween.parallel().tween_property(
		jumpscare,
		"scale",
		Vector2(15.0, 15.0), #besaran ngezoomnya
		0.2 #kecepatan zoom.
	)
	tween.parallel().tween_property(
		jumpscare,
		"position",
		Vector2(
			540,
			960
		),
		0.1 #kecepatan geser ke tengah.
	)
	tween.tween_property(
		jumpscare,
		"modulate:a",
		0.0,
		0.15 #kecepatan menghilang.
	)
	await tween.finished
	jumpscare.visible = false
	
func update_hearts():
	for i in range(max_health):
		if i < current_health:
			hearts[i].texture = full_heart
		else:
			hearts[i].texture = empty_heart
func damage_player(amount: int):
	current_health -= amount
	current_health = max(current_health, 0)
	update_hearts()
	if current_health <= 0:
		game_over()
		
func game_over():
	if is_game_over:
		return
	is_game_over = true
	music_player.stop()
	set_process(false)
	game_over_panel.visible = true
	get_tree().paused = true

func update_strings():
	string_label.text = "STRINGS : " + str(current_strings)
	
func update_combo():
	if combo <= 0:
		combo_label.visible = false
	else:
		combo_label.visible = true
		combo_label.text = "COMBO : " + str(combo)
		combo_label.scale = Vector2(1.1, 1.1)
		var tween = create_tween()
		tween.tween_property(
			combo_label,
			"scale",
			Vector2(1.0, 1.0),
			0.1
		)
	
func add_string(amount := 1):
	current_strings += amount
	update_strings()
	update_player_animation()
	
func update_player_animation():
	if player_character == null:
		print("DEBUG ERROR: player_character masih KOSONG / NULL! Periksa Inspector main.gd Anda.")
		return
		
	if not player_character.has_method("set_base_animation"):
		print("DEBUG ERROR: Node Player ditemukan, tapi tidak punya fungsi set_base_animation. Periksa skrip player.gd Anda.")
		return
		
	var target_tier := 0
	if current_strings >= 60:
		target_tier = 2
	elif current_strings >= 30:
		target_tier = 1
		
	if target_tier != current_string_tier:
		print("DEBUG SUCCESS: Mengubah tier dari ", current_string_tier, " ke ", target_tier, ". Jumlah string: ", current_strings)
		current_string_tier = target_tier
		
		if current_string_tier == 2:
			player_character.set_base_animation("idle_3")
		elif current_string_tier == 1:
			player_character.set_base_animation("idle_2")
		elif current_string_tier == 0:
			player_character.set_base_animation("idle")
