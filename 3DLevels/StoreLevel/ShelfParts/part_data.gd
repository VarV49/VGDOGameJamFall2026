class_name PartData
extends Resource
# This script is the data of the part, which is grabbed from the .tres file
# Which is then given to the part scene by the shelves



@export_enum("CPU", "GPU", "RAM", "Motherboard", "Fan") var category: String

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
@export var mesh: Mesh

