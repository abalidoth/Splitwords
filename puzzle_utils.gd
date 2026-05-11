extends Node


const CHARS: int= 377
const BSIZE:int = 29
const NBLOCKS:int = 13
const FULLMASK: int = 2**BSIZE - 1

var words: Dictionary

var tags_to_word_id: Dictionary[Array, Array]

var clue_table: Array[Array]

enum AlgState{SETTLING, SETTLED, NEEDS_BACKTRACK, GET_CLUES, FINISHED}


enum SingState{WALLED, SINGLE, OPEN}
enum GridState{WALL,UNFIXED, OPEN}

var tokens: Array[String]
const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tags_file: FileAccess = FileAccess.open("res://data/tags_to_word_index.txt", FileAccess.READ)
	var counter: int = 0
	while tags_file.get_position() < tags_file.get_length():
		counter += 1
		var line = tags_file.get_csv_line()
		var idx = int(line[0])
		var tags = []
		for i in line.slice(1):
			tags.append(int(i))
		if tags in tags_to_word_id:
			tags_to_word_id[tags].append(idx)
		else:
			tags_to_word_id[tags] = [idx]
		if counter%10000==0:
			print(counter)
		
		
	
	
	
	for i in range(2,16):
		var words_file: FileAccess = FileAccess.open("res://data/tags_length_"+str(i)+".json", FileAccess.READ)
		var json_t = words_file.get_as_text()
		words[i] = JSON.parse_string(json_t)
		print("len words ", len(words))
	
	for i in range(len(alphabet)):
		tokens.append(alphabet[i])
	for i in range(len(alphabet)):
		for j in range(i, len(alphabet)):
			tokens.append(alphabet[i]+alphabet[j])
	print(len(tokens)," ",13*29)
	
	

func full_mask() -> Array[int]:
		var out: Array[int] = []
		out.resize(NBLOCKS)
		out.fill(FULLMASK)
		return out

func blank_mask() -> Array[int]:
		var out: Array[int] = []
		out.resize(NBLOCKS)
		out.fill(0)
		return out



func mask_and(a:Array[int], b:Array[int]):
	var out = []
	for i in range(NBLOCKS):
		out.append(a[i]&b[i])
	return out
	
func mask_or(a:Array[int], b:Array[int]):
	var out = []
	for i in range(NBLOCKS):
		out.append(a[i]|b[i])
	return out


class CrossGrid:
	var size: Vector2i
	var grid: Dictionary[Vector2i,GridState] = {}
	var slot_starts: Dictionary[int, Vector2i]
	var across_slots: Array[int]
	var down_slots: Array[int]
	var across_slot_length: Dictionary[int, int]
	var down_slot_length: Dictionary[int, int]
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
	func _init(size_: Vector2i):
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
						
							
						
						
						
						
		
			


				
				
