tool
class_name Game
extends Spatial

onready var car := get_node("Car") as KinematicBody
onready var camera := get_node("Camera") as Camera
onready var camera_pos := get_node("CameraPos") as Spatial
onready var menu_camera_pos := get_node("MenuCameraPos") as Spatial
onready var ground := get_node("Ground") as Spatial
onready var ground_mesh := (get_node("Ground/MeshInstance") as MeshInstance).mesh as PlaneMesh
onready var road_shader := ground_mesh.surface_get_material(0) as ShaderMaterial

const left_boxes_scene := preload("res://LeftBoxes.tscn")
const right_boxes_scene := preload("res://RightBoxes.tscn")

enum State {MENU, STARTING, RUNNING}
var state: int = State.MENU

# how fast the camera and the car move forward
var speed := 20.0

var lane_width := 10.0
var target_lane := 0
var min_lane := 0
var max_lane := 1

var x_velocity := 0.0
var max_x_velocity := 20.0

var time_until_start := 2.0
var current_time_until_start := time_until_start

var time_until_menu_boxes := 2.0
var current_time_until_menu_boxes := time_until_menu_boxes
var menu_boxes_spawn_distance := 4.5

func _ready():
	# start in a lane
	car.translation	= target_lane_pos()
	road_shader.set_shader_param("lane_count", max_lane - min_lane + 1)
	# the shader uses UV coordinates, so params need to be adjusted based on the mesh size
	var ground_size := Vector2(ground.scale.x, ground.scale.z)
	road_shader.set_shader_param("lane_width", lane_width/ground_size.x)
	road_shader.set_shader_param("stripe_width", 0.5/ground_size.x)
	road_shader.set_shader_param("stripe_dist", 8.0/ground_size.y)
	road_shader.set_shader_param("stripe_len", 5.0/ground_size.y)
	road_shader.set_shader_param("line_width", 0.5/ground_size.x)
	# spawn initial boxes
	var t := menu_boxes_spawn_distance
	while t > 0:
		call_deferred("add_child", make_boxes(t, Side.LEFT, ""))
		t -= time_until_menu_boxes

func _physics_process(delta: float):
	if Engine.editor_hint:
		return # don't run in the editor
	match state:
		State.MENU:
			current_time_until_menu_boxes -= delta
			if current_time_until_menu_boxes <= 0:
				current_time_until_menu_boxes = time_until_menu_boxes
				call_deferred("add_child", make_boxes(menu_boxes_spawn_distance, Side.LEFT, ""))
		State.STARTING:
			current_time_until_start -= delta
			if current_time_until_start <= 0:
				state = State.RUNNING
	x_velocity *= pow(0.005, delta) # damping
	var x_acceleration := (target_lane_pos().x - car.translation.x) * 10
	x_velocity += x_acceleration * delta # spring motion
	x_velocity = clamp(x_velocity, -max_x_velocity, max_x_velocity)
	# move_and_slide handles `delta`
	var current_velocity := car.move_and_slide(Vector3.FORWARD * speed + Vector3.RIGHT * x_velocity)
	
	# look where we're going
	car.look_at(car.translation + current_velocity * 10, Vector3.UP)
	car.rotation.y += deg2rad(180) # car model is backwards
	
	# rotate wheels according to x acceleration
	var rot := -atan(x_acceleration * 0.005)
	(get_node("Car/front_left") as Spatial).rotation.y = rot
	(get_node("Car/front_right") as Spatial).rotation.y = rot
	
	# also update camera in `_physics_process` so it doesn't flicker
	# normal `translate` would move it in the direction it's facing, so use `global_translate`
	camera_pos.global_translate(Vector3.FORWARD * speed * delta)
	menu_camera_pos.global_translate(Vector3.FORWARD * speed * delta)
	match state:
		State.MENU:
			camera.transform = menu_camera_pos.transform
		State.STARTING:
			var ratio := ease(current_time_until_start/time_until_start, -2.0)
			camera.transform = camera_pos.transform.interpolate_with(menu_camera_pos.transform, ratio)
		State.RUNNING:
			camera.transform = camera_pos.transform
		

func _input(event: InputEvent):
	if Engine.editor_hint:
		return # don't run in the editor
	if state != State.RUNNING:
		return
	if event.is_action_pressed("change_lane_left") and target_lane > min_lane:
		target_lane -= 1
	if event.is_action_pressed("change_lane_right") and target_lane < max_lane:
		target_lane += 1

# where we're trying to go
func target_lane_pos() -> Vector3:
	var offset := -lane_width/2 if max_lane - min_lane % 2 == 1 else 0.0
	return Vector3(target_lane * lane_width + offset, car.translation.y, car.translation.z)

enum Side {LEFT, RIGHT}
# time is in seconds compared to now
func make_boxes(time: float, side: int, text: String) -> Boxes:
	var boxes: Boxes
	match side:
		Side.LEFT:
			boxes = left_boxes_scene.instance() as Boxes
		Side.RIGHT:
			boxes = right_boxes_scene.instance() as Boxes
	boxes.car = car
	boxes.camera = camera
	boxes.set_text(text)
	boxes.translation.z = car.translation.z - time * speed
	return boxes
