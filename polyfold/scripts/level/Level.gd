class_name Level 
extends Node

var _id : int
var _name : String
var _difficulty : int
var _polycube_file : PolycubeData
var _high_score : int

static func creat(id, name, difficulty, polycube_file, high_score = 0) -> Level:
	var level = Level.new()
	level._id = id
	level._name = name
	level._difficulty = difficulty
	level._polycube_file = polycube_file
	level._high_score = high_score
	return level
