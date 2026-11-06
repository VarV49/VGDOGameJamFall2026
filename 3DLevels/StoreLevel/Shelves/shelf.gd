class_name Shelf
extends Node3D

## Parts to place, in order. Index 0 goes on the first marker, index 1 on the second, etc.
## Leave an entry empty to skip that marker. Use the leaf part scenes
## (e.g. ram_ddr5_16gb.tscn), never base_part.tscn.
@export var stock: Array[PackedScene] = []

## Child node whose children are the position markers. Must be named "Slots".
@onready var slots_root: Node = $Slots

func _ready() -> void:
	_fill()

func _fill() -> void:
	var markers := slots_root.get_children()
	if stock.size() > markers.size():
		push_warning("Shelf '%s': %d parts but only %d markers" % [name, stock.size(), markers.size()])

	for i in min(stock.size(), markers.size()):
		if stock[i] == null:
			continue
		var p := stock[i].instantiate() as Part
		if p == null:
			push_warning("Shelf '%s': stock entry %d is not a Part scene" % [name, i])
			continue
		markers[i].add_child(p)
		p.transform = Transform3D.IDENTITY

## Optional: swap what's on the shelf at runtime (new job, new stock).
func restock(new_stock: Array[PackedScene]) -> void:
	for marker in slots_root.get_children():
		for child in marker.get_children():
			if child is Part:
				child.queue_free()
	stock = new_stock
	_fill()
