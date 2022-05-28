class_name Boxes
extends Spatial

const box_count := 3

var car: PhysicsBody
var camera: Spatial
var collided := false
var _text: String

signal hit
signal miss

func _ready():
	(get_node("Sprite3D") as Sprite3D).texture = (get_node("Sprite3D/Viewport") as Viewport).get_texture()
	(get_node("Sprite3D/Viewport/Label") as Label).text = _text
	for i in range(box_count):
		var node := get_node("Box" + str(i + 1)) as RigidBody
		if node.connect("body_entered", self, "collision") != OK:
			print("box signal connect error")
	translate(Vector3(randf() * 2 - 1, 0, 0) * 2)

func _process(_delta):
	for i in range(box_count):
		var node := get_node("Box" + str(i + 1)) as RigidBody
		if node.global_transform.origin.z < camera.translation.z + 10:
			return
	if not collided:
		emit_signal("miss")
	queue_free()

func set_text(t: String):
	_text = t

func collision(node: Node):
	if collided or node != car:
		return
	collided = true
	emit_signal("hit")

func set_color(color: Color):
	var mat := SpatialMaterial.new()
	mat.albedo_color = color
	for i in range(box_count):
		var node := get_node("Box" + str(i + 1) + "/MeshInstance") as MeshInstance
		node.material_override = mat
