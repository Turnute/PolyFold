extends Control

const GAME_PARAM_CUSTOM: PackedScene = preload("res://scenes/interfaces/GameParamCustom.tscn")

func _ready() -> void:
	pass # Replace with function body.


func _on_mode_custom_button_pressed() -> void:
	get_parent().add_child(GAME_PARAM_CUSTOM.instantiate())
	queue_free()

func _on_back_button_pressed() -> void:
	queue_free()
