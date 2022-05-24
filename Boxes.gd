class_name Boxes
extends Spatial

var _text: String

func _ready():
	(get_node("Sprite3D") as Sprite3D).texture = (get_node("Sprite3D/Viewport") as Viewport).get_texture()
	(get_node("Sprite3D/Viewport/Label") as Label).text = _text

func set_text(t: String):
	_text = t
