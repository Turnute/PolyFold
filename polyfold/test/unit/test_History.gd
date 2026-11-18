extends GutTest

var polycube : Polycube
var history : History 
const data_str = "res://data/polycubes/test_poly.tres"
var data : PolycubeData = load(data_str)

func before_each():
	polycube = PolycubeFactory.loadPolycube(data)
	polycube.createEdges()
	add_child_autofree(polycube)
	history = History.new()
	history.setPolucube(polycube)

func test_addAction() -> void:

	#Log._set_log_level(Log.Event.TRACE)
	#polycube.log()
	var action: UnfoldAction = UnfoldAction.createAction(0,Face.FaceEnum.TOP,Edge.EdgeEnum.TOP,UnfoldAction.DirEnum.FWD)
	
	Unfolder.executeMove(action, polycube)
	history.addAction(action)
	assert_eq(history._moves.size(), 1)
	history.addAction(action)
	assert_eq(history._moves.size(), 2)

func test_undoOneMove() -> void:
	#Log._set_log_level(Log.Event.TRACE)
	#polycube.log()
	var action: UnfoldAction = UnfoldAction.createAction(0,Face.FaceEnum.TOP,Edge.EdgeEnum.TOP,UnfoldAction.DirEnum.BWD)
	
	var face_disco_top = polycube.getFace(0,Face.FaceEnum.TOP)._adj_faces[Edge.EdgeEnum.TOP]
	var face_disco_left = polycube.getFace(0,Face.FaceEnum.TOP)._adj_faces[Edge.EdgeEnum.LEFT]
	var face_disco_right = polycube.getFace(0,Face.FaceEnum.TOP)._adj_faces[Edge.EdgeEnum.RIGHT]
	
	var face_init_id = polycube.getFace(0,Face.FaceEnum.TOP)._id_face
	
	Unfolder.executeMove(action, polycube)
	
	assert_eq(polycube.getFace(0,Face.FaceEnum.TOP)._adj_faces[Edge.EdgeEnum.TOP], -1)
	assert_eq(polycube.getFace(0,Face.FaceEnum.TOP)._adj_faces[Edge.EdgeEnum.LEFT], -1)
	assert_eq(polycube.getFace(0,Face.FaceEnum.TOP)._adj_faces[Edge.EdgeEnum.RIGHT], -1)
	
	assert_eq(polycube.getFaceFromFaceId(face_disco_left)._adj_faces[Edge.EdgeEnum.RIGHT], -1)
	assert_eq(polycube.getFaceFromFaceId(face_disco_right)._adj_faces[Edge.EdgeEnum.LEFT], -1)
	assert_eq(polycube.getFaceFromFaceId(face_disco_top)._adj_faces[Edge.EdgeEnum.BOTTOM], -1)


	
	history.addAction(action)
	history.undo()
	
	assert_eq(polycube.getFace(0,Face.FaceEnum.TOP)._adj_faces[Edge.EdgeEnum.TOP], face_disco_top)
	assert_eq(polycube.getFace(0,Face.FaceEnum.TOP)._adj_faces[Edge.EdgeEnum.LEFT], face_disco_left)
	assert_eq(polycube.getFace(0,Face.FaceEnum.TOP)._adj_faces[Edge.EdgeEnum.RIGHT], face_disco_right)
	
	assert_eq(polycube.getFaceFromFaceId(face_disco_left)._adj_faces[Edge.EdgeEnum.RIGHT], face_init_id)
	assert_eq(polycube.getFaceFromFaceId(face_disco_right)._adj_faces[Edge.EdgeEnum.LEFT], face_init_id)
	assert_eq(polycube.getFaceFromFaceId(face_disco_top)._adj_faces[Edge.EdgeEnum.BOTTOM], face_init_id)

func test_no_more_undo() -> void:
	var action: UnfoldAction = UnfoldAction.createAction(0,Face.FaceEnum.TOP,Edge.EdgeEnum.TOP,UnfoldAction.DirEnum.BWD)
	Unfolder.executeMove(action, polycube)
	history.addAction(action)
	assert_eq(history.head_list, 1)
	history.undo()
	assert_eq(history.head_list, 0)
	assert_false(history.undo(), "No more undo possible")

