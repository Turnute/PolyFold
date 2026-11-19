extends GutTest

var _polycube : Polycube

func before_each() -> void :
	var data : PolycubeData = PolycubeData.new()
	data.cube_matrix = [
		Vector3i(0, 0, 0),
		Vector3i(1, 0, 0)
	]

	_polycube = PolycubeFactory.loadPolycube(data)
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

func test_parallel_faces_in_different_planes_are_not_coplanar() -> void :
	var a : Face = _polycube._cubes[0].getFace(Face.FaceEnum.TOP)
	var b : Face = _polycube._cubes[1].getFace(Face.FaceEnum.TOP)
	a.global_transform = Transform3D.IDENTITY
	b.global_transform = Transform3D(Basis.IDENTITY, Vector3(3, 1, 2))

	assert_false(_polycube.areCoplanar(a, b))
	assert_false(_polycube.areCoplanar(b, a))

func test_intersecting_planes_are_not_coplanar() -> void :
	var a : Face = _polycube._cubes[0].getFace(Face.FaceEnum.TOP)
	var b : Face = _polycube._cubes[1].getFace(Face.FaceEnum.TOP)
	a.global_transform = Transform3D.IDENTITY
	b.global_transform = Transform3D(Basis(Vector3.RIGHT, PI / 4.0), Vector3.ZERO)

	assert_false(_polycube.areCoplanar(a, b))

func test_coplanarity_uses_world_space_after_parent_rotation() -> void :
	var a : Face = _polycube._cubes[0].getFace(Face.FaceEnum.TOP)
	var b : Face = _polycube._cubes[1].getFace(Face.FaceEnum.TOP)
	a.global_transform = Transform3D.IDENTITY
	b.global_transform = Transform3D(Basis.IDENTITY, Vector3(3, 0, 2))
	_polycube.rotation_degrees = Vector3(30, 40, 20)
	_polycube.position = Vector3(4, -3, 7)

	assert_true(_polycube.areCoplanar(a, b))
	assert_true(_polycube.areCoplanar(b, a))

func test_coplanarity_normalizes_face_normals_when_faces_are_scaled() -> void :
	var a : Face = _polycube._cubes[0].getFace(Face.FaceEnum.TOP)
	var b : Face = _polycube._cubes[1].getFace(Face.FaceEnum.TOP)
	a.global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3(2, 3, 4)), Vector3.ZERO)
	b.global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3(0.5, 0.25, 2)), Vector3(3, 0, 2))

	assert_true(_polycube.areCoplanar(a, b))
	assert_true(_polycube.areCoplanar(b, a))
