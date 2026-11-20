extends GutTest

var _polycube : Polycube
var _anchor : Face
var _middle : Face
var _tip : Face
var _body : Face
var _body_tip : Face

func before_each() -> void :
	# Three coplanar faces form a strip attached to two perpendicular faces.
	var cube : Cube = Cube.new()
	var sides : Array[int] = [
		Face.FaceEnum.TOP, Face.FaceEnum.FRONT, Face.FaceEnum.RIGHT,
		Face.FaceEnum.BOTTOM, Face.FaceEnum.BACK
	]
	var positions : Array[Vector3] = [
		Vector3.ZERO, Vector3.RIGHT, Vector3(2, 0, 0),
		Vector3(-0.5, -0.5, 0), Vector3(-0.5, -1.5, 0)
	]
	for i in range(5):
		var face : Face = preload("res://prefabs/face.tscn").instantiate() as Face
		face._side = sides[i]
		face._ogColor = Color(0.2, 0.4, 0.6)
		face.position = positions[i]
		if i >= 3:
			face.basis = Basis(Vector3.FORWARD, PI / 2.0)
		cube.add_child(face)
		cube._faces.append(face)
	_anchor = cube._faces[0]
	_middle = cube._faces[1]
	_tip = cube._faces[2]
	_body = cube._faces[3]
	_body_tip = cube._faces[4]
	_anchor._adj_faces = [5, 2, -1, -1]
	_middle._adj_faces = [4, 1, -1, -1]
	_tip._adj_faces = [-1, 5, -1, -1]
	_body._adj_faces = [6, 1, -1, -1]
	_body_tip._adj_faces = [-1, 2, -1, -1]
	_polycube = Polycube.new([cube])
	add_child_autofree(_polycube)

func test_collect_faces_visits_entire_connected_component() -> void :
	var found : Array[int] = _polycube.collectFaces(_tip._id_face, [])
	var expected : Array[int] = [1, 2, 4, 5, 6]
	found.sort()
	assert_eq(found, expected)

func test_collect_faces_handles_cycles_without_duplicates() -> void :
	_anchor.connectFace(_tip._id_face, Edge.EdgeEnum.LEFT)
	_tip.connectFace(_anchor._id_face, Edge.EdgeEnum.RIGHT)
	var found : Array[int] = _polycube.collectFaces(_anchor._id_face, [])
	var expected : Array[int] = [1, 2, 4, 5, 6]
	found.sort()
	assert_eq(found, expected)

func test_collect_faces_does_not_cross_excluded_faces() -> void :
	var found : Array[int] = _polycube.collectFaces(_anchor._id_face, [_middle._id_face])
	var expected : Array[int] = [1, 2, 6]
	found.sort()
	assert_eq(found, expected)

func test_collect_faces_returns_empty_for_excluded_or_disconnected_start() -> void :
	assert_true(_polycube.collectFaces(_anchor._id_face, [_anchor._id_face]).is_empty())
	assert_true(_polycube.collectFaces(-1, []).is_empty())

func test_collect_faces_restricts_traversal_to_reference_plane() -> void :
	var found : Array[int] = _polycube.collectFaces(_anchor._id_face, [], _anchor)
	var expected : Array[int] = [1, 4, 5]
	found.sort()
	assert_eq(found, expected)

func test_collect_faces_does_not_cross_another_plane_to_reach_a_coplanar_face() -> void :
	_body_tip.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 0, 2))
	var found : Array[int] = _polycube.collectFaces(_anchor._id_face, [], _anchor)
	var expected : Array[int] = [1, 4, 5]
	found.sort()
	assert_eq(found, expected)

func test_selection_group_does_not_merge_faces_with_a_second_body_attachment() -> void:
	_middle.connectFace(_body_tip._id_face, Edge.EdgeEnum.LEFT)
	_body_tip.connectFace(_middle._id_face, Edge.EdgeEnum.RIGHT)

	var group: Array[int] = _polycube.getSelectionGroup(_anchor._id_face)
	var expected: Array[int] = [_anchor._id_face]

	assert_eq(group, expected)

func test_selection_group_starts_at_clicked_face() -> void:
	var faces: Array[Face] = [_anchor, _middle, _tip]
	var expected: Array[Array] = [[1, 4, 5], [4, 5], [4]]

	for i in range(faces.size()):
		var group: Array[int] = _polycube.getSelectionGroup(faces[i]._id_face)
		group.sort()
		assert_eq(group, expected[i])

func test_selection_group_does_not_follow_cycle_back_to_body() -> void :
	_anchor.connectFace(_tip._id_face, Edge.EdgeEnum.LEFT)
	_tip.connectFace(_anchor._id_face, Edge.EdgeEnum.RIGHT)
	var group : Array[int] = _polycube.getSelectionGroup(_tip._id_face)
	var expected: Array[int] = [_tip._id_face]
	group.sort()
	assert_eq(group, expected)

func test_fold_group_contains_strip_and_excludes_stationary_body() -> void :
	var group : Array[int] = _polycube.getFoldGroup(_anchor._id_face, Edge.EdgeEnum.TOP)
	var expected : Array[int] = [1, 4, 5]
	group.sort()

	assert_eq(group, expected)
	assert_true(_polycube.canFoldFace(_anchor._id_face, Edge.EdgeEnum.TOP))

func test_fold_group_rejects_missing_hinge_and_hinge_inside_selection() -> void :
	assert_true(_polycube.getFoldGroup(_anchor._id_face, Edge.EdgeEnum.LEFT).is_empty())
	assert_true(_polycube.getFoldGroup(_anchor._id_face, Edge.EdgeEnum.BOTTOM).is_empty())
	assert_false(_polycube.canFoldFace(_anchor._id_face, Edge.EdgeEnum.LEFT))
	assert_false(_polycube.canFoldFace(_anchor._id_face, Edge.EdgeEnum.BOTTOM))

