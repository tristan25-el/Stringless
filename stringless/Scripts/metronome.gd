extends Node2D



func _physics_process(delta: float) -> void: 
	var beatDurationMs: int = 60 / 120 * 1000 #change 120 with the bpm of the song
	var lastBeat: int = 0
	var nextBeatPosition: int = 0
	nextBeatPosition = beatDurationMs
	
	
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
