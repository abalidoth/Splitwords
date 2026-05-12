extends Node2D

var progress_bars : Array[ProgressBar] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	###TEST ONLY
	#PuzzleHolder.size = Vector2i(8,8)
	#PuzzleHolder.obscurity = 100
	#PuzzleHolder.symmetric = true
	#PuzzleHolder.puzzle=PuzzleUtils.Puzzle.new(PuzzleHolder.size,PuzzleHolder.obscurity,PuzzleHolder.symmetric)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if PuzzleHolder.puzzle.state != PuzzleUtils.AlgState.FINISHED:
		PuzzleHolder.puzzle.update()
		update_puzzle_progress()
	else:
		get_tree().change_scene_to_file("res://main_screen.tscn")

func update_puzzle_progress() -> void:
	var num_bars:int = len(progress_bars)
	var num_states: int = len(PuzzleHolder.puzzle.backtrack_choices)
	print(num_bars, " ", num_states)
	var comp = PuzzleHolder.puzzle.completion*100
	if num_bars < num_states + 1:
		var new_bar : ProgressBar = ProgressBar.new()
		progress_bars.append(new_bar)
		%ProgressVBox.add_child(new_bar)
		new_bar.value = comp
	elif num_bars == num_states + 1:
			progress_bars[-1].value = comp
	elif num_bars > num_states + 1:
		var b = progress_bars.pop_back()
		b.queue_free()
		progress_bars[-1].value = comp
		
