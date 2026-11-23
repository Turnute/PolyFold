extends GutTest

var _controller : FoldDragController
var _polycube : Polycube
var _camera : Camera3D
var _anchor : Face
var _tip : Face
var _body : Face
var _handle : Edge

func before_each() -> void :
	var cube : Cube = Cube.new()
	var sides : Array[int] = [Face.FaceEnum.TOP, Face.FaceEnum.FRONT, Face.FaceEnum.BOTTOM]
	var positions : Array[Vector3] = [
		Vector3.ZERO, Vector3.RIGHT, Vector3(-0.5, -0.5, 0)
	]
	for i in range(3):
		var face : Face = preload("res://prefabs/face.tscn").instantiate() as Face
		face._side = sides[i]
		face._ogColor = Color(0.2, 0.4, 0.6)
		face.position = positions[i]
		if i == 2:
			face.basis = Basis(Vector3.FORWARD, PI / 2.0)
		cube.add_child(face)
		cube._faces.append(face)
	_anchor = cube._faces[0]
	_tip = cube._faces[1]
	_body = cube._faces[2]
	_anchor._adj_faces = [5, 2, -1, -1]
	_tip._adj_faces = [-1, 1, -1, -1]
	_body._adj_faces = [-1, 1, -1, -1]
	_polycube = Polycube.new([cube])
	add_child_autofree(_polycube)
	_polycube.selectFace(_anchor._id_face)
	_handle = _tip._edges[Edge.EdgeEnum.TOP]
	_camera = Camera3D.new()
	add_child_autofree(_camera)
	_camera.position = Vector3(0, 0, 5)
	_camera.look_at(Vector3.ZERO)
	# Kept outside the tree so physics advances only when a test requests it.
	_controller = autofree(FoldDragController.new())

func test_idle_controller_does_not_consume_input() -> void :
	assert_false(_controller.dragEdgeInput(InputEventMouseMotion.new()))

func test_begin_drag_rejects_missing_edge_or_camera_or_polycube() -> void :
	_controller.beginEdgeDrag(null, Vector3.ZERO, _camera, _polycube)
	assert_eq(_controller._drag_state, FoldDragController.DragState.IDLE)
	_controller.beginEdgeDrag(_handle, Vector3.ZERO, null, _polycube)
	assert_eq(_controller._drag_state, FoldDragController.DragState.IDLE)
	_controller.beginEdgeDrag(_handle, Vector3.ZERO, _camera, null)
	assert_eq(_controller._drag_state, FoldDragController.DragState.IDLE)
	assert_true(_controller._drag_initial_transforms.is_empty())

func test_begin_drag_rejects_handle_without_connected_hinge() -> void :
	var edge : Edge = _tip._edges[Edge.EdgeEnum.LEFT]
	_controller.beginEdgeDrag(edge, edge.global_position, _camera, _polycube)

	assert_eq(_controller._drag_state, FoldDragController.DragState.IDLE)
	assert_true(_controller._drag_detectors.is_empty())

func test_begin_drag_resolves_attachment_from_farthest_handle() -> void :
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)

	assert_eq(_controller._drag_state, FoldDragController.DragState.DRAGGING)
	assert_eq(_controller._drag_edge, _handle)
	assert_eq(_controller._drag_face, _anchor)
	assert_eq(_controller._drag_hinge, _anchor._edges[Edge.EdgeEnum.BOTTOM])
	assert_true(_controller._drag_pivot.is_equal_approx(Vector3(-0.5, 0, 0)))
	assert_true(_controller._drag_axis.is_equal_approx(Vector3.FORWARD))
	assert_eq(_controller._drag_initial_transforms.size(), 2)
	assert_true(_controller._drag_initial_transforms.has(_anchor))
	assert_true(_controller._drag_initial_transforms.has(_tip))
	assert_false(_controller._drag_initial_transforms.has(_body))
	assert_eq(_controller._drag_excluded_areas.size(), 2)
	assert_true(_controller._drag_excluded_areas.has(_anchor._fold_area.get_rid()))
	assert_true(_controller._drag_excluded_areas.has(_tip._fold_area.get_rid()))
	assert_false(_controller._drag_excluded_areas.has(_body._fold_area.get_rid()))

