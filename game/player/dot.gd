extends Node3D

@export var color: Color

func _ready() -> void:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	$MeshInstance3D.material_override = mat
