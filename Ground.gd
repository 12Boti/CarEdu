class_name Ground
extends Spatial

signal create_next

export var camera_path: NodePath
onready var camera := get_node(camera_path) as Spatial

var first := true
var next: Ground

func _ready():
	var err := connect("create_next", self, "_on_create_next")
	assert(err == OK)
	next = duplicate(DUPLICATE_SCRIPTS) as Ground
	next.first = false
	next.translate(Vector3.FORWARD)
	if first:
		_on_create_next()

func _process(_delta):
	if translation.z > camera.translation.z + scale.z:
		next.emit_signal("create_next")
		queue_free()

func _on_create_next():
	get_parent().call_deferred("add_child", next)
