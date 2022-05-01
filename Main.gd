tool
extends Spatial

onready var car := get_node("Car") as KinematicBody
onready var camera := get_node("Camera") as Camera
onready var ground_mesh := (get_node("Ground/MeshInstance") as MeshInstance).mesh as PlaneMesh
onready var road_shader := ground_mesh.surface_get_material(0) as ShaderMaterial

# how fast the camera and the car move forward
var speed := 20.0
# how fast the wheel particles move relative to the car
var wheel_particle_speed := 3.0

var lane_width := 10.0
var target_lane := 0
var min_lane := 0
var max_lane := 1

var x_accel := 0.0
var max_x_accel := 30.0

func _ready():
	# start in a lane
	car.translation	= target_lane_pos()
	road_shader.set_shader_param("lane_count", max_lane - min_lane + 1)
	# the shader uses UV coordinates, so params need to be adjusted based on the mesh size
	road_shader.set_shader_param("lane_width", lane_width/ground_mesh.size.x)
	road_shader.set_shader_param("stripe_width", 0.5/ground_mesh.size.x)
	road_shader.set_shader_param("stripe_dist", 8.0/ground_mesh.size.y)
	road_shader.set_shader_param("stripe_lent", 5.0/ground_mesh.size.y)
	road_shader.set_shader_param("line_width", 0.5/ground_mesh.size.x)

func _physics_process(delta: float):
	if Engine.editor_hint:
		return # don't run in the editor
	x_accel *= pow(0.005, delta) # damping
	x_accel += (target_lane_pos().x - car.translation.x) * 20 * delta # spring motion
	x_accel = clamp(x_accel, -max_x_accel, max_x_accel)
	# move_and_slide handles `delta`
	var current_velocity := car.move_and_slide(Vector3.FORWARD * speed + Vector3.RIGHT * x_accel)
	
	# look where we're going
	car.look_at(car.translation + current_velocity * 10, Vector3.UP)
	car.rotation.y += deg2rad(180) # car model is backwards
	
	# also update camera in `_physics_process` so it doesn't flicker
	# normal `translate` would move it in the direction it's facing, so use `global_translate`
	camera.global_translate(Vector3.FORWARD * speed * delta)

func _input(event: InputEvent):
	if Engine.editor_hint:
		return # don't run in the editor
	if event.is_action("change_lane_left") and target_lane > min_lane:
		target_lane -= 1
	if event.is_action("change_lane_right") and target_lane < max_lane:
		target_lane += 1

# where we're trying to go
func target_lane_pos() -> Vector3:
	var offset := -lane_width/2 if max_lane - min_lane % 2 == 1 else 0.0
	return Vector3(target_lane * lane_width + offset, car.translation.y, car.translation.z)
	
