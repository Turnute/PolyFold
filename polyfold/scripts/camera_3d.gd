extends Camera3D

## The target that the camera will focus on
@export var target : Node3D
@onready var raycast = $RayCast3D

## Angle of ratation of both x and y axis
var yaw: float = 0.0 
var pitch: float = 0.0

## Initial distance between the camera and the target
var distance : float = 2.0

##  Min, Max the camera can focus
var distance_min : float = 1.0
var distance_max : float = 10.0

## Speed of ration of the camera around the target
var sensibilite : float = 0.005

## Length of raycast 
const RAY_LENGTH = 1000

func _ready() -> void:
	## Init the pitch value so it not at the same height than the target
	pitch = clampf(pitch, deg_to_rad(10.0), deg_to_rad(80.0))	
	updatePositionCamera()


func _process(delta: float) -> void:
	pass

## Collect user inputs to eitheir zoom the camera or get a Godot Object
func _input(event : InputEvent):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				distance -= 0.1
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				distance += 0.1
			distance = clampf(distance, distance_min, distance_max)
			updatePositionCamera()
			
			if event.button_index == MOUSE_BUTTON_LEFT:
				var godot_object = getRaycastObject()
				#Do your thing


#Update the position of the camera that depend on the pitch, yawn and the actuel target
func updatePositionCamera() -> void :
	var offset = Vector3(
		cos(pitch) * sin(yaw),
		sin(pitch),
		cos(pitch) * cos(yaw)
	) * distance
	global_position = (offset+ target.global_position)
	look_at(target.global_position,Vector3.UP)
	
		
func _unhandled_input(event: InputEvent) -> void:
	## Click on eitheir (shift + mouse left click) or (shift + click mouse wheel) to rotate the camera 
	if event is InputEventMouseMotion and ((Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and (event.keycode == KEY_SHIFT))or (Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) and (event.shift_pressed))):
		yaw -= event.relative.x * sensibilite
		pitch -= event.relative.y * sensibilite
		pitch = clampf(pitch, deg_to_rad(10.0), deg_to_rad(80.0))
		updatePositionCamera()

## Return a dictionary if the raycast collide a godot object
func getRaycastObject() -> Dictionary : 
	var space_state = get_world_3d().direct_space_state
	var mousepos = get_viewport().get_mouse_position()
	var origin = self.project_ray_origin(mousepos)
	var end = origin + self.project_ray_normal(mousepos) * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	return result
