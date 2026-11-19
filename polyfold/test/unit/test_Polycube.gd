extends GutTest

var _polycube : Polycube

func before_each() -> void :
	var first : Cube = Cube.new()
	first._id = 0
	first._pos = Vector3i.ZERO
	var second : Cube = Cube.new()
	second._id = 1
	second._pos = Vector3i.RIGHT
	_polycube = Polycube.new([first, second])
	add_child_autofree(_polycube)

func test_initial_adjacency_matrix_has_no_connections() -> void :
	assert_eq(_polycube._adj.size(), 2)
	assert_eq(_polycube._adj[0].size(), 2)
	assert_eq(_polycube._adj[1].size(), 2)
	for row in _polycube._adj:
		for side in row:
			assert_eq(side, Face.FaceEnum.NONE)
	for cube in _polycube._cubes:
		assert_eq(cube.get_parent(), _polycube)

func test_add_adjacency_connects_both_cubes_with_their_own_sides() -> void :
	_polycube.addAdj(0, 1, Face.FaceEnum.FRONT, Face.FaceEnum.BACK)

	assert_eq(_polycube._adj[0][1], Face.FaceEnum.FRONT)
	assert_eq(_polycube._adj[1][0], Face.FaceEnum.BACK)
	assert_eq(_polycube._adj[0][0], Face.FaceEnum.NONE)
	assert_eq(_polycube._adj[1][1], Face.FaceEnum.NONE)

func test_init_adjacency_resets_existing_connections_without_adding_rows() -> void :
	_polycube.addAdj(0, 1, Face.FaceEnum.FRONT, Face.FaceEnum.BACK)
	_polycube.initAdj()
	_polycube.initAdj()

	assert_eq(_polycube._adj.size(), 2)
	for row in _polycube._adj:
		assert_eq(row.size(), 2)
		for side in row:
			assert_eq(side, Face.FaceEnum.NONE)

func test_init_cube_creates_six_faces_for_an_isolated_cube() -> void :
	_polycube.initCube(0)

	assert_eq(_polycube._cubes[0]._faces.size(), 6)
	for side in range(Face.FaceEnum.TOP, Face.FaceEnum.BACK + 1):
		assert_not_null(_polycube.getFace(0, side))

func test_init_cube_does_not_create_internal_faces() -> void :
	_polycube.addAdj(0, 1, Face.FaceEnum.FRONT, Face.FaceEnum.BACK)
	_polycube.initCube(0)
	_polycube.initCube(1)

	assert_eq(_polycube._cubes[0]._faces.size(), 5)
	assert_eq(_polycube._cubes[1]._faces.size(), 5)
	assert_null(_polycube.getFace(0, Face.FaceEnum.FRONT))
	assert_null(_polycube.getFace(1, Face.FaceEnum.BACK))
	assert_not_null(_polycube.getFace(0, Face.FaceEnum.BACK))
	assert_not_null(_polycube.getFace(1, Face.FaceEnum.FRONT))

func test_get_face_by_identifier_resolves_cube_and_original_side() -> void :
	_polycube.initCube(0)
	_polycube.initCube(1)

	assert_eq(_polycube.getFaceFromFaceId(1), _polycube._cubes[0].getFace(Face.FaceEnum.TOP))
	assert_eq(_polycube.getFaceFromFaceId(16), _polycube._cubes[1].getFace(Face.FaceEnum.BACK))

func test_get_face_returns_null_for_an_internal_face() -> void :
	_polycube.addAdj(0, 1, Face.FaceEnum.FRONT, Face.FaceEnum.BACK)
	_polycube.initCube(0)
	_polycube.initCube(1)

	assert_null(_polycube.getFaceFromFaceId(5))
	assert_null(_polycube.getFaceFromFaceId(16))

func test_average_position_preserves_fractional_coordinates() -> void :
	assert_true(_polycube.getAveragePos().is_equal_approx(Vector3(0.5, 0, 0)))
	_polycube._cubes[0]._pos = Vector3i(-2, 1, 3)
	_polycube._cubes[1]._pos = Vector3i(1, 4, -2)
	assert_true(_polycube.getAveragePos().is_equal_approx(Vector3(-0.5, 2.5, 0.5)))