func test_no_more_redo() -> void:
	var action: UnfoldAction = UnfoldAction.createAction(0,Face.FaceEnum.TOP,Edge.EdgeEnum.TOP,UnfoldAction.DirEnum.BWD)
	Unfolder.executeMove(action, polycube)
	history.addAction(action)
	assert_eq(history.head_list, 1)
	history.undo()
	assert_eq(history.head_list, 0)
	history.redo()
	assert_eq(history.head_list, 1)
	assert_false(history.redo(), "No more redo possible")

func test_redoOneMove() -> void:
	var action: UnfoldAction = UnfoldAction.createAction(0,Face.FaceEnum.TOP,Edge.EdgeEnum.TOP,UnfoldAction.DirEnum.BWD)
	
	var face_disco_top = polycube.getFace(0,Face.FaceEnum.TOP)._adj_faces[Edge.EdgeEnum.TOP]
	var face_disco_left = polycube.getFace(0,Face.FaceEnum.TOP)._adj_faces[Edge.EdgeEnum.LEFT]
	var face_disco_right = polycube.getFace(0,Face.FaceEnum.TOP)._adj_faces[Edge.EdgeEnum.RIGHT]
	
	var face_init_id = polycube.getFace(0,Face.FaceEnum.TOP)._id_face
	
	Unfolder.executeMove(action, polycube)
	
	assert_eq(polycube.getFace(0,Face.FaceEnum.TOP)._adj_faces[Edge.EdgeEnum.TOP], -1)
	assert_eq(polycube.getFace(0,Face.FaceEnum.TOP)._adj_faces[Edge.EdgeEnum.LEFT], -1)
	assert_eq(polycube.getFace(0,Face.FaceEnum.TOP)._adj_faces[Edge.EdgeEnum.RIGHT], -1)
	
	assert_eq(polycube.getFaceFromFaceId(face_disco_left)._adj_faces[Edge.EdgeEnum.RIGHT], -1)
	assert_eq(polycube.getFaceFromFaceId(face_disco_right)._adj_faces[Edge.EdgeEnum.LEFT], -1)
	assert_eq(polycube.getFaceFromFaceId(face_disco_top)._adj_faces[Edge.EdgeEnum.BOTTOM], -1)


	
	history.addAction(action)
	history.undo()
	
	assert_eq(polycube.getFace(0,Face.FaceEnum.TOP)._adj_faces[Edge.EdgeEnum.TOP], face_disco_top)
	assert_eq(polycube.getFace(0,Face.FaceEnum.TOP)._adj_faces[Edge.EdgeEnum.LEFT], face_disco_left)
	assert_eq(polycube.getFace(0,Face.FaceEnum.TOP)._adj_faces[Edge.EdgeEnum.RIGHT], face_disco_right)
	
	assert_eq(polycube.getFaceFromFaceId(face_disco_left)._adj_faces[Edge.EdgeEnum.RIGHT], face_init_id)
	assert_eq(polycube.getFaceFromFaceId(face_disco_right)._adj_faces[Edge.EdgeEnum.LEFT], face_init_id)
	assert_eq(polycube.getFaceFromFaceId(face_disco_top)._adj_faces[Edge.EdgeEnum.BOTTOM], face_init_id)
	
	history.redo()
	
	assert_eq(polycube.getFace(0,Face.FaceEnum.TOP)._adj_faces[Edge.EdgeEnum.TOP], -1)
	assert_eq(polycube.getFace(0,Face.FaceEnum.TOP)._adj_faces[Edge.EdgeEnum.LEFT], -1)
	assert_eq(polycube.getFace(0,Face.FaceEnum.TOP)._adj_faces[Edge.EdgeEnum.RIGHT], -1)
	
	assert_eq(polycube.getFaceFromFaceId(face_disco_left)._adj_faces[Edge.EdgeEnum.RIGHT], -1)
	assert_eq(polycube.getFaceFromFaceId(face_disco_right)._adj_faces[Edge.EdgeEnum.LEFT], -1)
	assert_eq(polycube.getFaceFromFaceId(face_disco_top)._adj_faces[Edge.EdgeEnum.BOTTOM], -1)
	