func test_group_detectors_keep_internal_seam_closed_and_inset_outer_borders() -> void :
	var original_size : Vector3 = _anchor._fold_shape.shape.size
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	var first : Dictionary = _controller._drag_detectors[_anchor]
	var second : Dictionary = _controller._drag_detectors[_tip]
	var inset : float = FoldDragController.GROUP_BORDER_INSET

	assert_eq(_controller._drag_detectors.size(), 2)
	assert_true(first["shape"].size.is_equal_approx(Vector3(
		1.0 - inset, original_size.y, 1.0 - 2.0 * inset
	)))
	assert_true(first["offset"].is_equal_approx(Vector3(inset / 2.0, 0, 0)))
	assert_true(second["offset"].is_equal_approx(Vector3(-inset / 2.0, 0, 0)))
	var first_border : float = _anchor.position.x + first["offset"].x + first["shape"].size.x / 2.0
	var second_border : float = _tip.position.x + second["offset"].x - second["shape"].size.x / 2.0
	assert_almost_eq(first_border, second_border, 0.00001)
	assert_true(_anchor._fold_shape.shape.size.is_equal_approx(original_size))
	assert_ne(first["shape"], _anchor._fold_shape.shape)

func test_predict_drag_point_rotates_around_hinge_in_both_directions() -> void :
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)

	assert_true(_controller.predictDragPoint(0.0).is_equal_approx(Vector3(1.5, 0, 0)))
	assert_true(_controller.predictDragPoint(90.0).is_equal_approx(Vector3(-0.5, -2, 0)))
	assert_true(_controller.predictDragPoint(-90.0).is_equal_approx(Vector3(-0.5, 2, 0)))

func test_preview_rotates_entire_group_without_moving_stationary_face() -> void :
	var body_transform : Transform3D = _body.global_transform
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	_controller.setPreviewAngle(-90.0)

	assert_true(_anchor.global_position.is_equal_approx(Vector3(-0.5, 0.5, 0)))
	assert_true(_tip.global_position.is_equal_approx(Vector3(-0.5, 1.5, 0)))
	assert_true(_body.global_transform.is_equal_approx(body_transform))
	assert_almost_eq(_controller._drag_angle, -90.0, 0.00001)

func test_preview_angles_are_relative_to_initial_pose_without_accumulation() -> void :
	var anchor_transform : Transform3D = _anchor.global_transform
	var tip_transform : Transform3D = _tip.global_transform
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	_controller.setPreviewAngle(30.0)
	_controller.setPreviewAngle(90.0)
	assert_true(_anchor.global_position.is_equal_approx(Vector3(-0.5, -0.5, 0)))
	assert_true(_tip.global_position.is_equal_approx(Vector3(-0.5, -1.5, 0)))

	_controller.setPreviewAngle(0.0)
	assert_true(_anchor.global_transform.is_equal_approx(anchor_transform))
	assert_true(_tip.global_transform.is_equal_approx(tip_transform))

func test_find_drag_angle_recovers_projected_angle_on_both_sides() -> void :
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	for angle in [-90.0, -30.0, 0.0, 34.0, 90.0]:
		var mouse : Vector2 = _camera.unproject_position(_controller.predictDragPoint(angle))
		assert_almost_eq(_controller.findDragAngle(mouse), angle, 0.001)

func test_find_drag_angle_respects_locked_direction() -> void :
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	_controller._drag_direction = 1
	var mouse : Vector2 = _camera.unproject_position(_controller.predictDragPoint(-30.0))
	assert_almost_eq(_controller.findDragAngle(mouse), 0.0, 0.001)

	_controller._drag_direction = -1
	mouse = _camera.unproject_position(_controller.predictDragPoint(30.0))
	assert_almost_eq(_controller.findDragAngle(mouse), 0.0, 0.001)

func test_find_drag_angle_keeps_previous_angle_when_all_candidates_are_behind_camera() -> void :
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	_controller._drag_angle = 23.0
	_camera.position = Vector3(0, 0, -5)
	_camera.look_at(Vector3(0, 0, -6))

	assert_almost_eq(_controller.findDragAngle(Vector2.ZERO), 23.0, 0.001)

func test_mouse_motion_locks_direction_only_after_threshold() -> void :
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	var event : InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = _camera.unproject_position(_controller.predictDragPoint(2.0))
	assert_true(_controller.dragEdgeInput(event))
	assert_eq(_controller._drag_direction, 0)

	event.position = _camera.unproject_position(_controller.predictDragPoint(4.0))
	_controller.dragEdgeInput(event)
	assert_eq(_controller._drag_direction, 1)
	assert_almost_eq(_controller._drag_requested_angle, 4.0, 0.001)
	assert_almost_eq(_controller._drag_angle, 0.0, 0.001)

func test_returning_to_zero_unlocks_direction_and_allows_reverse_drag() -> void :
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	var event : InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = _camera.unproject_position(_controller.predictDragPoint(20.0))
	_controller.dragEdgeInput(event)
	assert_eq(_controller._drag_direction, 1)

	event.position = _camera.unproject_position(_controller.predictDragPoint(0.0))
	_controller.dragEdgeInput(event)
	assert_eq(_controller._drag_direction, 0)
	event.position = _camera.unproject_position(_controller.predictDragPoint(-6.0))
	_controller.dragEdgeInput(event)
	assert_eq(_controller._drag_direction, -1)
	assert_almost_eq(_controller._drag_requested_angle, -6.0, 0.001)

