extends Node2D

@onready var music_player: AudioStreamPlayer = $AudioStreamPlayer

# --- NEW HELPERS FOR ACCURATE RECORDING ---
@export_group("Quantization (Snap to Beat)")
@export var use_quantization: bool = false   # Turn this ON in inspector to snap notes to the grid
@export var song_bpm: float = 120.0          # Put your song's actual BPM here
@export var grid_division: int = 4           # 1 = Quarter notes, 2 = 8th notes, 4 = 16th notes (Recommended)

@export_group("Playback Speed")
@export_range(0.25, 1.0, 0.05) var recording_speed: float = 1.0 # Lower this (e.g. 0.6 or 0.7) to slow down the song!
# ------------------------------------------
 
var recorded_beats: Array = []
var output_file_path: String = "res://Aset/Gameplay/beats.json"
var is_finished: bool = false

func _ready() -> void:
	print("--- BEAT RECORDER STARTED ---")
	print("Controls:")
	print("  A, S, D, F -> Record standard notes")
	print("  Hold SPACEBAR + A, S, D, F -> Record Impostor notes")
	print("----------------------------")
	
	if music_player:
		# Apply your custom slow-motion speed before playing
		music_player.pitch_scale = recording_speed
		music_player.play()
		music_player.finished.connect(_on_music_finished)
		
		if recording_speed < 1.0:
			print("Mode: SLOW MOTION ACTIVE (", recording_speed * 100, "% Speed). Timestamps will scale perfectly automatically!")
		if use_quantization:
			print("Mode: QUANTIZATION ACTIVE (Snapping to ", grid_division, "th notes at ", song_bpm, " BPM)")
	else:
		print("Error: AudioStreamPlayer node not found!")

func _input(event: InputEvent) -> void:
	if is_finished:
		return
		
	# 1. EMERGENCY SAVE: Check this FIRST so it always works, even if music stopped
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER:
			is_finished = true
			if music_player.playing:
				music_player.stop()
			save_to_json()
			return # Stop processing further keys

	# 2. Prevent recording if music isn't actively playing
	if not music_player.playing:
		return
		
	# 3. RECORD NOTES
	if event is InputEventKey and event.pressed and not event.echo:
		var lane: int = -1
		
		match event.keycode:
			KEY_A: lane = 0
			KEY_S: lane = 1
			KEY_D: lane = 2
			KEY_F: lane = 3
			
		if lane != -1:
			record_note(lane)

func record_note(lane: int):
	# Calculate highly accurate raw song timestamp
	var current_time = music_player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	
	# --- QUANTIZATION LOGIC ---
	if use_quantization and song_bpm > 0:
		var beat_duration = 60.0 / song_bpm
		var grid_step = beat_duration / grid_division
		# Snap the messy human reaction time to the closest exact mathematical step
		current_time = round(current_time / grid_step) * grid_step
	
	var is_impostor: bool = Input.is_key_pressed(KEY_SPACE)
	
	var note_data = {
		"time": round(current_time * 100.0) / 100.0,
		"lane": lane,
		"is_impostor": is_impostor
	}
	
	recorded_beats.append(note_data)
	
	if is_impostor:
		print("Recorded IMPOSTOR String at: ", note_data["time"], "s | Lane: ", lane)
	else:
		print("Recorded Normal String at: ", note_data["time"], "s | Lane: ", lane)

func _on_music_finished():
	if is_finished:
		return
	is_finished = true
	print("Song finished! Saving data...")
	save_to_json()



func save_to_json():
	recorded_beats.sort_custom(func(a, b): return a["time"] < b["time"])
	
	var file = FileAccess.open(output_file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(recorded_beats, "\t")
		file.store_string(json_string)
		file.close()
		print("=========================================")
		print("SUCCESS! Saved ", recorded_beats.size(), " notes to: ", output_file_path)
		print("=========================================")
	else:
		print("Failed to save file! Check if folder path 'res://Aset/' exists.")
