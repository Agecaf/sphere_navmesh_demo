class_name ViewSegments extends Node3D

@export var line_color: Color = Color.WHITE
@export var line_step: float = 0.03
@export var line_width: float = 0.01

func _ready() -> void:
	pass

func view_segments(segments: Array[Segment]) -> void:
	# Remove previous mesh
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	# Don't render empty paths
	if len(segments) == 0: return
	
	# Build mesh
	var rendered_segments: PackedVector3Array = PackedVector3Array()
	for segment in segments:
		rendered_segments.append_array(segment.render_thick(line_step, line_width))
	
	# Don't render empty paths
	if len(rendered_segments) == 0: return
	
	# Initialize the ArrayMesh.
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = rendered_segments
	arrays[Mesh.ARRAY_NORMAL] = rendered_segments
	
	# Create the Mesh.
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var m = MeshInstance3D.new()
	m.mesh = arr_mesh
	m.material_override = StandardMaterial3D.new()
	m.material_override.albedo_color = line_color
	add_child(m)
