extends Control

var main_game = preload("res://3DLevels/StoreLevel/micro_center_map.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_instructions_pressed() -> void:
	print("Instructions")


func _on_play_pressed() -> void:
	print("Play")
	get_tree().change_scene_to_packed(main_game)


func _on_exit_game_pressed() -> void:
	get_tree().quit()
