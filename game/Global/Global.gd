extends Node

var turn = 0 #0: player, 1: enemy
signal end_turn(player)
signal mouse_click_world(tilepos)
var selected_tile = -1
var player_is_selected = false

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
	"Holding": [5,10,15]
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

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("end_turn",self,"_on_end_turn")


func _process(delta):
	$Mouse.position = get_viewport().get_mouse_position()
	if Input.is_action_just_pressed("action_endturn") and turn == 0:
		emit_signal("end_turn",0)
	if Input.is_action_just_pressed("action_lc"):
		emit_signal("mouse_click_world",$Base.world_to_map($Mouse.position))
		print("Mouse click at "+String($Base.world_to_map($Mouse.position)))

func _on_end_turn(player):
	print("turn end, player "+String(player))

func get_mouse_pos():
	return $Mouse.position

func get_mouse_tile():
	return $Base.world_to_map($Mouse.position)


func _on_TurnButton_pressed():
	emit_signal("end_turn",0)
