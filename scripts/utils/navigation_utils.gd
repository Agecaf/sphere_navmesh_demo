class_name Navigation extends Object


static func find_triangle_containing(v: Vector3, navmesh: NavMeshSphere) -> int:
	
	# Look for the triangle containing the vector
	for idx in len(navmesh.normals):
		if VectorUtils.vector_inside_normals(v, navmesh.normals[idx]): 
			return idx
	
	return -1












































#
