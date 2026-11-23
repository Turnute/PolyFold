extends GutTest

var _polycube : Polycube
var _anchor : Face
var _tip : Face
var _body : Face
var _side : Face

func before_each() -> void :
	var cube : Cube = Cube.new()
	var sides : Array[int] = [
		Face.FaceEnum.TOP, Face.FaceEnum.FRONT,
		Face.FaceEnum.BOTTOM, Face.FaceEnum.BACK
	]
	var positions : Array[Vector3] = [
		Vector3.ZERO, Vector3.RIGHT,
		Vector3(-0.5, -0.5, 0), Vector3(0, -0.5, -0.5)
	]
	for i in range(4):
		var face : Face = preload("res://prefabs/face.tscn").instantiate() as Face
		face._side = sides[i]
		face.position = positions[i]
		if i == 2:
			face.basis = Basis(Vector3.FORWARD, PI / 2.0)
		elif i == 3:
			face.basis = Basis(Vector3.RIGHT, PI / 2.0)
		cube.add_child(face)
		cube._faces.append(face)
	_anchor = cube._faces[0]
	_tip = cube._faces[1]
	_body = cube._faces[2]
	_side = cube._faces[3]
	_anchor._adj_faces = [5, 2, 6, -1]
	_tip._adj_faces = [-1, 1, -1, -1]
	_body._adj_faces = [6, 1, -1, -1]
	_side._adj_faces = [2, -1, -1, 1]
	_polycube = Polycube.new([cube])
	add_child_autofree(_polycube)

func test_valid_move_requires_connected_hinge_outside_selection() -> void :
	var valid : UnfoldAction = UnfoldAction.createAction(
		0, Face.FaceEnum.TOP, Edge.EdgeEnum.TOP, UnfoldAction.DirEnum.FWD
	)
	var missing_hinge : UnfoldAction = UnfoldAction.createAction(
		0, Face.FaceEnum.TOP, Edge.EdgeEnum.LEFT, UnfoldAction.DirEnum.FWD
	)
	var internal_hinge : UnfoldAction = UnfoldAction.createAction(
		0, Face.FaceEnum.TOP, Edge.EdgeEnum.BOTTOM, UnfoldAction.DirEnum.FWD
	)

	assert_true(Unfolder.validMove(valid, _polycube))
	assert_false(Unfolder.validMove(missing_hinge, _polycube))
	assert_false(Unfolder.validMove(internal_hinge, _polycube))

func test_invalid_move_preserves_geometry_connections_and_action() -> void :
	var initial_transforms : Dictionary = {}
	var initial_connections : Dictionary = {}
	for face in _polycube._cubes[0]._faces:
		initial_transforms[face] = face.global_transform
		initial_connections[face] = face._adj_faces.duplicate()
	var action : UnfoldAction = UnfoldAction.createAction(
		0, Face.FaceEnum.TOP, Edge.EdgeEnum.LEFT, UnfoldAction.DirEnum.FWD
	)
	Unfolder.executeMove(action, _polycube)

	for face in _polycube._cubes[0]._faces:
		assert_true(face.global_transform.is_equal_approx(initial_transforms[face]))
		assert_eq(face._adj_faces, initial_connections[face])
	assert_true(action._group.is_empty())
	assert_true(action._deconnected_face.is_empty())

func test_forward_move_rotates_whole_group_and_preserves_stationary_faces() -> void :
	var body_transform : Transform3D = _body.global_transform
	var side_transform : Transform3D = _side.global_transform
	var hinge : Edge = _anchor._edges[Edge.EdgeEnum.BOTTOM]
	var pivot : Vector3 = hinge.global_position
	var action : UnfoldAction = UnfoldAction.createAction(
		0, Face.FaceEnum.TOP, Edge.EdgeEnum.TOP, UnfoldAction.DirEnum.FWD
	)
	Unfolder.executeMove(action, _polycube)

	assert_true(_anchor.global_position.is_equal_approx(Vector3(-0.5, -0.5, 0)))
	assert_true(_tip.global_position.is_equal_approx(Vector3(-0.5, -1.5, 0)))
	assert_true(_anchor.global_basis.y.is_equal_approx(Vector3.RIGHT))
	assert_true(_tip.global_basis.y.is_equal_approx(Vector3.RIGHT))
	assert_true(hinge.global_position.is_equal_approx(pivot))
	assert_true(_body.global_transform.is_equal_approx(body_transform))
	assert_true(_side.global_transform.is_equal_approx(side_transform))
	var group : Array[int] = action._group.duplicate()
	group.sort()
	var expected : Array[int] = [1, 5]
	assert_eq(group, expected)

