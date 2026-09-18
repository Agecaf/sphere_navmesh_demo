class_name Segment extends RefCounted

var v0: Vector3
var v1: Vector3
var normal: Vector3
var midpoint: Vector3
var m_dot_v: float
var length: float

# Initialize
func _init(from: Vector3, to: Vector3) -> void:
	v0 = from.normalized()
	v1 = to.normalized()
	normal = v0.cross(v1).normalized()
	length = acos(v0.dot(v1))
	midpoint = (v0 + v1).normalized()
	m_dot_v = midpoint.dot(v0)


func intersection_with(other: Segment) -> Vector3:
	var v: Vector3 = normal.cross(other.normal).normalized()
	if v.dot(midpoint) < 0: v *= -1
	if v.dot(midpoint) < m_dot_v: return Vector3(0.0, 0.0, 0.0)
	if v.dot(other.midpoint) < other.m_dot_v: return Vector3(0.0, 0.0, 0.0)
	return v

func intersects(other: Segment) -> bool:
	# Find the point of intersection
	var v: Vector3 = normal.cross(other.normal).normalized()
	if v.dot(midpoint) < 0: v *= -1
	if v.dot(midpoint) < m_dot_v: return false
	if v.dot(other.midpoint) < other.m_dot_v: return false
	return true

# Render a segment
func render_thin(step: float) -> PackedVector3Array:
	var out: PackedVector3Array = PackedVector3Array()
	var num_steps: int = ceil(length / step)
	
	var v: Vector3 = Vector3(0.0, 0.0, 0.0)
	# Build the path, each step as a line segment!
	out.push_back(v0)
	for idx in num_steps:
		if idx == 0: continue
		# v = lerp(v0, v1, idx / float(num_steps)).normalized()
		v = VectorUtils.sphere_lerp(v0, v1, idx / float(num_steps))
		out.push_back(v)
		out.push_back(v)
	out.push_back(v1)
	
	return out

# Render a segment with thickness
func render_thick(step: float, width: float) -> PackedVector3Array:
	var out: PackedVector3Array = PackedVector3Array()
	var strip: PackedVector3Array = PackedVector3Array()
	var num_steps: int = ceil(length / step)
	
	var v: Vector3 = Vector3(0.0, 0.0, 0.0)
	var v_up: Vector3 = Vector3(0.0, 0.0, 0.0)
	var v_down: Vector3 = Vector3(0.0, 0.0, 0.0)
	
	# Build the path, each step as a line segment!
	strip.push_back(v0)
	for idx in num_steps:
		if idx == 0: continue
		v = VectorUtils.sphere_lerp(v0, v1, idx / float(num_steps))
		# lerp(v0, v1, idx / float(num_steps)).normalized()
		v_up = v + normal * width * 0.5
		v_down = v - normal * width * 0.5
		strip.push_back(v_up)
		strip.push_back(v_down)
	strip.push_back(v1)
	
	# Build output from strip
	for idx in len(strip) - 2:
		if posmod(idx, 2) == 0:
			out.push_back(strip[idx])
			out.push_back(strip[idx+1])
			out.push_back(strip[idx+2])
		else:
			out.push_back(strip[idx])
			out.push_back(strip[idx+2])
			out.push_back(strip[idx+1])
	
	return out
