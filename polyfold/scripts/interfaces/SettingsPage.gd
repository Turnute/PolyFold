class_name SettingsPage
extends Control

func _ready() -> void:
	%SettingsPanel.back.connect(queue_free)   # Retour → la page se supprime
