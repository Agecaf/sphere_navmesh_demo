extends Node3D


func _ready() -> void:
	
	var step = 0.02
	var width = 0.01
	
	# Create random segments
	var segments: Array[Segment] = []
	var vectors: Array[Vector3]
	var rendered_segments: PackedVector3Array = PackedVector3Array()
	for idx in 20:
		var v0 = RandomUtils.vector()
		var v1 = RandomUtils.vector()
		var segment = Segment.new(v0, v1)
		segments.push_back(segment)
		vectors.push_back(v0)
		vectors.push_back(v1)
		rendered_segments.append_array(segment.render_thick(step, width))
	
	# Initialize the ArrayMesh.
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = rendered_segments

	# Create the Mesh.
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var m = MeshInstance3D.new()
	m.mesh = arr_mesh
	m.material_override = StandardMaterial3D.new()
	m.material_override.albedo_color = Color.BLUE
	# add_child(m)
	
	
	# Cull intersecting segments
	vectors = []
	var idx: int = len(segments) - 2
	while idx >= 0:
		var jdx: int = len(segments) - 1
		while jdx > idx:
			if segments[idx].intersects(segments[jdx]):
				vectors.push_back(segments[idx].intersection_with(segments[jdx]))
				# segments.remove_at(jdx)
			jdx -= 1
		idx -= 1
	$ViewSegments.view_segments(segments)
	
	
	# View those segments' vectors
	$ViewVectors.view_vectors(vectors)
