extends Node

var turn = 0 #0: player, 1: enemy
signal end_turn(player)
signal mouse_click_world(tilepos)
var selected_tile = -1


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("end_turn",self,"_on_end_turn")


func _process(delta):
	$Mouse.position = get_viewport().get_mouse_position()
	if Input.is_action_just_pressed("action_endturn") and turn == 0:
		emit_signal("end_turn",0)
	if Input.is_action_just_pressed("action_lc"):
		emit_signal("mouse_click_world",$Base.world_to_map($Mouse.position))
		print("Mouse click at "+String($Base.world_to_map($Mouse.position)))

func _on_end_turn(player):
	print("turn end, player "+String(player))
	pass

func get_mouse_pos():
	return $Mouse.position
