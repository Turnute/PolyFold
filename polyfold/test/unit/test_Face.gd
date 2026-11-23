extends GutTest

var _face : Face

func before_each() -> void :
	_face = preload("res://prefabs/face.tscn").instantiate() as Face
	_face._id_cube = 12
	_face._side = Face.FaceEnum.FRONT
	_face._ogColor = Color(0.2, 0.4, 0.6)
	_face._adj_faces = [11, 12, 13, 14]
	add_child_autofree(_face)

func test_face_identifier_and_decoder_agree_for_all_sides() -> void :
	for side in range(Face.FaceEnum.TOP, Face.FaceEnum.BACK + 1):
		_face._side = side
		var expected : Array[int] = [12, side]
		assert_eq(_face._id_face, 120 + side)
		assert_eq(Face.faceIdToCubeIDWithSide(_face._id_face), expected)

func test_first_cube_face_identifier_keeps_cube_zero() -> void :
	var expected : Array[int] = [0, Face.FaceEnum.BACK]
	assert_eq(Face.faceIdToCubeIDWithSide(6), expected)

func test_get_info_returns_side_before_cube_identifier() -> void :
	var expected : Array[int] = [Face.FaceEnum.FRONT, 12]
	assert_eq(_face.getInfo(), expected)

func test_ready_creates_one_edge_per_side_at_face_boundary() -> void :
	var expected : Array[Vector3] = [
		Vector3(0.5, 0, 0), Vector3(-0.5, 0, 0),
		Vector3(0, 0, -0.5), Vector3(0, 0, 0.5)
	]
	assert_eq(_face._edges.size(), 4)
	for i in range(4):
		assert_eq(_face._edges[i]._side, i)
		assert_eq(_face._edges[i].get_parent(), _face)
		assert_true(_face._edges[i].position.is_equal_approx(expected[i]))

func test_select_and_unselect_restore_color_and_handle_state() -> void :
	_face.select()
	assert_eq(_face._material.albedo_color, _face._selectionColor)
	for edge in _face._edges:
		assert_true(edge._mesh.visible)
		assert_false(edge._col.disabled)

	_face.unselect()
	assert_eq(_face._material.albedo_color, _face._ogColor)
	for edge in _face._edges:
		assert_false(edge._mesh.visible)
		assert_true(edge._col.disabled)

func test_switch_edges_toggles_every_handle() -> void :
	_face.switchEdges()
	for edge in _face._edges:
		assert_true(edge._mesh.visible)
		assert_false(edge._col.disabled)

	_face.switchEdges()
	for edge in _face._edges:
		assert_false(edge._mesh.visible)
		assert_true(edge._col.disabled)

func test_show_edges_sets_every_handle_to_requested_state() -> void :
	_face.showEdges(true)
	_face.showEdges(true)
	for edge in _face._edges:
		assert_true(edge._mesh.visible)
		assert_false(edge._col.disabled)

	_face.showEdges(false)
	for edge in _face._edges:
		assert_false(edge._mesh.visible)
		assert_true(edge._col.disabled)

func test_rotation_around_top_edge_keeps_pivot_fixed() -> void :
	var edge : Edge = _face._edges[Edge.EdgeEnum.TOP]
	var pivot : Vector3 = edge.global_position
	_face.rotateAroundEdge(edge, 90.0)

	assert_true(_face.global_position.is_equal_approx(Vector3(0.5, 0.5, 0)))
	assert_true(_face.global_basis.y.is_equal_approx(Vector3.RIGHT))
	assert_true(edge.global_position.is_equal_approx(pivot))

func test_rotation_around_left_edge_uses_other_axis() -> void :
	var edge : Edge = _face._edges[Edge.EdgeEnum.LEFT]
	var pivot : Vector3 = edge.global_position
	_face.rotateAroundEdge(edge, 90.0)

	assert_true(_face.global_position.is_equal_approx(Vector3(0, -0.5, -0.5)))
	assert_true(_face.global_basis.y.is_equal_approx(Vector3.BACK))
	assert_true(edge.global_position.is_equal_approx(pivot))

func test_opposite_rotations_restore_initial_transform() -> void :
	var edge : Edge = _face._edges[Edge.EdgeEnum.RIGHT]
	var initial : Transform3D = _face.global_transform
	_face.rotateAroundEdge(edge, -90.0)
	_face.rotateAroundEdge(edge, 90.0)

	assert_true(_face.global_transform.is_equal_approx(initial))

func test_rotation_uses_hinge_axis_after_parent_rotation() -> void :
	var parent : Node3D = Node3D.new()
	add_child_autofree(parent)
	_face.reparent(parent)
	parent.position = Vector3(3, 4, 5)
	parent.rotation_degrees.y = 90.0
	var edge : Edge = _face._edges[Edge.EdgeEnum.TOP]
	var pivot : Vector3 = edge.global_position
	_face.rotateAroundEdge(edge, 90.0)

	assert_true(_face.global_position.is_equal_approx(Vector3(3, 4.5, 4.5)))
	assert_true(_face.global_basis.y.is_equal_approx(Vector3.FORWARD))
	assert_true(edge.global_position.is_equal_approx(pivot))

func test_cut_insets_disconnected_borders_and_preserves_thickness() -> void :
	var thickness : float = _face._mesh.mesh.size.y
	var mesh_y : float = _face._mesh.position.y
	_face._adj_faces = [-1, 12, -1, 14]
	_face.updateConnectionVisuals()

	assert_true(_face._mesh.mesh.size.is_equal_approx(Vector3(
		1.0 - Face.CUT_INSET, thickness, 1.0 - Face.CUT_INSET
	)))
	assert_true(_face._mesh.position.is_equal_approx(Vector3(
		-Face.CUT_INSET / 2.0, mesh_y, Face.CUT_INSET / 2.0
	)))

func test_cutting_all_borders_shrinks_mesh_without_moving_center() -> void :
	_face._adj_faces = [-1, -1, -1, -1]
	_face.updateConnectionVisuals()
	var expected : float = 1.0 - 2.0 * Face.CUT_INSET

	assert_almost_eq(_face._mesh.mesh.size.x, expected, 0.00001)
	assert_almost_eq(_face._mesh.mesh.size.z, expected, 0.00001)
	assert_almost_eq(_face._mesh.position.x, 0.0, 0.00001)
	assert_almost_eq(_face._mesh.position.z, 0.0, 0.00001)

func test_reconnecting_borders_restores_mesh_without_accumulating_insets() -> void :
	var initial_size : Vector3 = _face._mesh.mesh.size
	var initial_position : Vector3 = _face._mesh.position
	_face.disconnectFace(11)
	_face.updateConnectionVisuals()
	_face.updateConnectionVisuals()
	_face.connectFace(11, Edge.EdgeEnum.TOP)

	assert_true(_face._mesh.mesh.size.is_equal_approx(initial_size))
	assert_true(_face._mesh.position.is_equal_approx(initial_position))

func test_each_face_has_its_own_mesh_and_highlight_material() -> void :
	var other : Face = preload("res://prefabs/face.tscn").instantiate() as Face
	other._ogColor = Color(0.6, 0.3, 0.2)
	other._adj_faces = [21, 22, 23, 24]
	add_child_autofree(other)
	var other_size : Vector3 = other._mesh.mesh.size
	_face.disconnectFace(11)
	_face.select()

	assert_ne(_face._mesh.mesh, other._mesh.mesh)
	assert_ne(_face._material, other._material)
	assert_true(other._mesh.mesh.size.is_equal_approx(other_size))
	assert_eq(other._material.albedo_color, other._ogColor)
