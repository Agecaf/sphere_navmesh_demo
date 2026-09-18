class_name FlowerUtils extends Object

const golden_angle: float = 2.39996323

# A spherical array of vectors
static func sphere(n: int) -> Array[Vector3]:
	
	var yaw: float = 0.0
	var pitch: float = 0.0
	var out: Array[Vector3] = []
	
	for idx in n:
		yaw = golden_angle * idx
		pitch = asin((idx / float(n)) * 2.0 - 1.0)
		out.push_back(Vector3(cos(yaw)*cos(pitch), sin(pitch), sin(yaw)*cos(pitch)))
	
	return out
