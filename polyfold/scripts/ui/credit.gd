extends Control


func _ready() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version")
	%VersionLabel.text = "%s %s – 2026" % [tr("VERSION"), version]


func _on_back_button_pressed() -> void:
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("window_fullscreen"):
		Settings.set_fullscreen(!Settings.fullscreen)
		get_viewport().set_input_as_handled()
