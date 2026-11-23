extends Node

const GAME_MODE_CHOICE: PackedScene = preload("res://scenes/interfaces/GameModeChoice.tscn")

func _ready() -> void:
	pass

func _on_play_button_pressed() -> void:
	add_child(GAME_MODE_CHOICE.instantiate())

func _on_settings_button_pressed() -> void:
	MenuManager._display_settings(self)

func _on_quit_button_pressed() -> void:
	get_tree().quit()   # ferme le jeu

func _on_credits_button_pressed() -> void:
	MenuManager._display_credits(self)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("window_fullscreen"):
		Settings.set_fullscreen(!Settings.fullscreen)
		get_viewport().set_input_as_handled()
