extends Node2D

var combat_scene = preload("res://game/Combat/CombatScene.tscn")

export var char_name = "Name"
var type = "Player"
export(int,1,7) var max_ap = 5
var ap = 0
export(int,1,5) var rank = 1
var xp = 0 # out of 100
export(int,1,5) var influence = 3
export(int,1,5) var construction = 1
export(int,1,5) var command = 2
export var sprite = preload("res://icon.png")
var defaultpreview = preload("res://gfx/tile_ownership.png")
var previewsprites = [
	preload("res://gfx/tile_rice_0.png"),
	-1,
	preload("res://gfx/building_fishingboat.png"),
	preload("res://gfx/building_housing.png"),
	preload("res://gfx/building_barracks.png"),
	-1,
	-1,
	-1,
	-1,
	preload("res://gfx/building_elephant_pen.png"),
	preload("res://gfx/building_storehouse.png"),
	-1,
	preload("res://gfx/building_monument.png")
	]
var deletesprite = preload("res://gfx/occupied_tile.png")
var army = 0
var footmen = 5
var archers = 0
var cavalry = 0
var elephants = 0
var max_army = 0
var tile_pos = Vector2(0,0)
var selected = false
var animtime = 0
var mode = PLAYER_ACTION.IDLE
var build_selected = -1
var selected_military_source = -1

enum PLAYER_ACTION {
	IDLE, MOVE, BUILD, REMOVE, REINFORCE, REINFORCE_CHOOSE
}

onready var floor_map = get_parent().get_node("FloorMap")
onready var building_map = get_parent().get_node("BuildingMap")
onready var movement_map = get_parent().get_node("MovementMap")
onready var camera = get_parent().get_node("WorldCamera")

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite.texture = sprite
	$SpritePreview.texture = defaultpreview
	ap = max_ap
	max_army = 10*command
	army = footmen + archers + cavalry + elephants
	tile_pos = floor_map.world_to_map(position)
	Global.connect("mouse_click_world",self,"_on_mouse_click")
	Global.connect("end_turn",self,"_on_end_turn")

