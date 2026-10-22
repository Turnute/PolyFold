extends StaticBody3D

class_name Edge

# Référence aux objets de la scène
@onready var mesh : MeshInstance3D = $MeshInstance3D
@onready var col : CollisionShape3D = $CollisionShape3D

# Énumérateur de sa position au sein d'une face
enum EdgeEnum { TOP, BOTTOM, LEFT, RIGHT }
var side : EdgeEnum

# A la création, l'edge est invisible et non-interactible
func _ready() -> void:
	mesh.visible = false
	col.disabled = true

# Sélection d'un edge
func select() -> void:
	print("Selected " + get_parent().name)

# Déselection d'un edge (clic dans le vide)
func unselect() -> void:
	print("Unelected " + get_parent().name)

# Switch de la visibilité et interactibilité de l'edge
func switch() -> void:
	mesh.visible = !mesh.visible
	col.disabled = !col.disabled
