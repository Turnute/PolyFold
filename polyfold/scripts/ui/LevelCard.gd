extends Button

@export var text_color := Color("#1B3A5C")
@export var text_color_locked := Color("#6B7380")

@export var star_color_on := Color("#EF9F27")
@export var star_color_off := Color("#B4B2A9")

@onready var new_level_color := Color("4a8fd940")

@onready var number_label: Label = $Margin/VBox/NumberLabel
@onready var name_label: Label = $Margin/VBox/NameLabel
@onready var stars_box: HBoxContainer = $Margin/VBox/StarsBox
@onready var lock_icon: TextureRect = $Margin/VBox/LockIcon
@onready var moves_label: Label = $Margin/VBox/MovesLabel
@onready var time_label: Label = $Margin/VBox/TimeLabel
@onready var status_label: Label = $Margin/VBox/StatusLabel

signal level_chosen(level_id: int)
var level_id := -1


func _ready() -> void:
	pass

## Fill the card with the level data.
## [br][br]
## [b]Parameters:[/b]
## [br]- [param number]: The level id
## [br]- [param name_key]: Translation key of the level name
## [br]- [vbest_moves]: Best number of moves, or -1 if never completed
## [br]- [param best_time]: Best time in seconds, or -1 if never completed
## [br]- [param stars]: Number of stars won (0 to 3)
## [br]- [param locked]: true if the player cannot play this level
func setup(number: int, name_key: String, best_moves: int, best_time: int,
		stars: int, locked: bool) -> void:

	level_id = number

	var completed := best_moves != -1
	number_label.text = str(number)
	name_label.text = tr(name_key)
	disabled = locked
	lock_icon.visible = locked
	stars_box.visible = not locked
	moves_label.visible = completed and not locked
	time_label.visible = completed and not locked
	status_label.visible = locked or not completed

	if locked:
		status_label.text = tr("LEVEL_LOCKED")
	elif not completed:
		status_label.text = tr("LEVEL_NEW")
		status_label.add_theme_stylebox_override("normal", _make_badge(new_level_color))
	else:
		moves_label.text = tr("LEVEL_BEST_MOVES") % best_moves
		time_label.text = tr("LEVEL_BEST_TIME") % _format_time(best_time)

	_set_stars(stars)

	var color := text_color_locked if locked else text_color
	for label in [number_label, name_label, moves_label, time_label, status_label]:
		label.add_theme_color_override("font_color", color)

## Color the stars (yellow = on (won) & grey = off).
## [br][br]
## [b]Parameters:[/b]
## [br]- [param count]: Number of stars won
func _set_stars(count: int) -> void:
	for i in stars_box.get_child_count():
		var star := stars_box.get_child(i) as TextureRect
		star.self_modulate = star_color_on if i < count else star_color_off

## Style apply on text for new level
func _make_badge(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(6)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	return box

## ex : 75 -> 01:15
func _format_time(seconds: int) -> String:
	return "%02d:%02d" % [seconds / 60, seconds % 60]


func _on_pressed() -> void:
	level_chosen.emit(level_id)
