extends Node

signal selection_occurred(grid_position:Vector2i)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_letter_box_got_selected(grid_position:Vector2i):
	selection_occurred.emit(grid_position)
