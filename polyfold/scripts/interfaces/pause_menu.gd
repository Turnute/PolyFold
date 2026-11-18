class_name PauseMenu
extends Control
## This class handles the creation of the [code]Pause[/code] interface
## as well as the various events associated with the buttons on the menu.

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
	MenuManager._display_help(self)
