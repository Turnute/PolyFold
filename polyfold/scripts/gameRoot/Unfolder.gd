class_name Unfolder
extends Node

## Script gérant les dépliements

## Checks if a move is valid: not disconnecting and no overlap
static func validMove(UnfoldAction) -> bool:
	return true

## Executes an Unfolding move
static func executeMove(UnfoldAction) -> void:
	print(UnfoldAction)
	pass
