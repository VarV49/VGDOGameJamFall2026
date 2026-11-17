extends CharacterBody3D

@export var speed := 12.0
@export var turn_speed := 14.0

@onready var pivot: Node3D = $BodyPivot   # holds CharacterModel + PickupArea

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("left", "right", "forward", "backward")
	var dir := Vector3(input.x, 0, input.y)

	if dir.length() > 0.1:
		dir = dir.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed

		var target_yaw := atan2(-dir.x, -dir.z)   # model faces -Z; use atan2(dir.x, dir.z) if it faces +Z
		pivot.rotation.y = lerp_angle(pivot.rotation.y, target_yaw, turn_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()
