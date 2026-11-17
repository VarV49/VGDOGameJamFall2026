class_name Hazard
extends Area3D

## Add as an Area3D child of anything that should hurt the player: a shopping
## cart, a roach... It costs points while the player overlaps it.
##
## Setup:
##   - Give it a CollisionShape3D a bit bigger than the thing it's on.
##   - Its Collision Mask must include the layer your player is on.
##   - The player must be in the group "player" (Node dock -> Groups).
## Because it's a child of the cart / roach, it moves along with it.

## Points lost per hit. GameState's cooldown stops it draining every frame.
@export var damage: int = 50

func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			GameState.enemy_hit(damage)
			return