extends Camera3D

## The target that the camera will focus on
@export var _target : Polycube
@onready var _raycast = $RayCast3D

## Angle of ratation of both x and y axis
var _yaw: float = 0.0 
var _pitch: float = 0.0

## Initial distance between the camera and the target
var _distance : float = 2.0

##  Min, Max the camera can focus
var _distance_min : float = 1.0
var _distance_max : float = 10.0

## Speed of ration of the camera around the target
var _sensibilite : float = 0.005

## Length of raycast 
const _RAY_LENGTH = 1000

var _curr_selected_face_id : int = -1

func _ready() -> void:
	## Init the pitch value so it not at the same height than the target
	_pitch = clampf(_pitch, deg_to_rad(10.0), deg_to_rad(80.0))
	updatePositionCamera()

func _process(delta: float) -> void:
	pass

## Collect user inputs to eitheir zoom the camera or get a Godot Object
func _input(event : InputEvent):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_distance -= 0.1
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_distance += 0.1
			_distance = clampf(_distance, _distance_min, _distance_max)
			updatePositionCamera()
			
			if event.button_index == MOUSE_BUTTON_LEFT and not event.shift_pressed:
				var godot_object = getRaycastObject()
				print(godot_object)
				if godot_object:
					var selected_object = godot_object["collider"]
					var parent = selected_object.get_parent()
					if is_instance_of(selected_object, Edge):
						# TODO : Déterminer la direction
						# dynamiquement, en fonction du déplacement
						# de la souris par rapport à la face sélectionnée
						var action : UnfoldAction = selected_object.select(UnfoldAction.DirEnum.FWD)
						Unfolder.executeMove(action, _target)
					elif is_instance_of(parent, Face):
						if _curr_selected_face_id != parent._id_face:
							if _curr_selected_face_id != -1:
								_target.unselectFace(_curr_selected_face_id)
							_curr_selected_face_id = parent._id_face
							_target.selectFace(_curr_selected_face_id)
				else:
					_target.unselectAllFaces()
					_curr_selected_face_id = -1
					pass

#Update the position of the camera that depend on the pitch, yawn and the actuel target
func updatePositionCamera() -> void :
	if _target != null :
		var offset = Vector3(
			cos(_pitch) * sin(_yaw),
			sin(_pitch),
			cos(_pitch) * cos(_yaw)
		) * _distance
		var position_target : Vector3
		if _target.has_method("getAveragePos"):
			position_target = _target.getAveragePos()
		else : 
			position_target = _target.global_position
		global_position = (offset+ position_target)
		look_at(position_target,Vector3.UP)
	
		
func _unhandled_input(event: InputEvent) -> void:
	## Click on eitheir (shift + mouse left click) or (shift + click mouse wheel) to rotate the camera 
	if event is InputEventMouseMotion and ((Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and (event.shift_pressed))or (Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE))):
		_yaw -= event.relative.x * _sensibilite
		_pitch += event.relative.y * _sensibilite
		_pitch = clampf(_pitch, deg_to_rad(10.0), deg_to_rad(80.0))
		updatePositionCamera()

## Return a dictionary if the raycast collide a godot object
func getRaycastObject() -> Dictionary : 
	var space_state = get_world_3d().direct_space_state
	var mousepos = get_viewport().get_mouse_position()
	var origin = self.project_ray_origin(mousepos)
	var end = origin + self.project_ray_normal(mousepos) * _RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	return result

func target(object : Polycube) -> void :
	_target = object
	updatePositionCamera()
