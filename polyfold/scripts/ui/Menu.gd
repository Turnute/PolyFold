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
