extends TileMap

class_name Town

#a change
var bound_hex = preload("res://game/MainGame/ControlHex/Hexagon.tscn")

export var town_name := "Town"
var owned_tiles = []
export(int,0,100) var base_support := 20
var tile_pos = Vector2(0,0)
var pop_limit = 0
var population = 0
var food_limit = 0
var food = 0
var support_limit = 0
var support = 0
export(int,"Player","Enemy") var ownership = 0 
export var fortified = false
var buildings = []
var selected_tile = -1
var selected_building_data = {}
export var color = Color(1,1,1,1)
var border_color = Color(1,1,1,1)

onready var floor_map = get_parent().get_parent().get_node("FloorMap")
onready var building_map = get_parent().get_parent().get_node("BuildingMap")

func _ready():
	tile_pos = floor_map.world_to_map(position)
	generate_owned_tiles()
	match ownership:
		0:
			border_color = Color.lightblue
		1:
			border_color = Color(0.8,0,0)
	if fortified:
		$Sprite.texture = load("res://gfx/building_town_center_1.png")
	$Name.text = town_name
	if !Array(owned_tiles).has(building_map.world_to_map(position)):
		owned_tiles.append(building_map.world_to_map(position))
	building_map.set_cell(tile_pos.x,tile_pos.y,Global.B_OCCUPIED_X)
	support = base_support
	for tile in owned_tiles:
		init_building(tile)
	calculate_pop_limit()
	calculate_food_limit()
	calculate_support_limit()
	display_info()
	create_boundaries()
	Global.connect("end_turn",self,"_on_end_turn")
	Global.connect("mouse_click_world",self,"_on_mouse_click")

func _process(delta):
	if selected_tile is Vector2:
		var building_at_tile
		for building in buildings:
			if building.Position == selected_tile:
				building_at_tile = building
				selected_building_data = building
				break
		display_gui(building_at_tile)

func generate_owned_tiles():
	for cell in get_used_cells():
		owned_tiles.append(cell+tile_pos)
		set_cell(cell.x,cell.y,-1)
#	if !owned_tiles.has(tile_pos):
#		owned_tiles.append(tile_pos)

func create_boundaries():
	var owned_tiles_array = Array(owned_tiles)
#	var arr = []
#	for i in 13:
#		var vec = Vector2(int(rand_range(-4,4)),int(rand_range(-4,4)))
#		arr.append(vec)
#	var owned_tiles_array = Array(owned_tiles)
	for tile in owned_tiles_array:
		var bounds = [true,true,true,true,true,true]
		match int(abs(tile.y)) % 2:
			0: #even case
				if owned_tiles_array.has(Vector2(tile.x,tile.y-1)):
					bounds[0] = false
				if owned_tiles_array.has(Vector2(tile.x,tile.y+1)):
					bounds[2] = false
				if owned_tiles_array.has(Vector2(tile.x-1,tile.y+1)):
					bounds[3] = false
				if owned_tiles_array.has(Vector2(tile.x-1,tile.y-1)):
					bounds[5] = false
			1: #odd case
				if owned_tiles_array.has(Vector2(tile.x+1,tile.y-1)):
					bounds[0] = false
				if owned_tiles_array.has(Vector2(tile.x+1,tile.y+1)):
					bounds[2] = false
				if owned_tiles_array.has(Vector2(tile.x,tile.y+1)):
					bounds[3] = false
				if owned_tiles_array.has(Vector2(tile.x,tile.y-1)):
					bounds[5] = false
		#always do these two checks, regardless of case
		if owned_tiles_array.has(Vector2(tile.x+1,tile.y)):
			bounds[1] = false
		if owned_tiles_array.has(Vector2(tile.x-1,tile.y)):
			bounds[4] = false
		#create the hexagon instance
		var bound_hex_inst = bound_hex.instance()
		bound_hex_inst.position = floor_map.map_to_world(tile)
		bound_hex_inst.sides = bounds
		bound_hex_inst.modulate = border_color
		get_parent().call_deferred("add_child",bound_hex_inst)

