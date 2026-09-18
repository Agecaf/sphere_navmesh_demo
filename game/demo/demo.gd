extends Node3D

var navmesh: NavMeshSphere
var start_selected: bool = false

# Ok? Ok.
func _ready() -> void:
	$ParallelThread.navmesh_ready.connect(reload)
	$Pathfinder.path_ready.connect(_on_path_ready)
	$World.click.connect(click)

func reload() -> void:
	Debug.log("Reload finished!")
	navmesh = $ParallelThread.get_navmesh()
	
	# View obstacles
	$ObstacleVectors.view_vectors(navmesh.obstacle_vertices)
	$ObstacleSegments.view_segments(Triangulation.edges_to_segments(navmesh.obstacle_edges, navmesh.vertices))
	
	# View grid
	$GridSegments.view_segments(Triangulation.edges_to_segments(navmesh.edges, navmesh.vertices))
	



func click(pos: Vector3) -> void:
	if not start_selected:
		$StartPosition.position = pos
		start_selected = true
	else:
		$EndPosition.position = pos
		start_selected = false
		$Pathfinder.find_path(navmesh, $StartPosition.position, $EndPosition.position)


func _on_path_ready() -> void:
	
	var path: Array[Vector3] = $Pathfinder.get_navigation_path()
	
	# Build and show segments
	var segments: Array[Segment] = []
	for idx in len(path)-1:
		segments.push_back(Segment.new(path[idx], path[idx+1]))
	$PathSegments.view_segments(segments)
	
	# Build and show debug
	var debug_path: Array[Vector3] = $Pathfinder.get_debug_path()
	var segments_debug: Array[Segment] = []
	for idx in len(debug_path)-1:
		segments_debug.push_back(Segment.new(debug_path[idx], debug_path[idx+1]))
	$DebugSegments.view_segments(segments_debug)






#
