extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	PuzzleUtils.word_data = load("res://word_data.tres")
	get_tree().change_scene_to_file("res://loading_screen.tscn")
