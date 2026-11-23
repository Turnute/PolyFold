class_name HelpMenu
extends Control
## This class handles the creation of the [code]Help[/code] interface
## as well as the various events associated with the buttons on the menu.

## Detect if the [code]Escape[/code] is pressed and close the menu.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("window_fullscreen"):
		Settings.set_fullscreen(!Settings.fullscreen)
		get_viewport().set_input_as_handled()


## Function called when the [code]close_button[/code] button is pressed.
func _on_close_button_pressed() -> void:
	queue_free()

## Function called when the [code]confirm[/code] button is pressed.
func _on_confirm_pressed() -> void:
	queue_free()
