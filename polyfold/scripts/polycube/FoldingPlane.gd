extends Node3D

@export var _grid_material: StandardMaterial3D
@onready var _mesh: MeshInstance3D = $Plane

func _ready() -> void:
	initGrid()

func initGrid() -> void:
	var size : Vector2 = _mesh.mesh.size
	for i in range(size[0]/2):
		var line_x : MeshInstance3D = MeshInstance3D.new()
		line_x.mesh = BoxMesh.new()
		line_x.material_override = _grid_material
		
		var line_z : MeshInstance3D = MeshInstance3D.new()
		line_z.mesh = BoxMesh.new()
		line_z.material_override = _grid_material
		
		line_x.mesh.size = Vector3(200.0, 0.025, 0.025)
		line_z.mesh.size = Vector3(0.025, 0.025, 200.0)
		
		var line_xx : MeshInstance3D = line_x.duplicate()
		var line_zz : MeshInstance3D = line_z.duplicate()
		
		line_x.position = Vector3(0, 0, i + 0.5)
		line_xx.position = Vector3(0, 0, -1 * i - 0.5)
		line_z.position = Vector3(i + 0.5, 0, 0)
		line_zz.position = Vector3(-1 * i - 0.5, 0, 0)
		
		add_child(line_x)
		add_child(line_xx)
		add_child(line_z)
		add_child(line_zz)

func switch() -> void :
	self.visible = not self.visible
