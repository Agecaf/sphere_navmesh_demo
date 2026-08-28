class_name Triangulation extends Object


#
# Triangulation core methods
#

# Find the nearest neighbors for a set of vertices
static func find_nearest_neighbors(vertices: Array[Vector3]) -> Array[PackedInt64Array]:
	var neighbors: Array[PackedInt64Array] = []
	
	# Loop through vertices
	for idx in len(vertices):
		var u: Vector3 = vertices[idx]
		
		# Find normals
		var normals: Array[Vector3] = []
		var normals_indices: Array[int] = []
		for jdx in len(vertices):
			if idx == jdx: continue
			var v: Vector3 = vertices[jdx]
			if u.dot(v) > 0:
				var n: Vector3 = u.slide(v).normalized()
				normals.push_back(n)
				normals_indices.push_back(jdx)
		
		# Find neighbors which pass all normals
		var u_neighbors: PackedInt64Array = PackedInt64Array()
		for jdx in len(vertices):
			if idx == jdx: continue
			var all_pass: bool = true
			for kdx in len(normals):
				if normals_indices[kdx] == jdx: continue
				if vertices[jdx].dot(normals[kdx]) < 0.0:
					all_pass = false
			if all_pass:
				u_neighbors.push_back(jdx)
		neighbors.push_back(u_neighbors)
	
	return neighbors


# Link the vertices
static func link_vertices(vertices: Array[Vector3], neighbors: Array[PackedInt64Array]) -> void:
	
	# Sort by degree
	var degrees: Array[Vector2i]
	for idx in len(neighbors):
		degrees.push_back(Vector2i(idx, len(neighbors[idx])))
	degrees.sort_custom(func(a, b): return a.y < b.y)
	
	# Link
	var idx: int = 0
	while idx < len(degrees):
		var pair: Vector2i = degrees[idx]
		var incomplete = link_vertex(pair.x, vertices, neighbors)
		if incomplete: degrees.push_back(pair)
		idx += 1

# Triangulate a linked neighborhood graph
static func triangulate_linked(vertices: Array[Vector3], neighbors: Array[PackedInt64Array]) -> Array[Vector3i]:
	var triangles: Array[Vector3i] = []
	
	# Loop through vertices
	for idx in len(vertices):
		# Ensure we're sorted
		sort_neighbors(idx, vertices, neighbors)
		
		# Add triangles
		var neighborhood: PackedInt64Array = neighbors[idx]
		var neighborhood_size: int = len(neighborhood)
		for vdx in neighborhood_size:
			var jdx: int = int(neighborhood[vdx])
			var kdx: int = int(neighborhood[posmod(vdx+1, neighborhood_size)])
			if(Basis(vertices[idx], vertices[jdx], vertices[kdx]).determinant() > 0.00001):
				continue
			var triangle: Vector3i = Vector3i(idx, jdx, kdx)
			find_or_add_triangle(triangle, triangles)
	
	return triangles

#
# Edges methods
#

# Sorts the edges nicely.
static func edge_from_to(from: int, to: int) -> Vector2i:
	if to < from: return Vector2i(to, from)
	return Vector2i(from, to)

# Get the edges from neighbors information
static func neighbors_to_edges(neighbors: Array[PackedInt64Array]) -> Array[Vector2i]:
	var edges: Array[Vector2i] = []
	
	# Collect the edges, making sure not to repeat them by having them be ordered pairs.
	for idx in len(neighbors):
		for jdx in neighbors[idx]:
			if idx < jdx:
				edges.push_back(Vector2i(idx, jdx))
	
	return edges


# Transforms a list of abstract edges to concrete segments.
static func edges_to_segments(edges: Array[Vector2i], vertices: Array[Vector3]) -> Array[Segment]:
	var segments: Array[Segment] = []
	
	for edge in edges:
		segments.push_back(
			Segment.new(vertices[edge.x], vertices[edge.y])
		)
	
	return segments


#
# Vertex methods
#

# Link vertex
static func link_vertex(idx: int, vertices: Array[Vector3], neighbors: Array[PackedInt64Array]) -> bool:
	# Sort neighbors
	sort_neighbors(idx, vertices, neighbors)
	
	# Link
	var incomplete: bool = false
	var neighborhood: PackedInt64Array = neighbors[idx]
	var neighborhood_size: int = len(neighborhood)
	for vdx in neighborhood_size:
		var jdx: int = int(neighborhood[vdx])
		var kdx: int = int(neighborhood[posmod(vdx+1, neighborhood_size)])
		if jdx in neighbors[kdx]: continue
		if(Basis(vertices[idx], vertices[jdx], vertices[kdx]).determinant() > 0.0):
			incomplete = true
			continue
		neighbors[jdx].push_back(kdx)
		neighbors[kdx].push_back(jdx)
	return incomplete