func _on_end_turn(player):
	if player == ownership:
		tick_tiles()
	if ownership == 0:
		support += 5
	calculate_pop_limit()
	calculate_food_limit()
	calculate_support_limit()
	display_info()

func tick_tiles():
	for building in buildings:
		# go through every building, and process based on its building.Type
		match building.Type:
			Global.B_RICE_PADDY: 
				building.Progress += 1
				if building.Progress == 4:
					building.Progress = 0
					food += 5
			Global.B_FISHING_BOAT:
				food += 1
			Global.B_HOUSING, Global.B_HOUSING_T2: 
				building.Progress += 1
				if building.Progress == 2:
					building.Progress = 0
					population += 1
			Global.B_BARRACKS:
				if building.InProduction != []:
					building.InProduction[0][1] += 1
					if building.InProduction[0][1] >= building.InProduction[0][2]:
						building.Holding[building.InProduction[0][0]] += 1
						building.InProduction.remove(0)
			Global.B_BARRACKS_T2:
				if building.InProduction != []:
					building.InProduction[0][1] += 2
					if building.InProduction[0][1] >= building.InProduction[0][2]:
						building.Holding[building.InProduction[0][0]] += 1
						building.InProduction.remove(0)
			Global.B_ELEPHANT_PEN:
				if building.InProduction != []:
					building.InProduction[0][1] += 1
					if building.InProduction[0][1] >= building.InProduction[0][2]:
						building.Holding[building.InProduction[0][0]] += 1
						building.InProduction.remove(0)
			Global.B_TEMPLE, Global.B_MONUMENT, Global.B_SCHOOL:
				support += 5
	pass

func init_building(pos):
	var building_data = {}
	match building_map.get_cell(pos.x,pos.y):
		Global.B_RICE_PADDY:
			building_data = Global.rice_paddy.duplicate(true)
		Global.B_FISHING_BOAT:
			building_data = Global.fishing_boat.duplicate(true)
		Global.B_HOUSING:
			building_data = Global.housing.duplicate(true)
		Global.B_BARRACKS:
			building_data = Global.barracks.duplicate(true)
		Global.B_ELEPHANT_PEN:
			building_data = Global.elephant_pen.duplicate(true)
		Global.B_STOREHOUSE: 
			building_data = Global.storehouse.duplicate(true)
		Global.B_TEMPLE:
			building_data = Global.temple.duplicate(true)
		Global.B_MONUMENT:
			building_data = Global.monument.duplicate(true)
		Global.B_SCHOOL:
			building_data = Global.school.duplicate(true)
	if building_data.has("Position"):
		building_data.Position = pos
	if building_data.hash() != {}.hash():
		buildings.append(building_data)
func calculate_pop_limit():
	# go through each owned tile and determine its benefits to the population limit.
	pop_limit = 0
	for tile in owned_tiles:
		var this_tile_pop = 0
		var current_tile = floor_map.get_cell(tile.x,tile.y)
		match current_tile:
			Global.T_GRASS:
				this_tile_pop += 1
		var current_building = building_map.get_cell(tile.x,tile.y)
		match current_building:
			Global.B_HOUSING:
				this_tile_pop += 4
			Global.B_HOUSING_T2:
				this_tile_pop += 8
				
		pop_limit += this_tile_pop
	population = clamp(population,0,pop_limit)

func calculate_food_limit():
	# go through each owned tile and determine its benefits to the food limit.
	food_limit = 60
	for tile in owned_tiles:
		var this_tile_food = 0
		var current_building = building_map.get_cell(tile.x,tile.y)
		match current_building:
			Global.B_STOREHOUSE:
				this_tile_food += 30
			Global.B_STOREHOUSE_T2:
				this_tile_food += 60
			Global.B_HOUSING:
				this_tile_food += 5
		food_limit += this_tile_food
	food = clamp(food,0,food_limit)
	
