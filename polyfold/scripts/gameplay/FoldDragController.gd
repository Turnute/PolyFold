class_name FoldDragController
extends Node

enum DragState { IDLE, DRAGGING }

## Minimum angle in degrees required to lock the direction.
const DIRECTION_LOCK_ANGLE: float = 4.0
## Minimum angle in degrees required to snap to a quarter turn.
const SNAP_ENTER_ANGLE: float = 75.0
## Minimum angle in degrees required to remain snapped.
const SNAP_EXIT_ANGLE: float = 70.0

## Camera used for screen projection.
var _camera: Camera3D
## Polycube receiving the committed move.
var _target: Polycube
## History of action 
var _history : History = History.new()
## Edge grabbed by the player.
var _drag_edge: Edge
## Face being dragged.
var _drag_face: Face
## Opposite edge used as the hinge.
var _drag_hinge: Edge
## Initial world-space hinge position.
var _drag_pivot: Vector3
## Current preview angle in degrees.
var _drag_angle: float = 0.0
## World-space rotation axis.
var _drag_axis: Vector3
## Current interaction state.
var _drag_state: DragState = DragState.IDLE
## World-space point grabbed at drag start.
var _drag_point: Vector3
## Locked direction: 0 unset, 1 positive, -1 negative.
var _drag_direction: int = 0
## Whether the preview is snapped to a quarter turn.
var _drag_snapped: bool = false
## Dictionary of Face -> initial Transform3D.
var _drag_initial_transforms: Dictionary = {}
## Array of excluded areas from a collision detection check
var _drag_excluded_areas: Array[RID] = []
## Whether a collision occured during a folding drag
var _drag_colliding : bool
## Latest mouse request, waiting for physics validation.
var _drag_requested_angle: float = 0.0
## Whether the mouse was released before validation completed.
var _drag_release_requested: bool = false
## Maximum subdivision depth when checking a rotation interval.
const SWEEP_MAX_DEPTH: int = 16
## Retraction applied only to the moving group's outer borders.
const GROUP_BORDER_INSET: float = 0.01
## Temporary group volume: Face -> shape and local offset.
var _drag_detectors: Dictionary = {}
## Whether a collision has been detected.
var _error_detected: bool = false
## The angle of the error.
var _error_angle: float = 0.0
## The angle threshold at which a new error can occur during the same drag. 
const ERROR_ANGLE: float = 3.0

## Resolves the handle's actual hinge and captures every moving face once.
func beginEdgeDrag(
	selected_edge: Edge,
	hit_point: Vector3,
	cam: Camera3D,
	polycube: Polycube
) -> void:
	endEdgeDrag(false)

	if not is_instance_valid(selected_edge):
		return
	if not is_instance_valid(cam) or not is_instance_valid(polycube):
		return

	var action: UnfoldAction = selected_edge.select(UnfoldAction.DirEnum.FWD)
	var face: Face = polycube.getFace(action._id_cube, action._face)

	if not is_instance_valid(face):
		return

	var hinge: Edge = face.getOppositeEdge(face._edges[action._edge])
	var group: Array[int] = polycube.getFoldGroup(
		face._id_face,
		action._edge
	)

	if group.is_empty():
		return

	_camera = cam
	_target = polycube
	_history.setPolucube(_target)
	_drag_edge = selected_edge
	_drag_face = face
	_drag_hinge = hinge
	_drag_pivot = hinge.global_position
	_drag_axis = polycube.getEdgeAxis(face, hinge)
	_drag_point = hit_point
	_drag_angle = 0.0
	_drag_direction = 0
	_drag_snapped = false
	_drag_state = DragState.DRAGGING

	_drag_initial_transforms.clear()
	_drag_excluded_areas.clear()
	_drag_colliding = false
	
	_drag_requested_angle = 0.0
	_drag_detectors.clear()
	_error_detected = false

	for cube in polycube._cubes:
		for fixed_face in cube._faces:
			if not group.has(fixed_face._id_face):
				fixed_face.updateFoldDetector(group)

	for face_id in group:
		var member: Face = polycube.getFaceFromFaceId(face_id)
		_drag_initial_transforms[member] = member.global_transform
		_drag_excluded_areas.append(member._fold_area.get_rid())

		var inset: Array[float] = []
		for neighbour_id in member._adj_faces:
			inset.append(
				0.0 if group.has(neighbour_id) else GROUP_BORDER_INSET
			)

		var source: BoxShape3D = member._fold_shape.shape
		var shape := BoxShape3D.new()
		shape.margin = 0.0
		shape.size = Vector3(
			1.0 - inset[0] - inset[1],
			source.size.y,
			1.0 - inset[2] - inset[3]
		)

		_drag_detectors[member] = {
			"shape": shape,
			"offset": Vector3(
				(inset[1] - inset[0]) * 0.5,
				0.0,
				(inset[2] - inset[3]) * 0.5
			)
		}

