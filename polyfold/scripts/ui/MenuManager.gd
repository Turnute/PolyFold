class_name MenuManager
extends Control

const GAME_LEVEL := "res://scenes/interfaces/GameLevel.tscn"
const SETTINGS_PAGE := "res://scenes/interfaces/Settings.tscn"
const HELP := "res://scenes/interfaces/HelpMenu.tscn"
const PAUSE := "res://scenes/interfaces/PauseMenu.tscn"
const POPUP := "res://prefabs/interfaces/ErrorPopup.tscn"
const MAIN_MENU := "res://scenes/interfaces/Menu.tscn"

## Create the interface by customizing the fields.
static func _display_help(parent : Node) -> HelpMenu:
	Log.info("Displaying help menu")
	var interface: HelpMenu = load(HELP).instantiate()
	interface.get_node("%rule_fourth_desc").text = TranslationServer.tr("HELP_RULES_4") % [TranslationServer.tr("GAME_LEVEL_UNDO"), TranslationServer.tr("GAME_LEVEL_REDO")]
	parent.add_child(interface)
	return interface

## Create the interface by customizing the fields.
static func _display_pause(parent : Node) -> PauseMenu:
	Log.info("Pausing game")
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
	Log.info("Pop-up error")
	var interface: ErrorPopup = load(POPUP).instantiate()
	interface.get_node("%error_title").text = title
	interface.get_node("%error_message").text = message
	parent.add_child(interface)
	return interface

## Create a settings window and return it.
static func _display_settings(parent: Node) -> void:
	Log.info("Display settings")
	parent.add_child(load(SETTINGS_PAGE).instantiate())
