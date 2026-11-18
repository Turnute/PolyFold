extends GutTest

const _data_str = "res://data/polycubes/test_poly.tres"
var _data : PolycubeData = load(_data_str)
var _polycube : Polycube


func before_each() -> void :
	_polycube = PolycubeFactory.loadPolycube(_data)
	_polycube.createEdges()
	add_child_autofree(_polycube)

func test_are_coplanar() -> void :
	var a : Face = _polycube._cubes[0].getFace(Face.FaceEnum.TOP)
	var b : Face = _polycube._cubes[1].getFace(Face.FaceEnum.TOP)
	var c : Face = _polycube._cubes[1].getFace(Face.FaceEnum.RIGHT)
	var d : Face = _polycube._cubes[0].getFace(Face.FaceEnum.LEFT)

	assert_true(_polycube.areCoplanar(a, b))
	assert_false(_polycube.areCoplanar(a, c))
	assert_false(_polycube.areCoplanar(c, d))

func test_shifted_faces_in_same_plane_are_coplanar() -> void:
	var a: Face = _polycube._cubes[0].getFace(Face.FaceEnum.TOP)
	var b: Face = _polycube._cubes[1].getFace(Face.FaceEnum.TOP)

	a.global_transform = Transform3D.IDENTITY
	b.global_transform = Transform3D(Basis.IDENTITY, Vector3(3, 0, 2))

	assert_true(_polycube.areCoplanar(a, b))

func test_faces_with_opposite_normals_can_be_coplanar() -> void:
	var a: Face = _polycube._cubes[0].getFace(Face.FaceEnum.TOP)
	var b: Face = _polycube._cubes[1].getFace(Face.FaceEnum.TOP)

	a.global_transform = Transform3D.IDENTITY
	b.global_transform = Transform3D(Basis(Vector3.RIGHT, PI),Vector3(3, 0, 0))

	assert_true(_polycube.areCoplanar(a, b))

func test_get_opposite_edges() -> void:
	var f: Face = autofree(Face.new())
	var edges: Array[Edge] = []

	for i in range(4):
		var e: Edge = autofree(Edge.new())
		e._side = i
		edges.append(e)

	f._edges = edges

	assert_eq(f.getOppositeEdge(edges[0]), edges[1])
	assert_eq(f.getOppositeEdge(edges[1]), edges[0])
	assert_eq(f.getOppositeEdge(edges[2]), edges[3])
	assert_eq(f.getOppositeEdge(edges[3]), edges[2])
	
	assert_eq(f.getOppositeEdge(edges[0]), f._edges[1])
	assert_eq(f.getOppositeEdge(edges[1]), f._edges[0])
	assert_eq(f.getOppositeEdge(edges[2]), f._edges[3])
	assert_eq(f.getOppositeEdge(edges[3]), f._edges[2])
