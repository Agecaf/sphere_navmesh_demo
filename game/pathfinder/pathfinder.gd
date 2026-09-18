extends Node

signal path_ready()

var navmesh: NavMeshSphere
var start_position: Vector3
var end_position: Vector3

var path: Array[Vector3] = []
var debug_path: Array[Vector3] = []

# Multithreading
var finished: bool = true
var mtx: Mutex
var thread: Thread

# Initialization
func _ready() -> void:
	mtx = Mutex.new()
	finished = true
	thread = Thread.new()

# Return the navigation path
func get_navigation_path() -> Array[Vector3]:
	var out: Array[Vector3] = []
	# Unfinished
	if not is_finished(): return out
	
	# Get the path
	mtx.lock()
	for v in path:
		out.push_back(Vector3(v))
	mtx.unlock()
	return out

# Return the debug path
func get_debug_path() -> Array[Vector3]:
	var out: Array[Vector3] = []
	# Unfinished
	if not is_finished(): return out
	
	# Get the path
	mtx.lock()
	for v in debug_path:
		out.push_back(Vector3(v))
	mtx.unlock()
	return out


#Check if it's finished
func is_finished() -> bool:
	var out: bool
	mtx.lock()
	out = finished
	mtx.unlock()
	return out

# Called to start the path finding thread
func find_path(_navmesh: NavMeshSphere, _start: Vector3, _end: Vector3):
	
	# Check validity
	if _navmesh == null or _start == Vector3(0.0, 0.0, 0.0) or _end == Vector3(0.0, 0.0, 0.0):
		return
	
	# Check not finished
	if not is_finished():
		Debug.log("Still finding path, cannot start new search.")
		return
	
	# Get parameters
	mtx.lock()
	navmesh = _navmesh
	start_position = _start
	end_position = _end
	
	# Initialize
	debug_path = []
	path = []
	mtx.unlock()
	# And begin the thread
	Debug.log("Reloading... ")
	if thread.is_started(): thread.wait_to_finish()
	thread.start(find_path_threaded)

# The path finding thread!
func find_path_threaded() -> void:
	# Get params
	mtx.lock()
	var nm: NavMeshSphere = navmesh
	var start: Vector3 = Vector3(start_position)
	var end: Vector3 = Vector3(end_position)
	mtx.unlock()
	
	
	# Find triangles containing normals
	var start_idx: int = Navigation.find_triangle_containing(start, nm)
	var end_idx: int = Navigation.find_triangle_containing(end, nm)
	
	# Validate start and end triangle
	if start_idx == -1 or end_idx == -1:
		mtx.lock()
		finished = true
		path = [start, end]
		path_ready.emit.call_deferred()
		mtx.unlock()
	
	# A Star pathfinding
	var a_star_path: Array[int] = a_star_pathfind(start_idx, end_idx, nm)
	if len(a_star_path) == 0:
		# No path found
		mtx.lock()
		finished = true
		path = []
		path_ready.emit.call_deferred()
		mtx.unlock()
		return
	
	# Output path
	var out: Array[Vector3] = make_vector_path(a_star_path, nm)
	out.push_front(start)
	out.push_back(end)
	
	mtx.lock()
	for v in out: debug_path.push_back(v)
	mtx.unlock()
	
	# Simplify path
	simplify_path(out, nm)
	
	# Finish
	mtx.lock()
	finished = true
	path = out
	path_ready.emit.call_deferred()
	mtx.unlock()


# A Star pathfinding
func a_star_pathfind(start: int, end: int, nm: NavMeshSphere) -> Array[int]:
	
	# Nodes: x -> current, y -> previous, z -> path length, w -> path+heuristic
	var open: Dictionary[int, Vector4] = {}
	var closed: Dictionary[int,Vector4] = {}
	
	# Start pathfinding by opening the start vector
	open.set(start, Vector4(float(start), float(-1), 0.0, dist(start, end, nm)))
	
	while true:
		# Find the next node, the one with least path+heuristic
		if len(open) == 0: break
		var current_node: Vector4 = Vector4(-1.0, -1.0, -1.0, 100.0)
		for key in open.keys():
			if open[key].w < current_node.w:
				current_node = open[key]
		
		
		# The current node index
		var idx: int = int(current_node.x)
		if idx < 0 or idx >= len(nm.triangles): break
		
		# Close node
		open.erase(idx)
		closed.set(idx, current_node)
		
		# Check if we've reached the end!
		if idx == end:
			# Build path
			var out: Array[int] = []
			out.push_front(idx)
			while idx != start:
				# Navigate path through previous and extend the path
				idx = int(closed[idx].y)
				out.push_front(idx)
			return out
		
		# Open neighbors
		for jdx in nm.triangle_neighbors[idx]:
			
			# Don't reopen closed nodes
			if closed.has(jdx): continue
			
			# New node
			var new_path_length: float = current_node.z + dist(jdx, idx, nm)
			var new_node: Vector4 = Vector4(
				float(jdx), 
				float(idx), 
				new_path_length, 
				new_path_length + dist(jdx, end, nm)
			)
			
			# Open it if it has a better heuristic
			if not open.has(jdx): open.set(jdx, new_node)
			elif new_node.w < open[jdx].w: open.set(jdx, new_node)
	
	return []

# Distance along navmesh, for heuristics
func dist(from: int, to: int, nm: NavMeshSphere) -> float:
	return VectorUtils.sphere_distance(nm.centers[from], nm.centers[to])