func calculate_support_limit():
	# go through each owned tile and determine its benefits to the support limit.
	support_limit = 100
	for tile in owned_tiles:
		var this_tile_support = 0
		var current_building = building_map.get_cell(tile.x,tile.y)
		match current_building:
			Global.B_MONUMENT:
				this_tile_support += 10
			Global.B_TEMPLE:
				this_tile_support += 25
			Global.B_SCHOOL:
				this_tile_support += 50
		support_limit += this_tile_support
	support = clamp(support,0,support_limit)

func display_info():
	print("Town Name: "+town_name)
	print("Support: "+String(support)+"/"+String(support_limit))
	print("Population: "+String(population)+"/"+String(pop_limit))
	print("Food: "+String(food)+"/"+String(food_limit))
	$PopulationNumber.text = String(population)+"/"+String(pop_limit)
	$FoodNumber.text = String(food)+"/"+String(food_limit)
	$SupportNumber.text = String(support)+"/"+String(support_limit)
	
func display_gui(building: Dictionary):
	match building.Type:
		Global.B_BARRACKS, Global.B_BARRACKS_T2:
			$UI/BarracksPanel.visible = true
			Global.display_type = Global.display.POPUP
			$UI/BarracksPanel/FootmenButton.disabled = !(population >= 1 and building.InProduction.size() < 6)
			$UI/BarracksPanel/ArchersButton.disabled = !(population >= 1 and building.InProduction.size() < 6)
			$UI/BarracksPanel/CavalryButton.disabled = !(population >= 2 and building.InProduction.size() < 6)
			$UI/BarracksPanel/RemoveButton.disabled = !(building.InProduction.size() > 0)
			$UI/BarracksPanel/UpgradeButton.disabled = !(building.Type == Global.B_BARRACKS and population >= 10 and support >= 75)
			$UI/BarracksPanel/BarracksPanel2/InProgress.text = ""
			match building.Type:
				Global.B_BARRACKS:
					$UI/BarracksPanel/Name.text = "Barracks"
					$UI/BarracksPanel/Sprite.visible = true
					$UI/BarracksPanel/SpriteT2.visible = false
				Global.B_BARRACKS_T2:
					$UI/BarracksPanel/Name.text = "Barracks Tier 2"
					$UI/BarracksPanel/UpgradeButton.hint_tooltip = "This building is already at Tier 2."
					$UI/BarracksPanel/Sprite.visible = false
					$UI/BarracksPanel/SpriteT2.visible = true
			for unit in building.InProduction:
				match unit[0]:
					0:
						$UI/BarracksPanel/BarracksPanel2/InProgress.text += "Footmen "
					1:
						$UI/BarracksPanel/BarracksPanel2/InProgress.text += "Archers "
					2:
						$UI/BarracksPanel/BarracksPanel2/InProgress.text += "Cavalry "
			if building.InProduction.size() > 0:
				var currentunit = building.InProduction[0]
				$UI/BarracksPanel/BarracksPanel2/ProgressBar.value = float(currentunit[1])/float(currentunit[2])
			else:
				$UI/BarracksPanel/BarracksPanel2/ProgressBar.value = 0
			$UI/BarracksPanel/Reserves.text = "Reserves:\nFootmen: "+String(building.Holding[0])+"\nArchers: "+String(building.Holding[1])+"\nCavalry: "+String(building.Holding[2])
			$UI/BarracksPanel/Population.text = "Local Population: "+String(population)+"/"+String(pop_limit)+"\nLocal Food: "+String(food)+"/"+String(food_limit)
		Global.B_ELEPHANT_PEN:
			$UI/ElephantPenPanel.visible = true
			Global.display_type = Global.display.POPUP
			$UI/ElephantPenPanel/ElephantButton.disabled = !(population >= 10 and food >= 20 and building.InProduction.size() < 3)
			$UI/ElephantPenPanel/RemoveButton.disabled = !(building.InProduction.size() > 0)
			$UI/ElephantPenPanel/ElephantPenPanel/InProgress.text = ""
			for unit in building.InProduction:
				$UI/ElephantPenPanel/ElephantPenPanel/InProgress.text += "War Elephant "
			if building.InProduction.size() > 0:
				var currentunit = building.InProduction[0]
				$UI/ElephantPenPanel/ElephantPenPanel/ProgressBar.value = float(currentunit[1])/float(currentunit[2])
			else:
				$UI/ElephantPenPanel/ElephantPenPanel/ProgressBar.value = 0
			$UI/ElephantPenPanel/Reserves.text = "Reserves:\nWar Elephants: "+String(building.Holding[0])
			$UI/ElephantPenPanel/Population.text = "Local Population: "+String(population)+"/"+String(pop_limit)+"\nLocal Food: "+String(food)+"/"+String(food_limit)
		Global.B_HOUSING, Global.B_HOUSING_T2:
			$UI/HousingPanel.visible = true
			Global.display_type = Global.display.POPUP
			$UI/HousingPanel/UpgradeButton.disabled = !(population >= 10 and support >= 75 and building.Type == Global.B_HOUSING)
			match building.Type:
				Global.B_HOUSING:
					$UI/HousingPanel/Name.text = "Housing"
					$UI/HousingPanel/Sprite.visible = true
					$UI/HousingPanel/SpriteT2.visible = false
				Global.B_HOUSING_T2:
					$UI/HousingPanel/Sprite.visible = false
					$UI/HousingPanel/SpriteT2.visible = true
					$UI/HousingPanel/Name.text = "Housing Tier 2"
					$UI/HousingPanel/UpgradeButton.hint_tooltip = "This building is already at Tier 2."
		Global.B_STOREHOUSE, Global.B_STOREHOUSE_T2:
			$UI/StorehousePanel.visible = true
			Global.display_type = Global.display.POPUP
			$UI/StorehousePanel/UpgradeButton.disabled = !(population >= 10 and support >= 75 and building.Type == Global.B_STOREHOUSE)
			match building.Type:
				Global.B_STOREHOUSE:
					$UI/StorehousePanel/Name.text = "Storehouse"
					$UI/StorehousePanel/Sprite.visible = true
					$UI/StorehousePanel/SpriteT2.visible = false
				Global.B_STOREHOUSE_T2:
					$UI/StorehousePanel/Sprite.visible = false
					$UI/StorehousePanel/SpriteT2.visible = true
					$UI/StorehousePanel/Name.text = "Storehouse Tier 2"
					$UI/StorehousePanel/UpgradeButton.hint_tooltip = "This building is already at Tier 2."
		Global.B_MONUMENT, Global.B_TEMPLE, Global.B_SCHOOL:
			$UI/MonumentPanel.visible = true
			Global.display_type = Global.display.POPUP
			$UI/MonumentPanel/UpgradeButton.disabled = !(population >= 10 and support >= 75 and (building.Type == Global.B_MONUMENT or building.Type == Global.B_TEMPLE))
			match building.Type:
				Global.B_MONUMENT:
					$UI/MonumentPanel/Name.text = "Monument"
					$UI/MonumentPanel/Sprite.visible = true
					$UI/MonumentPanel/SpriteT2.visible = false
					$UI/MonumentPanel/SpriteT3.visible = false
					$UI/MonumentPanel/UpgradeButton.hint_tooltip = "Upgrade this building to a Temple.\nTemples can hold up to 25 influence instead of 10.\nUpgrading this will cost 10 population and 75 influence."
				Global.B_TEMPLE:
					$UI/MonumentPanel/Name.text = "Temple"
					$UI/MonumentPanel/Sprite.visible = false
					$UI/MonumentPanel/SpriteT2.visible = true
					$UI/MonumentPanel/SpriteT3.visible = false
					$UI/MonumentPanel/UpgradeButton.hint_tooltip = "Upgrade this building to a School.\nTemples can hold up to 50 influence instead of 10.\nUpgrading this will cost 10 population and 75 influence."
				Global.B_SCHOOL:
					$UI/MonumentPanel/Name.text = "School"
					$UI/MonumentPanel/Sprite.visible = false
					$UI/MonumentPanel/SpriteT2.visible = false
					$UI/MonumentPanel/SpriteT3.visible = true
					$UI/MonumentPanel/UpgradeButton.hint_tooltip = "This building is at its highest tier."
