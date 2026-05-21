extends Node2D

@onready var music_player: AudioStreamPlayer = $AudioStreamPlayer # Adjust path to your audio node

var recorded_beats: Array = []
var output_file_path: String = "res://Aset/beats.json"
var is_finished: bool = false

func _ready() -> void:
	print("--- BEAT RECORDER STARTED ---")
	print("Controls:")
	print("  A, S, D, F -> Record standard notes")
	print("  Hold SPACEBAR + A, S, D, F -> Record Impostor notes")
	print("----------------------------")
	
	if music_player:
		music_player.play()
		# Connect the finished signal so it auto-saves when the song ends
		music_player.finished.connect(_on_music_finished)
	else:
		print("Error: AudioStreamPlayer node not found!")

func _input(event: InputEvent) -> void:
	if is_finished or not music_player.playing:
		return
		
	# We only want to record on the exact frame the key is pressed down
	if event is InputEventKey and event.pressed and not event.echo:
		var lane: int = -1
		
		# Map the keys to lane indexes (0 to 3)
		match event.keycode:
			KEY_A: lane = 0
			KEY_S: lane = 1
			KEY_D: lane = 2
			KEY_F: lane = 3
			
		# If an ASDF key was pressed, record it!
		if lane != -1:
			record_note(lane)

func record_note(lane: int):
	# Calculate the highly accurate timestamp of the song right now
	var current_time = music_player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	
	# Check if the player is holding Spacebar to flag it as an impostor string
	var is_impostor: bool = Input.is_key_pressed(KEY_SPACE)
	
	# Create the data block matching what our main level loader expects
	var note_data = {
		"time": round(current_time * 100.0) / 100.0, # Rounds to 2 decimal places (e.g., 2.34)
		"lane": lane,
		"is_impostor": is_impostor
	}
	
	recorded_beats.append(note_data)
	
	# Console printout so you know it's working live
	if is_impostor:
		print("Recorded IMPOSTOR String at: ", note_data["time"], "s in Lane: ", lane)
	else:
		print("Recorded Normal String at: ", note_data["time"], "s in Lane: ", lane)

func _on_music_finished():
	if is_finished:
		return
	is_finished = true
	
	print("Song finished! Saving data...")
	save_to_json()

# Emergency save: If you don't want to listen to the whole song, press ENTER to save early
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_ENTER and event.pressed):
		if not is_finished:
			is_finished = true
			music_player.stop()
			save_to_json()

func save_to_json():
	# 1. Sort the array chronologically by time just in case inputs were registered weirdly
	recorded_beats.sort_custom(func(a, b): return a["time"] < b["time"])
	
	# 2. Open the file for writing
	var file = FileAccess.open(output_file_path, FileAccess.WRITE)
	if file:
		# Convert our array into a clean JSON string with formatting tabs
		var json_string = JSON.stringify(recorded_beats, "\t")
		file.store_string(json_string)
		file.close()
		
		print("=========================================")
		print("SUCCESS! Saved ", recorded_beats.size(), " notes to: ", output_file_path)
		print("=========================================")
	else:
		print("Failed to save file! Check if folder path 'res://Aset/' exists.")