# Make a vector path from centers and midpoints
func make_vector_path(idx_path: Array[int], nm: NavMeshSphere) -> Array[Vector3]:
	
	var out: Array[Vector3] = []
	
	for pdx in len(idx_path) - 1:
		var idx: int = idx_path[pdx]
		var jdx: int = idx_path[pdx+1]
		out.push_back(nm.centers[idx])
		var edge: Vector2i = Triangulation.triangles_shared_edge(nm.triangles[idx], nm.triangles[jdx])
		if edge.x < 0 or edge.y < 0: continue
		var midpoint: Vector3 = (nm.vertices[edge.x] + nm.vertices[edge.y]).normalized()
		out.push_back(midpoint)
	
	out.push_back(nm.centers[idx_path[-1]])
	
	return out


# Simplify a path
func simplify_path(p: Array[Vector3], nm: NavMeshSphere) -> void:
	
	# Information on whether we can simplify the path around a node or not.
	var q: Array[bool] = []
	q.push_back(true)
	for idx in len(p)-2: q.push_back(false)
	q.push_back(true)
	
	# Forever
	var validated: Array[int] = []
	while true:
		# Find somewhere we can simplify
		var validating: bool = false
		
		# Randomize the order of simplification
		var idx: int = q.find(false, int(randf() * len(q)))
		if idx < 0: idx = q.find(false)
		
		# If none are found, validate to possibly simplify even further
		# This makes sure we're going around corners, not towards them
		if idx < 0: 
			return
			
			# Validation is bugged at the moment.
			validating = true
			idx = validate(p, nm)
			
			# Break infinite loops
			if idx in validated: return
			validated.push_back(idx)
			if idx < 0: return
		
		# Get vectors and normals
		var v0: Vector3 = p[idx-1]
		var v1: Vector3 = p[idx]
		var v2: Vector3 = p[idx+1]
		var normals = VectorUtils.triangle_normals(v0, v1, v2)
		
		# Check if there's any obstacles
		var obstacles: Array[Vector3] = []
		for obs in nm.obstacle_vertices:
			if obs == v0 or obs == v2: continue
			if VectorUtils.vector_inside_normals(obs, normals):
				obstacles.push_back(obs)
		
		# No obstacles, can simplify!
		if len(obstacles) == 0:
			q.remove_at(idx)
			p.remove_at(idx)
		
		# One obstacle, can simplify!
		elif len(obstacles) == 1:
			q[idx] = true
			p[idx] = obstacles[0]
		
		# Too many obstacles, probably sharp corner
		elif len(obstacles) > 6:
			q[idx] = true
			
			# Avoid infinite validating
			if validating: return
		
		# Many obstacles, use graham scan!
		else:
			var gs: Array[Vector3] = graham_scan(v0, v1, v2, obstacles)
			q.remove_at(idx)
			p.remove_at(idx)
			gs.reverse()
			for v in gs:
				p.insert(idx, v)
				q.insert(idx, true)
		
		# Note: the number of q[idx] which are false has decreased by 1, 
		# So infinite loop terminates
		


# Povides a graham scan to find the convex hull of some points.
func graham_scan(v0: Vector3, v1: Vector3, v2: Vector3, obstacles: Array[Vector3]) -> Array[Vector3]:
	# Output path
	var out: Array[Vector3] = []
	out.push_back(v0)
	
	# Make and sort the list of obstacles by how close they are to v0 in angle
	var list: Array[Vector3] = []
	var v0_m_v1_n: Vector3 = (v0 - v1).normalized()
	for obs in obstacles: list.push_back(obs)
	list.sort_custom(func(a: Vector3, b: Vector3): 
		return (a-v1).normalized().dot(v0_m_v1_n) > (b-v1).normalized().dot(v0_m_v1_n) 
	)
	list.push_back(v2)
	
	# Add them to the stack, remove the previous one if bad
	var direction: Vector3 = (v1-v0).cross(v2-v1).normalized()
	for v in list:
		out.push_back(v)
		
		if len(out) >= 3:
			if (out[-2]-out[-3]).cross(out[-1]-out[-2]).dot(direction) < 0.0:
				out.remove_at(len(out)-2)
		
	
	out.pop_back()
	out.pop_front()
	
	return out


# Checks that we're moving around cornerers, not towards them
func validate(p: Array[Vector3], nm: NavMeshSphere) -> int:
	# Loop through path vertices
	var pdx: int = 0
	while pdx < len(p) - 2:
		pdx += 1
		# Get vectors
		var v0 = p[pdx-1]
		var v1 = p[pdx]
		var v2 = p[pdx+1]
		
		# Get normals
		var n0 = v1.cross(v2).normalized()
		var n2 = v0.cross(v1).normalized()
		if n0.dot(v0) < 0.0: n0 *= -1.0
		if n2.dot(v2) < 0.0: n2 *= -1.0
		
		# Get vertex indices if available (could be -1)
		var i0 = nm.vertices.find(v0)
		var i1 = nm.vertices.find(v1)
		var i2 = nm.vertices.find(v2)
		
		# Find neighbors
		if i1 < 0: pdx += 1; continue
		var neighbors: PackedInt64Array = nm.obstacle_neighors[i1]
		
		# Verify neighbors
		for jdx in neighbors:
			if jdx == i0: continue
			if jdx == i2: continue
			
			# Check if we have a vector out of order,
			# That's enough to validate
			var v: Vector3 = nm.vertices[jdx]
			if v.dot(n0) < 0.0 or v.dot(n2) < 0.0:
				prints(i1, v1)
				return pdx
	
	return -1

#
