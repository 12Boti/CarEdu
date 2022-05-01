class_name Ground
extends Spatial

signal create_next

export var camera_path: NodePath
onready var camera := get_node(camera_path) as Spatial

var first := true
var next: Ground

func _ready():
	assert(connect("create_next", self, "_on_create_next") == OK)
	next = duplicate(DUPLICATE_SCRIPTS) as Ground
	next.first = false
	next.translate(Vector3(0, 0, -128))
	if first:
		_on_create_next()

func _process(_delta):
	if translation.z > camera.translation.z + 64:
		next.emit_signal("create_next")
		queue_free()

func _on_create_next():
	get_parent().call_deferred("add_child", next)
