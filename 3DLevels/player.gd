extends CharacterBody3D

# Variables for movement speed and jump velocity
const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Mouse sense
@export var mouse_sense: float = 0.002
var paused: bool = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Controls player yaw or looking horizontally (left-right)
func _input(event: InputEvent) -> void:
	# makes sure that the player has infinite range for looking
	# this also makes it so there is an escape key to be able to leave the game and such
	if event.is_action_pressed("toggle_pause") and paused == false:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		paused = true
	elif event.is_action_pressed("toggle_pause") and paused == true:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		paused = false
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sense)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# Using wasd as movement controls
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
