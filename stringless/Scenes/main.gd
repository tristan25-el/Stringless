extends Node2D

# --- NEW VARIABLES ADDED HERE ---
@export var tile_scene: PackedScene # This is where your tile scene goes
@onready var music_player: AudioStreamPlayer = $AudioStreamPlayer # Assumes you have an AudioStreamPlayer node named this
@export var global_offset := 0.0

var current_note_index: int = 0 # Tracks which note is next in line to spawn
var spawn_lead_time: float = 2.0 # How many seconds BEFORE the hit-time the tile should spawn
# --------------------------------

var beat_map: Array = []

var perfect_window := 0.05
var good_window := 0.10
var miss_window := 0.20
var score := 0
var combo := 0

func load_beat_map(file_path: String):
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close() # Biasakan menutup file setelah dibaca
		
		# Mengubah string JSON menjadi Array of Dictionaries di Godot 4
		var parsed_data = JSON.parse_string(json_string)
		
		if parsed_data != null:
			beat_map = parsed_data
		else:
			print("Gagal membaca format JSON.")
	else:
		print("File beats.json tidak ditemukan!")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Panggil fungsi saat game dimulai
	load_beat_map("res://Aset/beats.json")
	
	print("Data Beat Map siap! Jumlah note: ", beat_map.size())
	
	# Automatically start playing the music once the map is successfully loaded
	if beat_map.size() > 0 and music_player:
		music_player.play()
	# ----------------------------

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# --- SPRAWNING LOGIC ADDED HERE (Replacing 'pass') ---
	if not music_player or not music_player.playing:
		return
		
	# Calculate highly accurate current audio time adjusted for latency
	var current_time = get_song_time()

	# Check if it's time to spawn upcoming notes
	while current_note_index < beat_map.size():
		var note_data = beat_map[current_note_index]
		var hit_time = note_data["time"] 
		
		# If the song time has reached the point where the note needs to spawn
		if current_time >= (hit_time - spawn_lead_time):
			spawn_tile(note_data)
			current_note_index += 1 # Move to the next note in your JSON list
		else:
			break # Stop checking if the next note isn't ready yet
	# ----------------------------------------------------

# --- NEW HELPER FUNCTION ADDED AT THE BOTTOM ---
func spawn_tile(data: Dictionary):
	if tile_scene == null:
		print("Warning: No tile scene assigned to PackedScene!")
		return
		
	var new_tile = tile_scene.instantiate()
	add_child(new_tile)
	
	# If your individual tile script has an setup function, run it here:
	if new_tile.has_method("initialize"):
		new_tile.initialize(data, spawn_lead_time)
# ------------------------------------------------


# Accurate song time
func get_song_time() -> float:
	return music_player.get_playback_position() \
	+ AudioServer.get_time_since_last_mix() \
	- AudioServer.get_output_latency() \
	+ global_offset

# Input checker
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and !event.echo:
		match event.keycode:
			KEY_A:
				check_hit(0)
			KEY_S:
				check_hit(1)
			KEY_D:
				check_hit(2)
			KEY_F:
				check_hit(3)

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

	# JUDGEMENT
	if closest_diff <= perfect_window:
		print("PERFECT")
		score += 300
		combo += 1
		closest_note.hit()
	elif closest_diff <= good_window:
		print("GOOD")
		score += 100
		combo += 1
		closest_note.hit()
	elif closest_diff <= miss_window:
		print("BAD")
		score += 50
		combo = 0
		closest_note.hit()
	else:
		register_miss()
		
	print("Score: ", score)
	print("Combo: ", combo)

# AUTO MISS
func register_miss():
	if combo > 0:
		combo = 0
	print("MISS")
