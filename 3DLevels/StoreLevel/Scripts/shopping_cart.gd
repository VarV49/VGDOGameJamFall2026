class_name ShoppingCart
extends Node3D


@export var route: Path3D
@export var speed: float = 2.0
## Seconds to pause at each point of the route.
@export var wait_time: float = 0.0
## On: 1 -> 2 -> 3 -> 1 -> ... (a circuit). Off: 1 -> 2 -> 3 -> 2 -> 1 (back and forth).
@export var loop: bool = true
## Turn the cart to face where it's going. The cart's front is its -Z side.
@export var face_direction: bool = true
@export var turn_speed: float = 6.0

var _points: Array[Vector3] = []
var _index: int = 1
var _dir: int = 1
var _wait_left: float = 0.0

func _ready() -> void:
	# Lets the physics engine treat the cart as a moving solid, so the player
	# is pushed by it instead of the cart clipping through them.

	if route == null or route.curve == null or route.curve.point_count < 2:
		push_warning("ShoppingCart '%s': assign a Path3D with at least 2 points to Route" % name)
		set_physics_process(false)
		return

	# Copy the route's points into world space once. The cart keeps its own
	# height, so the Path3D can be drawn on the floor.
	var y: float = global_position.y
	for i in route.curve.point_count:
		var p: Vector3 = route.to_global(route.curve.get_point_position(i))
		_points.append(Vector3(p.x, y, p.z))

	global_position = _points[0]

func _physics_process(delta: float) -> void:
	if _wait_left > 0.0:
		_wait_left -= delta
		return

	var target: Vector3 = _points[_index]
	var to: Vector3 = target - global_position
	var step: float = speed * delta

	if to.length() <= step:
		global_position = target
		_advance()
		_wait_left = wait_time
		return

	global_position += to.normalized() * step
	if face_direction:
		var yaw: float = atan2(-to.x, -to.z)
		rotation.y = lerp_angle(rotation.y, yaw, clampf(turn_speed * delta, 0.0, 1.0))

func _advance() -> void:
	if loop:
		_index = (_index + 1) % _points.size()
	else:
		if _index + _dir >= _points.size() or _index + _dir < 0:
			_dir = -_dir
		_index += _dir
