extends Button

@export var text_color := Color("#1B3A5C")
@export var text_color_locked := Color("#6B7380")

@onready var number_label: Label = $Margin/VBox/NumberLabel
@onready var name_label: Label = $Margin/VBox/NameLabel
@onready var lock_icon: TextureRect = $Margin/VBox/LockIcon
@onready var score_label: Label = $Margin/VBox/ScoreLabel

func _ready() -> void:
	pass

func setup(number: String, name_key: String, best_score: int, locked: bool) -> void:
	number_label.text = number
	name_label.text = tr(name_key)
	disabled = locked
	lock_icon.visible = locked

	if locked:
		score_label.text = tr("LEVEL_LOCKED")
	elif best_score == -1:
		score_label.text = tr("LEVEL_NEW")
	else:
		score_label.text = tr("LEVEL_BEST_SCORE") % best_score
	
	var color := text_color_locked if locked else text_color
	for label in [number_label, name_label, score_label]:
		label.add_theme_color_override("font_color", color)
