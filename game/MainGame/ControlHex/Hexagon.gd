extends Node2D


export var sides = [true, true, true, true, true, true]


# Called when the node enters the scene tree for the first time.
func _ready():
	$Side1.visible = sides[0]
	$Side2.visible = sides[1]
	$Side3.visible = sides[2]
	$Side4.visible = sides[3]
	$Side5.visible = sides[4]
	$Side6.visible = sides[5]
