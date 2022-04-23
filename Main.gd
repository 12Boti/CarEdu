extends Spatial

onready var car := get_node("Car") as KinematicBody
onready var camera := get_node("Camera") as Camera
onready var wheel_particles: Array = [get_node("Car/LeftParticles"), get_node("Car/RightParticles")]
onready var animation_player := get_node("AnimationPlayer") as AnimationPlayer

# how fast the camera and the car move
var speed := 20.0
# how fast the wheel particles move relative to the car
var wheel_particle_speed := 3.0

var lane_width := 3.0
var target_lane := 0
var min_lane := 0
var max_lane := 1

var x_accel := 0.0
var max_x_accel := 15.0

func _ready():
	car.translation	= target_lane_pos()

func _physics_process(delta: float):
	x_accel *= pow(0.05, delta)
	x_accel += (target_lane_pos().x - car.translation.x) * 30 * delta
	x_accel = clamp(x_accel, -max_x_accel, max_x_accel)
	# move_and_slide handles `delta`
	var current_velocity = car.move_and_slide(Vector3.FORWARD * speed + Vector3.RIGHT * x_accel)
	
	if car.translation == target_lane_pos():
		car.rotation.y = deg2rad(180) # car model is backwards
	else:
		car.look_at(car.translation + current_velocity * 10, Vector3.UP)
		car.rotation.y += deg2rad(180) # car model is backwards
	
	# also update camera in `_physics_process` so it doesn't flicker
	# normal `translate` would move it in the direction it's facing
	camera.global_translate(Vector3.FORWARD * speed * delta)
	for p in wheel_particles:
		var mat := (p as Particles).process_material as ParticlesMaterial
		mat.initial_velocity = speed - wheel_particle_speed

func _input(event: InputEvent):
	if event.is_action("change_lane_left") and target_lane > min_lane:
		target_lane -= 1
	if event.is_action("change_lane_right") and target_lane < max_lane:
		target_lane += 1

func target_lane_pos() -> Vector3:
	var offset := -lane_width/2 if max_lane - min_lane % 2 == 1 else 0.0
	return Vector3(target_lane * lane_width + offset, car.translation.y, car.translation.z)
	