func test_average_position_stays_in_initial_grid_space() -> void :
	_polycube.position = Vector3(10, 20, 30)
	_polycube.rotation_degrees = Vector3(20, 30, 40)
	assert_true(_polycube.getAveragePos().is_equal_approx(Vector3(0.5, 0, 0)))

func test_empty_polycube_has_empty_adjacency_and_zero_average_position() -> void :
	var empty : Polycube = autofree(Polycube.new([]))
	assert_true(empty._adj.is_empty())
	assert_true(empty.getAveragePos().is_equal_approx(Vector3.ZERO))

func test_face_adjacency_connects_convex_edges_on_a_single_cube() -> void :
	var single : Polycube = Polycube.new([Cube.new()])
	single.initCube(0)
	single.initFaceAdj()
	add_child_autofree(single)
	var top : Face = single.getFace(0, Face.FaceEnum.TOP)
	var expected : Array[int] = [5, 6, 3, 4]

	assert_eq(top._adj_faces, expected)
	for face in single._cubes[0]._faces:
		assert_eq(face._adj_faces.size(), 4)
		for neighbour_id in face._adj_faces:
			assert_ne(neighbour_id, -1)
			assert_true(single.getFaceFromFaceId(neighbour_id)._adj_faces.has(face._id_face))

func test_face_adjacency_connects_coplanar_faces_on_neighbouring_cubes() -> void :
	_polycube.addAdj(0, 1, Face.FaceEnum.FRONT, Face.FaceEnum.BACK)
	_polycube.initCube(0)
	_polycube.initCube(1)
	_polycube.initFaceAdj()
	var first : Face = _polycube.getFace(0, Face.FaceEnum.TOP)
	var second : Face = _polycube.getFace(1, Face.FaceEnum.TOP)

	assert_eq(first.getNeighbouringFace(Edge.EdgeEnum.TOP), 11)
	assert_eq(second.getNeighbouringFace(Edge.EdgeEnum.BOTTOM), 1)
	assert_true(_polycube.areCoplanar(first, second))

func test_face_adjacency_connects_concave_edges_and_remains_reciprocal() -> void :
	var third : Cube = Cube.new()
	third._id = 2
	third._pos = Vector3i(1, 1, 0)
	_polycube._cubes.append(third)
	_polycube.add_child(third)
	_polycube.initAdj()
	_polycube.addAdj(0, 1, Face.FaceEnum.FRONT, Face.FaceEnum.BACK)
	_polycube.addAdj(1, 2, Face.FaceEnum.TOP, Face.FaceEnum.BOTTOM)
	for i in range(3):
		_polycube.initCube(i)
	_polycube.initFaceAdj()
	var top : Face = _polycube.getFace(0, Face.FaceEnum.TOP)
	var inner : Face = _polycube.getFace(2, Face.FaceEnum.BACK)

	assert_eq(top.getNeighbouringFace(Edge.EdgeEnum.TOP), 26)
	assert_eq(inner.getNeighbouringFace(Edge.EdgeEnum.BOTTOM), 1)
	for cube in _polycube._cubes:
		for face in cube._faces:
			for neighbour_id in face._adj_faces:
				assert_ne(neighbour_id, -1)
				assert_true(_polycube.getFaceFromFaceId(neighbour_id)._adj_faces.has(face._id_face))

func test_init_face_adjacency_restores_connections_after_a_cut() -> void :
	_polycube.addAdj(0, 1, Face.FaceEnum.FRONT, Face.FaceEnum.BACK)
	_polycube.initCube(0)
	_polycube.initCube(1)
	_polycube.initFaceAdj()
	var face : Face = _polycube.getFace(0, Face.FaceEnum.TOP)
	var expected : Array[int] = face._adj_faces.duplicate()
	face.disconnectFace(11)
	_polycube.initFaceAdj()

	assert_eq(face._adj_faces, expected)
