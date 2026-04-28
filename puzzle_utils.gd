extends Node


const CHARS: int= 377
const BSIZE:int = 29
const NBLOCKS:int = 13
const FULLMASK: int = 2**BSIZE - 1

var words: Dictionary

enum alg_state{SETTLING, SETTLED, NEEDS_BACKTRACK, FINISHED}

var tokens: Array[String]
const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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


	



				
				
class Puzzle:
	var slots: Array[Array]
	var slot_vertical: Array[bool]
	var squares: Array[Vector2i]
	var square_to_slot: Dictionary[Vector2i, Array]
	var char_masks: Dictionary[Vector2i, Array]
	var update_queue: Array
	var backtrack_choices: Array
	
	var obscurity: int #between 20 and 100
	
	var completed_puzzle:Dictionary[Vector2i, int]
	
	var state = alg_state.SETTLING
	
	var iterations: int = 0
	
	func _init(slots_: Array[Array], slot_vertical_: Array[bool], obscurity_: int):
		iterations=0
		assert(len(slots_)==len(slot_vertical_))
		slots = slots_
		slot_vertical = slot_vertical_
		obscurity=obscurity_
		squares = []
		update_queue = []
		backtrack_choices = []
		for i in range(len(slots)):
			var sl: Array[Vector2i] = slots[i]
			var v: bool = slot_vertical[i]
			update_queue.append(i)
			for sq in sl:
				if sq not in squares:
					squares.append(sq)
					square_to_slot[sq] = [null, null]
					square_to_slot[sq][int(v)] = i
					char_masks[sq] = full_mask()
				else:
					assert(square_to_slot[sq][int(v)] == null)
					square_to_slot[sq][int(v)] = i
		state = alg_state.SETTLING
					
	func update() -> void:
		iterations += 1
		if state == alg_state.NEEDS_BACKTRACK:
			if len(backtrack_choices)== 0:
				_init(slots, slot_vertical, obscurity) #just restart the process, something went wrong
				return
			var backtrack = backtrack_choices.pop_back()
			var bt_char_masks:Dictionary[Vector2i,Array] = backtrack[0]
			var bt_last_choice: Vector2i = backtrack[1]
			var bt_last_char: int = backtrack[2]
			var sq_with_choices: Array[Vector2i] = []
			var excluded_mask = exclude_mask(bt_char_masks[bt_last_choice], bt_last_char)
			bt_char_masks[bt_last_choice] = excluded_mask
			for i in bt_char_masks.keys():
				if is_mask_zero(char_masks[i]):
					#Unsolvable state. Backtrack.
					return
				if not is_mask_singleton(bt_char_masks[i]):
					sq_with_choices.append(i)
			if not sq_with_choices:
				#I think this is bad. Don't reset backtrack flag, just move back to previous choice.
				return
			var new_choice_sq: Vector2i = sq_with_choices.pick_random()
			var new_choice_char: int = mask_to_list(bt_char_masks[new_choice_sq]).pick_random()
			bt_char_masks[new_choice_sq] = single_mask(new_choice_char)
			backtrack_choices.append([bt_char_masks,new_choice_sq, new_choice_char])
			update_queue = square_to_slot[new_choice_sq].duplicate_deep()+square_to_slot[bt_last_choice].duplicate_deep()
			state = alg_state.SETTLING
			
		elif state == alg_state.SETTLING:
			if not update_queue:
				state = alg_state.SETTLED
				return
			var slot_idx:int = update_queue.pop_front()
			var slot: Array[Vector2i] = slots[slot_idx]
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
				state = alg_state.NEEDS_BACKTRACK
			var changes: Array[bool] = blocks_changed(cumulative_mask,slot_masks)
			for i in len(changes):
				if changes[i]:
					char_masks[slot[i]]=cumulative_mask[i]
					var cross_slot: int = square_to_slot[slot[i]][int(not vert)]
					if cross_slot not in update_queue:
						update_queue.append(cross_slot)
				
				
		elif state == alg_state.SETTLED:
			var sq_with_choices:Array[Vector2i] = []
			for i in char_masks.keys():
				if not is_mask_singleton(char_masks[i]):
					sq_with_choices.append(i)
			if not sq_with_choices:
				#Everything is down to one choice. We're done!
				state = alg_state.FINISHED
				for i in char_masks.keys():
					var l = mask_to_list(char_masks[i])
					assert(len(l)==1)
					completed_puzzle[i]=l[0]
				return
			var new_choice_sq: Vector2i = sq_with_choices.pick_random()
			var new_choice_list: Array[int] = mask_to_list(char_masks[new_choice_sq])
			var new_choice_char: int = new_choice_list.pick_random()
			char_masks[new_choice_sq] = single_mask(new_choice_char)
			backtrack_choices.append([char_masks,new_choice_sq, new_choice_char])
			update_queue = square_to_slot[new_choice_sq].duplicate_deep()
			state = alg_state.SETTLING
			
		elif state == alg_state.FINISHED:
			return
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
				
		