func _on_mouse_click(pos):
	if Global.display_type == Global.display.NONE:
		var selected_building = {}
		if Array(owned_tiles).has(pos):
			for building in buildings:
				if building.Position == pos:
					Global.selected_tile = pos
					selected_building = building
					print(Global.selected_tile)
					break
		if selected_building.has("Type"):
			match selected_building.Type:
				Global.B_BARRACKS, Global.B_BARRACKS_T2, Global.B_ELEPHANT_PEN, Global.B_HOUSING, Global.B_HOUSING_T2, Global.B_STOREHOUSE, Global.B_STOREHOUSE_T2, Global.B_MONUMENT, Global.B_TEMPLE, Global.B_SCHOOL:
					selected_tile = selected_building.Position

func _on_BarracksExitButton_pressed():
	selected_tile = -1
	selected_building_data = {}
	$UI/BarracksPanel.visible = false
	Global.display_type = Global.display.NONE

func _on_BarracksRemoveButton_pressed():
	if selected_building_data.InProduction.size() > 0:
		selected_building_data.InProduction.remove(0)

func _on_BarracksFootmenButton_pressed():
	if selected_building_data.InProduction.size() < 6:
		selected_building_data.InProduction.append([0,0,2])

func _on_BarracksArchersButton_pressed():
	if selected_building_data.InProduction.size() < 6:
		selected_building_data.InProduction.append([1,0,2])

