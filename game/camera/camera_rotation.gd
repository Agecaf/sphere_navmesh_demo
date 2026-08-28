extends Node3D

const SPEED: float = 1.0
var yaw: float = 0.0
var pitch: float = 0.0

# Processadsawdsawdsa
func _process(delta: float) -> void:
	# Input
	if Input.is_action_pressed(&"left"): yaw -= delta * SPEED
	if Input.is_action_pressed(&"right"): yaw += delta * SPEED
	if Input.is_action_pressed(&"up"): pitch += delta * SPEED
	if Input.is_action_pressed(&"down"): pitch -= delta * SPEED
	
	pitch = clampf(pitch, -PI*0.5, PI*0.5)
	
	# Raycast camera
	var intersection: Vector3 = Vector3(0.0, 0.0, 0.0)
	var normal: Vector3 = $Camera3D.project_ray_normal(get_viewport().get_mouse_position())
	var origin: Vector3 = $Camera3D.project_ray_origin(get_viewport().get_mouse_position())
	
	var theta: float = acos(origin.normalized().dot(-normal))
	var y: float = origin.length()
	if y * sin(theta) < 1.0:
		var x = y*cos(theta) - sqrt(1.0 - y*y*sin(theta)*sin(theta))
		intersection = origin + x * normal
		if Input.is_action_just_pressed(&"click"):
			get_parent().click.emit(intersection)
	
	$Pointer.global_position = intersection
	
	# Rotation
	rotation = Vector3(0.0, yaw, pitch)
