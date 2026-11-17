class_name ErrorPopup
extends Control

const POPUP = preload("res://prefabs/interfaces/error_popup.tscn")

## Create an error popup and return it.
## [br][br]
## [b]Parameters:[/b]
## [br]- [param title]: Title of the error
## [br]- [param message]: Message of the error
## [br][b]Returns:[/b] [code]Control[/code] - The prepared popup
static func create(title: String, message: String) -> ErrorPopup:
	var interface: ErrorPopup = POPUP.instantiate()
	interface.get_node("%error_title").text = title
	interface.get_node("%error_message").text = message
	return interface
