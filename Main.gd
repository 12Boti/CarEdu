extends Spatial

onready var car := get_node("Car") as KinematicBody
onready var camera := get_node("Camera") as Camera

# how fast the camera and the car move
var speed := 20.0

func _process(delta: float):
	# move_and_slide handles `delta`
	car.move_and_slide(Vector3.FORWARD * speed)
	# normal `translate` would move it in the direction it's facing
	camera.global_translate(Vector3.FORWARD * speed * delta)
