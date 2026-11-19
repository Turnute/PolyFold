class_name History

# List of actions made by the player
static var _moves : Array[UnfoldAction]
# Head of the list of actions
static var head_list : int
# The actual polycube on the scene
static var _polycube : Polycube

# Create an empty history
func _init() -> void :
	_moves = []
	head_list = 0
	_polycube = null
	pass

# Initiate the polycube
func setPolucube(pol: Polycube) -> void :
	_polycube = pol

# Add an action to the history
func addAction(action: UnfoldAction) -> void :
	if head_list != _moves.size():
		_moves.resize(head_list)
	_moves.append(action)
	head_list+=1

# Undo an action and come back to a previous state of the polycube
static func undo() -> bool:
	if head_list == 0:
		print("No moves to undo...")
		return false
	var last_action : UnfoldAction = _moves[head_list - 1]
	var dir_inv = UnfoldAction.DirEnum.BWD if last_action._dir == UnfoldAction.DirEnum.FWD else UnfoldAction.DirEnum.FWD
	var undo_action = UnfoldAction.createActionGroup(last_action._id_cube, last_action._face, last_action._edge, dir_inv,last_action._group, last_action._deconnected_face)
	Unfolder.connectMove(undo_action, _polycube)
	head_list-=1
	return true

# Redo an action and come back to a next state of the polycube
static func redo() -> bool:
	if _moves.size() == head_list :
		print("No moves to redo...")
		return false
	head_list+=1
	var redo_action : UnfoldAction = _moves[head_list - 1]
	redo_action._deconnected_face.clear()
	Unfolder.executeMove(redo_action, _polycube)
	return true
