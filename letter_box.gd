extends Node2D
class_name LetterBox

@export var base_color: Color
@export var hover_color: Color
@export var selected_color: Color
@export var selected_hover_color: Color
@export var vertical_clue_color: Color
@export var vertical_hover_color: Color
@export var horizontal_clue_color: Color
@export var horizontal_hover_color: Color

var current_base_color: Color = base_color
var current_highlight_color: Color = hover_color

@export var grid_position : Vector2i

var selected : bool = false
enum BoxState {BLANK, SINGLE, SLASH_UP, SLASH_DOWN}

var state: BoxState
#var blank: bool = true
#var slashed : bool = false
#var slash_up : bool = false

var mouse_in: bool = false

var first_letter: String = ""
var second_letter: String = ""

signal got_selected(grid_pos: Vector2i)

const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_base_color = base_color
	current_highlight_color = hover_color
	if mouse_in:
		modulate = current_highlight_color
	else:
		modulate = current_base_color
	got_selected.connect(SignalBus._on_letter_box_got_selected)
	SignalBus.selection_occurred.connect(_on_signal_bus_selection_occurred)

func set_clue_number(i: int)-> void:
	%ClueLabel.show()
	%ClueLabel.text = str(i)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func select() -> void:
	selected = true
	current_base_color = selected_color
	current_highlight_color = selected_hover_color
	if mouse_in:
		modulate = current_highlight_color
	else:
		modulate = current_base_color

func deselect(_selected_grid_position: Vector2i, h_slot:Array, v_slot:Array) -> void:
	selected = false
	if grid_position in h_slot:
		current_base_color = horizontal_clue_color
		current_highlight_color = horizontal_hover_color
	elif grid_position in v_slot:
		current_base_color = vertical_clue_color
		current_highlight_color = vertical_hover_color
	else:
		current_base_color = base_color
		current_highlight_color = hover_color
	if mouse_in:
		modulate = current_highlight_color
	else:
		modulate = current_base_color
	
func set_blank() -> void:
	state = BoxState.BLANK
	%DownElements.hide()
	%UpElements.hide()
	%CenterLabel.hide()
	first_letter = ""
	second_letter = ""

func set_single() -> void:
	state = BoxState.SINGLE
	%UpElements.hide()
	%DownElements.hide()
	%CenterLabel.show()
	%CenterLabel.text = first_letter
	
func set_upper() -> void:
	state = BoxState.SLASH_UP
	%CenterLabel.hide()
	%DownElements.hide()
	%UpElements.show()
	%UpperLeftLabel.text=first_letter
	%LowerRightLabel.text = second_letter
	
func set_lower()-> void:
	state = BoxState.SLASH_DOWN
	%CenterLabel.hide()
	%UpElements.hide()
	%DownElements.show()
	%LowerLeftLabel.text=first_letter
	%UpperRightLabel.text = second_letter
	
func rotate_letters() -> void:
	var temp:String
	if state == BoxState.SLASH_UP:
		temp = first_letter
		first_letter = second_letter
		second_letter = temp
		set_lower()
	elif state == BoxState.SLASH_DOWN:
		set_upper()
	
func flip_letters() -> void:
	var temp: String
	if state in [BoxState.SLASH_UP, BoxState.SLASH_DOWN]:
		temp = first_letter
		first_letter = second_letter
		second_letter = temp
		if state == BoxState.SLASH_UP:
			set_upper()
		else:
			set_lower()
		

func _on_signal_bus_selection_occurred(grid_position_selected:Vector2i, h_slot: Array, v_slot: Array) -> void:
	if grid_position != grid_position_selected:
		deselect(grid_position_selected, h_slot, v_slot)

func handle_letter_input(s: String) -> void:
	if state == BoxState.BLANK:
		first_letter = s
		set_single()
	elif state == BoxState.SINGLE:
		second_letter = s
		set_upper()
	else:
		pass
		

func _input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo and event.pressed:
		if selected:
			var key_label = OS.get_keycode_string(event.key_label)
			if key_label in alphabet:
				handle_letter_input(key_label)
					
			elif event.keycode in [KEY_SPACE, KEY_BACKSPACE]:
				set_blank()
	
	


func _on_area_2d_mouse_entered() -> void:
	mouse_in = true
	modulate = current_highlight_color


func _on_area_2d_mouse_exited() -> void:
	mouse_in = false
	modulate = current_base_color
		


func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
				if event.double_click:
					rotate_letters()
				else:
					got_selected.emit(grid_position)
					select()
			elif event.button_index == MouseButton.MOUSE_BUTTON_RIGHT:
				if state in [BoxState.SLASH_UP, BoxState.SLASH_DOWN]:
					rotate_letters()
				
