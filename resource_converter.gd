extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var data = DataResource.new()
	
	var tags_file: FileAccess = FileAccess.open("res://data/tags_to_word_index.txt", FileAccess.READ)
	var counter: int = 0
	while tags_file.get_position() < tags_file.get_length():
		counter += 1
		var line = tags_file.get_csv_line()
		var idx = int(line[0])
		var tags = []
		for i in line.slice(1):
			tags.append(int(i))
		if tags in data.tags_to_word_id:
			data.tags_to_word_id[tags].append(idx)
		else:
			data.tags_to_word_id[tags] = [idx]
		if counter%10000==0:
			print(counter)
	
	for i in range(2,16):
		print(i)
		var words_file: FileAccess = FileAccess.open("res://data/tags_length_"+str(i)+".json", FileAccess.READ)
		var json_t = words_file.get_as_text()
		data.words[i] = JSON.parse_string(json_t)
		
	var clues_file: FileAccess = FileAccess.open("res://clues_clean.csv", FileAccess.READ)
	counter = 0
	var _waste = tags_file.get_csv_line() #kill the header
	while clues_file.get_position()< clues_file.get_length():
		counter += 1
		var line = clues_file.get_csv_line()
		if len(line)==1:
			continue
		var idx = int(line[0])
		var word = line[1]
		var clue_list = line.slice(2,12)
		var clue_obscurity = line[-1]
		data.word_id_to_clues[idx] = [word, clue_list, clue_obscurity]
		if counter%10000 ==0:
			print(counter)
			
	ResourceSaver.save(data, "word_data.tres")
	print("done!")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
