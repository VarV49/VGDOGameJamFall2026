extends Marker3D

## Attach to a Marker3D child of your player, named "Hand".
## Position it in front of / above the chest. Held parts follow it.
## Assumes the player faces -Z (Godot's default forward).

@export var reach := 1.8          # how far away a slot can be
@export var min_facing := 0.3     # 1 = dead ahead, 0 = sideways. Higher = stricter

var held: Part = null

@onready var body: Node3D = get_parent()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return

	var slot: Slot = _best_slot()
	if slot == null:
		return

	if held == null:
		held = slot.take()
		held.reparent(self, false)
		held.transform = Transform3D.IDENTITY
	else:
		slot.put(held)
		held = null

## Picks the nearest slot in front of the player that can actually do something:
## a slot holding a part if our hands are empty, or one that accepts our part if not.
func _best_slot() -> Slot:
	var forward := -body.global_transform.basis.z
	var best: Slot = null
	var best_dist := INF

	for node in get_tree().get_nodes_in_group("slots"):
		var s: Slot = node as Slot
		if s == null:
			continue

		var useful: bool = (s.part != null) if held == null else s.can_accept(held)
		if not useful:
			continue

		var to := s.global_position - body.global_position
		to.y = 0.0
		var dist := to.length()
		if dist > reach:
			continue
		if dist > 0.01 and forward.dot(to / dist) < min_facing:
			continue

		if dist < best_dist:
			best = s
			best_dist = dist

	return best