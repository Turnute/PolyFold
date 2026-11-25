class_name MenuManager
extends Control

const LOG_TAG := "[MenuManager] "

const GAME_LEVEL := "res://scenes/interfaces/GameLevel.tscn"
const GAME_SCENE := "res://scenes/GameScene.tscn"
const FINISH := "res://scenes/interfaces/FinishMenu.tscn"
const SETTINGS_PAGE := "res://scenes/interfaces/Settings.tscn"
const HELP := "res://scenes/interfaces/HelpMenu.tscn"
const PAUSE := "res://scenes/interfaces/PauseMenu.tscn"
const POPUP := "res://prefabs/interfaces/ErrorPopup.tscn"
const MAIN_MENU := "res://scenes/interfaces/Menu.tscn"
const CREDITS = ("res://scenes/interfaces/Credits.tscn")

## Create the interface by customizing the fields.
static func _display_help(parent : Node) -> HelpMenu:
	Log.info(LOG_TAG + "Displaying help menu")
	var interface: HelpMenu = load(HELP).instantiate()
	interface.get_node("%rule_fourth_desc").text = TranslationServer.tr("HELP_RULES_4") % [TranslationServer.tr("GAME_LEVEL_UNDO"), TranslationServer.tr("GAME_LEVEL_REDO")]
	parent.add_child(interface)
	return interface

## Create the interface by customizing the fields.
static func _display_pause(parent : Node) -> PauseMenu:
	Log.info(LOG_TAG + "Pausing game")
	parent.get_tree().paused = true
	var interface: PauseMenu = load(PAUSE).instantiate()
	parent.add_child(interface)
	return interface

## Create an error popup and return it.
## [br][br]
## [b]Parameters:[/b]
## [br]- [param title]: Title of the error
## [br]- [param message]: Message of the error
static func _display_error(parent: Node, title: String, message: String) -> ErrorPopup:
	Log.info(LOG_TAG + "Pop-up error")
	var interface: ErrorPopup = load(POPUP).instantiate()
	interface.get_node("%error_title").text = title
	interface.get_node("%error_message").text = message
	parent.add_child(interface)
	return interface

## Create a settings window and return it.
static func _display_settings(parent: Node) -> void:
	Log.info(LOG_TAG + "Display settings")
	parent.add_child(load(SETTINGS_PAGE).instantiate())

## 
static func _display_game_level(parent : Node, mode: GameLevel.gameMode, level_name: String, level_description: String,
				move_goal: int, time_goal: int) -> GameLevel:
	Log.info(LOG_TAG + "Display Game Level")
	var interface: GameLevel = load(GAME_LEVEL).instantiate()
	interface.initialize(mode, level_name, level_description, move_goal, time_goal)
	parent.add_child(interface)
	return interface

## 
static func _display_polycube(parent : Node, data_str : String, nb_cubes : int, max_adj : int) -> Node3D :
	Log.info(LOG_TAG + "Display Polycube")
	if(!data_str.is_empty()) :
		SpawnPolycube.data_str = data_str
	else :
		SpawnPolycube.nb_cubes = nb_cubes
		SpawnPolycube.max_adj = max_adj
	var polycube = load(GAME_SCENE).instantiate()
	return polycube
	
## 
static func _display_finish(parent : Node, time: int, moves: int, time_goal: int, moves_goal: int,
							nb_undo: int, nb_redo: int) -> FinishMenu:
	Log.info(LOG_TAG + "Display Finish Menu")
	var interface: FinishMenu = load(FINISH).instantiate()
	interface.initialize(time, moves, time_goal, moves_goal, nb_undo, nb_redo)
	parent.add_child(interface)
	return interface

static func _display_credits(parent: Node) -> void:
	Log.info(LOG_TAG + "Display credits")
	parent.add_child(load(CREDITS).instantiate())
