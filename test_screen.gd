extends Node2D

var puzzle: PuzzleUtils.Puzzle
var puzzle_done = false
var slots: Array[Array]=[]
var verts: Array[bool]=[]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in [0,1,2]:
		var hslot: Array[Vector2i] = []
		var vslot: Array[Vector2i] = []
		for j in [0,1,2]:
			hslot.append(Vector2i(j,i))
			vslot.append(Vector2i(i,j))
		slots.append(hslot)
		verts.append(false)
		slots.append(vslot)
		verts.append(true)
		
	print(slots)
	print(verts)
	puzzle=PuzzleUtils.Puzzle.new(slots, verts, 100)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if puzzle.state != PuzzleUtils.alg_state.FINISHED:
		puzzle.update()
	elif not puzzle_done:
		puzzle_done = true
		var output = ""
		for i in range(3):
			for j in range(3):
				var v = Vector2i(j,i)
				var t = puzzle.completed_puzzle[v]
				var o = PuzzleUtils.tokens[t]
				if len(o)==1:
					o+=" "
				output += "(" + o + ")"
			output += "\n"
		%Label3.text = output
	else:
		puzzle=PuzzleUtils.Puzzle.new(slots, verts, 100)
		puzzle_done = false
		
	%Label2.text = str(puzzle.state)
	%Label.text = str(puzzle.iterations)
