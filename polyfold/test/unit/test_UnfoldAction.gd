extends GutTest

func test_create_action_records_requested_move_with_no_previous_cuts() -> void :
	var action : UnfoldAction = UnfoldAction.createAction(
		12, Face.FaceEnum.FRONT, Edge.EdgeEnum.LEFT, UnfoldAction.DirEnum.BWD
	)

	assert_eq(action._id_cube, 12)
	assert_eq(action._face, Face.FaceEnum.FRONT)
	assert_eq(action._edge, Edge.EdgeEnum.LEFT)
	assert_eq(action._dir, UnfoldAction.DirEnum.BWD)
	assert_true(action._group.is_empty())
	assert_true(action._deconnected_face.is_empty())

func test_create_action_group_keeps_faces_and_cuts_for_reconnection() -> void :
	var group : Array[int] = [21, 35]
	var cuts : Array = [[21, Edge.EdgeEnum.LEFT, 46], [46, Edge.EdgeEnum.TOP, 21]]
	var action : UnfoldAction = UnfoldAction.createActionGroup(
		2, Face.FaceEnum.TOP, Edge.EdgeEnum.RIGHT, UnfoldAction.DirEnum.FWD,
		group, cuts
	)

	assert_eq(action._id_cube, 2)
	assert_eq(action._face, Face.FaceEnum.TOP)
	assert_eq(action._edge, Edge.EdgeEnum.RIGHT)
	assert_eq(action._dir, UnfoldAction.DirEnum.FWD)
	assert_eq(action._group, group)
	assert_eq(action._deconnected_face, cuts)

func test_new_actions_do_not_share_default_group_or_cut_arrays() -> void :
	var first : UnfoldAction = UnfoldAction.createAction(
		0, Face.FaceEnum.TOP, Edge.EdgeEnum.TOP, UnfoldAction.DirEnum.FWD
	)
	var second : UnfoldAction = UnfoldAction.createAction(
		0, Face.FaceEnum.TOP, Edge.EdgeEnum.TOP, UnfoldAction.DirEnum.FWD
	)
	first._group.append(1)
	first._deconnected_face.append([1, Edge.EdgeEnum.LEFT, 2])

	assert_ne(first, second)
	assert_true(second._group.is_empty())
	assert_true(second._deconnected_face.is_empty())
