extends Control


func _ready() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version")
	%VersionLabel.text = "%s %s – 2026" % [tr("VERSION"), version]
