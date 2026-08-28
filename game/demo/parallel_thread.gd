extends Node

signal navmesh_ready()

var navmesh: NavMeshSphere = null
var finished: bool = true
var mtx: Mutex
var thread: Thread

# Initialization
func _ready() -> void:
	mtx = Mutex.new()
	finished = true
	thread = Thread.new()
	
	reload.call_deferred()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"reload"):
		reload()


# Get the navmesh safely!
func get_navmesh() -> NavMeshSphere:
	var out: NavMeshSphere = null
	mtx.lock()
	if finished: out = navmesh
	mtx.unlock()
	return out

# Check if it's finished!
func is_finished() -> bool:
	var out: bool
	mtx.lock()
	out = finished
	mtx.unlock()
	return out

#
func reload() -> void:
	
	# Check if not finished!
	mtx.lock()
	if not finished:
		mtx.unlock()
		return
	
	# Otherwise reset
	navmesh = null
	finished = false
	mtx.unlock()
	
	
	# And begin the thread
	Debug.log("Reloading... ")
	if thread.is_started(): thread.wait_to_finish()
	thread.start(triangulate_threaded)


func triangulate_threaded() -> void:
	var vertices: Array[Vector3] = []
	
	# Generate random vectors
	vertices.clear()
	for idx in 100: vertices.push_back(RandomUtils.vector())
	Triangulation.cull_vertices_too_close(vertices, 0.05)
	
	# Find nearest neighbors
	var neighbors: Array[PackedInt64Array] = Triangulation.find_nearest_neighbors(vertices)
	var edges_nearest: Array[Vector2i] = Triangulation.neighbors_to_edges(neighbors)
	
	# Build obstacles
	var obstacles: Array[Vector2i] = []
	for edge in edges_nearest:
		if randf() < 0.5:
			obstacles.push_back(edge)
	
	# Link to get triangulation
	Triangulation.link_vertices(vertices, neighbors)
	var edges = Triangulation.neighbors_to_edges(neighbors)
	
	# Build navmesh
	var nm: NavMeshSphere = NavMeshSphere.build(vertices, neighbors, edges, obstacles)
	
	mtx.lock()
	finished = true
	navmesh = nm
	mtx.unlock()
	navmesh_ready.emit.call_deferred()


func _exit_tree():
	thread.wait_to_finish()