func _process(delta):
	Global.player_positions.append(tile_pos)
	$Name.visible = (Global.zoom_value <= Global.zoom_text_invis_threshold)
	#$ArmyStats.visible = (Global.zoom_value <= Global.zoom_text_invis_threshold)
	army = footmen + archers + cavalry + elephants
	$UI/Panel.visible = selected
	$UI/Mode.text = String($SpritePreview.visible)
	$SelectedArrow.visible = selected
	if mode == PLAYER_ACTION.REINFORCE:
		$UI/ReinforceMenu.visible = true
	else:
		$UI/ReinforceMenu.visible = false
	animtime += delta*4
	if animtime >= 4:
		animtime -= 4
	$Sprite.region_rect.position.x = 64 * int(animtime)
	$Name.text = char_name
	$ArmyStats.text = String(army)+"/"+String(max_army)
	#if Input.is_action_just_pressed("action_lc"):
		#test_movement(floor_map.world_to_map(mouse_pos))
	$SpritePreview.position = building_map.map_to_world(Global.get_mouse_tile())-position+$Sprite.position+Vector2(0,8)
	if xp >= 100 and rank < 5:
		level_up()
	if !selected:
		$SpritePreview.visible = false
	else:
		camera.position = position + Vector2(32,20)
		$SpritePreview.visible = true
		$UI/Panel/InfoPanel/Name.text = char_name
		$UI/Panel/InfoPanel/FootmanCount.text = String(footmen)
		$UI/Panel/InfoPanel/ArcherCount.text = String(archers)
		$UI/Panel/InfoPanel/CavalryCount.text = String(cavalry)
		$UI/Panel/InfoPanel/ElephantCount.text = String(elephants)
		$UI/Panel/InfoPanel/TotalCount.text = "TOTAL\n"+String(army)+"/"+String(max_army)
		if mode == PLAYER_ACTION.BUILD:
			if build_selected != -1 or build_selected == -99:
				if build_selected != -99:
					$SpritePreview.texture = previewsprites[build_selected]
					if check_valid_build(Global.get_mouse_tile(), build_selected):
						$SpritePreview.modulate = Color(0,1,0,0.7)
						if Input.is_action_just_pressed("action_rc"):
							building_map.set_cell(Global.get_mouse_tile().x,Global.get_mouse_tile().y,build_selected)
							var towns = get_parent().get_node("Towns")
							for town in towns.get_children():
								if town is TileMap:
									if town.ownership == 0: #player ownership
										if town.owned_tiles.has(Global.get_mouse_tile()):
											town.init_building(Global.get_mouse_tile())
					else:
						$SpritePreview.modulate = Color(1,0,0,0.7)
				else:
					$SpritePreview.texture = deletesprite
					var towns = get_parent().get_node("Towns")
					for town in towns.get_children():
						if town is TileMap:
							if town.ownership == 0: #player ownership
								if town.owned_tiles.has(Global.get_mouse_tile()) and building_map.get_cell(Global.get_mouse_tile().x,Global.get_mouse_tile().y) != -1 and building_map.get_cell(Global.get_mouse_tile().x,Global.get_mouse_tile().y) != 1:
									$SpritePreview.modulate = Color(0,1,0,0.7)
									if Input.is_action_just_pressed("action_rc"):
										building_map.set_cell(Global.get_mouse_tile().x,Global.get_mouse_tile().y,-1)
										for building in town.buildings:
											if building.Position == Global.get_mouse_tile():
												town.buildings.erase(building)
												build_selected = -1
												break
								else:
									$SpritePreview.modulate = Color(1,0,0,0.7)
			else:
				$SpritePreview.visible = false
		elif mode == PLAYER_ACTION.MOVE:
			$SpritePreview.texture = defaultpreview
			var current_building = building_map.get_cell(Global.get_mouse_tile().x,Global.get_mouse_tile().y)
			var is_barracks = false
			match current_building:
				Global.B_BARRACKS,Global.B_BARRACKS_T2,Global.B_ELEPHANT_PEN:
					$SpritePreview/Label.visible = true
					is_barracks = true
				_:
					$SpritePreview/Label.visible = false
			var movement_data = test_movement(Global.get_mouse_tile())
			if movement_data.Cost <= ap and movement_data.CanMove:
				if Input.is_action_just_pressed("action_rc"):
					tile_pos = Global.get_mouse_tile()
					ap -= movement_data.Cost
					position = floor_map.map_to_world(tile_pos)
					if is_barracks:
						$ReinforceWait.start(0.3)
				$SpritePreview.modulate = Color(0,1,0,0.7)
			else:
				$SpritePreview.modulate = Color(1,0,0,0.7)
		elif mode == PLAYER_ACTION.REINFORCE_CHOOSE:
			$UI/Panel/ReinforceButton.text = "Cancel"
			if check_valid_barracks(Global.get_mouse_tile()):
				$SpritePreview.modulate = Color(0,1,0,0.7)
				if Input.is_action_just_pressed("action_rc"):
					selected_military_source = Global.get_mouse_tile()
					mode = PLAYER_ACTION.REINFORCE
					$UI/Panel/ReinforceButton.text = "Army"
			else:
				$SpritePreview.modulate = Color(1,0,0,0.7)
		elif mode == PLAYER_ACTION.REINFORCE:
			Global.display_type = Global.display.PLAYER
			selected = true
			$SpritePreview/Label.visible = false
			var barracksinfo = get_building_data(selected_military_source)
			match barracksinfo.Type:
				Global.B_BARRACKS, Global.B_BARRACKS_T2:
					$UI/ReinforceMenu/Footman/Quantity.text = String(barracksinfo.Holding[0]).pad_zeros(2)
					$UI/ReinforceMenu/Archer/Quantity.text = String(barracksinfo.Holding[1]).pad_zeros(2)
					$UI/ReinforceMenu/Cavalry/Quantity.text = String(barracksinfo.Holding[2]).pad_zeros(2)
					$UI/ReinforceMenu/Elephants/Quantity.text = "00"
					$UI/ReinforceMenu/Footman/Deposit.disabled = !(footmen > 0)
					$UI/ReinforceMenu/Footman/Withdraw.disabled = !(barracksinfo.Holding[0] > 0 and army < max_army)
					$UI/ReinforceMenu/Archer/Deposit.disabled = !(archers > 0)
					$UI/ReinforceMenu/Archer/Withdraw.disabled = !(barracksinfo.Holding[1] > 0 and army < max_army)
					$UI/ReinforceMenu/Cavalry/Deposit.disabled = !(cavalry > 0)
					$UI/ReinforceMenu/Cavalry/Withdraw.disabled = !(barracksinfo.Holding[2] > 0 and army < max_army)
					$UI/ReinforceMenu/Elephants/Deposit.disabled = true
					$UI/ReinforceMenu/Elephants/Withdraw.disabled = true
				Global.B_ELEPHANT_PEN:
					$UI/ReinforceMenu/Footman/Quantity.text = "00"
					$UI/ReinforceMenu/Archer/Quantity.text = "00"
					$UI/ReinforceMenu/Cavalry/Quantity.text = "00"
					$UI/ReinforceMenu/Elephants/Quantity.text = String(barracksinfo.Holding[0]).pad_zeros(2)
					$UI/ReinforceMenu/Footman/Deposit.disabled = true
					$UI/ReinforceMenu/Footman/Withdraw.disabled = true
					$UI/ReinforceMenu/Archer/Deposit.disabled = true
					$UI/ReinforceMenu/Archer/Withdraw.disabled = true
					$UI/ReinforceMenu/Cavalry/Deposit.disabled = true
					$UI/ReinforceMenu/Cavalry/Withdraw.disabled = true
					$UI/ReinforceMenu/Elephants/Deposit.disabled = !(elephants > 0)
					$UI/ReinforceMenu/Elephants/Withdraw.disabled = !(barracksinfo.Holding[0] > 0 and army < max_army)
		#print(floor_map.get_cell(Global.get_mouse_tile().x,Global.get_mouse_tile().y))

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

