extends GutTest

var _cube : Cube

func before_each() -> void :
	_cube = Cube.new()
	_cube._id = 7
	_cube._pos = Vector3i(2, 3, 4)
	_cube._col = Color(0.2, 0.4, 0.6)
	add_child_autofree(_cube)

func test_get_face_returns_null_when_side_is_absent() -> void :
	assert_null(_cube.getFace(Face.FaceEnum.TOP))
	_cube.createFace(Face.FaceEnum.BOTTOM)
	assert_null(_cube.getFace(Face.FaceEnum.TOP))

func test_create_face_preserves_cube_identity_and_color() -> void :
	_cube.createFace(Face.FaceEnum.LEFT)
	var face : Face = _cube.getFace(Face.FaceEnum.LEFT)

	assert_eq(_cube._faces.size(), 1)
	assert_eq(face.get_parent(), _cube)
	assert_eq(face._id_cube, 7)
	assert_eq(face._side, Face.FaceEnum.LEFT)
	assert_eq(face._id_face, 73)
	assert_eq(face._ogColor, _cube._col)
	assert_eq(face._material.albedo_color, _cube._col)

func test_create_top_face_places_it_on_upper_surface() -> void :
	_cube.createFace(Face.FaceEnum.TOP)
	var face : Face = _cube.getFace(Face.FaceEnum.TOP)

	assert_true(face.position.is_equal_approx(Vector3(2, 4, 4)))
	assert_true(face.basis.y.is_equal_approx(Vector3.UP))

func test_create_bottom_face_points_down() -> void :
	_cube.createFace(Face.FaceEnum.BOTTOM)
	var face : Face = _cube.getFace(Face.FaceEnum.BOTTOM)

	assert_true(face.position.is_equal_approx(Vector3(2, 3, 4)))
	assert_true(face.basis.y.is_equal_approx(Vector3.DOWN))

func test_create_left_face_points_towards_negative_z() -> void :
	_cube.createFace(Face.FaceEnum.LEFT)
	var face : Face = _cube.getFace(Face.FaceEnum.LEFT)

	assert_true(face.position.is_equal_approx(Vector3(2, 3.5, 3.5)))
	assert_true(face.basis.y.is_equal_approx(Vector3.FORWARD))

func test_create_right_face_points_towards_positive_z() -> void :
	_cube.createFace(Face.FaceEnum.RIGHT)
	var face : Face = _cube.getFace(Face.FaceEnum.RIGHT)

	assert_true(face.position.is_equal_approx(Vector3(2, 3.5, 4.5)))
	assert_true(face.basis.y.is_equal_approx(Vector3.BACK))

func test_create_front_face_points_towards_positive_x() -> void :
	_cube.createFace(Face.FaceEnum.FRONT)
	var face : Face = _cube.getFace(Face.FaceEnum.FRONT)

	assert_true(face.position.is_equal_approx(Vector3(2.5, 3.5, 4)))
	assert_true(face.basis.y.is_equal_approx(Vector3.RIGHT))

func test_create_back_face_points_towards_negative_x() -> void :
	_cube.createFace(Face.FaceEnum.BACK)
	var face : Face = _cube.getFace(Face.FaceEnum.BACK)

	assert_true(face.position.is_equal_approx(Vector3(1.5, 3.5, 4)))
	assert_true(face.basis.y.is_equal_approx(Vector3.LEFT))

func test_get_face_finds_requested_side_among_several_faces() -> void :
	_cube.createFace(Face.FaceEnum.RIGHT)
	_cube.createFace(Face.FaceEnum.TOP)
	_cube.createFace(Face.FaceEnum.BACK)

	assert_eq(_cube.getFace(Face.FaceEnum.RIGHT), _cube._faces[0])
	assert_eq(_cube.getFace(Face.FaceEnum.TOP), _cube._faces[1])
	assert_eq(_cube.getFace(Face.FaceEnum.BACK), _cube._faces[2])
	assert_null(_cube.getFace(Face.FaceEnum.LEFT))
