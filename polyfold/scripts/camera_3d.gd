extends Camera3D

## The target that the camera will focus on
@export var _target : Polycube
# @onready var _raycast = $RayCast3D # UNUSED

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

## EDGE DRAGGING RELATED VARIABLES
## The edge being dragged by the player
var _drag_edge : Edge
## The face the dragged edge belongs to (and thus the player moves around)
var _drag_face : Face
## The face's hinge: its opposite edge to the one being dragged.
var _drag_hinge : Edge
## The drag hinge's global position
var _drag_pivot : Vector3
## The face's initial transform
var _drag_initial_transform : Transform3D
## The angle at which the face is currently being rotated
var _drag_angle : float = 0.0
## The rotation's direction (see Face.rotateAroundEdge method)
var _drag_axis : Vector3

enum DragState { IDLE, DRAGGING, ANIMATING }
var _drag_state : DragState = DragState.IDLE

## The 3D Point found by the raycast
var _drag_point : Vector3

## Angle at which an unfolding is considered committed
const COMMIT_ANGLE: float = 90.0


func _ready() -> void:
	## Init the pitch value so it not at the same height than the target
	_pitch = clampf(_pitch, deg_to_rad(10.0), deg_to_rad(80.0))
	updatePositionCamera()

# func _process(delta: float) -> void: # UNUSED
#	pass

## Collect user inputs to eitheir zoom the camera or get a Godot Object
func _input(event : InputEvent):
	if dragEdgeInput(event):
		get_viewport().set_input_as_handled()
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
				print(godot_object)
				if godot_object:
					var selected_object = godot_object["collider"]
					var parent = selected_object.get_parent()
					if is_instance_of(selected_object, Edge):
						beginEdgeDrag(selected_object, godot_object["position"])
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

## Update the position of the camera that depend on the pitch, yawn and the actuel target
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

## Targets the camera towards the designated Polycube object, and
## recenters it.
func target(object : Polycube) -> void :
	_target = object
	updatePositionCamera()

## Begins the action of a an edge being dragged by the player.
## Sets the dragging related variables.
func beginEdgeDrag(selected_edge : Edge, hit_point: Vector3) -> void :
	_drag_edge = selected_edge
	_drag_face = selected_edge.get_parent()
	_drag_hinge = _drag_face.getOppositeEdge(selected_edge)
	_drag_pivot = _drag_hinge.global_position
	_drag_initial_transform = _drag_face.global_transform
	_drag_angle = 0.0
	_drag_state = DragState.DRAGGING
	_drag_point = hit_point
	match selected_edge._side:
		Edge.EdgeEnum.TOP, Edge.EdgeEnum.BOTTOM:
			_drag_axis = Vector3.FORWARD
		Edge.EdgeEnum.LEFT, Edge.EdgeEnum.RIGHT:
			_drag_axis = Vector3.RIGHT
	_drag_axis = (_drag_initial_transform.basis * _drag_axis).normalized()

## Handles input for a drag:
## if IDLE, returns false (and the rest or the input handling system continues as normal)
## if DRAGGING, handles the dragging event
## if ANIMATING, returns true (and blocks the rest of the input handling system while
## the unfolding animation is unfinished)
func dragEdgeInput(event : InputEvent) -> bool :
	match _drag_state:
		DragState.IDLE:
			return false
		DragState.DRAGGING:
			# MOVING THE MOUSE -> DRAGGING THE OBJECT
			if event is InputEventMouseMotion:
					print("DRAGGING!") # DEBUG
					var angle: float = findDragAngle(event.position)
					setPreviewAngle(angle)
					if absf(angle) >= COMMIT_ANGLE:
						_drag_state = DragState.IDLE
						# set the direction from the current angle
						var direction : UnfoldAction.DirEnum
						if angle > 0:
							direction = UnfoldAction.DirEnum.FWD
						else: direction = UnfoldAction.DirEnum.BWD
						var action : UnfoldAction = _drag_edge.select(direction)
						_drag_face.global_transform = _drag_initial_transform
						Unfolder.executeMove(action, _target)
						
			
			# RELEASING THE MOUSE BUTTON -> STOP DRAG
			elif event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
					print("STOP!") # DEBUG
					_drag_state = DragState.IDLE
					setPreviewAngle(0.0)
			
			return true
		DragState.ANIMATING:
			return true # bloque les commandes dans _input
		_:
			return false

## Rotates the dragged face at a certain angle to preview its unfolding action
func setPreviewAngle(angle : float) -> void :
	_drag_face.global_transform = _drag_initial_transform # reset l'angle de la face
	_drag_face.rotateAroundEdge(_drag_hinge, angle)
	_drag_angle = angle

## Predicts the position of the drag_point (place where we clicked) after
## a rotation of a certain angle
func predictDragPoint(angle : float) -> Vector3 :
	var offset : Vector3 = _drag_point - _drag_pivot
	var rotation_basis : Basis = Basis(_drag_axis, deg_to_rad(angle))
	var rotated_offset : Vector3 = rotation_basis * offset
	
	return _drag_pivot + rotated_offset

## Finds and returns the angle at which predictDragPoint returns a position
## closest to the mouse cursor
func findDragAngle(mouse_pos : Vector2) -> float :
	var best_angle : float = _drag_angle
	var best_error : float = INF
	
	for angle in range(-90.0, 91.0, 2.0):
		var point_3d : Vector3 = predictDragPoint(angle)
		# if is_position_behind(point_3d): continue
		var point_2d : Vector2 = unproject_position(point_3d)
		var error : float = point_2d.distance_squared_to(mouse_pos)
		if error < best_error:
			best_angle = angle
			best_error = error
		
	return best_angle
