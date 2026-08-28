class_name ViewVectors extends Node3D

@export var point_color: Color = Color.WHITE
@export var point_size: float = 0.03

var mm: MultiMesh
var mmi: MultiMeshInstance3D

func _ready() -> void:
	
	# Create multimesh
	mm = MultiMesh.new()
	mm.mesh = SphereMesh.new()
	mm.use_colors = true
	mm.transform_format = MultiMesh.TRANSFORM_3D
	
	# Create Multimesh instance
	mmi = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = point_color
	mmi.material_override = mat
	
	add_child(mmi)

func view_vectors(vectors: Array[Vector3]) -> void:
	# Basis
	var shared_basis: Basis = Basis.IDENTITY * 0.03
	
	# Setup mesh
	mm.instance_count = 0
	mm.instance_count = len(vectors)
	for idx in len(vectors):
		mm.set_instance_transform(idx, Transform3D(shared_basis, vectors[idx]))
		
	# Color
	mmi.material_override.albedo_color = point_color
