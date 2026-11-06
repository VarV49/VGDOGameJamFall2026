class_name Part
extends Node3D

@export var id: StringName
@export var display_name: String
@export_enum("CPU", "GPU", "RAM", "ALU") var category: String
@export var socket_type: StringName