extends Camera2D

func _ready():
	Global.connect("focus_nhi",self,"_on_focus_nhi")
	Global.connect("focus_trac",self,"_on_focus_trac")

func _process(delta):
	zoom.x = Global.zoom_value
	zoom.y = Global.zoom_value
	if Input.is_action_just_released("action_wheelup"):
		Global.zoom_value += 0.2
	if Input.is_action_just_released("action_wheeldown"):
		Global.zoom_value -= 0.2
	if Input.is_action_just_pressed("action_wheelclick"):
		Global.zoom_value = 1
	$UI.scale = Vector2(Global.zoom_value,Global.zoom_value)
	Global.zoom_value = clamp(Global.zoom_value,0.2,4)
	if Global.display_type == Global.display.NONE:
		for area in $UI/Left.get_overlapping_areas():
			if area.name == "Mouse":
				position.x -= 4
				break
		for area in $UI/Right.get_overlapping_areas():
			if area.name == "Mouse":
				position.x += 4
				break
		for area in $UI/Up.get_overlapping_areas():
			if area.name == "Mouse":
				position.y -= 4
				break
		for area in $UI/Down.get_overlapping_areas():
			if area.name == "Mouse":
				position.y += 4
				break

func _on_focus_trac():
	var targettile = Global.player_positions[0]
	position = get_parent().get_node("FloorMap").map_to_world(targettile)+Vector2(32,20)
	Global.zoom_value = 1

func _on_focus_nhi():
	var targettile = Global.player_positions[1]
	position = get_parent().get_node("FloorMap").map_to_world(targettile)+Vector2(32,20)
	Global.zoom_value = 1
