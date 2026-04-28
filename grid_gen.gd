extends Node


class CrossGrid:
	var size: Vector2i
	var grid: Dictionary[Vector2i,int] = {}
	const array_3 = [
		Vector2i(0,0),
		Vector2i(0,1),
		Vector2i(0,2),
		Vector2i(1,0),
		Vector2i(1,1),
		Vector2i(1,2),
		Vector2i(2,0),
		Vector2i(2,1),
		Vector2i(2,2),
	]
	func _init(size_: Vector2i):
		size = size_
		for j in range(size.y):
			for i in range(size.x):
				grid[Vector2i(i,j)]=0
				
	func check_filled_lines() -> bool:
		for j in range(size.y):
			var has_empty: bool = false
			for i in range(size.x):
				if grid[Vector2i(i,j)] != -1:
					has_empty = true
					break
			if not has_empty:
				return false
		for i in range(size.x):
			var has_empty: bool = false
			for j in range(size.y):
				if grid[Vector2i(i,j)] != -1:
					has_empty = true
					break
			if not has_empty:
				return false
		return true
		
	func check_3x3_block() -> bool:
		for i in range(size.x-2):
			for j in range(size.y-2):
				var has_empty: bool = false
				var v0 : Vector2i = Vector2i(i,j)
				for v in array_3:
					if grid[v0+v]!=-1:
						has_empty = true
						break
				if not has_empty:
					return false
		return true
		

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
