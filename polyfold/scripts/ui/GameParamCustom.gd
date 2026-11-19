extends Control

func _on_start_button_pressed() -> void:
	var move_goal := int(%MoveGoal.value)
	var time_goal := int(%TimeGoal.value)

	if move_goal == 0:
		move_goal = -1
	if time_goal == 0:
		time_goal = -1
 
	var info = "Game param custom = NB coups : " + str(move_goal) + " | Temps : " + str(time_goal)
	Log.info(info)
	
	var polycube = MenuManager._display_polycube(self, "", 5, 5)
	get_tree().change_scene_to_node(polycube)

	# crée la partie
	var game = MenuManager._display_game_level(polycube, GameLevel.gameMode.CUSTOM, "GAME_LEVEL_NAME_CUSTOM", "", move_goal, time_goal)
	game.startChrono()


func _on_back_button_pressed() -> void:
	get_parent().add_child(load("res://scenes/interfaces/GameModeChoice.tscn").instantiate())
	queue_free()
