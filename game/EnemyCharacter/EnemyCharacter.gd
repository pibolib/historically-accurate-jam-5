extends Node2D

var tile_pos = Vector2(0,0)
var type = "Enemy"
var current_town = -1
var footmen = 5
var archers = 0
var cavalry = 0
var elephants = 0
var sprites = [preload("res://gfx/enemy1.png"),preload("res://gfx/enemy2.png")]
var animtime = 0
var ap = 3
var target = Vector2(0,0)
export(int, 1, 5, 1) var difficulty_level = 1

onready var floor_map = get_parent().get_node("FloorMap")
onready var building_map = get_parent().get_node("BuildingMap")
onready var movement_map = get_parent().get_node("MovementMap")

func _ready():
	match difficulty_level:
		1:
			footmen = int(rand_range(5,10))
			archers = int(rand_range(0,5))
		2:
			footmen = int(rand_range(5,15))
			archers = int(rand_range(0,7))
			cavalry = int(rand_range(0,2))
		3:
			footmen = int(rand_range(5,20))
			archers = int(rand_range(0,10))
			cavalry = int(rand_range(0,3))
		4:
			footmen = int(rand_range(10,25))
			archers = int(rand_range(2,10))
			cavalry = int(rand_range(0,4))
		5:
			footmen = int(rand_range(10,30))
			archers = int(rand_range(2,12))
			cavalry = int(rand_range(0,5))
			elephants = int(rand_range(0,2))
	$Label.text = "Lv. "+String(difficulty_level)+"/5"
	$Sprite.texture = sprites[randi()%2]
	tile_pos = floor_map.world_to_map(position)
	Global.connect("end_turn",self,"_on_end_turn")
	target = tile_pos
	get_current_town()

func _process(delta):
	animtime += delta*3
	if animtime >= 3:
		animtime -= 3
	$Sprite.region_rect.position.x = 64 * int(animtime)
	position = floor_map.map_to_world(tile_pos)
	var move_towards = target_move(target).Pos
	if Global.turn == 1:
		ap -= target_move(target).Cost
		tile_pos = move_towards
		get_current_town()
	if !(current_town is int):
		for pos in Global.player_positions:
			if current_town.owned_tiles.has(pos):
				target = pos
				break
func get_current_town():
	var towns = get_parent().get_node("Towns")
	for town in towns.get_children():
		if town is TileMap:
			if town.owned_tiles.has(tile_pos):
				current_town = town
				break

func target_move(pos):
	var info = {
		"Cost": 0,
		"Pos": Vector2(0,0)
	}
	var distance = 0
	var cost = 0
	var current_pos = tile_pos
	var goal_pos = pos
	while current_pos != goal_pos and cost < ap:
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
		var current_cell = floor_map.get_cell(current_pos.x,current_pos.y)
		if current_cell != Global.T_WATER:
			cost += 1
		else:
			cost += 1
			info.Cost = cost
			info.Pos = current_pos
			return info
		movement_map.set_cell(current_pos.x,current_pos.y,1)
	info.Cost = cost
	info.Pos = current_pos
	return info

func _on_end_turn(player):
	if player == 1:
		ap = 3

