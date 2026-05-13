extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_h_slider_value_changed(value: float) -> void:
	%ObscurityValue.text = "%3d" % value
	%WordObscurityExplainer.text = "The algorithm will only use the top %3d%% most common words. Lower values will be easier, but make puzzles take longer to generate." % value


func _on_generate_puzzle_button_pressed() -> void:
	pass
	PuzzleHolder.size = Vector2i(%WidthSpinBox.value, %HeightSpinBox.value)
	PuzzleHolder.obscurity = %ObscuritySlider.value
	PuzzleHolder.symmetric = %SymmetricCheck.button_pressed
	PuzzleHolder.puzzle=Puzzle.new()
	PuzzleHolder.puzzle.initialize(PuzzleHolder.size,PuzzleHolder.obscurity,PuzzleHolder.symmetric)

	get_tree().change_scene_to_file("res://data_load_screen.tscn")
	


func _on_test_puzzle_button_pressed() -> void:
	PuzzleHolder.puzzle = load("res://saved_puzzle.tres")
	PuzzleHolder.grid = load("res://saved_grid.tres")
	get_tree().change_scene_to_file("res://main_screen.tscn")
