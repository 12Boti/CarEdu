extends Spatial

onready var game := get_node("Game") as Game
onready var start_menu := get_node("StartMenu") as Control
onready var file_dialog := get_node("StartMenu/FileDialog") as FileDialog
onready var load_error_dialog := get_node("StartMenu/LoadErrorDialog") as AcceptDialog
onready var load_error_dialog_label := get_node("StartMenu/LoadErrorDialog/Message") as Label
onready var start_button := get_node("StartMenu/VBoxContainer/StartButton") as Button
onready var level_select_button := get_node("StartMenu/VBoxContainer/LevelSelectButton") as Button
onready var animation_player := get_node("AnimationPlayer") as AnimationPlayer
onready var tween := get_node("Tween") as Tween
onready var hud := get_node("HUD") as Control
onready var task_label := get_node("HUD/Task") as Label
onready var darken := get_node("HUD/Darken") as ColorRect
onready var score_label := get_node("HUD/Score") as Label

var level_data = null
var questions_left: int
var score := 0

func _on_StartButton_pressed():
	match level_data.type:
		"collect":
			var boxes := []
			for b in level_data.right:
				boxes.append({"text": b, "right": true})
			for b in level_data.wrong:
				boxes.append({"text": b, "right": false})
			questions_left = boxes.size()
			boxes.shuffle()
			var t := 10.0
			for b in boxes:
				var node = game.make_boxes(t, Game.Side.LEFT if randf() < 0.5 else Game.Side.RIGHT, b.text)
				node.connect("hit", self, "good_answer" if b.right else "bad_answer")
				node.connect("miss", self, "bad_answer" if b.right else "good_answer")
				game.call_deferred("add_child", node)
				t += 5.0
		var t:
			if typeof(t) == TYPE_STRING:
				show_error("Unknown level type '" + t + "'")
			else:
				show_error("Invalid level type")
			return
	start_menu.hide()
	game.state = Game.State.STARTING
	hud.show()
	var task_show_time := 3.0
	tween.interpolate_property(hud, "modulate:a", 0, 1, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0)
	task_label.text = level_data.text
	# to update rect_size
	task_label.hide()
	task_label.show()
	task_label.margin_left = -task_label.rect_size.x/2
	task_label.margin_top = -task_label.rect_size.y/2
	tween.interpolate_property(task_label, "margin_left", null, 10, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 1 + task_show_time)
	tween.interpolate_property(task_label, "margin_top", null, 10, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 1 + task_show_time)
	tween.interpolate_property(task_label, "anchor_left", null, 0, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 1 + task_show_time)
	tween.interpolate_property(task_label, "anchor_top", null, 0, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 1 + task_show_time)
	tween.interpolate_property(task_label, "rect_scale", null, Vector2.ONE * 0.8, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 1 + task_show_time)
	tween.interpolate_property(darken, "modulate:a", null, 0, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 1 + task_show_time)
	tween.start()

func bad_answer():
	questions_left -= 1
	score -= 1
	animation_player.play("-1")
	score_label.text = "Score: " + str(score)
	if questions_left == 0:
		finished()

func good_answer():
	questions_left -= 1
	score += 1
	animation_player.play("+1")
	score_label.text = "Score: " + str(score)
	if questions_left == 0:
		finished()

func finished():
	yield(get_tree().create_timer(1), "timeout")
	tween.interpolate_property(darken, "modulate:a", null, 1, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0)
	tween.interpolate_property(score_label, "anchor_left", null, 0.5, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0)
	tween.interpolate_property(score_label, "anchor_top", null, 0.5, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0)
	tween.interpolate_property(score_label, "anchor_right", null, 0.5, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0)
	tween.interpolate_property(score_label, "anchor_bottom", null, 0.5, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0)
	tween.interpolate_property(score_label, "margin_right", null, score_label.rect_size.x/2, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0)
	tween.interpolate_property(score_label, "margin_bottom", null, score_label.rect_size.y/2, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0)
	tween.start()
	yield(get_tree().create_timer(5), "timeout")
	get_tree().reload_current_scene()

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
