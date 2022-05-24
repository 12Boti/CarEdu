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
	start_menu.visible = false
	game.state = Game.State.STARTING

func _on_LevelSelectButton_pressed():
	file_dialog.popup_centered_ratio()

func _on_FileDialog_file_selected(path: String):
	var file := File.new()
	if file.open(path, File.READ) != OK:
		load_error_dialog_label.text = "Unable to open file"
		load_error_dialog.popup_centered()
		return
	var text_content := file.get_as_text()
	file.close()
	var json_result := JSON.parse(text_content)
	if json_result.error != OK:
		load_error_dialog_label.text = (
			"Line " + str(json_result.error_line + 1) + ":\n" + json_result.error_string
		)
		load_error_dialog.popup_centered()
		return
	level_data = json_result.result
	level_select_button.text = path
	start_button.disabled = false