func test_backward_move_rotates_in_opposite_direction() -> void :
	var action : UnfoldAction = UnfoldAction.createAction(
		0, Face.FaceEnum.TOP, Edge.EdgeEnum.TOP, UnfoldAction.DirEnum.BWD
	)
	Unfolder.executeMove(action, _polycube)

	assert_true(_anchor.global_position.is_equal_approx(Vector3(-0.5, 0.5, 0)))
	assert_true(_tip.global_position.is_equal_approx(Vector3(-0.5, 1.5, 0)))
	assert_true(_anchor.global_basis.y.is_equal_approx(Vector3.LEFT))
	assert_true(_tip.global_basis.y.is_equal_approx(Vector3.LEFT))

func test_move_records_both_sides_of_cuts_but_preserves_hinge_and_internal_links() -> void :
	var action : UnfoldAction = UnfoldAction.createAction(
		0, Face.FaceEnum.TOP, Edge.EdgeEnum.TOP, UnfoldAction.DirEnum.BWD
	)
	Unfolder.executeMove(action, _polycube)
	var expected_cuts : Array = [
		[1, Edge.EdgeEnum.LEFT, 6], [6, Edge.EdgeEnum.RIGHT, 1]
	]

	assert_eq(action._deconnected_face, expected_cuts)
	assert_eq(_anchor.getNeighbouringFace(Edge.EdgeEnum.LEFT), -1)
	assert_eq(_side.getNeighbouringFace(Edge.EdgeEnum.RIGHT), -1)
	assert_eq(_anchor.getNeighbouringFace(Edge.EdgeEnum.TOP), _tip._id_face)
	assert_eq(_tip.getNeighbouringFace(Edge.EdgeEnum.BOTTOM), _anchor._id_face)
	assert_eq(_anchor.getNeighbouringFace(Edge.EdgeEnum.BOTTOM), _body._id_face)
	assert_eq(_body.getNeighbouringFace(Edge.EdgeEnum.BOTTOM), _anchor._id_face)
	assert_eq(_body.getNeighbouringFace(Edge.EdgeEnum.TOP), _side._id_face)

func test_move_with_only_one_attachment_has_no_cuts_to_record() -> void :
	_anchor.disconnectFace(_side._id_face)
	_side.disconnectFace(_anchor._id_face)
	var action : UnfoldAction = UnfoldAction.createAction(
		0, Face.FaceEnum.TOP, Edge.EdgeEnum.TOP, UnfoldAction.DirEnum.BWD
	)
	Unfolder.executeMove(action, _polycube)

	assert_true(action._deconnected_face.is_empty())
	assert_eq(_anchor.getNeighbouringFace(Edge.EdgeEnum.BOTTOM), _body._id_face)

func test_inverse_move_restores_geometry_and_connections_in_both_directions() -> void :
	var initial_transforms : Dictionary = {}
	var initial_connections : Dictionary = {}
	for face in _polycube._cubes[0]._faces:
		initial_transforms[face] = face.global_transform
		initial_connections[face] = face._adj_faces.duplicate()

	for direction in [UnfoldAction.DirEnum.FWD, UnfoldAction.DirEnum.BWD]:
		var action : UnfoldAction = UnfoldAction.createAction(
			0, Face.FaceEnum.TOP, Edge.EdgeEnum.TOP, direction
		)
		Unfolder.executeMove(action, _polycube)
		var inverse_direction : UnfoldAction.DirEnum = UnfoldAction.DirEnum.BWD
		if direction == UnfoldAction.DirEnum.BWD:
			inverse_direction = UnfoldAction.DirEnum.FWD
		var inverse : UnfoldAction = UnfoldAction.createActionGroup(
			action._id_cube, action._face, action._edge, inverse_direction,
			action._group, action._deconnected_face
		)
		Unfolder.connectMove(inverse, _polycube)

		for face in _polycube._cubes[0]._faces:
			assert_true(face.global_transform.is_equal_approx(initial_transforms[face]))
			assert_eq(face._adj_faces, initial_connections[face])
