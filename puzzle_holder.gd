extends Node

var size: Vector2i

var symmetric: bool

var obscurity: int

var puzzle: Puzzle

#What needs to happen: store CrossGrid and Puzzle to separate files, then reconstruct?

var saved_puzzle: Puzzle = load("res://saved_puzzle.tres")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
