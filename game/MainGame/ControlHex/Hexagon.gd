extends Node2D

class_name Hexagon

export var sides = [true, true, true, true, true, true]

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.connect("update_borders",self,"_on_border_update")
	$Side1.visible = sides[0]
	$Side2.visible = sides[1]
	$Side3.visible = sides[2]
	$Side4.visible = sides[3]
	$Side5.visible = sides[4]
	$Side6.visible = sides[5]

func _on_border_update():
	queue_free()
