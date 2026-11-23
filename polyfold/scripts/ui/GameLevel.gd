class_name GameLevel
extends Control

var debut_temps : int = 0
var temps_ecoule : int = 0
var debut_pause_temps : int = 0
var chrono_is_running : bool = false
var moves : int = 0
var all_moves : int = 0
var time_goal : int = 0
var move_goal : int = 0
var nb_undo : int = 0
var nb_redo : int = 0

enum gameMode { LEVEL, PUZZLE, ENDLESS, CUSTOM }


func _ready() -> void:
	Game._on_unfolding.connect(addMove)
	Game._on_game_finished.connect(gameFinished)
	Game._on_resume.connect(resumeChrono)

## Create the interface by customizing the fields.
## [br][br]
## [b]Parameters:[/b]
## [br]- [param mode]: The game mode
## [br]- [param level_name]: The name of the level
## [br]- [param level_description]: The level description (theme name, number of cubes, etc.)
## [br]- [param move_goal]: Target number of moves (if negative, no target is applied)
## [br]- [param time_goal]: Time target in seconds (if negative, no target is applied)
## [br][b]Returns:[/b] [code]Control[/code] - The interface, prepared and added to the parent
func initialize(mode: gameMode, level_name: String, level_description: String,
				move_goal: int, time_goal: int) -> void:
	self.time_goal = time_goal
	self.move_goal = move_goal
	
	if(mode == gameMode.LEVEL):
		get_node("%level_name").text = TranslationServer.translate("GAME_LEVEL_NAME") % int(level_name)
	elif(mode == gameMode.PUZZLE):
		# TODO
		pass
	elif(mode == gameMode.ENDLESS):
		# TODO
		pass
	elif(mode == gameMode.CUSTOM):
		# TODO
		pass
	
	get_node("%level_description").text = level_description
	
	get_node("%move_number").text = TranslationServer.translate("GAME_LEVEL_MOVE") % 0
	var m_goal = ""
	if(move_goal > 0):
		m_goal = TranslationServer.translate("GAME_LEVEL_GOAL") % TranslationServer.translate("GAME_LEVEL_MOVE") % move_goal
	else:
		m_goal = TranslationServer.translate("GAME_LEVEL_GOAL") % "-"
	get_node("%move_goal").text = m_goal
	
	get_node("%time_count").text = "00:00:00"
	var t_goal = ""
	if(time_goal > 0):
		var minutes = time_goal / 60
		var secondes = time_goal % 60
		var temps = "%02d:%02d" % [minutes, secondes]
		t_goal = TranslationServer.translate("GAME_LEVEL_GOAL") % temps
	else:
		t_goal = TranslationServer.translate("GAME_LEVEL_GOAL") % "-"
	get_node("%time_goal").text = t_goal
	refreshActionButtons()


## Start the stopwatch.
func startChrono() -> void:
	Log.info("Start Game")
	chrono_is_running = true
	debut_temps = Time.get_ticks_msec()

## Resume the stopwatch.
func resumeChrono() -> void:
	Log.info("Resume Game")
	chrono_is_running = true
	var duree_pause: int = Time.get_ticks_msec() - debut_pause_temps
	debut_temps += duree_pause

## Stop/pause the stopwatch.
func stopChrono() -> void:
	Log.info("Stop/Pause Game")
	chrono_is_running = false
	debut_pause_temps = Time.get_ticks_msec() 


## Increments the stopwatch (if the stopwatch is running)
func _process(delta: float) -> void:
	if not chrono_is_running:
		return
		
	temps_ecoule = Time.get_ticks_msec() - debut_temps
	var total: int = int(max(temps_ecoule, 0)) / 1000
	var minutes: int = total / 60
	var secondes: int = total % 60
	%time_count.text = "%02d:%02d" % [minutes, secondes]

## Add one move
func addMove() -> void:
	moves += 1
	%move_number.text = TranslationServer.translate("GAME_LEVEL_MOVE") % moves
	if(moves > all_moves):
		all_moves = moves
	refreshActionButtons()

## Remove one move
func removeMove() -> void:
	moves -= 1
	%move_number.text = TranslationServer.translate("GAME_LEVEL_MOVE") % moves
	refreshActionButtons()


## Function called when the [code]pause_button[/code] button is pressed.
func _on_pause_button_pressed() -> void:
	stopChrono()
	MenuManager._display_pause(self)

## Function that updates the [code]Undo[/code] and [code]Redo[/code] buttons
## based on the moves made
func refreshActionButtons() -> void:
	# Undo
	if(moves == 0):
		%undo_button.disabled = true
	else:
		%undo_button.disabled = false
	
	# Redo
	if(moves == all_moves):
		%redo_button.disabled = true
	else:
		%redo_button.disabled = false
		

## Function called when the [code]undo_button[/code] button is pressed.
func _on_undo_button_pressed() -> void:
	var done : bool = History.undo()
	if(done):
		nb_undo += 1
		removeMove()
	

## Function called when the [code]redo_button[/code] button is pressed.
func _on_redo_button_pressed() -> void:
	var done : bool = History.redo()
	if(done):
		nb_redo += 1
		addMove()

## Detect if the [code]Escape[/code] is pressed and open the Pause menu.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_pause_button_pressed()
	elif event.is_action_pressed("window_fullscreen"):
		Settings.set_fullscreen(!Settings.fullscreen)
	elif event.is_action_pressed("ui_undo"):
		History.undo()
	elif event.is_action_pressed("ui_redo"):
		History.redo()

func changeTransparencyInfoLevel(transparency: float) -> void:
	%info_level.get_theme_stylebox("panel").bg_color.a = transparency
	%level_name.label_settings.font_color.a = transparency
	%level_description.label_settings.font_color.a = transparency
	%move_icon.modulate.a = transparency
	%move_number.label_settings.font_color.a = transparency
	%move_goal.label_settings.font_color.a = transparency
	%time_icon.modulate.a = transparency
	%time_count.label_settings.font_color.a = transparency
	%time_goal.label_settings.font_color.a = transparency
	
func _on_info_level_mouse_entered() -> void:
	changeTransparencyInfoLevel(0.5) # 50% transparency
	

func _on_info_level_mouse_exited() -> void:
	changeTransparencyInfoLevel(1.0)
	
func gameFinished() -> void:
	var parent = get_parent()
	queue_free()
	MenuManager._display_finish(parent, temps_ecoule, moves,
								time_goal, move_goal, nb_undo, nb_redo)