func test_snap_uses_separate_enter_and_exit_thresholds() -> void :
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	var angles : Array[float] = [74.0, 76.0, 70.0, 68.0]
	var expected_snapped : Array[bool] = [false, true, true, false]
	var expected_requests : Array[float] = [74.0, 90.0, 90.0, 68.0]
	for i in range(angles.size()):
		var event : InputEventMouseMotion = InputEventMouseMotion.new()
		event.position = _camera.unproject_position(_controller.predictDragPoint(angles[i]))
		_controller.dragEdgeInput(event)
		assert_eq(_controller._drag_snapped, expected_snapped[i])
		assert_almost_eq(_controller._drag_requested_angle, expected_requests[i], 0.001)

func test_negative_drag_snaps_to_negative_quarter_turn() -> void :
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	var event : InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = _camera.unproject_position(_controller.predictDragPoint(-76.0))
	_controller.dragEdgeInput(event)

	assert_eq(_controller._drag_direction, -1)
	assert_true(_controller._drag_snapped)
	assert_almost_eq(_controller._drag_requested_angle, -90.0, 0.001)

func test_mouse_release_waits_for_physics_validation_and_ignores_later_motion() -> void :
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	_controller._drag_requested_angle = -30.0
	var release : InputEventMouseButton = InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	assert_true(_controller.dragEdgeInput(release))
	assert_true(_controller._drag_release_requested)
	assert_eq(_controller._drag_state, FoldDragController.DragState.DRAGGING)

	var motion : InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = _camera.unproject_position(_controller.predictDragPoint(-80.0))
	_controller.dragEdgeInput(motion)
	assert_almost_eq(_controller._drag_requested_angle, -30.0, 0.001)

func test_other_mouse_buttons_do_not_request_drag_release() -> void :
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	var event : InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = false
	_controller.dragEdgeInput(event)
	assert_false(_controller._drag_release_requested)

	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	_controller.dragEdgeInput(event)
	assert_false(_controller._drag_release_requested)

func test_cancel_restores_group_and_clears_all_drag_state() -> void :
	var anchor_transform : Transform3D = _anchor.global_transform
	var tip_transform : Transform3D = _tip.global_transform
	var connections : Array[int] = _anchor._adj_faces.duplicate()
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	_controller.setPreviewAngle(-45.0)
	_controller._drag_release_requested = true
	_controller._drag_colliding = true
	_controller.endEdgeDrag(false)

	assert_true(_anchor.global_transform.is_equal_approx(anchor_transform))
	assert_true(_tip.global_transform.is_equal_approx(tip_transform))
	assert_eq(_anchor._adj_faces, connections)
	assert_eq(_polycube._selected_face_id, -1)
	assert_eq(_controller._drag_state, FoldDragController.DragState.IDLE)
	assert_null(_controller._camera)
	assert_null(_controller._target)
	assert_null(_controller._drag_face)
	assert_null(_controller._drag_edge)
	assert_null(_controller._drag_hinge)
	assert_true(_controller._drag_initial_transforms.is_empty())
	assert_true(_controller._drag_detectors.is_empty())
	assert_true(_controller._drag_excluded_areas.is_empty())
	assert_false(_controller._drag_snapped)
	assert_false(_controller._drag_release_requested)
	assert_false(_controller._drag_colliding)
	assert_eq(_controller._drag_direction, 0)
	assert_almost_eq(_controller._drag_angle, 0.0, 0.001)
	assert_almost_eq(_controller._drag_requested_angle, 0.0, 0.001)

func test_commit_without_snap_restores_initial_pose() -> void :
	var initial : Transform3D = _anchor.global_transform
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	_controller.setPreviewAngle(-40.0)
	_controller._drag_direction = -1
	_controller.endEdgeDrag(true)

	assert_true(_anchor.global_transform.is_equal_approx(initial))
	assert_eq(_controller._drag_state, FoldDragController.DragState.IDLE)

func test_commit_applies_one_quarter_turn_instead_of_adding_to_preview() -> void :
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	_controller.setPreviewAngle(-90.0)
	_controller._drag_direction = -1
	_controller._drag_snapped = true
	_controller.endEdgeDrag(true)

	assert_true(_anchor.global_position.is_equal_approx(Vector3(-0.5, 0.5, 0)))
	assert_true(_tip.global_position.is_equal_approx(Vector3(-0.5, 1.5, 0)))
	assert_true(_anchor.global_basis.y.is_equal_approx(Vector3.LEFT))
	assert_eq(_controller._drag_state, FoldDragController.DragState.IDLE)

