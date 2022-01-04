extends Node

var turn = 0 #0: player, 1: enemy
signal end_turn(player)


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("end_turn",self,"_on_end_turn")


func _process(delta):
	if Input.is_action_just_pressed("action_endturn") and turn == 0:
		emit_signal("end_turn",0)
		

func _on_end_turn(player):
	print("turn end, player "+String(player))
	pass
