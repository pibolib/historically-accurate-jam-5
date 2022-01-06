extends TileMap

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
var current_mouse_tile = -1
var selected_tile = -1

enum {
	T_GRASS, T_SAND, T_WATER, T_DIRT, T_ROCK
} # tile types, building types, special tiles
enum {
	B_RICE_PADDY_L1, B_OCCUPIED_X, B_FISHING_BOAT, B_HOUSING, B_BARRACKS, B_GUARD_TOWER,
	B_ELEPHANT_PEN, B_STOREHOUSE, B_TEMPLE, B_MONUMENT, B_SCHOOL
}

var rice_paddy_l1 = {
	"Type": B_RICE_PADDY_L1,
	"Position": Vector2(0,0),
	"Name": "Rice Paddy (Tier 1)",
	"Description": "A place where rice is cultivated. Produces 5 food every 4 turns.",
	"Progress": 0 # out of 4
}

var fishing_boat = {
	"Type": B_FISHING_BOAT,
	"Position": Vector2(0,0),
	"Name": "Fishing Boat",
	"Description": "A setup for fishing in the nearby waters. Produces 1 food per turn.",
}

var housing = {
	"Type": B_HOUSING,
	"Position": Vector2(0,0),
	"Name": "Housing",
	"Description": "General Housing. Increases maximum population by 4, produces 1 population every 2 turns.",
	"Progress": 0 #out of 2
}

var barracks = {
	"Type": B_BARRACKS,
	"Position": Vector2(0,0),
	"Name": "Barracks (Tier 1)",
	"Description": "Training facilities for military troops. Allows for the production of footmen, archers, and cavalry.",
	"InProduction": [],
	"Holding": []
}

var guard_tower = {
	"Type": B_GUARD_TOWER,
	"Position": Vector2(0,0),
	"Name": "Guard Tower",
	"Description": "Tower from which a large stretch of land can be seen. Houses military forces not in active use.",
	"Holding": []
}

var elephant_pen = {
	"Type": B_ELEPHANT_PEN,
	"Position": Vector2(0,0),
	"Name": "Elephant Pen",
	"Description": "Facilities used to raise elephants for use in war. Allows for production of War Elephants.",
	"InProduction": [],
	"Holding": []
}

var storehouse = {
	"Type": B_STOREHOUSE,
	"Position": Vector2(0,0),
	"Name": "Storehouse",
	"Description": "Stores food for long periods of time. Increases maximum food by 30.",
}

var temple = {
	"Type": B_TEMPLE,
	"Position": Vector2(0,0),
	"Name": "Temple",
	"Description": "A small temple. Increases the maximum local influence by 20, increases influence per turn by 5.",
}

var monument = {
	"Type": B_MONUMENT,
	"Position": Vector2(0,0),
	"Name": "Monument",
	"Description": "A small monument. Increases the maximum local influence by 40, increases influence per turn by 5.",
}

var school = {
	"Type": B_SCHOOL,
	"Position": Vector2(0,0),
	"Name": "School",
	"Description": "A school. Increases the maximum local influence by 75, increases influence per turn by 5.",
}

func _ready():
	var floor_map = get_parent().get_node("FloorMap")
	var building_map = get_parent().get_node("BuildingMap")
	tile_pos = floor_map.world_to_map(position)
	generate_owned_tiles()
	if fortified:
		$Sprite.texture = load("res://gfx/building_town_center_1.png")
	$Name.text = town_name
	if !Array(owned_tiles).has(building_map.world_to_map(position)):
		owned_tiles.append(building_map.world_to_map(position))
	building_map.set_cell(tile_pos.x,tile_pos.y,B_OCCUPIED_X)
	support = base_support
	for tile in owned_tiles:
		init_building(tile)
	calculate_pop_limit()
	display_info()
	create_boundaries()
	Global.connect("end_turn",self,"_on_end_turn")
	Global.connect("mouse_click_world",self,"_on_mouse_click")

func generate_owned_tiles():
	for cell in get_used_cells():
		owned_tiles.append(cell+tile_pos)
		set_cell(cell.x,cell.y,-1)
#	if !owned_tiles.has(tile_pos):
#		owned_tiles.append(tile_pos)

func create_boundaries():
	var floor_map = get_parent().get_node("FloorMap")
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
		get_parent().call_deferred("add_child",bound_hex_inst)

