extends Camera3D

## The target that the camera will focus on.
@export var _target : Polycube
## Controller used to drag and commit folds.
@onready var _fold_drag: FoldDragController = $FoldDragController

## Camera yaw angle in radians.
var _yaw: float = 0.0
## Camera pitch angle in radians.
var _pitch: float = 0.0

## Initial distance between the camera and the target.
var _distance : float = 2.0

## Minimum camera distance from the targeted object.
var _distance_min : float = 1.0
## Maxiumum camera distance from the targeted object
var _distance_max : float = 10.0

## Speed of ration of the camera around the target.
var _sensibilite : float = 0.005

## Length of raycast.
const _RAY_LENGTH = 1000

## Selected face identifier, or -1 when nothing is selected.
var _curr_selected_face_id : int = -1

## Initializes the pitch so the camera stays above the target.
func _ready() -> void:
	_pitch = clampf(_pitch, deg_to_rad(10.0), deg_to_rad(80.0))
	updatePositionCamera()

# func _process(delta: float) -> void: # UNUSED
#	pass

## Handles zoom, object selection, and fold dragging.
func _input(event : InputEvent):
	if _fold_drag.dragEdgeInput(event):
		get_viewport().set_input_as_handled()
		return
	
	if not is_instance_valid(_target):
		return
	
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
				Log.trace(str(godot_object))
				if godot_object:
					var selected_object = godot_object["collider"]
					var parent = selected_object.get_parent()
					if is_instance_of(selected_object, Edge):
						_fold_drag.beginEdgeDrag(selected_object, godot_object["position"], self, _target)
					elif is_instance_of(parent, Face):
						if _target._selected_face_id != parent._id_face:
							if _curr_selected_face_id != -1:
								_target.unselectFace(_curr_selected_face_id)
							_curr_selected_face_id = parent._id_face
							_target.selectFace(_curr_selected_face_id)
				else:
					_target.unselectAllFaces()
					_curr_selected_face_id = -1
					pass

## Updates the camera position from its pitch, yaw, distance, and actual target.
func updatePositionCamera() -> void :
	if is_instance_valid(_target):
		var offset = Vector3(
			cos(_pitch) * sin(_yaw),
			sin(_pitch),
			cos(_pitch) * cos(_yaw)
		) * _distance
		var position_target : Vector3
		if _target.has_method("getAveragePos"):
			position_target = _target.to_global(_target.getAveragePos())
		else : 
			position_target = _target.global_position
		global_position = (offset+ position_target)
		look_at(position_target,Vector3.UP)

## Rotates the camera with Shift + left drag or middle drag.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and ((Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and (event.shift_pressed))or (Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE))):
		_yaw -= event.relative.x * _sensibilite
		_pitch += event.relative.y * _sensibilite
		_pitch = clampf(_pitch, deg_to_rad(10.0), deg_to_rad(80.0))
		updatePositionCamera()

## Returns the raycast hit, or an empty dictionary if nothing is hit.
func getRaycastObject() -> Dictionary : 
	var space_state = get_world_3d().direct_space_state
	var mousepos = get_viewport().get_mouse_position()
	var origin = self.project_ray_origin(mousepos)
	var end = origin + self.project_ray_normal(mousepos) * _RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	query.collision_mask = 1
	var result = space_state.intersect_ray(query)
	return result

## Targets the designated polycube and recenters the camera.
func target(object : Polycube) -> void :
	if is_instance_valid(_fold_drag):
		_fold_drag.endEdgeDrag(false)
	if is_instance_valid(_target) and _target.is_node_ready():
		_target.unselectAllFaces()
	_curr_selected_face_id = -1
	_target = object
	updatePositionCamera()