func _on_BarracksCavalryButton_pressed():
	if selected_building_data.InProduction.size() < 6:
		selected_building_data.InProduction.append([2,0,3])

func _on_BarracksUpgradeButton_pressed():
	selected_building_data.Type = Global.B_BARRACKS_T2
	building_map.set_cell(selected_building_data.Position.x,selected_building_data.Position.y,Global.B_BARRACKS_T2)
	population -= 10
	support -= 75

func _on_ElephantPenRemoveButton_pressed():
	if selected_building_data.InProduction.size() > 0:
		selected_building_data.InProduction.remove(0)

func _on_ElephantPenElephantButton_pressed():
	if selected_building_data.InProduction.size() < 3:
		selected_building_data.InProduction.append([0,0,10])

func _on_ElephantPenExitButton_pressed():
	selected_tile = -1
	selected_building_data = {}
	$UI/ElephantPenPanel.visible = false
	Global.display_type = Global.display.NONE


func _on_HousingExitButton_pressed():
	selected_tile = -1
	selected_building_data = {}
	$UI/HousingPanel.visible = false
	Global.display_type = Global.display.NONE

func _on_HousingUpgradeButton_pressed():
	selected_building_data.Type = Global.B_HOUSING_T2
	building_map.set_cell(selected_building_data.Position.x,selected_building_data.Position.y,Global.B_HOUSING_T2)
	population -= 10
	support -= 75


func _on_StorehouseExitButton_pressed():
	selected_tile = -1
	selected_building_data = {}
	$UI/StorehousePanel.visible = false
	Global.display_type = Global.display.NONE

func _on_StorehouseUpgradeButton_pressed():
	selected_building_data.Type = Global.B_STOREHOUSE_T2
	building_map.set_cell(selected_building_data.Position.x,selected_building_data.Position.y,Global.B_STOREHOUSE_T2)
	population -= 10
	support -= 75


func _on_MonumentExitButton_pressed():
	selected_tile = -1
	selected_building_data = {}
	$UI/MonumentPanel.visible = false
	Global.display_type = Global.display.NONE


func _on_MonumentUpgradeButton_pressed():
	match selected_building_data.Type:
		Global.B_MONUMENT:
			selected_building_data.Type = Global.B_TEMPLE
			building_map.set_cell(selected_building_data.Position.x,selected_building_data.Position.y,Global.B_TEMPLE)
		Global.B_TEMPLE:
			selected_building_data.Type = Global.B_SCHOOL
			building_map.set_cell(selected_building_data.Position.x,selected_building_data.Position.y,Global.B_SCHOOL)
	population -= 10
	support -= 75