func check_valid_build(location, type):
	if building_map.get_cell(location.x,location.y) != -1:
		return false
	var towns = get_parent().get_node("Towns")
	var floor_tile = floor_map.get_cell(location.x,location.y)
	for town in towns.get_children():
		if town is TileMap:
			if town.ownership == 0: #player ownership
				if town.owned_tiles.has(tile_pos):
					if town.owned_tiles.has(location):
						match type:
							Global.B_RICE_PADDY:
								if floor_tile != Global.T_WATER and floor_tile != Global.T_GRAVEL and floor_tile != Global.T_ROCK:
									return true
							Global.B_FISHING_BOAT:
								if floor_tile == Global.T_WATER:
									return true
							Global.B_BARRACKS, Global.B_HOUSING, Global.B_MONUMENT, Global.B_STOREHOUSE:
								if floor_tile != Global.T_WATER:
									return true
							Global.B_ELEPHANT_PEN:
								if floor_tile == Global.T_GRASS or floor_tile == Global.T_DARK_GRASS:
									return true
	return false
	
func check_valid_barracks(location):
	var towns = get_parent().get_node("Towns")
	for town in towns.get_children():
		if town is TileMap:
			if town.ownership == 0: #player ownership
				if town.owned_tiles.has(tile_pos):
					var town_buildings = town.buildings
					var valid_barracks_locs = []
					for building in town_buildings:
						if building.Type == Global.B_BARRACKS or building.Type == Global.B_BARRACKS_T2 or building.Type == Global.B_ELEPHANT_PEN:
							valid_barracks_locs.append(building.Position)
					if valid_barracks_locs.has(location):
						return true
	return false

func get_building_data(location):
	var towns = get_parent().get_node("Towns")
	for town in towns.get_children():
		if town is TileMap:
			if town.ownership == 0:
				for building in town.buildings:
					if building.Position == location:
						return building
	return {}


func test_movement(pos):
	var movement_data = {
		"Cost": 0,
		"Distance": 0,
		"CanMove": true
	}
	if mode == PLAYER_ACTION.MOVE:
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
			var current_cell = floor_map.get_cell(current_pos.x,current_pos.y)
			if current_cell != Global.T_WATER:
				cost += 1
			else:
				cost += 2
			movement_map.set_cell(current_pos.x,current_pos.y,0)
		if floor_map.get_cell(goal_pos.x,goal_pos.y) == Global.T_WATER:
			movement_data.CanMove = false
		movement_data.Cost = cost
		movement_data.Distance = distance
		return movement_data
		
func _on_mouse_click(pos):
	var pos_match = (pos == tile_pos)
	if pos_match and Global.display_type == Global.display.NONE:
		selected = true
		Global.display_type = Global.display.PLAYER
		mode = PLAYER_ACTION.MOVE
		$SpritePreview.visible = true
	if Global.mouse_pos_viewport.y < 256 and Global.display_type == Global.display.PLAYER:
		if !pos_match:
			if mode == PLAYER_ACTION.BUILD:
				build_selected = -1
				mode = PLAYER_ACTION.MOVE
			else:
				selected = false
				Global.display_type = Global.display.NONE

