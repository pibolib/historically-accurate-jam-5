extends Node2D

var ingame = false
var turn = 0 #0: player, 1: enemy
var zoom_value = 1
var zoom_text_invis_threshold = 2
var mouse_pos_viewport = Vector2(0,0)
var combattants = []
signal end_turn(player)
signal mouse_click_world(tilepos)
signal update_borders()
signal focus_trac()
signal focus_nhi()
var selected_tile = -1
var in_combat = false
enum display {
	NONE, 
	PLAYER, 
	POPUP,
	SMALL_BUTTON
}
var display_type = display.NONE

enum {
	T_GRASS = 0, 
	T_SAND = 1, 
	T_WATER = 10, 
	T_DIRT = 2, 
	T_ROCK = 4,
	T_GRAVEL = 5,
	T_DARK_GRASS = 7
} # tile types, building types, special tiles
enum {
	B_RICE_PADDY = 0, 
	B_OCCUPIED_X = 1, 
	B_FISHING_BOAT = 2, 
	B_HOUSING = 3, 
	B_BARRACKS = 4, 
	B_ENV_FOREST1 = 5,
	B_ENV_FOREST2 = 6,
	B_BARRACKS_T2 = 7,
	B_HOUSING_T2 = 8,
	B_ELEPHANT_PEN = 9, 
	B_STOREHOUSE = 10
	B_STOREHOUSE_T2 = 11, 
	B_MONUMENT = 12, 
	B_TEMPLE = 13, 
	B_SCHOOL = 14,
	B_NULL = 999
}

var player_positions = [
	
]

var rice_paddy = {
	"Type": B_RICE_PADDY,
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
	"Holding": [0,0,0]
}

var guard_tower = {
	"Type": B_NULL,
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
	"Holding": [0]
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
	if ingame:
		$UI/TurnButton.visible = !(display_type == display.POPUP)
		$UI/EndTurn.visible = !(display_type == display.POPUP)
		$UI/NhiButton.visible = (display_type == display.NONE)
		$UI/TracButton.visible = (display_type == display.NONE)
		player_positions = []
		mouse_pos_viewport = get_viewport().get_mouse_position()
		$Mouse.position = get_global_mouse_position()
		if Input.is_action_just_pressed("action_endturn") and turn == 0:
			emit_signal("end_turn",turn)
			turn = 1
		if Input.is_action_just_pressed("action_lc"):
			emit_signal("mouse_click_world",$Base.world_to_map($Mouse.position))
		$UI/Label.text = String(display_type)
		$UI/TurnButton.disabled = !$EnemyTurnWait.is_stopped()
	else:
		$UI/EndTurn.visible = false
		$UI/Label.visible = false
		$UI/TurnButton.visible = false
		$UI/NhiButton.visible = false
		$UI/TracButton.visible = false

func _on_end_turn(player):
	print("turn end, player "+String(player))

func get_mouse_pos():
	return $Mouse.position

func get_mouse_tile():
	return $Base.world_to_map($Mouse.position)


func _on_TurnButton_pressed():
	if turn == 0:
		emit_signal("end_turn",0)
		turn = 1
		$EnemyTurnWait.start(0.5)

func _on_Timer_timeout():
	emit_signal("end_turn",1)
	turn = 0
	$EnemyTurnWait.stop()


func _on_TracButton_pressed():
	emit_signal("focus_trac")


func _on_NhiButton_pressed():
	emit_signal("focus_nhi")
