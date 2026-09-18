class_name RandomUtils extends Object

static func vector() -> Vector3:
	var yaw = randf() * TAU
	var pitch = asin(randf() * 2.0 - 1.0)
	return Vector3(cos(yaw) * cos(pitch), sin(pitch), sin(yaw) * cos(pitch))
