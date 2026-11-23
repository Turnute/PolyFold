class_name FinishMenu
extends Node


## Create the interface by customizing the fields.
## [br][br]
## [b]Parameters:[/b]
## [br]- [param time]: Duration of the game (in seconds)
## [br]- [param moves]: Number of moves of the game
## [br]- [param time_goal]: Time goal of the game
## [br]- [param moves_goal]: Moves goal of the game
## [br]- [param nb_undo]: Number of undos performed during the game
## [br]- [param nb_redo]: Number of redos performed during the game
func initialize(time: int, moves: int, time_goal: int, moves_goal: int,
				nb_undo: int, nb_redo: int) -> void:
	# Stars
	var star_yellow = Color.html("#f6c445")
	var star_gray = Color.html("#7a869680")
	get_node("%Star_1").self_modulate = star_yellow
	get_node("%Star_2").self_modulate = star_yellow
	get_node("%Star_3").self_modulate = star_yellow
	
	
	
	# Infos
	var total_time := int(max(time, 0.0) * 100.0)
	var minutes := total_time / 6000
	var secondes := (total_time / 100) % 60
	var centiemes := total_time % 100
	var time_count := "%02d:%02d:%02d" % [minutes, secondes, centiemes]
	
	get_node("%infos").text = "%s - %s" % [time_count, TranslationServer.tr("GAME_LEVEL_MOVE") % moves]
	
	
	
	# Time goal
	var icon_time := get_node("icon_time_goal") as TextureRect
	if(time_goal > 0):
		var total_time_goal := int(max(time_goal, 0.0) * 100.0)
		var minutes_goal := total_time_goal / 6000
		var secondes_goal := (total_time_goal / 100) % 60
		var time_goal_count := "%02dm%02ds" % [minutes, secondes]
		
		if(time < time_goal):
			icon_time.texture = preload("res://assets/icons/checkmark.svg")
		else:
			icon_time.texture = preload("res://assets/icons/cross.svg")
		get_node("label_time_goal").text = TranslationServer.tr("FINISH_GOALS_TIME") % time_goal_count
	else:
		icon_time.visible = false
		get_node("label_time_goal").text = TranslationServer.tr("FINISH_GOALS_TIME_NONE")
			
	
		
	# Moves goal
	var icon_moves := get_node("icon_moves_goal") as TextureRect
	if(moves_goal == 0):
		if(moves < moves_goal):
			icon_moves.texture = preload("res://assets/icons/checkmark.svg")
		else:
			icon_moves.texture = preload("res://assets/icons/cross.svg")
		get_node("label_moves_goal").text = TranslationServer.tr("FINISH_GOALS_MOVES") % moves_goal
	else:
		icon_moves.visible = false
		get_node("label_moves_goal").text = TranslationServer.tr("FINISH_GOALS_MOVES_NONE")
	
	
	# Stats
	get_node("%undo_number").text = nb_undo
	get_node("%nb_redo").text = nb_redo
	
	
	
## Function called when the [code]Leave_button[/code] button is pressed.
func _on_leave_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/interfaces/Menu.tscn")
