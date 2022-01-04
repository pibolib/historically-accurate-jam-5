extends Node2D

export var char_name = "Name"
export(int,1,7) var max_ap = 5
var ap = 0
export(int,1,5) var rank = 1
var xp = 0 # out of 100
export(int,1,5) var influence = 3
export(int,1,5) var construction = 1
export(int,1,5) var command = 2
export var sprite = preload("res://icon.png")
var army = 0
var footmen = 300
var archers = 100
var cavalry = 100
var elephants = 0
var max_army = 0
var tile_pos = Vector2(0,0)
var selected = true
var animtime = 0

enum {
	T_GRASS, T_SAND, T_WATER, T_DIRT, T_ROCK
} # tile types, building types, special tiles
enum {
	B_RICE_PADDY_L1, B_OCCUPIED_X, 
}

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite.texture = sprite
	$SpritePreview.texture = sprite
	var floor_map = get_parent().get_node("FloorMap")
	ap = max_ap
	max_army = 3000*command
	army = footmen + archers + cavalry + elephants
	tile_pos = floor_map.world_to_map(position)

func _process(delta):
	animtime += delta
	if animtime >= 4:
		animtime -= 4
	$Sprite.region_rect.position.x = 64 * int(animtime)
	var floor_map = get_parent().get_node("FloorMap")
	var mouse_pos = get_viewport().get_mouse_position()
	$Name.text = char_name + " ("+String(ap)+"/"+String(max_ap)+" AP)"+"\n"+String(army)+"/"+String(max_army)
	#if Input.is_action_just_pressed("action_lc"):
		#test_movement(floor_map.world_to_map(mouse_pos))
	$SpritePreview.position = floor_map.map_to_world(floor_map.world_to_map(mouse_pos))-position+$Sprite.position
	if $SpritePreview.position != Vector2(32,32):
		$SpritePreview.visible = true
	else:
		$SpritePreview.visible = false
	if xp >= 100 and rank < 5:
		level_up()
		

func level_up():
	var skill_pts = 2
	while skill_pts > 0:
		var choose = randi()%3
		match choose:
			0:
				if influence < 5:
					influence += 1
					skill_pts -= 1
			1:
				if construction < 5:
					construction += 1
					skill_pts -= 1
			2:
				if command < 5:
					command += 1
					skill_pts -= 1
		if influence == 5 and construction == 5 and command == 5:
			skill_pts = 0
	xp -= 100
	max_army = 3000*command
	print("Level up!")

func test_movement(pos):
	var floor_map = get_parent().get_node("FloorMap")
	var distance = 0
	var cost = 0
	var current_pos = tile_pos
	var goal_pos = pos
	while current_pos != goal_pos:
		if current_pos.x == goal_pos.x:
			if current_pos.y < goal_pos.y:
				current_pos.y += 1
			elif current_pos.y > goal_pos.y:
				current_pos.y -= 1
		elif current_pos.y == goal_pos.y:
			if current_pos.x < goal_pos.x:
				current_pos.x += 1
			elif current_pos.x > goal_pos.x:
				current_pos.x -= 1
		else:
			if int(current_pos.y) % 2 == 0:
				if current_pos.x < goal_pos.x: # right
					if current_pos.y < goal_pos.y: # down, right
						current_pos.y += 1
					elif current_pos.y > goal_pos.y: # up, right
						current_pos.y -= 1
				elif current_pos.x > goal_pos.x: # left
					if current_pos.y < goal_pos.y: # down, left
						current_pos.y += 1
						current_pos.x -= 1
					elif current_pos.y > goal_pos.y: # up, left
						current_pos.y -= 1
						current_pos.x -= 1
			else:
				if current_pos.x < goal_pos.x: # right
					if current_pos.y < goal_pos.y: # down, right
						current_pos.y += 1
						current_pos.x += 1
					elif current_pos.y > goal_pos.y: # up, right
						current_pos.y -= 1
						current_pos.x += 1
				elif current_pos.x > goal_pos.x: # left
					if current_pos.y < goal_pos.y: # down, left
						current_pos.y += 1
					elif current_pos.y > goal_pos.y: # up, left
						current_pos.y -= 1
		distance += 1
		if floor_map.get_cell(current_pos.x,current_pos.y) != T_WATER:
			cost += 1
		else:
			cost += 2
	print("AP Cost: "+String(cost)+", Distance: "+String(distance))
	if cost <= ap and floor_map.get_cell(goal_pos.x,goal_pos.y) != T_WATER:
		print("Can Move")
		tile_pos = goal_pos
		position = floor_map.map_to_world(tile_pos)
		xp += distance
	else:
		print("Can't Move")
