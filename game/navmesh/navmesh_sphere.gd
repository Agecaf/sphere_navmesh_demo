class_name NavMeshSphere extends RefCounted

# Vertices
var vertices: Array[Vector3] = []
var vertex_neighors: Array[PackedInt64Array] = []
var obstacle_vertices: Array[Vector3] = []
var obstacle_neighors: Array[PackedInt64Array] = []


# Edges
var edges: Array[Vector2i]
var obstacle_edges: Array[Vector2i]

# Triangles
var triangles: Array[Vector3i] = []
var triangle_neighbors: Array[PackedInt64Array] = []
var centers: Array[Vector3] = []
var connections: Array[Vector2i] = []
var normals: Array[Basis] = []


# Build a navmesh from the given information
static func build(_vertices: Array[Vector3], _neighbors: Array[PackedInt64Array], _edges: Array[Vector2i], _obstacle_edges: Array[Vector2i]) -> NavMeshSphere:
	# Get data
	var navmesh: NavMeshSphere = NavMeshSphere.new()
	navmesh.vertices = _vertices
	navmesh.vertex_neighors = _neighbors
	navmesh.edges = _edges
	navmesh.obstacle_edges = _obstacle_edges
	
	# Triangulate
	navmesh.triangles = Triangulation.triangulate_linked(navmesh.vertices, navmesh.vertex_neighors)
	navmesh.centers = Triangulation.triangles_to_centers(navmesh.vertices, navmesh.triangles)
	navmesh.triangle_neighbors =  Triangulation.find_triangle_neighbors_around_obstacles(navmesh.triangles, navmesh.obstacle_edges)
	navmesh.connections = Triangulation.neighbors_to_edges(navmesh.triangle_neighbors)
	
	# Find normals
	navmesh.find_normals()
	navmesh.find_obstacle_vertices()
	
	return navmesh


# Find the normals
func find_normals() -> void:
	normals = []
	
	# Loop through triangles
	for t in triangles:
		# Find normals
		var v1: Vector3 = vertices[t.x]
		var v2: Vector3 = vertices[t.y]
		var v3: Vector3 = vertices[t.z]
		var n1: Vector3 = v2.cross(v3).normalized()
		var n2: Vector3 = v3.cross(v1).normalized()
		var n3: Vector3 = v1.cross(v2).normalized()
		
		# Make sure they're in the right orientation
		if n1.dot(v1) < 0.0: n1 *= -1.0
		if n2.dot(v2) < 0.0: n2 *= -1.0
		if n3.dot(v3) < 0.0: n3 *= -1.0
		normals.push_back(Basis(n1, n2, n3))


# Find the obstacle vertices
func find_obstacle_vertices() -> void:
	# Initialize obstacle_neighbors
	obstacle_neighors = []
	for idx in len(vertices):
		obstacle_neighors.push_back(PackedInt64Array())
	
	# List of obstacle indices with repetition
	var obstacle_indices: Array[int] = []
	for edge in obstacle_edges:
		obstacle_indices.push_back(edge.x)
		obstacle_indices.push_back(edge.y)
		
		# And keep track of obstacle neighbors
		obstacle_neighors[edge.x].push_back(edge.y)
		obstacle_neighors[edge.y].push_back(edge.x)
	
	# Then add those indices which were found
	for idx in len(vertices):
		if idx in obstacle_indices:
			obstacle_vertices.push_back(vertices[idx])
	
	
	



#
