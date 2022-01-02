extends Node2D

var bound_hex = preload("res://game/MainGame/ControlHex/Hexagon.tscn")

export var town_name := "Town"
export var owned_tiles = PoolVector2Array([Vector2(0,0)])
export(float,0,1,0.01) var base_support := 0.20
export(float,0,1,0.01) var footman_rate := 0.50
export(float,0,1,0.01) var archer_rate := 0.40
export(float,0,1,0.01) var cavalry_rate := 0.10
var pop_rate = 0
export var tile_pos := Vector2(0,0)
var pop_limit = 0
var army_bandwidth = 0
var garrison_footman = 0
var garrison_archer = 0
var garrison_cavalry = 0
var population = 0
var support = 0
export var fortified = false

enum {
	T_GRASS, T_SAND, T_WATER, T_DIRT, T_ROCK
} # tile types, building types, special tiles
enum {
	B_RICE_PADDY_L1, B_OCCUPIED_X
}


# Called when the node enters the scene tree for the first time.
func _ready():
	if fortified:
		$Sprite.texture = load("res://gfx/building_town_center_1.png")
	$Name.text = town_name
	var building_map = get_parent().get_node("BuildingMap")
	if !Array(owned_tiles).has(building_map.world_to_map(position)):
		owned_tiles.append(building_map.world_to_map(position))
	building_map.set_cell(tile_pos.x,tile_pos.y,B_OCCUPIED_X)
	support = base_support
	calculate_pop_limit()
	calculate_bandwidth()
	display_info()
	create_boundaries()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func create_boundaries():
	var floor_map = get_parent().get_node("FloorMap")
	var owned_tiles_array = Array(owned_tiles)
	for tile in owned_tiles_array:
		var bounds = [true,true,true,true,true,true]
		match int(tile.y) % 2:
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

func end_turn():
	tick_tiles()
	calculate_bandwidth()
	calculate_pop_limit()

func tick_tiles():
	# go through each owned tile, and perform an action based on what building is on that tile.
	# if a building is unfinished, then transition the building to the next phase.
	var floor_map = get_parent().get_node("FloorMap")
	var building_map = get_parent().get_node("BuildingMap")

func init_building(pos):
	pass

func calculate_military_growth():
	pass
	
func calculate_civilian_growth():
	pass

func calculate_bandwidth():
	# go through each owned tile and determine its benefits to the bandwidth.
	# sand tile: +100, grass tile: +200, rice paddy: x10, rice paddy L.2: x20, barracks: x15, barracks L.2: x30
	# bonus/detriment to bandwidth due to support: 2*support*bandwidth (50% -> 100% of available bandwidth, 100% -> 200%)
	army_bandwidth = 0
	var floor_map = get_parent().get_node("FloorMap")
	var building_map = get_parent().get_node("BuildingMap")
	for tile in owned_tiles:
		var this_tile_bandwidth = 0
		
		var current_tile = floor_map.get_cell(tile.x,tile.y)
		match current_tile:
			T_GRASS:
				this_tile_bandwidth = 200
			T_SAND:
				this_tile_bandwidth = 100
			T_WATER:
				this_tile_bandwidth = 5
			T_ROCK:
				this_tile_bandwidth = 0
			T_DIRT:
				this_tile_bandwidth = 50
				
		var current_building = building_map.get_cell(tile.x,tile.y)
		match current_building:
			B_RICE_PADDY_L1:
				this_tile_bandwidth *= 10
				
		army_bandwidth += this_tile_bandwidth
	army_bandwidth = floor(army_bandwidth * support * 2)

func calculate_pop_limit():
	# go through each owned tile and determine its benefits to the bandwidth.
	# sand tile: +25, grass tile: +150, rice paddy: x15, rice paddy L.2: x30
	pop_limit = 0
	var floor_map = get_parent().get_node("FloorMap")
	var building_map = get_parent().get_node("BuildingMap")
	for tile in owned_tiles:
		var this_tile_pop = 0
		
		var current_tile = floor_map.get_cell(tile.x,tile.y)
		match current_tile:
			T_GRASS:
				this_tile_pop = 150
			T_SAND:
				this_tile_pop = 50
			T_WATER:
				this_tile_pop = 5
			T_ROCK:
				this_tile_pop = 10
			T_DIRT:
				this_tile_pop = 75
				
		var current_building = building_map.get_cell(tile.x,tile.y)
		match current_building:
			B_RICE_PADDY_L1:
				this_tile_pop *= 15
				
		pop_limit += this_tile_pop

func display_info():
	print("Town Name: "+town_name)
	print("Support: "+String(support*100)+"%")
	print("Population Limit: "+String(pop_limit))
	print("Army Bandwidth: "+String(army_bandwidth))
