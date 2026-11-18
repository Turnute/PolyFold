extends GutTest

const _data_str = "res://data/polycubes/test_poly.tres"
var _data : PolycubeData = load(_data_str)
var _polycube : Polycube


func before_each() -> void :
	_polycube = PolycubeFactory.loadPolycube(_data)
	add_child_autofree(_polycube)

func test_are_coplanar() -> void :
	var a : Face = _polycube._cubes[0].getFace(Face.FaceEnum.TOP)
	var b : Face = _polycube._cubes[1].getFace(Face.FaceEnum.TOP)
	var c : Face = _polycube._cubes[1].getFace(Face.FaceEnum.LEFT)

	assert_true(_polycube.areCoplanar(a, b))
	assert_false(_polycube.areCoplanar(a, c))
