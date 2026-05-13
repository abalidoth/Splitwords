extends Node2D

var puzzle: Puzzle
var puzzle_done = false
var slots: Array[Array]=[]
var verts: Array[bool]=[]
var size: Vector2i = Vector2i(8,8)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	puzzle=Puzzle.new(size,100,true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	for loop in range(1):
		%ProgressBar.value = puzzle.completion*100
		if puzzle.state != Puzzle.AlgState.FINISHED:
			puzzle.update()
		elif not puzzle_done:
			puzzle_done = true
			var output = ""
			for j in range(size.y):
				for i in range(size.x):
					var v = Vector2i(i,j)
					if v not in puzzle.completed_puzzle:
						output += "####"
					else:
						var t = puzzle.completed_puzzle[v]
						var o = PuzzleUtils.tokens[t]
						if len(o)==1:
							o+=" "
						output += "(" + o + ")"
				output += "\n"
			%Label3.text = output
		else:
			puzzle=Puzzle.new(size,100,true)
			puzzle_done = false
			
		%Label2.text = str(puzzle.state)
		%Label.text = str(puzzle.iterations)
