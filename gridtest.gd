extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var gr = CrossGrid.new(Vector2i(8,8))
	gr.generate_grid(true)
	gr.generate_slots()
	%Label.text = gr.print_grid(true)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	var gr = CrossGrid.new(Vector2i(8,8))
	gr.generate_grid(true)
	gr.generate_slots()
	%Label.text = gr.print_grid(true)
