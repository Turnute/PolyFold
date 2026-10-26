class_name FoldDragController
extends Node

var _camera: Camera3D
var _target: Polycube
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

## Begins the action of a an edge being dragged by the player.
## Sets the dragging related variables.
func beginEdgeDrag(selected_edge : Edge, hit_point: Vector3, cam : Camera3D, polycube : Polycube) -> void :
	_camera = cam
	_target = polycube
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
		if _camera.is_position_behind(point_3d):
			continue
		var point_2d : Vector2 = _camera.unproject_position(point_3d)
		var error : float = point_2d.distance_squared_to(mouse_pos)
		if error < best_error:
			best_angle = angle
			best_error = error
		
	return best_angle
