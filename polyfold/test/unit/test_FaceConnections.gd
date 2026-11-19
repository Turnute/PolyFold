extends GutTest

var _face : Face

func before_each() -> void :
	_face = autofree(Face.new())
	_face._adj_faces = [
		11,	# TOP connected face id
		12,	# BOTTOM connected face id
		-1,	# LEFT connected face id (disconnected)
		14	# RIGHT connected face id
		]

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

func test_disconnect_from_edge_cuts_other_connections() -> void :
	var e : Edge = autofree(Edge.new())
	e._side = Edge.EdgeEnum.TOP
	var disconnected_faces = _face.disconnectFromEdge(e)
	var expected_cuts = [12, 14]
	var expected = [11, -1, -1, -1]
	
	assert_eq(disconnected_faces, expected_cuts)
	assert_eq(_face._adj_faces, expected)

func test_disconnect_twice() -> void :
	var disconnected_side : int = _face.disconnectFace(14)
	assert_eq(disconnected_side, Edge.EdgeEnum.RIGHT)
	
	disconnected_side = _face.disconnectFace(14)
	var expected : Array[int] = [11, 12, -1, -1]
	
	assert_eq(disconnected_side, -1)
	assert_eq(_face._adj_faces, expected)

func test_get_neighbouring_face_returns_connection_or_minus_one() -> void :
	assert_eq(_face.getNeighbouringFace(Edge.EdgeEnum.TOP), 11)
	assert_eq(_face.getNeighbouringFace(Edge.EdgeEnum.BOTTOM), 12)
	assert_eq(_face.getNeighbouringFace(Edge.EdgeEnum.LEFT), -1)
	assert_eq(_face.getNeighbouringFace(Edge.EdgeEnum.RIGHT), 14)

func test_connect_face_only_changes_requested_side() -> void :
	_face.connectFace(23, Edge.EdgeEnum.LEFT)
	var expected : Array[int] = [11, 12, 23, 14]
	assert_eq(_face._adj_faces, expected)

	_face.connectFace(24, Edge.EdgeEnum.RIGHT)
	expected = [11, 12, 23, 24]
	assert_eq(_face._adj_faces, expected)

func test_disconnect_from_missing_hinge_cuts_all_connections() -> void :
	var edge : Edge = autofree(Edge.new())
	edge._side = Edge.EdgeEnum.LEFT
	var disconnected : Array[int] = _face.disconnectFromEdge(edge)
	var expected_cuts : Array[int] = [11, 12, 14]
	var expected : Array[int] = [-1, -1, -1, -1]

	assert_eq(disconnected, expected_cuts)
	assert_eq(_face._adj_faces, expected)

func test_disconnect_from_edge_twice_does_not_cut_hinge() -> void :
	var edge : Edge = autofree(Edge.new())
	edge._side = Edge.EdgeEnum.TOP
	_face.disconnectFromEdge(edge)
	var disconnected : Array[int] = _face.disconnectFromEdge(edge)
	var expected : Array[int] = [11, -1, -1, -1]

	assert_true(disconnected.is_empty())
	assert_eq(_face._adj_faces, expected)
