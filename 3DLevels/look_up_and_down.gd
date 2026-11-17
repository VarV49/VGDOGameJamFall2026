extends Camera3D

# mouse sense
var mouse_sens: float = 0.002
# Variables for min and max look angles
@export var min_look_angle: float = -PI/6
@export var max_look_angle: float = PI/6

# Controls the pitch of the camera angle
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation.x -= event.relative.y * mouse_sens
		# Ensures the player cannot look too far upward or downward
		rotation.x = (clamp(rotation.x, min_look_angle, max_look_angle))
