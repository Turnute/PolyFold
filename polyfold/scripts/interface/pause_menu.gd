class_name PauseMenu
extends Control
## This class handles the creation of the [code]Pause[/code] interface
## as well as the various events associated with the buttons on the menu.

const PAUSE = preload("res://scenes/interface/Pause_Menu.tscn")


## Create the interface by customizing the fields.
## [br][br]
## [br][b]Returns:[/b] [code]Control[/code] - The interface added to the parent
static func create(parent: Node) -> PauseMenu:
	parent.get_tree().paused = true
	var interface: PauseMenu = PAUSE.instantiate()
	parent.add_child(interface)
	return interface
	

## Function called when the [code]Resume_button[/code] button is pressed.
func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	queue_free()

## Detect if the [code]Escape[/code] is pressed and close the menu.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_resume_button_pressed()
		get_viewport().set_input_as_handled()

## Function called when the [code]Help_button[/code] button is pressed.
func _on_help_button_pressed() -> void:
	HelpMenu.create(self)
