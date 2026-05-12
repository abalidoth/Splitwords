extends Node

signal selection_occurred(grid_position:Vector2i, h_slot: Array, v_slot:Array)
signal trigger_recheck()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_letter_box_got_selected(grid_position:Vector2i):
	var slots = PuzzleHolder.puzzle.square_to_slot[grid_position]
	var h_slot = PuzzleHolder.puzzle.slots[slots[0]]
	var v_slot = PuzzleHolder.puzzle.slots[slots[1]]
	selection_occurred.emit(grid_position, h_slot, v_slot)
	
func _on_letter_box_letter_changed():
	trigger_recheck.emit()
