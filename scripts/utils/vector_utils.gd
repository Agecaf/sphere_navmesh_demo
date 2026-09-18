class_name VectorUtils extends Object


# Spherical distance
static func sphere_distance(a: Vector3, b: Vector3) -> float:
	return acos(a.dot(b))

# Spherical interpolation
static func sphere_lerp(a: Vector3, b: Vector3, lambda: float) -> Vector3:
	var c = b.slide(a).normalized()
	var theta = clampf(lambda, 0.0, 1.0) * sphere_distance(a, b)
	return a * cos(theta) + c * sin(theta)

# Check whether a vector is inside the normals
static func vector_inside_normals(v: Vector3, normals: Basis) -> bool:
	return (
		v.dot(normals.x) > 0.0 and
		v.dot(normals.y) > 0.0 and
		v.dot(normals.z) > 0.0
	)

# The normals of a triangle for easy comparison.
static func triangle_normals(v1: Vector3, v2: Vector3, v3: Vector3) -> Basis:
	# Normals
	var n1: Vector3 = v2.cross(v3).normalized()
	var n2: Vector3 = v3.cross(v1).normalized()
	var n3: Vector3 = v1.cross(v2).normalized()
	
	# Make sure they're in the right orientation
	if n1.dot(v1) < 0.0: n1 *= -1.0
	if n2.dot(v2) < 0.0: n2 *= -1.0
	if n3.dot(v3) < 0.0: n3 *= -1.0
	
	return Basis(n1, n2, n3)
