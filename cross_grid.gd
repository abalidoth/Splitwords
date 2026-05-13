extends Resource
class_name CrossGrid


enum GridState{WALL,UNFIXED, OPEN}

enum SingState{WALLED, SINGLE, OPEN}

@export var size: Vector2i
@export var grid: Dictionary[Vector2i,GridState] = {}
@export var slot_starts: Dictionary[int, Vector2i]
@export var across_slots: Array[int]
@export var down_slots: Array[int]
@export var across_slot_length: Dictionary[int, int]
@export var down_slot_length: Dictionary[int, int]
const RIGHT = Vector2i(1,0)
const DOWN = Vector2i(0,1)
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

func initialize(size_: Vector2i):
	size = size_
	for j in range(size.y):
		for i in range(size.x):
			grid[Vector2i(i,j)]=GridState.UNFIXED
			
func check_filled_lines() -> bool:
	for j in range(size.y):
		var has_empty: bool = false
		for i in range(size.x):
			if grid[Vector2i(i,j)] != GridState.WALL:
				has_empty = true
				break
		if not has_empty:
			return false
	for i in range(size.x):
		var has_empty: bool = false
		for j in range(size.y):
			if grid[Vector2i(i,j)] != GridState.WALL:
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
				if grid[v0+v]!=GridState.WALL:
					has_empty = true
					break
			if not has_empty:
				return false
	return true
	
func check_continuity() -> bool:
	var to_check: Array[Vector2i] = []
	var in_cont: Array[Vector2i] = []
	for j in range(size.y):
		for i in range(size.x):
			var v: Vector2i = Vector2i(i,j)
			if grid[v]!= GridState.WALL:
				to_check.append(v)
	in_cont.append(to_check.pop_back())
	
	var recheck = true
	while recheck:
		var new_check: Array[Vector2i] = []
		var new_cont : Array[Vector2i] = in_cont.duplicate_deep()
		recheck = false
		for v in to_check:
			var good = false
			for i in in_cont:
				if abs((v-i).x)+abs((v-i).y) == 1:
					recheck = true
					new_cont.append(v)
					good=true
					break
			if not good:
				new_check.append(v)
		to_check = new_check
		in_cont = new_cont
	if len(to_check)>0:
		return false
	else:
		return true
		
func check_singletons():
	var out: Array[Vector2i] = []
	for j in range(size.y):
		var sing_state:SingState = SingState.WALLED
		var last_coord: Vector2i
		for i in range(size.x):
			var v = Vector2i(i,j)
			var g = grid[v]
			if g == GridState.WALL:
				if sing_state == SingState.WALLED:
					pass
				elif sing_state == SingState.SINGLE:
					out.append(last_coord)
					sing_state = SingState.WALLED
				else: #SingState == SingState.OPEN:
					sing_state = SingState.WALLED
			else: # g == GridState.UNFIXED or g==GridState.OPEN:
				if sing_state == SingState.WALLED:
					last_coord = v
					sing_state = SingState.SINGLE
				else: #sing_state == SingState.SINGLE or sing_state == SingState.OPEN:
					sing_state = SingState.OPEN
		#check the end boundary
		if sing_state == SingState.SINGLE:
			out.append(last_coord)
			
	#repeat for columns
	for i in range(size.x):
		var sing_state:SingState = SingState.WALLED
		var last_coord: Vector2i
		for j in range(size.y):
			var v = Vector2i(i,j)
			var g = grid[v]
			if g == GridState.WALL:
				if sing_state == SingState.WALLED:
					pass
				elif sing_state == SingState.SINGLE:
					out.append(last_coord)
					sing_state = SingState.WALLED
				else: #SingState == SingState.OPEN:
					sing_state = SingState.WALLED
			else: # g == GridState.UNFIXED or g==GridState.OPEN:
				if sing_state == SingState.WALLED:
					last_coord = v
					sing_state = SingState.SINGLE
				else: #sing_state == SingState.SINGLE or sing_state == SingState.OPEN:
					sing_state = SingState.OPEN
		#check the end boundary
		if sing_state == SingState.SINGLE:
			out.append(last_coord)
	return out
	
func print_grid(numbers:bool = false) -> String:
	var line = ""

	for i in range(size.x*3+1):
		line+="-"
	var s = ""
	s+= line + "\n"
	for j in range(size.y):
		for i in range(size.x):
			s+="|"
			var v = Vector2i(i,j)
			if grid[v] == GridState.WALL:
				s += "##"
			elif grid[v] == GridState.OPEN:
				if numbers:
					var n = slot_starts.find_key(v)
					if n != null:
						s += "%2d"%n
					else:
						s+= "  "
				else:
					s += "  "
			else:
				s += "??"
		s += "|\n"
		s += line
		s+="\n"
	return s
				

func generate_grid(symmetric: bool = true) -> void:
	var checkpoint: Dictionary[Vector2i, GridState]
	var last_block : Vector2i
	var processing : bool = true
	var broken: bool = false
	
	while processing:
		#print(print_grid())
		var options : Array[Vector2i] = []
		for j in range(size.y):
			for i in range(size.x):
				var vec: Vector2i = Vector2i(i,j)
				if grid[vec] == GridState.UNFIXED:
					options.append(vec)
		if len(options) == 0:
			processing = false
			break
		var option: Vector2i = options.pick_random()
		checkpoint = grid.duplicate_deep()
		grid[option]=GridState.WALL
		if symmetric:
			grid[size - Vector2i(1,1) - option] = GridState.WALL
		last_block = option
		
		var finished_sing : bool = false
		while not finished_sing:
			var sings: Array[Vector2i] = check_singletons()
			if len(sings) == 0:
				finished_sing = true
				break
			for v in sings:
				if grid[v] == GridState.OPEN:
					broken = true
					break
				elif grid[v] == GridState.UNFIXED:
					grid[v] = GridState.WALL
				else:
					pass
			if broken:
				break
		if not broken and not check_filled_lines():
			broken = true
		if not broken and not check_3x3_block():
			broken = true
		if not broken and not check_continuity():
			broken = true
		if broken:
			grid = checkpoint.duplicate_deep()
			grid[last_block] = GridState.OPEN
			if symmetric:
				grid[size - Vector2i(1,1) - last_block] = GridState.OPEN
	#print(print_grid())
	
func generate_slots() -> void:
	var clue_number: int = 1
	for j in range(size.y):
		for i in range(size.x):
			var v = Vector2i(i,j)
			if grid[v] == GridState.OPEN:
				var flagged: bool = false
				var up = v - DOWN
				var left = v - RIGHT
				if left not in grid or grid[left] == GridState.WALL:
					flagged = true
					slot_starts[clue_number] = v
					across_slots.append(clue_number)
					
					var cursor = v
					var l = 0
					while cursor in grid and grid[cursor] == GridState.OPEN:
						l+=1
						cursor += RIGHT
					across_slot_length[clue_number] = l
				if up not in grid or grid[up] == GridState.WALL:
					if not flagged:
						flagged = true
						slot_starts[clue_number] = v
					down_slots.append(clue_number)
					
					var cursor = v
					var l = 0
					while cursor in grid and grid[cursor] == GridState.OPEN:
						l+=1
						cursor += DOWN
					down_slot_length[clue_number] = l
				if flagged:
					clue_number += 1
