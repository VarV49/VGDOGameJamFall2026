class_name Shelf
extends Node3D

## Parts to place, in order. Index 0 goes on the first slot, index 1 on the second, etc.
## Leave an entry empty to skip that slot. Use the leaf part scenes
## (e.g. ram_ddr5_16gb.tscn), never base_part.tscn.
@export var stock: Array[PackedScene] = []

## Child node whose children are the Slot markers. Must be named "Slots".
@onready var slots_root: Node = $Slots

func _ready() -> void:
	_fill()

func _fill() -> void:
	var slots := slots_root.get_children()
	if stock.size() > slots.size():
		push_warning("Shelf '%s': %d parts but only %d slots" % [name, stock.size(), slots.size()])

	for i in min(stock.size(), slots.size()):
		if stock[i] == null:
			continue
		var slot := slots[i] as Slot
		if slot == null:
			push_warning("Shelf '%s': child %d of Slots doesn't have slot.gd" % [name, i])
			continue
		var p := stock[i].instantiate() as Part
		if p == null:
			push_warning("Shelf '%s': stock entry %d is not a Part scene" % [name, i])
			continue
		slot.put(p)

## Optional: swap what's on the shelf at runtime (new job, new stock).
func restock(new_stock: Array[PackedScene]) -> void:
	for node in slots_root.get_children():
		var slot := node as Slot
		if slot and slot.part:
			slot.take().queue_free()
	stock = new_stock
	_fill()