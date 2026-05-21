extends Node2D

# --- NEW VARIABLES ADDED HERE ---
@export var tile_scene: PackedScene # This is where your tile scene goes
@onready var music_player: AudioStreamPlayer = $AudioStreamPlayer # Assumes you have an AudioStreamPlayer node named this

var current_note_index: int = 0 # Tracks which note is next in line to spawn
var spawn_lead_time: float = 2.0 # How many seconds BEFORE the hit-time the tile should spawn
# --------------------------------

var beat_map: Array = []

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
	
	# --- NEW SETUP ADDED HERE ---
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
	var current_time = music_player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()

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
