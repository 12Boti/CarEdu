extends Spatial

onready var game := get_node("Game") as Game
onready var start_menu := get_node("StartMenu") as Control
onready var file_dialog := get_node("StartMenu/FileDialog") as FileDialog
onready var load_error_dialog := get_node("StartMenu/LoadErrorDialog") as AcceptDialog
onready var load_error_dialog_label := get_node("StartMenu/LoadErrorDialog/Message") as Label
onready var start_button := get_node("StartMenu/VBoxContainer/StartButton") as Button
onready var level_select_button := get_node("StartMenu/VBoxContainer/LevelSelectButton") as Button

var level_data = null

func _on_StartButton_pressed():
	match level_data.type:
		"collect":
			var boxes := []
			for b in level_data.right:
				boxes.append({"text": b, "right": true})
			for b in level_data.wrong:
				boxes.append({"text": b, "right": false})
			boxes.shuffle()
			var t := 10.0
			for b in boxes:
				var node = game.make_boxes(t, Game.Side.LEFT, b.text)
				node.connect("hit", game, "good_answer" if b.right else "bad_answer")
				node.connect("miss", game, "bad_answer" if b.right else "good_answer")
				game.call_deferred("add_child", node)
				t += 5.0
		var t:
			if typeof(t) == TYPE_STRING:
				show_error("Unknown level type '" + t + "'")
			else:
				show_error("Invalid level type")
			return
	start_menu.visible = false
	game.state = Game.State.STARTING

func _on_LevelSelectButton_pressed():
	file_dialog.popup_centered_ratio()

func _on_FileDialog_file_selected(path: String):
	var file := File.new()
	if file.open(path, File.READ) != OK:
		show_error("Unable to open file")
		return
	var text_content := file.get_as_text()
	file.close()
	var json_result := JSON.parse(text_content)
	if json_result.error != OK:
		show_error("Line " + str(json_result.error_line + 1) + ":\n" + json_result.error_string)
		return
	level_data = json_result.result
	level_select_button.text = path
	start_button.disabled = false

func show_error(msg: String):
	load_error_dialog_label.text = msg
	load_error_dialog.popup_centered()
	
