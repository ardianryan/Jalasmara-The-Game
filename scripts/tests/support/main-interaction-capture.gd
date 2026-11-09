extends "res://scripts/Main.gd"

var spoken_to: Array[String]=[]

func _npc_interact(name_text: String) -> void:
	spoken_to.append(name_text)
