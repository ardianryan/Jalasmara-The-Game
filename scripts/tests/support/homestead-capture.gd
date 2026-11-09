extends "res://scripts/HomesteadUI.gd"
var requests:Array=[]
func _perform(action: String,extra: Dictionary={}) -> void:
	requests.append({"action":action,"extra":extra.duplicate(true)})
