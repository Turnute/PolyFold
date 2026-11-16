class_name GameLevel
extends Control

const GAME_LEVEL_INTERFACE: PackedScene = preload("res://scenes/interface/Game_LevelMode.tscn")

var temps_ecoule: float = 0.0
var chrono_is_running: bool = false
var moves : int = 0

## Create the interface by customizing the fields.
## [br][br]
## [b]Parameters:[/b]
## [br]- [param level_number]: The level number
## [br]- [param level_description]: The level description (theme name, number of cubes, etc.)
## [br]- [param move_goal]: Target number of moves (if negative, no target is applied)
## [br]- [param time_goal]: Time target in seconds (if negative, no target is applied)
## [br][b]Returns:[/b] [code]Control[/code] - The interface, prepared and added to the parent
static func create(parent: Node, level_number: int, level_description: String,
				move_goal: int, time_goal: int) -> GameLevel:
	var interface = GAME_LEVEL_INTERFACE.instantiate() as GameLevel
	
	parent.add_child(interface)
	
	interface.get_node("%level_name").text = TranslationServer.translate("GAME_LEVEL_NAME") % level_number
	interface.get_node("%level_description").text = level_description
	
	interface.get_node("%move_number").text = TranslationServer.translate("GAME_LEVEL_MOVE") % 0
	var m_goal = ""
	if(move_goal > 0):
		m_goal = TranslationServer.translate("GAME_LEVEL_GOAL") % TranslationServer.translate("GAME_LEVEL_MOVE") % move_goal
	else:
		m_goal = TranslationServer.translate("GAME_LEVEL_GOAL") % "-"
	interface.get_node("%move_goal").text = m_goal
	
	interface.get_node("%time_count").text = "00:00:00"
	var t_goal = ""
	if(time_goal > 0):
		var minutes = time_goal / 60
		var secondes = time_goal % 60
		var temps = "%02d:%02d:%02d" % [minutes, secondes, 0]
		t_goal = TranslationServer.translate("GAME_LEVEL_GOAL") % temps
	else:
		t_goal = TranslationServer.translate("GAME_LEVEL_GOAL") % "-"
	interface.get_node("%time_goal").text = t_goal
	
	return interface

## Start the stopwatch.
func startChrono() -> void:
	chrono_is_running = true

## Stop/pause the stopwatch.
func stopChrono() -> void:
	chrono_is_running = false

## Increments the stopwatch (if the stopwatch is running)
func _process(delta: float) -> void:
	if not chrono_is_running:
		return
		
	temps_ecoule += delta
	var total: int = int(temps_ecoule)
	var minutes: int = total / 60
	var secondes: int = total % 60
	var centiemes: int = int((temps_ecoule - total) * 100)
	%time_count.text = "%02d:%02d:%02d" % [minutes, secondes, centiemes]

## Add one move
func addMove() -> void:
	moves += 1
	%move_number.text = TranslationServer.translate("GAME_LEVEL_MOVE") % moves

## Remove one move
func removeMove() -> void:
	moves -= 1
	%move_number.text = TranslationServer.translate("GAME_LEVEL_MOVE") % moves	
