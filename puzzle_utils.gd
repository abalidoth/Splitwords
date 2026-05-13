extends Node


const CHARS: int= 377
const BSIZE:int = 29
const NBLOCKS:int = 13
const FULLMASK: int = 2**BSIZE - 1

#var words: Dictionary

#var tags_to_word_id: Dictionary[Array, Array]

#var clue_table: Array[Array]




var tokens: Array[String]
const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

var word_data: DataResource# = load("res://word_data.tres")



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#var tags_file: FileAccess = FileAccess.open("res://data/tags_to_word_index.txt", FileAccess.READ)
	#var counter: int = 0
	#while tags_file.get_position() < tags_file.get_length():
		#counter += 1
		#var line = tags_file.get_csv_line()
		#var idx = int(line[0])
		#var tags = []
		#for i in line.slice(1):
			#tags.append(int(i))
		#if tags in tags_to_word_id:
			#tags_to_word_id[tags].append(idx)
		#else:
			#tags_to_word_id[tags] = [idx]
		#if counter%10000==0:
			#print(counter)
		
		
	
	#
	#
	#for i in range(2,16):
		#var words_file: FileAccess = FileAccess.open("res://data/tags_length_"+str(i)+".json", FileAccess.READ)
		#var json_t = words_file.get_as_text()
		#words[i] = JSON.parse_string(json_t)
		#print("len words ", len(words))
	
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


						
							
						
						
						
						
		
			
