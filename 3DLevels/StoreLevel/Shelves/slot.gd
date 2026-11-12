class_name Slot
extends Marker3D

## Empty = accepts any part (shelves, benches). Set it (e.g. "DDR5") for sockets.
@export var accepts_socket: StringName = &""

var part: Part = null

func _ready() -> void:
	add_to_group("slots")

func can_accept(p: Part) -> bool:
	if part != null:
		return false
	return accepts_socket == &"" or p.socket_type == accepts_socket

## Works for a brand new part (no parent yet) or one that's already in the tree.
func put(p: Part) -> void:
	part = p
	if p.get_parent() == null:
		add_child(p)
	else:
		p.reparent(self, false)
	p.transform = Transform3D.IDENTITY

## Hands the part over. The caller is responsible for reparenting it.
func take() -> Part:
	var p := part
	part = null
	return p