# Sort the neighbors
static func sort_neighbors(idx: int, vertices: Array[Vector3], neighbors: Array[PackedInt64Array]) -> void:
	# Ignore vectors with too few neighbors
	if len(neighbors[idx]) <= 2: return
	
	# Get a basis
	var v = vertices[idx]
	var a: Vector3 = v.cross(vertices[neighbors[idx][0]]).normalized()
	var b: Vector3 = v.cross(a).normalized()
	
	# Make list for sorting, based on angle around the vector
	var list: Array[Vector2] = []
	for jdx in neighbors[idx]:
		list.push_back(Vector2(float(jdx), atan2(vertices[jdx].dot(a), vertices[jdx].dot(b))))
	list.sort_custom(func(alpha, beta): return alpha.y < beta.y)
	
	
	# Update new neighbors
	var new_neighbors: PackedInt64Array = PackedInt64Array()
	for pair in list: new_neighbors.push_back(int(pair.x))
	neighbors[idx] = new_neighbors
	


# Cull vertices that are too close to each other.
static func cull_vertices_too_close(vertices: Array[Vector3], epsilon: float) -> void:
	
	var idx: int = len(vertices)-2
	while idx >= 0:
		var jdx: int = len(vertices) - 1
		while jdx > idx:
			if vertices[idx].distance_to(vertices[jdx]) < epsilon:
				vertices.remove_at(jdx)
			jdx -= 1
		idx -= 1

#
# Triangle functions
#
static func number_of_common_vertices(a: Vector3i, b:Vector3i) -> int:
	return (
		int(a.x == b.x) +
		int(a.x == b.y) +
		int(a.x == b.z) +
		int(a.y == b.x) +
		int(a.y == b.y) +
		int(a.y == b.z) +
		int(a.z == b.x) +
		int(a.z == b.y) +
		int(a.z == b.z)
	)

# Whether two triangles are the same
static func triangles_are_the_same(a: Vector3i, b: Vector3i) -> bool:
	return number_of_common_vertices(a, b) == 3

# The shared edge between two adjecent triangles
static func triangles_are_adjacent(a: Vector3i, b: Vector3i) -> bool:
	return number_of_common_vertices(a, b) == 2

# The shared edge between two adjacent triangles
static func triangles_shared_edge(a: Vector3i, b: Vector3i) -> Vector2i:
	var common: Array[int] = []
	if (a.x == b.x or a.x == b.y or a.x == b.z): common.push_back(a.x)
	if (a.y == b.x or a.y == b.y or a.y == b.z): common.push_back(a.y)
	if (a.z == b.x or a.z == b.y or a.z == b.z): common.push_back(a.z)
	if len(common) == 2:
		common.sort()
		return Vector2(common[0], common[1])
	return Vector2(-1, -1)

# Try to find a triangle in a list of triangles, or add it, and get the index.
static func find_or_add_triangle(triangle: Vector3i, triangles: Array[Vector3i]) -> int:
	# Try to find
	for idx in len(triangles):
		if triangles_are_the_same(triangles[idx], triangle):
			return idx
	
	# Or add
	triangles.push_back(triangle)
	return len(triangles) - 1

# Find the centers of a set of triangles.
static func triangles_to_centers(vertices: Array[Vector3], triangles: Array[Vector3i]) -> Array[Vector3]:
	var centers: Array[Vector3] = []
	
	# Find the centers of mass
	for t in triangles:
		centers.push_back(
			(vertices[t.x] + vertices[t.y] + vertices[t.z]).normalized()
		)
	
	return centers

# Find the neighbors to each triangle
static func find_triangle_neighbors_around_obstacles(triangles: Array[Vector3i], edge_obstacles: Array[Vector2i]) -> Array[PackedInt64Array]:
	var neighbors: Array[PackedInt64Array] = []
	
	for idx in len(triangles):
		var t_neighbors: PackedInt64Array = PackedInt64Array()
		for jdx in len(triangles):
			var a = triangles[idx]
			var b = triangles[jdx]
			if triangles_are_adjacent(a, b):
				var edge = triangles_shared_edge(a, b)
				if not edge in edge_obstacles:
					t_neighbors.push_back(jdx)
		neighbors.push_back(t_neighbors)
	
	return neighbors
