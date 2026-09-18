extends Node3D

var mm: MultiMesh
var mmi: MultiMeshInstance3D

func _ready() -> void:
	# Basis
	var shared_basis: Basis = Basis.IDENTITY * 0.03
	
	# Create multimesh
	mm = MultiMesh.new()
	mm.mesh = SphereMesh.new()
	
	# Create instances
	mm.use_colors = true
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = 200
	for idx in 200:
		mm.set_instance_color(idx, Color(randf(), randf(), randf()))
		mm.set_instance_transform(idx, Transform3D(shared_basis, RandomUtils.vector()))
	
	# Create Multimesh instance
	mmi = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.439, 0.182, 0.165, 1.0)
	mmi.material_override = mat
	add_child(mmi)
	
	# Test viewvectors
	var vs: Array[Vector3]
	for idx in 40:
		vs.push_back(RandomUtils.vector())
	$ViewVectors.view_vectors(FlowerUtils.sphere(500))
	
