extends Node2D

var Clue_load = preload("res://clue.tscn")
var Letterbox_load = preload("res://letter_box.tscn")

const LETTER_BOX_SIZE = 400.0

@export var board_max_dim: int = 500.0

var square_size: float

var square_scale: float

var clue_nodes: Dictionary[int,Clue] = {}
var letterbox_nodes: Dictionary[Vector2i,LetterBox] = {}

var across_empty: bool = true
var down_empty: bool = true

#In the following, 4-Across is 4 and 3-down is -3.
var down_across_to_slot: Dictionary[int,int] = {}
var slot_to_down_across: Dictionary[int,int] = {}

func get_across_max()-> float:
	return max(0, %AcrossVBox.size.y - %AcrossScroll.size.y)
	
func get_down_max()-> float:
	return max(0, %DownVBox.size.y - %DownScroll.size.y)

func create_clue(clue_number:int, clue_index:int, clue_vertical:bool, clue_text: String):
	var cl: Clue = Clue_load.instantiate()
	cl.set_props(clue_number, clue_index, clue_text, clue_vertical, PuzzleHolder.puzzle.slots[clue_index])
	if clue_vertical:
		if down_empty:
			down_empty = false
		else:
			var sep = HSeparator.new()
			%DownVBox.add_child(sep)
		%DownVBox.add_child(cl)
	else:
		if across_empty:
			across_empty = false
		else:
			var sep = HSeparator.new()
			%AcrossVBox.add_child(sep)
		%AcrossVBox.add_child(cl)
	clue_nodes[clue_index] = cl



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.selection_occurred.connect(_on_signal_bus_selection_occurred)
	SignalBus.trigger_recheck.connect(_on_signal_bus_trigger_recheck)
	
	var board_max_squares = max(PuzzleHolder.size.x,PuzzleHolder.size.y)
	square_size = board_max_dim/board_max_squares
	square_scale = square_size/LETTER_BOX_SIZE
	
	%BlackBackground.size = square_size * PuzzleHolder.size
	
	
	
	
	for j in range(PuzzleHolder.size.y):
		for i in range(PuzzleHolder.size.x):
			var v = Vector2i(i,j)
			if v in PuzzleHolder.puzzle.squares:
				var lb:LetterBox = Letterbox_load.instantiate()
				%Board.add_child(lb)
				lb.position = v*square_size
				lb.scale = square_scale*Vector2.ONE
				lb.grid_position = v
				letterbox_nodes[v] = lb
				var clue_num = PuzzleHolder.puzzle.grid.slot_starts.find_key(v)
				if clue_num != null:
					lb.set_clue_number(clue_num)
					for sl_ind in range(len(PuzzleHolder.puzzle.slots)):
						var slot = PuzzleHolder.puzzle.slots[sl_ind]
						if slot[0]==v:
							var direction = slot[1]-slot[0]
							if direction == Vector2i(1,0):
								create_clue(clue_num,sl_ind,false,PuzzleHolder.puzzle.slot_to_clue[sl_ind])
								down_across_to_slot[clue_num] = sl_ind
								slot_to_down_across[sl_ind] = clue_num
								
							elif direction == Vector2i(0,1):
								create_clue(clue_num,sl_ind,true,PuzzleHolder.puzzle.slot_to_clue[sl_ind])
								down_across_to_slot[-clue_num] = sl_ind
								slot_to_down_across[sl_ind] = -clue_num
							else:
								assert(false) #something has gone wrong
			
							
	
	

func _on_signal_bus_selection_occurred(grid_position: Vector2i, h_slot: Array, v_slot: Array):
	pass
	
func _on_signal_bus_trigger_recheck() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if %AcrossScroll is ScrollContainer:
		%testlabel.text = str(%AcrossScroll.get_v_scroll_bar().value)+" "+str(get_across_max())


func _on_button_pressed() -> void:
	var puz: PuzzleSaver = PuzzleSaver.new()
	puz.puzzle = PuzzleHolder.puzzle
	puz.size = PuzzleHolder.size
	ResourceSaver.save(puz,"saved_puzzle.tres")
	pass
