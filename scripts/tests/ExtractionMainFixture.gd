extends "res://scripts/Main.gd"

var messages := 0

func _ready() -> void:
	set_process(false)
	nala=PlayerScript.new()
	add_child(nala)
	nala.set_physics_process(false)
	camera=Camera2D.new()
	add_child(camera)
	status=Label.new()
	add_child(status)

func _update_hud() -> void:
	pass

func _show_message(_title: String,_message: String) -> void:
	messages+=1
	modal_open=true
	nala.frozen=true