## Updates the preview and consumes input while dragging.
func dragEdgeInput(event: InputEvent) -> bool:
	if _drag_state == DragState.IDLE:
		return false

	if (
		not is_instance_valid(_camera)
		or not is_instance_valid(_target)
		or not is_instance_valid(_drag_edge)
		or not is_instance_valid(_drag_face)
		or not is_instance_valid(_drag_hinge)
	):
		endEdgeDrag(false)
		return true
	
	if _drag_release_requested:
		return true

	if event is InputEventMouseMotion:
		var raw_angle: float = findDragAngle(event.position)

		if _drag_direction != 0 and is_zero_approx(raw_angle):
			_drag_direction = 0
			raw_angle = findDragAngle(event.position)

		if _drag_direction == 0 and absf(raw_angle) >= DIRECTION_LOCK_ANGLE:
			if raw_angle > 0.0:
				_drag_direction = 1
			else:
				_drag_direction = -1

		if _drag_snapped:
			_drag_snapped = absf(raw_angle) >= SNAP_EXIT_ANGLE
		else:
			_drag_snapped = absf(raw_angle) >= SNAP_ENTER_ANGLE

		var preview_angle: float = raw_angle
		if _drag_snapped:
			preview_angle = 90.0 * _drag_direction

		_drag_requested_angle = preview_angle

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_drag_release_requested = true

	return true


## Ends the drag, committing only a snapped preview when requested.
func endEdgeDrag(commit: bool) -> void:
	if _drag_state == DragState.IDLE:
		return

	_drag_state = DragState.IDLE

	if is_instance_valid(_drag_face):
		# Restore the initial pose before applying the full quarter turn.
		for face in _drag_initial_transforms:
			if is_instance_valid(face):
				face.global_transform = _drag_initial_transforms[face]

		if (
			commit
			and _drag_snapped
			and _drag_direction != 0
			and is_instance_valid(_drag_edge)
			and is_instance_valid(_target)
		):
			var direction: UnfoldAction.DirEnum = UnfoldAction.DirEnum.FWD
			if _drag_direction < 0:
				direction = UnfoldAction.DirEnum.BWD

			var action: UnfoldAction = _drag_edge.select(direction)
			Unfolder.executeMove(action, _target)
			## Add the action into the historic
			_history.addAction(action)
			Game._on_unfolding.emit()

	if is_instance_valid(_target):
		_target.unselectAllFaces()
	_camera = null
	_target = null
	_drag_edge = null
	_drag_face = null
	_drag_hinge = null
	_drag_angle = 0.0
	_drag_direction = 0
	_drag_snapped = false
	_drag_initial_transforms.clear()
	_drag_detectors.clear()
	_drag_excluded_areas.clear()
	_drag_requested_angle = 0.0
	_drag_release_requested = false
	_drag_colliding = false
	_error_detected = false


## Sets the preview angle relative to the initial pose.
func setPreviewAngle(angle: float) -> void:
	var rotation := Basis(_drag_axis, deg_to_rad(angle))

	for face in _drag_initial_transforms:
		var t: Transform3D = _drag_initial_transforms[face]

		t.origin = _drag_pivot + rotation * (t.origin - _drag_pivot)
		t.basis = rotation * t.basis

		face.global_transform = t

	_drag_angle = angle


## Returns the grabbed point's world position for an angle in degrees.
func predictDragPoint(angle: float) -> Vector3:
	var offset: Vector3 = _drag_point - _drag_pivot
	var rotation_basis := Basis(_drag_axis, deg_to_rad(angle))
	return _drag_pivot + rotation_basis * offset


## Finds the closest projected angle within the locked direction.
func findDragAngle(mouse_pos: Vector2) -> float:
	var best_angle: float = _drag_angle
	var best_error: float = INF
	var min_angle: int = -90
	var max_angle: int = 90

	if _drag_direction > 0:
		min_angle = 0
	elif _drag_direction < 0:
		max_angle = 0

	for candidate in range(min_angle, max_angle + 1, 2):
		var angle: float = float(candidate)
		var point_3d: Vector3 = predictDragPoint(angle)
		if _camera.is_position_behind(point_3d):
			continue

		var point_2d: Vector2 = _camera.unproject_position(point_3d)
		var error: float = point_2d.distance_squared_to(mouse_pos)
		if error < best_error:
			best_angle = angle
			best_error = error

	return best_angle


## Checks the temporary group volume against stationary face detectors.
func previewOverlaps() -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.collision_mask = 2
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.exclude = _drag_excluded_areas

	var space := _target.get_world_3d().direct_space_state

	for face in _drag_detectors:
		var detector: Dictionary = _drag_detectors[face]
		var offset: Vector3 = detector["offset"]

		query.shape = detector["shape"]
		query.transform = (
			face.global_transform
			* Transform3D(Basis.IDENTITY, offset)
		)

		if not space.intersect_shape(query, 1).is_empty():
			return true

	return false


## Advances the preview and rejects the first overlapping pose.
func _physics_process(_delta: float) -> void:
	if _drag_state != DragState.DRAGGING:
		return

	if not is_instance_valid(_target):
		endEdgeDrag(false)
		return

	_drag_colliding = false

	while _drag_angle != _drag_requested_angle:
		var previous_angle: float = _drag_angle
		var next_angle: float = move_toward(
			_drag_angle,
			_drag_requested_angle,
			0.25
		)

		setPreviewAngle(next_angle)
		_drag_colliding = previewOverlaps()

		if _drag_colliding:
			setPreviewAngle(previous_angle)
			error()
			break
	
	if _error_detected:
		if absf(_drag_angle - _error_angle) >= ERROR_ANGLE:
			_error_detected = false
	
	if _drag_release_requested:
		endEdgeDrag(
			_drag_snapped
			and not _drag_colliding
			and absf(_drag_angle) == 90.0
		)

## Collision feedback: faces flash red and camera shake
func error() -> void:
	if _error_detected:
		return

	_error_detected = true
	_error_angle = _drag_angle
	
	if is_instance_valid(_camera) and _camera.has_method("shake"):
		_camera.shake()
		
	for face in _drag_detectors:
		face.error()