func _on_ReinforceButton_pressed():
	if mode == PLAYER_ACTION.MOVE:
		mode = PLAYER_ACTION.REINFORCE_CHOOSE
	else:
		mode = PLAYER_ACTION.MOVE


func _on_RemoveButton_pressed():
	mode = PLAYER_ACTION.REMOVE


func _on_BuildButton_pressed():
	mode = PLAYER_ACTION.BUILD

func _on_BuildMenuAction_pressed(type):
	mode = PLAYER_ACTION.BUILD
	if build_selected == type:
		build_selected = -1
		mode = PLAYER_ACTION.MOVE
	else:
		build_selected = type


func _on_BuildBackButton_pressed():
	mode = PLAYER_ACTION.MOVE
	build_selected = -1
	selected = true
	$UI/Panel.visible = selected

func _on_end_turn(player):
	if player == 0:
		ap = max_ap


func _on_ReinforceBackButton_pressed():
	mode = PLAYER_ACTION.MOVE
	selected_military_source = -1
	selected = true
	Global.display_type = Global.display.PLAYER
	$UI/Panel.visible = selected

func _on_FootmanDeposit_pressed():
	var barracksinfo = get_building_data(selected_military_source)
	if footmen > 0:
		footmen -= 1
		barracksinfo.Holding[0] += 1


func _on_FootmanWithdraw_pressed():
	var barracksinfo = get_building_data(selected_military_source)
	if footmen + archers + cavalry + elephants < max_army and barracksinfo.Holding[0] > 0:
		footmen += 1
		barracksinfo.Holding[0] -= 1


func _on_ArcherDeposit_pressed():
	var barracksinfo = get_building_data(selected_military_source)
	if archers > 0:
		archers -= 1
		barracksinfo.Holding[1] += 1


func _on_ArcherWithdraw_pressed():
	var barracksinfo = get_building_data(selected_military_source)
	if footmen + archers + cavalry + elephants < max_army and barracksinfo.Holding[1] > 0:
		archers += 1
		barracksinfo.Holding[1] -= 1

func _on_CavalryDeposit_pressed():
	var barracksinfo = get_building_data(selected_military_source)
	if cavalry > 0:
		cavalry -= 1
		barracksinfo.Holding[2] += 1


func _on_CavalryWithdraw_pressed():
	var barracksinfo = get_building_data(selected_military_source)
	if footmen + archers + cavalry + elephants < max_army and barracksinfo.Holding[2] > 0:
		cavalry += 1
		barracksinfo.Holding[2] -= 1

func _on_DestroyButton_pressed():
	build_selected = -99


func _on_ElephantDeposit_pressed():
	var barracksinfo = get_building_data(selected_military_source)
	if elephants > 0:
		elephants -= 1
		barracksinfo.Holding[0] += 1


func _on_ElephantWithdraw_pressed():
	var barracksinfo = get_building_data(selected_military_source)
	if footmen + archers + cavalry + elephants < max_army and barracksinfo.Holding[0] > 0:
		elephants += 1
		barracksinfo.Holding[0] -= 1


func _on_ReinforceWait_timeout():
	if check_valid_barracks(tile_pos):
		selected_military_source = tile_pos
		mode = PLAYER_ACTION.REINFORCE
		$ReinforceWait.stop()


func _on_Player_area_entered(area):
	if area.name == "Enemy" and !Global.in_combat:
		Global.in_combat = true
		Global.combattants = [self, area.get_parent()]
		var new_combat = combat_scene.instance()
		new_combat.playerside = [footmen,archers,cavalry,elephants]
		new_combat.enemyside = [area.get_parent().footmen,area.get_parent().archers,area.get_parent().cavalry,area.get_parent().elephants]
		selected = false
		mode = PLAYER_ACTION.MOVE
		get_parent().add_child(new_combat)
	if area.name == "Town" and area.get_parent().ownership != 0 and !Global.in_combat:
		Global.in_combat = true
		Global.combattants = [self, area.get_parent()]
		var new_combat = combat_scene.instance()
		new_combat.playerside = [footmen,archers,cavalry,elephants]
		new_combat.enemyside = [floor(area.get_parent().pop_limit/2),0,0,0]
		selected = false
		mode = PLAYER_ACTION.MOVE
		get_parent().add_child(new_combat)
