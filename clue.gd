extends MarginContainer

class_name Clue

@export var default_color: Color
@export var highlight_color: Color

@export var clue_number: int
@export var clue_text: String

@export var clue_index: int #this is the invisible index
var vertical: bool
var associated_squares: Array

var clear_box: StyleBoxFlat = preload("res://clear_clue_style_box.tres")
var selected_box: StyleBoxFlat = preload("res://selected_clue_style_box.tres")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	

func set_props(n:int, ind: int, s:String, v:bool, sq: Array):
	clue_number = n
	%ClueNumber.text = str(n)
	clue_text = s
	%ClueText.text = clue_text
	vertical =v
	clue_index = ind
	associated_squares = sq

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func highlight() -> void:
	%PanelContainer.add_theme_stylebox_override("panel", selected_box)
	
func un_highlight() -> void:
	%PanelContainer.add_theme_stylebox_override("panel", clear_box)
	
func _on_signal_bus_selection_occurred(grid_position_selected:Vector2i) -> void:
	if grid_position_selected in associated_squares:
		highlight()
	else:
		un_highlight()
