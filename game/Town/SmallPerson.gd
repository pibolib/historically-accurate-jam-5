extends Node2D


var moving_type = true

func _ready():
	$Timer.wait_time = rand_range(2,5)
	$Timer.start()


func _process(delta):
	pass


func _on_Timer_timeout():
	pass # Replace with function body.
