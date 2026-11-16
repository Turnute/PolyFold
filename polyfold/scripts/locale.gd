extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Définir la langue (par exemple en français ou en anglais)
	TranslationServer.set_locale("fr")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
