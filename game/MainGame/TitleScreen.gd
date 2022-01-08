extends Node2D


func _on_Button_pressed():
	get_tree().change_scene("res://game/MainGame/World-Tony.tscn")
	Global.ingame = true
	Global.currenttrack = 1
