class_name PlayerHand
extends Marker3D

## Attach to a Marker3D child of your player, named "Hand".
## Position it in front of / above the chest. Held parts follow it.
## Assumes the player faces -Z (Godot's default forward).
##
## E does one of these, whichever target is closest in front of you:
##   - hands empty, slot with a part  -> pick it up
##   - holding a part, slot that fits -> put it down
##   - holding a part, computer with a hardware job -> go into the repair scene
##   - computer with a software job (hands full or empty) -> go into the repair scene

@export var reach: float = 1.8          # how far away something can be
@export var min_facing: float = 0.3     # 1 = dead ahead, 0 = sideways. Higher = stricter

var held: Part = null

@onready var body: Node3D = get_parent()

func _ready() -> void:
	add_to_group("hand")

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return

	print("E pressed | slots: ", get_tree().get_nodes_in_group("slots").size(),
		" | computers: ", get_tree().get_nodes_in_group("computers").size(),
		" | held: ", held)

	var slot: Slot = _best_slot()
	var computer: Computer = _best_computer()

	# Both in range: the closer one wins.
	if computer != null and (slot == null or _reach_dist(computer) <= _reach_dist(slot)):
		_hand_to_repair(computer)
		return

	if slot == null:
		return

	if held == null:
		give(slot.take())
	else:
		slot.put(held)
		held = null

## Puts a part in the player's hands (used here, and when backing out of a repair).
func give(p: Part) -> void:
	held = p
	if p.get_parent() == null:
		add_child(p)
	else:
		p.reparent(self, false)
	p.transform = Transform3D.IDENTITY

func _hand_to_repair(computer: Computer) -> void:
	var p: Part = null
	# Hardware jobs take the held part into the repair scene. Software jobs
	# take nothing; whatever you're holding stays in your hand.
	if not computer.job.is_software:
		p = held
		held = null
		p.get_parent().remove_child(p)
	get_viewport().set_input_as_handled()   # this E press shouldn't also reach the repair scene
	GameState.repair_requested.emit(computer, p)

## Distance on the floor to n, or INF if it's out of reach or behind the player.
func _reach_dist(n: Node3D) -> float:
	var forward: Vector3 = -body.global_transform.basis.z
	var to: Vector3 = n.global_position - body.global_position
	to.y = 0.0
	var dist: float = to.length()
	if dist > reach:
		return INF
	if dist > 0.01 and forward.dot(to / dist) < min_facing:
		return INF
	return dist

## Nearest slot in front of the player that can actually do something:
## one holding a part if our hands are empty, or one that accepts our part if not.
func _best_slot() -> Slot:
	var best: Slot = null
	var best_dist: float = INF

	for node in get_tree().get_nodes_in_group("slots"):
		var s: Slot = node as Slot
		if s == null:
			continue

		var useful: bool = (s.part != null) if held == null else s.can_accept(held)
		if not useful:
			continue

		var d: float = _reach_dist(s)
		if d < best_dist:
			best = s
			best_dist = d

	return best

## Nearest customer computer in front of the player that we can work on:
## hardware jobs only while holding a part, software jobs any time.
func _best_computer() -> Computer:
	var best: Computer = null
	var best_dist: float = INF

	for node in get_tree().get_nodes_in_group("computers"):
		var c: Computer = node as Computer
		if c == null or c.job == null:
			continue
		if not c.job.is_software and held == null:
			continue

		var d: float = _reach_dist(c)
		if d < best_dist:
			best = c
			best_dist = d

	return best