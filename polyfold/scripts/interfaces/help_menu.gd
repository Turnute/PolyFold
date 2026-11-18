class_name HelpMenu
extends Control
## This class handles the creation of the [code]Help[/code] interface
## as well as the various events associated with the buttons on the menu.

const HELP = preload("res://scenes/interfaces/HelpMenu.tscn")


## Create the interface by customizing the fields.
## [br][br]
## [br][b]Returns:[/b] [code]Control[/code] - The interface added to the parent
static func create(parent: Node) -> HelpMenu:
	var interface: HelpMenu = HELP.instantiate()
	interface.get_node("%rule_fourth_desc").text = TranslationServer.tr("HELP_RULES_4") % [TranslationServer.tr("GAME_LEVEL_UNDO"), TranslationServer.tr("GAME_LEVEL_REDO")]
	parent.add_child(interface)
	return interface
	

## Detect if the [code]Escape[/code] is pressed and close the menu.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free()
		get_viewport().set_input_as_handled()


## Function called when the [code]close_button[/code] button is pressed.
func _on_close_button_pressed() -> void:
	queue_free()

## Function called when the [code]confirm[/code] button is pressed.
func _on_confirm_pressed() -> void:
	queue_free()