class Puzzle:
	
	const RIGHT = Vector2i(1,0)
	const DOWN = Vector2i(0,1)
	
	var completion: float
	
	var size: Vector2i
	var grid: CrossGrid
	var symmetric: bool
	var slots: Array[Array]
	var slot_vertical: Array[bool]
	var squares: Array[Vector2i]
	var square_to_slot: Dictionary[Vector2i, Array]
	var char_masks: Dictionary[Vector2i, Array]
	var update_queue: Array
	var backtrack_choices: Array
	
	var obscurity: int #between 20 and 100
	
	var completed_puzzle:Dictionary[Vector2i, int]
	
	var state = AlgState.SETTLING
	
	var iterations: int = 0
	
	func _init(size_: Vector2i, obscurity_: int, symmetric_: bool) -> void:
		completion = 0.0
		size = size_
		obscurity = obscurity_
		symmetric = symmetric_
		grid = CrossGrid.new(size)
		grid.generate_grid(symmetric)
		grid.generate_slots()
		
		slots = []
		slot_vertical = []
		
		for ac in grid.across_slots:
			var cursor = grid.slot_starts[ac]
			var out = []
			for i in range(grid.across_slot_length[ac]):
				out.append(cursor)
				cursor+= RIGHT
			slots.append(out)
			slot_vertical.append(false)
			
		
		for dw in grid.down_slots:
			var cursor = grid.slot_starts[dw]
			var out = []
			for i in range(grid.down_slot_length[dw]):
				out.append(cursor)
				cursor+= DOWN
			slots.append(out)
			slot_vertical.append(true)
		
		
		iterations=0
		squares = []
		char_masks = {}
		square_to_slot = {}
		update_queue = []
		backtrack_choices = []
		for i in range(len(slots)):
			var sl: Array = slots[i]
			var v: bool = slot_vertical[i]
			update_queue.append(i)
			for sq in sl:
				print(sq, " ", v)
				if sq not in squares:
					squares.append(sq)
					square_to_slot[sq] = [null, null]
					square_to_slot[sq][int(v)] = i
					char_masks[sq] = full_mask()
				else:
					assert(square_to_slot[sq][int(v)] == null)
					square_to_slot[sq][int(v)] = i
		state = AlgState.SETTLING
			
	
	#func old_init(slots_: Array[Array], slot_vertical_: Array[bool], obscurity_: int):
		#iterations=0
		#assert(len(slots_)==len(slot_vertical_))
		#slots = slots_
		#slot_vertical = slot_vertical_
		#obscurity=obscurity_
		#squares = []
		#update_queue = []
		#backtrack_choices = []
		#for i in range(len(slots)):
			#var sl: Array[Vector2i] = slots[i]
			#var v: bool = slot_vertical[i]
			#update_queue.append(i)
			#for sq in sl:
				#if sq not in squares:
					#squares.append(sq)
					#square_to_slot[sq] = [null, null]
					#square_to_slot[sq][int(v)] = i
					#char_masks[sq] = full_mask()
				#else:
					#assert(square_to_slot[sq][int(v)] == null)
					#square_to_slot[sq][int(v)] = i
		#state = AlgState.SETTLING
					
	func update() -> void:
		
		for sq in squares:
			if is_mask_zero(char_masks[sq]):
				print(sq, char_masks[sq])
				assert(false)
		
		iterations += 1
		
		var potential = 0.0
		var currently_open = 0.0
		for sq in squares:
			var ch = char_masks[sq]
			currently_open += len(mask_to_list(ch))
			potential += CHARS
		completion = 1-currently_open/potential
		print(currently_open," ",potential)
		
		if state == AlgState.NEEDS_BACKTRACK:
			if len(backtrack_choices)== 0:
				_init(size, obscurity, symmetric) #just restart the process, something went wrong
				return
			var backtrack = backtrack_choices.pop_back()
			var bt_char_masks:Dictionary[Vector2i,Array] = backtrack[0].duplicate_deep()
			var bt_last_choice: Vector2i = backtrack[1]
			var bt_last_char: int = backtrack[2]
			var sq_with_choices: Array[Vector2i] = []
			var excluded_mask = exclude_mask(bt_char_masks[bt_last_choice], bt_last_char)
			print(mask_to_list(bt_char_masks[bt_last_choice])," ",bt_last_char)
			if is_mask_zero(excluded_mask):
				#Unsolvable. Backtrack.
				return
			bt_char_masks[bt_last_choice] = excluded_mask.duplicate_deep()
			for i in bt_char_masks.keys():
				if is_mask_zero(bt_char_masks[i]):
					#This should not be happening.
					assert(false)
				if not is_mask_singleton(bt_char_masks[i]):
					sq_with_choices.append(i)
			if not sq_with_choices:
				#I think this is bad. Don't reset backtrack flag, just move back to previous choice.
				return
			var new_choice_sq: Vector2i = sq_with_choices.pick_random()
			var new_choice_char: int = mask_to_list(bt_char_masks[new_choice_sq]).pick_random()
			backtrack_choices.append([bt_char_masks.duplicate_deep(),new_choice_sq, new_choice_char])
			bt_char_masks[new_choice_sq] = single_mask(new_choice_char)
			char_masks = bt_char_masks.duplicate_deep()
			update_queue = square_to_slot[new_choice_sq].duplicate_deep()+square_to_slot[bt_last_choice].duplicate_deep()
			state = AlgState.SETTLING
			
		elif state == AlgState.SETTLING:
				
			if not update_queue:
				state = AlgState.SETTLED
				return
			var slot_idx:int = update_queue.pop_front()
			var slot: Array = slots[slot_idx]
			var vert: bool = slot_vertical[slot_idx]
			var slot_masks: Array[Array] = []
			var cumulative_mask:Array[Array] = []
			for i in range(len(slot)):
				cumulative_mask.append(blank_mask())
			for i in slot:
				slot_masks.append(char_masks[i])
			for word_and_pct:Array in PuzzleUtils.words[len(slot)]:
				#str(len(slot)) because of the way the json imports
				var word = word_and_pct[0]
				var pct = word_and_pct[1]
				if pct >= (100.0-obscurity)/100.0:
					if check_slot(slot_masks, word):
						update_mask_with_word(cumulative_mask, word)
			if not slot_mask_is_valid(cumulative_mask):
				#we have broken something. backtrack!
				state = AlgState.NEEDS_BACKTRACK
				return
			var changes: Array[bool] = blocks_changed(cumulative_mask,slot_masks)
			for i in len(changes):
				if changes[i]:
					char_masks[slot[i]]=cumulative_mask[i]
					var cross_slot: int = square_to_slot[slot[i]][int(not vert)]
					if cross_slot not in update_queue:
						update_queue.append(cross_slot)
				
				
		elif state == AlgState.SETTLED:
			var sq_with_choices:Array[Vector2i] = []
			for i in char_masks.keys():
				if not is_mask_singleton(char_masks[i]):
					sq_with_choices.append(i)
			if not sq_with_choices:
				#Everything is down to one choice. We're done!
				state = AlgState.FINISHED
				for i in char_masks.keys():
					var l = mask_to_list(char_masks[i])
					assert(len(l)==1)
					completed_puzzle[i]=l[0]
				return
			var new_choice_sq: Vector2i = sq_with_choices.pick_random()
			var new_choice_list: Array[int] = mask_to_list(char_masks[new_choice_sq])
			var new_choice_char: int = new_choice_list.pick_random()
			backtrack_choices.append([char_masks.duplicate_deep(),new_choice_sq, new_choice_char])
			char_masks[new_choice_sq] = single_mask(new_choice_char)
			update_queue = square_to_slot[new_choice_sq].duplicate_deep()
			state = AlgState.SETTLING
			
		elif state == AlgState.FINISHED:
			return
			
		elif state == AlgState.GET_CLUES:
			pass
		else:
			assert(false) #something bad has happened with state
				
				
				
			
	func check_slot(slot_masks:Array[Array], word:Array)-> bool:
		assert(len(slot_masks)==len(word))
		for i in range(len(slot_masks)):
			var mask:Array[int] = slot_masks[i]
			var character: int = word[i]
			@warning_ignore("integer_division")
			var block: int = character/BSIZE
			var digit: int = character%BSIZE
			if mask[block]&(2**digit):
				pass
			else:
				return false
		return true
	
	func update_mask_with_word(slot_masks:Array[Array], word:Array)-> void:
		assert(len(slot_masks)==len(word))
		for i in len(slot_masks):
			var character: int = word[i]
			@warning_ignore("integer_division")
			var block: int = character/BSIZE
			var digit: int = character%BSIZE
			slot_masks[i][block] = slot_masks[i][block]|(2**digit)
			
	func slot_mask_is_valid(slot_masks:Array[Array]) -> bool:
		for m in slot_masks:
			var valid = false
			for b in m:
				if b:
					valid = true
					break
			if not valid:
				return false
		return true
	
	func full_mask() -> Array[int]:
		var out: Array[int] = []
		out.resize(NBLOCKS)
		out.fill(FULLMASK)
		return out
			
	
	func blank_mask() -> Array[int]:
		var out: Array[int] = []
		out.resize(NBLOCKS)
		out.fill(0)
		return out
		
	func single_mask(n: int) -> Array[int]:
		var out: Array[int] = []
		out.resize(NBLOCKS)
		out.fill(0)
		@warning_ignore("integer_division")
		var block: int = n/BSIZE
		var digit: int = n%BSIZE
		out[block] = 2**digit
		return out
		
	func is_power_two(i:int) -> bool:
		if i==0 or i==1:
			return true
		elif i%2 == 1:
			return false
		else:
			@warning_ignore("integer_division")
			return is_power_two(i/2)

	func is_mask_zero(mask:Array[int]) -> bool:
		return mask.all(func(x):return x==0)

	func is_mask_singleton(mask:Array[int]) -> bool:
		var has_value: bool = false
		for i in mask:
			if i:
				if has_value:
					return false
				else:
					if is_power_two(i):
						has_value= true
					else:
						return false
		return has_value
		
	func exclude_mask(mask:Array[int], character: int) -> Array[int]:
		var out: Array[int] = []
		@warning_ignore("integer_division")
		var block: int = character/BSIZE
		var digit: int = character%BSIZE
		for i in range(NBLOCKS):
			if block == i:
				out.append(mask[i]&(FULLMASK-2**digit))
			else:
				out.append(mask[i])
		return out
		
	func mask_to_list(mask:Array[int]) -> Array[int]:
		var out:Array[int] = []
		for b in range(NBLOCKS):
			var work: int = mask[b]
			for digit in range(BSIZE):
				if work%2:
					out.append(b*BSIZE+digit)
				@warning_ignore("integer_division")
				work = work/2
		return out
	
	func blocks_changed(masks_1:Array[Array], masks_2:Array[Array]) -> Array[bool]:
		assert(len(masks_1) == len(masks_2))
		var changes: Array[bool] = []
		for m in range(len(masks_1)):
			var changed : bool = false
			for b in range(NBLOCKS):
				if masks_1[m][b]!=masks_2[m][b]:
					changed = true
					break
			changes.append(changed)
		return changes
				
		
