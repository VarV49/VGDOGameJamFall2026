class_name RepairJob
extends Resource

## One kind of job a customer can bring. Normally made by JobGenerator, but you
## can also make .tres files of this by hand
## (FileSystem -> right click -> New Resource -> RepairJob).

@export var customer_name: String = "Customer"
@export_multiline var request: String = "My CPU died, can you replace it?"

@export_group("Hardware job")
## What the player has to bring back.
@export_enum("CPU", "GPU", "RAM", "PSU", "Drive", "Motherboard", "Cable", "Fan") var required_category: String = "CPU"
## Leave empty to accept any socket type of that category.
@export var required_socket: StringName = &""

@export_group("Software job")
## No part needed: the player presses E on the computer and holds E to work.
@export var is_software: bool = false
@export var software_task: String = ""
## Seconds of holding E to finish a software job.
@export var work_time: float = 4.0

@export_group("Payout")
@export var reward: int = 100
## Lost if the customer runs out of patience.
@export var penalty: int = 0
## Seconds the customer waits after arriving.
@export var patience: float = 60.0

## Hardware jobs only.
func accepts(p: Part) -> bool:
	if is_software:
		return false
	if p.category != required_category:
		return false
	return required_socket == &"" or p.socket_type == required_socket