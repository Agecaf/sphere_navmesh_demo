extends Node3D


var vectors: Array[Vector3] = []
var vectors2: Array[Vector3] = []
var segments: Array[Segment] = []
var segments2: Array[Segment] = []
var segments3: Array[Segment] = []
var neighbors: Array[PackedInt64Array]
var navmesh: NavMeshSphere

func _ready() -> void:
	
	# Generate random vectors
	for idx in 100: vectors.push_back(RandomUtils.vector())
	# vectors = FlowerUtils.sphere(120)
	
	Triangulation.cull_vertices_too_close(vectors, 0.05)
	
	# Triangulate them
	triangulate()
	
	$ViewSegments.view_segments(segments)
	$ViewSegments2.view_segments(segments2)
	$ViewSegments3.view_segments(segments3)
	$ViewVectors.view_vectors(vectors2)
	$ViewVectors2.view_vectors(vectors)

func triangulate() -> void:
	
	# Find nearest neighbors
	neighbors = Triangulation.find_nearest_neighbors(vectors)
	var edges2 = Triangulation.neighbors_to_edges(neighbors)
	# segments2 = Triangulation.edges_to_segments(edges2, vectors)
	
	# build obstacles
	var obstacles: Array[Vector2i] = []
	for edge in edges2:
		if randf() < 0.5:
			obstacles.push_back(edge)
	
	# Link to get triangulation
	Triangulation.link_vertices(vectors, neighbors)
	var edges = Triangulation.neighbors_to_edges(neighbors)
	segments2 = Triangulation.edges_to_segments(obstacles, vectors)
	segments3 = Triangulation.edges_to_segments(edges, vectors)
	
	navmesh = NavMeshSphere.build(vectors, neighbors, edges, obstacles)
	
	# var triangles: Array[Vector3i] = Triangulation.triangulate_linked(vectors, neighbors)
	# vectors2 = Triangulation.triangles_to_centers(vectors, triangles)
	
	vectors2 = navmesh.centers
	segments = Triangulation.edges_to_segments(navmesh.connections, navmesh.centers)
	
