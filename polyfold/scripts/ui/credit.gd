extends Control


func _ready() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version")
	%VersionLabel.text = "%s %s – 2026" % [tr("VERSION"), version]


func _on_back_button_pressed() -> void:
	queue_free()