func test_fold_group_includes_non_coplanar_dependent_branch() -> void :
	_body.disconnectFace(_body_tip._id_face)
	_body_tip.disconnectFace(_body._id_face)
	
	var extra: Cube = Cube.new()
	extra._id = 1
	extra.createFace(Face.FaceEnum.TOP)
	extra.createFace(Face.FaceEnum.FRONT)

	var body_a: Face = extra.getFace(Face.FaceEnum.TOP)
	var body_b: Face = extra.getFace(Face.FaceEnum.FRONT)

	body_a._adj_faces = [body_b._id_face, _body._id_face, -1, -1]
	body_b._adj_faces = [_body._id_face, body_a._id_face, -1, -1]

	_body.connectFace(body_a._id_face, Edge.EdgeEnum.TOP)
	_body.connectFace(body_b._id_face, Edge.EdgeEnum.LEFT)

	_polycube._cubes.append(extra)
	_polycube.add_child(extra)
	
	_tip.connectFace(_body_tip._id_face, Edge.EdgeEnum.TOP)
	_body_tip.connectFace(_tip._id_face, Edge.EdgeEnum.BOTTOM)
	var group : Array[int] = _polycube.getFoldGroup(_anchor._id_face, Edge.EdgeEnum.TOP)
	var expected : Array[int] = [1, 4, 5, 6]
	group.sort()

	assert_eq(group, expected)
	assert_false(group.has(_body._id_face))

func test_get_edge_axis_uses_world_orientation_and_normalizes_scale() -> void :
	_anchor.rotation_degrees.y = 90.0
	_anchor.scale = Vector3(2, 3, 4)
	var top_axis : Vector3 = _polycube.getEdgeAxis(_anchor, _anchor._edges[Edge.EdgeEnum.TOP])
	var left_axis : Vector3 = _polycube.getEdgeAxis(_anchor, _anchor._edges[Edge.EdgeEnum.LEFT])

	assert_true(top_axis.is_equal_approx(Vector3.LEFT))
	assert_true(left_axis.is_equal_approx(Vector3.FORWARD))
	assert_almost_eq(top_axis.length(), 1.0, 0.00001)
	assert_almost_eq(left_axis.length(), 1.0, 0.00001)

func test_farthest_handle_is_parallel_boundary_on_opposite_end_of_strip() -> void :
	var group : Array[int] = [1, 5, 4]
	var hinge : Edge = _anchor._edges[Edge.EdgeEnum.BOTTOM]
	var handle : Edge = _polycube.findFarthestHandle(group, _anchor, hinge)

	assert_eq(handle, _tip._edges[Edge.EdgeEnum.TOP])
	assert_false(group.has(_tip.getNeighbouringFace(handle._side)))

func test_farthest_handle_still_resolves_after_parent_rotation() -> void :
	_polycube.rotation_degrees = Vector3(20, 60, 30)
	_polycube.position = Vector3(4, 3, -2)
	var group : Array[int] = [1, 5, 4]
	var handle : Edge = _polycube.findFarthestHandle(
		group, _anchor, _anchor._edges[Edge.EdgeEnum.BOTTOM]
	)

	assert_eq(handle, _tip._edges[Edge.EdgeEnum.TOP])

func test_find_farthest_handle_returns_null_for_empty_group() -> void :
	assert_null(_polycube.findFarthestHandle([], _anchor, _anchor._edges[Edge.EdgeEnum.BOTTOM]))

func test_select_face_highlights_group_and_binds_only_farthest_handle() -> void :
	_polycube.selectFace(_anchor._id_face)
	var handle : Edge = _tip._edges[Edge.EdgeEnum.TOP]

	assert_eq(_polycube._selected_face_id, _anchor._id_face)
	assert_eq(handle._fold_face, _anchor)
	assert_eq(handle._fold_grabbed_side, Edge.EdgeEnum.TOP)
	for face in [_anchor, _middle, _tip]:
		assert_eq(face._material.albedo_color, face._selectionColor)
	for face in [_body, _body_tip]:
		assert_eq(face._material.albedo_color, face._ogColor)
	for face in _polycube._cubes[0]._faces:
		for edge in face._edges:
			assert_eq(edge._mesh.visible, edge == handle)
			assert_eq(edge._col.disabled, edge != handle)

func test_selecting_another_group_clears_previous_handle_binding() -> void :
	_polycube.selectFace(_anchor._id_face)
	var old_handle : Edge = _tip._edges[Edge.EdgeEnum.TOP]
	_polycube.selectFace(_body_tip._id_face)
	var new_handle : Edge = _body_tip._edges[Edge.EdgeEnum.TOP]

	assert_null(old_handle._fold_face)
	assert_false(old_handle._mesh.visible)
	assert_eq(_anchor._material.albedo_color, _anchor._ogColor)
	assert_eq(new_handle._fold_face, _body_tip)
	assert_true(new_handle._mesh.visible)

func test_unselect_all_faces_restores_colors_and_hides_handles() -> void :
	_polycube.selectFace(_tip._id_face)
	_polycube.unselectAllFaces()

	assert_eq(_polycube._selected_face_id, -1)
	for face in _polycube._cubes[0]._faces:
		assert_eq(face._material.albedo_color, face._ogColor)
		for edge in face._edges:
			assert_false(edge._mesh.visible)
			assert_true(edge._col.disabled)
