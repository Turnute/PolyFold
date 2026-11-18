extends GutTest

var _face : Face

func before_each() -> void :
	_face = Face.new()
	_face._adj_faces = [11, 12, -1, 14]

func test_disconnect_face_preserves_other_connections() -> void :
	var disconnected_side : int = _face.disconnectFace(12)
	var expected : Array[int] = [11, -1, -1, 14]
	
	assert_eq(disconnected_side, Edge.EdgeEnum.BOTTOM)
	assert_eq(_face._adj_faces, expected)

func test_disconnect_missing_face_changes_nothing() -> void :
	var init : Array[int] = _face._adj_faces.duplicate()
	var disconnected_side : int = _face.disconnectFace(99)
	assert_eq(disconnected_side, -1)
	assert_eq(_face._adj_faces, init)

func test_connect_face_restores_cut_connection() -> void :
	_face.disconnectFace(12)
	_face.connectFace(12, Edge.EdgeEnum.BOTTOM)
	var expected : Array[int] = [11, 12, -1, 14]
	assert_eq(_face._adj_faces, expected)
