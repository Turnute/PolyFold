extends GutTest

var _face : Face
var _edge : Edge

func before_each() -> void :
	_face = preload("res://prefabs/face.tscn").instantiate() as Face
	_face._id_cube = 3
	_face._side = Face.FaceEnum.RIGHT
	_face._adj_faces = [-1, -1, -1, -1]
	add_child_autofree(_face)
	_edge = _face._edges[Edge.EdgeEnum.TOP]

func test_edge_starts_hidden_with_collision_disabled() -> void :
	assert_false(_edge._mesh.visible)
	assert_true(_edge._col.disabled)

func test_switch_toggles_visibility_and_collision_together() -> void :
	_edge.switch()
	assert_true(_edge._mesh.visible)
	assert_false(_edge._col.disabled)

	_edge.switch()
	assert_false(_edge._mesh.visible)
	assert_true(_edge._col.disabled)

func test_show_edge_sets_state_even_when_called_twice() -> void :
	_edge.showEdge(true)
	_edge.showEdge(true)
	assert_true(_edge._mesh.visible)
	assert_false(_edge._col.disabled)

	_edge.showEdge(false)
	_edge.showEdge(false)
	assert_false(_edge._mesh.visible)
	assert_true(_edge._col.disabled)

func test_select_uses_parent_face_when_no_attachment_is_bound() -> void :
	_edge = _face._edges[Edge.EdgeEnum.LEFT]
	var action : UnfoldAction = _edge.select(UnfoldAction.DirEnum.BWD)

	assert_eq(action._id_cube, 3)
	assert_eq(action._face, Face.FaceEnum.RIGHT)
	assert_eq(action._edge, Edge.EdgeEnum.LEFT)
	assert_eq(action._dir, UnfoldAction.DirEnum.BWD)

func test_select_uses_bound_attachment_instead_of_handle_parent() -> void :
	var attachment : Face = autofree(Face.new())
	attachment._id_cube = 8
	attachment._side = Face.FaceEnum.BACK
	_edge._fold_face = attachment
	_edge._fold_grabbed_side = Edge.EdgeEnum.RIGHT
	var action : UnfoldAction = _edge.select(UnfoldAction.DirEnum.FWD)

	assert_eq(action._id_cube, 8)
	assert_eq(action._face, Face.FaceEnum.BACK)
	assert_eq(action._edge, Edge.EdgeEnum.RIGHT)
	assert_eq(action._dir, UnfoldAction.DirEnum.FWD)

func test_select_falls_back_to_parent_after_attachment_is_freed() -> void :
	var attachment : Face = Face.new()
	_edge._fold_face = attachment
	attachment.free()
	var action : UnfoldAction = _edge.select(UnfoldAction.DirEnum.FWD)

	assert_eq(action._id_cube, 3)
	assert_eq(action._face, Face.FaceEnum.RIGHT)
	assert_eq(action._edge, Edge.EdgeEnum.TOP)
