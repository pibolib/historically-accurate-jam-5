extends Node2D


var playerside = [0,0,0,0]
var enemyside = [0,0,0,0]
var playermorale = 1
var enemymorale = 1
var player = -1
var enemy = -1

enum {
	U_FOOTMAN, U_ARCHER, U_CAVALRY, U_ELEPHANT
}

var footman = {
	"VersusFootman": [0.3,0.4,0.3],
	"VersusArcher":  [0.6,0.2,0.2],
	"VersusCavalry": [0.3,0.2,0.5],
	"VersusElephant":[0.1,0.1,0.8]
}
var archer = {
	"VersusFootman": [0.5,0.5,0.0],
	"VersusArcher":  [0.3,0.4,0.3],
	"VersusCavalry": [0.2,0.8,0.0],
	"VersusElephant":[0.1,0.9,0.0]
}
var cavalry = {
	"VersusFootman": [0.5,0.3,0.2],
	"VersusArcher":  [0.7,0.2,0.1],
	"VersusCavalry": [0.4,0.3,0.3],
	"VersusElephant":[0.2,0.3,0.5]
}
var elephant = {
	"VersusFootman": [0.8,0.1,0.1],
	"VersusArcher":  [0.8,0.1,0.1],
	"VersusCavalry": [0.6,0.2,0.2],
	"VersusElephant":[0.5,0.0,0.5]
}
var battle_round = 1
var recent_results_player = "None"
var recent_results_enemy = "None"

func _ready():
	pass

func _process(delta):
	Global.display_type = Global.display.POPUP


func _on_RoundButton_pressed():
	pass # Replace with function body.
