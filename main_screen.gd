extends Node2D

var Clue_load = preload("res://clue.tscn")

func get_across_max()-> float:
	return max(0, %AcrossVBox.size.y - %AcrossScroll.size.y)
	
func get_down_max()-> float:
	return max(0, %DownVBox.size.y - %DownScroll.size.y)

func create_clue(clue_number:int, clue_vertical:bool, clue_text: String):
	var cl: Clue = Clue_load.instantiate()
	pass
	cl.set_props(clue_number, clue_text, clue_vertical, [])
	if clue_vertical:
		%DownVBox.add_child(cl)
	else:
		%AcrossVBox.add_child(cl)
	pass



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.selection_occurred.connect(_on_signal_bus_selection_occurred)
	for i in range(30):
			
		create_clue(i,i%2==1,"Lorem ipsum dolor sit amet")

func _on_signal_bus_selection_occurred(grid_position: Vector2i):
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if %AcrossScroll is ScrollContainer:
		%testlabel.text = str(%AcrossScroll.get_v_scroll_bar().value)+" "+str(get_across_max())
