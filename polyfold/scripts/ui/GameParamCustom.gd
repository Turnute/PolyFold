extends Control

const LOG_TAG := "[GameParamCustom] "

func _on_start_button_pressed() -> void:
	
	var nb_cube := int(%NbCube.value)
	var max_adj := int(%MaxAdj.value)
	
	var move_goal := int(%MoveGoal.value)
	var time_goal := int(%TimeGoal.value)

	if move_goal == 0:
		move_goal = -1
	if time_goal == 0:
		time_goal = -1
 
	Log.info(LOG_TAG + "Lancement partie personnalisée (cubes : %d, adjacences max : %d, coups : %d, temps : %d)" % [nb_cube, max_adj, move_goal, time_goal])
	
	var polycube = MenuManager._display_polycube(self, "", nb_cube, max_adj)
	get_tree().change_scene_to_node(polycube)

	# crée la partie
	var game = MenuManager._display_game_level(polycube, GameLevel.gameMode.CUSTOM, "GAME_LEVEL_NAME_CUSTOM", "", move_goal, time_goal)
	game.startChrono()


func _on_back_button_pressed() -> void:
	get_parent().add_child(load("res://scenes/interfaces/GameModeChoice.tscn").instantiate())
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("window_fullscreen"):
		Settings.set_fullscreen(!Settings.fullscreen)
		get_viewport().set_input_as_handled()


func _on_help_button_pressed() -> void:
	MenuManager._display_help(self)