func _on_end_turn(player):
	if player == ownership:
		tick_tiles()
	calculate_pop_limit()
	calculate_food_limit()
	calculate_support_limit()
	display_info()

func tick_tiles():
	for building in buildings:
		# go through every building, and process based on its building.Type
		match building.Type:
			B_RICE_PADDY_L1: 
				building.Progress += 1
				if building.Progress == 4:
					building.Progress = 0
					food += 5
			B_FISHING_BOAT:
				food += 1
			B_HOUSING: 
				building.Progress += 1
				if building.Progress == 2:
					building.Progress = 0
					population += 1
			B_BARRACKS:
				if building.InProduction != []:
					building.InProduction[0][1] += 1
					if building.InProduction[0][1] >= building.InProduction[0][2]:
						building.Holding.append(building.InProduction[0][0])
						building.InProduction.remove(0)
			B_ELEPHANT_PEN:
				if building.InProduction != []:
					building.InProduction[0][1] += 1
					if building.InProduction[0][1] >= building.InProduction[0][2]:
						building.Holding.append(building.InProduction[0][0])
						building.InProduction.remove(0)
			B_TEMPLE, B_MONUMENT, B_SCHOOL:
				support += 5
	pass

func init_building(pos):
	var building_map = get_parent().get_node("BuildingMap")
	var building_data = {}
	match building_map.get_cell(pos.x,pos.y):
		B_RICE_PADDY_L1:
			building_data = rice_paddy_l1.duplicate()
		B_FISHING_BOAT:
			building_data = fishing_boat.duplicate()
		B_HOUSING:
			building_data = housing.duplicate()
		B_BARRACKS:
			building_data = barracks.duplicate()
		B_GUARD_TOWER:
			building_data = guard_tower.duplicate()
		B_ELEPHANT_PEN:
			building_data = elephant_pen.duplicate()
		B_STOREHOUSE: 
			building_data = storehouse.duplicate()
		B_TEMPLE:
			building_data = temple.duplicate()
		B_MONUMENT:
			building_data = monument.duplicate()
		B_SCHOOL:
			building_data = school.duplicate()
	if building_data.has("Position"):
		building_data.Position = pos
	if building_data.hash() != {}.hash():
		buildings.append(building_data)
func calculate_pop_limit():
	# go through each owned tile and determine its benefits to the population limit.
	pop_limit = 0
	var floor_map = get_parent().get_node("FloorMap")
	var building_map = get_parent().get_node("BuildingMap")
	for tile in owned_tiles:
		var this_tile_pop = 0
		var current_tile = floor_map.get_cell(tile.x,tile.y)
		match current_tile:
			T_GRASS:
				this_tile_pop += 1
		var current_building = building_map.get_cell(tile.x,tile.y)
		match current_building:
			B_HOUSING:
				this_tile_pop += 4
				
		pop_limit += this_tile_pop
	population = clamp(population,0,pop_limit)

func calculate_food_limit():
	# go through each owned tile and determine its benefits to the food limit.
	food_limit = 60
	var building_map = get_parent().get_node("BuildingMap")
	for tile in owned_tiles:
		var this_tile_food = 0
		var current_building = building_map.get_cell(tile.x,tile.y)
		match current_building:
			B_STOREHOUSE:
				this_tile_food += 30
				
		food_limit += this_tile_food
	food = clamp(food,0,food_limit)
	
func calculate_support_limit():
	# go through each owned tile and determine its benefits to the support limit.
	support_limit = 25
	var building_map = get_parent().get_node("BuildingMap")
	for tile in owned_tiles:
		var this_tile_support = 0
		var current_building = building_map.get_cell(tile.x,tile.y)
		match current_building:
			B_TEMPLE:
				this_tile_support += 20
			B_MONUMENT:
				this_tile_support += 40
			B_SCHOOL:
				this_tile_support += 75
		support_limit += this_tile_support
	support = clamp(support,0,support_limit)

func display_info():
	print("Town Name: "+town_name)
	print("Support: "+String(support)+"/"+String(support_limit))
	print("Population: "+String(population)+"/"+String(pop_limit))
	print("Food: "+String(food)+"/"+String(food_limit))

func _on_mouse_click(pos):
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
			B_BARRACKS:
				selected_building.InProduction.append([0,0,4])
				print(selected_building.InProduction)
		
