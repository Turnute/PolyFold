extends Control

func _on_start_button_pressed() -> void:
	var move_goal := int(%MoveGoal.value)
	var time_goal := int(%TimeGoal.value)

	if move_goal == 0:
		move_goal = -1
	if time_goal == 0:
		time_goal = -1

	print("coups : ", move_goal, " / temps : ", time_goal)

	# crée la partie
	var game := GameLevel.create(get_tree().root, 0, "", move_goal, time_goal)
	game.get_node("%level_name").text = tr("GAME_MODE_CUSTOM")  # sinon on voit « Niveau 0 »
	game.startChrono()

	#clear empilement page
	get_tree().current_scene.queue_free()
	get_tree().current_scene = game


func _on_back_button_pressed() -> void:
	get_parent().add_child(load("res://scenes/interfaces/GameModeChoice.tscn").instantiate())
	queue_free()