func test_new_drag_cancels_previous_preview_before_capturing_pose() -> void :
	var initial : Transform3D = _anchor.global_transform
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	_controller.setPreviewAngle(-30.0)
	_controller.beginEdgeDrag(_handle, Vector3(1.5, 0, 0), _camera, _polycube)
	var captured : Transform3D = _controller._drag_initial_transforms[_anchor]

	assert_true(_anchor.global_transform.is_equal_approx(initial))
	assert_true(captured.is_equal_approx(initial))
	assert_almost_eq(_controller._drag_angle, 0.0, 0.001)
	assert_eq(_controller._drag_initial_transforms.size(), 2)

func test_input_cancels_drag_when_camera_is_no_longer_available() -> void :
	var initial : Transform3D = _anchor.global_transform
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	_controller.setPreviewAngle(-30.0)
	_controller._camera = null
	assert_true(_controller.dragEdgeInput(InputEventMouseMotion.new()))

	assert_eq(_controller._drag_state, FoldDragController.DragState.IDLE)
	assert_true(_anchor.global_transform.is_equal_approx(initial))
	assert_true(_controller._drag_detectors.is_empty())

func test_preview_ignores_all_moving_face_detectors() -> void :
	_body._fold_area.collision_layer = 0
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	_tip.global_transform = _anchor.global_transform
	await wait_physics_frames(2)

	assert_false(_controller.previewOverlaps())

func test_preview_detects_stationary_face_area() -> void :
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	_body.global_transform = _anchor.global_transform
	await wait_physics_frames(2)

	assert_true(_controller.previewOverlaps())

func test_preview_ignores_static_bodies_even_on_detector_layer() -> void :
	_body._fold_area.collision_layer = 0
	var obstacle : StaticBody3D = StaticBody3D.new()
	obstacle.collision_layer = 2
	var collision : CollisionShape3D = CollisionShape3D.new()
	var box : BoxShape3D = BoxShape3D.new()
	box.size = Vector3(0.5, 0.5, 0.5)
	collision.shape = box
	obstacle.add_child(collision)
	add_child_autofree(obstacle)
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	await wait_physics_frames(2)

	assert_false(_controller.previewOverlaps())

func test_physics_commits_snapped_release_after_validating_rotation() -> void :
	_body._fold_area.collision_layer = 0
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	_controller._drag_direction = -1
	_controller._drag_snapped = true
	_controller._drag_requested_angle = -90.0
	_controller._drag_release_requested = true
	await wait_physics_frames(2)
	_controller._physics_process(1.0 / 60.0)

	assert_eq(_controller._drag_state, FoldDragController.DragState.IDLE)
	assert_true(_anchor.global_position.is_equal_approx(Vector3(-0.5, 0.5, 0)))
	assert_true(_tip.global_position.is_equal_approx(Vector3(-0.5, 1.5, 0)))

func test_collision_rolls_back_preview_and_release_cancels_move() -> void :
	_body._fold_area.collision_layer = 0
	var obstacle : Area3D = Area3D.new()
	obstacle.collision_layer = 2
	var collision : CollisionShape3D = CollisionShape3D.new()
	var box : BoxShape3D = BoxShape3D.new()
	box.size = Vector3(0.2, 0.2, 0.4)
	collision.shape = box
	obstacle.add_child(collision)
	obstacle.position = Vector3(0.9, 0.9, 0)
	add_child_autofree(obstacle)
	var initial : Transform3D = _anchor.global_transform
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	_controller._drag_direction = -1
	_controller._drag_snapped = true
	_controller._drag_requested_angle = -90.0
	await wait_physics_frames(2)
	_controller._physics_process(1.0 / 60.0)

	assert_true(_controller._drag_colliding)
	assert_lt(_controller._drag_angle, 0.0)
	assert_gt(_controller._drag_angle, -90.0)
	assert_false(_controller.previewOverlaps())
	_controller._drag_release_requested = true
	_controller._physics_process(1.0 / 60.0)
	assert_eq(_controller._drag_state, FoldDragController.DragState.IDLE)
	assert_true(_anchor.global_transform.is_equal_approx(initial))

func test_input_cancels_drag_when_target_is_no_longer_available() -> void :
	var initial : Transform3D = _anchor.global_transform
	_controller.beginEdgeDrag(_handle, _handle.global_position, _camera, _polycube)
	_controller.setPreviewAngle(-30.0)
	_controller._target = null
	assert_true(_controller.dragEdgeInput(InputEventMouseMotion.new()))

	assert_eq(_controller._drag_state, FoldDragController.DragState.IDLE)
	assert_true(_anchor.global_transform.is_equal_approx(initial))
	assert_null(_controller._drag_face)
	assert_null(_controller._drag_edge)
	assert_true(_controller._drag_detectors.is_empty())
