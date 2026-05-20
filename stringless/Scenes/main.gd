extends Node2D

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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
