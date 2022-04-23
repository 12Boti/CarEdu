extends Spatial

onready var car := get_node("Car") as KinematicBody
onready var camera := get_node("Camera") as Camera
onready var wheel_particles: Array = [get_node("Car/LeftParticles"), get_node("Car/RightParticles")]

# how fast the camera and the car move
var speed := 20.0
# how fast the wheel particles move relative to the car
var wheel_particle_speed := 3.0

func _process(delta: float):
	# normal `translate` would move it in the direction it's facing
	camera.global_translate(Vector3.FORWARD * speed * delta)
	for p in wheel_particles:
		var mat := (p as Particles).process_material as ParticlesMaterial
		mat.initial_velocity = speed - wheel_particle_speed

func _physics_process(_delta: float):
	# move_and_slide handles `delta`
	var _new_velocity = car.move_and_slide(Vector3.FORWARD * speed)
