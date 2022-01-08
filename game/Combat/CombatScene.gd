extends Node2D


var playerside = [50,0,0,0]
var enemyside = [0,0,0,5]
var player = -1
var enemy = -1
var turn = 0 # player = 0, enemy = 1
var player_tactic = 0 # offensive = 0, defensive = 1
var battle_state = 0 # normal = 0, player win = 1, player lose = 2
var recent_turn = {
	"PlayerLosses": 0,
	"PlayerSuccess": 0,
	"PlayerNothing": 0,
	"PlayerFail": 0,
	"EnemyLosses": 0,
}

enum {
	U_FOOTMAN, U_ARCHER, U_CAVALRY, U_ELEPHANT
}
enum {
	RESULT_SUCCESS, RESULT_NONE, RESULT_FAILURE
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
var unitdata = [footman, archer, cavalry, elephant]
var battle_round = 1
var recent_results_player = "None"
var recent_results_enemy = "None"

func _ready():
	Global.display_type = Global.display.POPUP

func _process(delta):
	$UI/Panel/Title.text = "Combat! Round "+String(battle_round)
	match player_tactic:
		0:
			$UI/Panel/Tactic.text = "Tactics: Offensive"
		1:
			$UI/Panel/Tactic.text = "Tactics: Defensive"
	$UI/Panel/Ally/FootmenCount.text = String(playerside[0])
	$UI/Panel/Ally/ArcherCount.text = String(playerside[1])
	$UI/Panel/Ally/CavalryCount.text = String(playerside[2])
	$UI/Panel/Ally/ElephantCount.text = String(playerside[3])
	$UI/Panel/Enemy/FootmenCount.text = String(enemyside[0])
	$UI/Panel/Enemy/ArcherCount.text = String(enemyside[1])
	$UI/Panel/Enemy/CavalryCount.text = String(enemyside[2])
	$UI/Panel/Enemy/ElephantCount.text = String(enemyside[3])
func run_turn(team):
	match team:
		0:
			var targettype = -1
			var validtarget = false
			var odds_base = [0,0,0]
			var odds = [0,0,0]
			var result = RESULT_NONE
			for unittype in 4:
				for unit in playerside[unittype]:
					if enemyside[0] <= 0 and enemyside[1] <= 0 and enemyside[2] <= 0 and enemyside[3] <= 0:
						break
					targettype = -1
					validtarget = false
					while !validtarget:
						targettype = randi()%4
						if enemyside[targettype] > 0:
							validtarget = true
					match targettype:
						U_FOOTMAN:
							odds_base = unitdata[unittype].VersusFootman
						U_ARCHER:
							odds_base = unitdata[unittype].VersusArcher
						U_CAVALRY:
							odds_base = unitdata[unittype].VersusCavalry
						U_ELEPHANT:
							odds_base = unitdata[unittype].VersusElephant
					odds = odds_base.duplicate(true)
					if player_tactic == 1:
						odds[0] -= 0.1
						odds[2] -= 0.1
						odds[1] += 0.2
					var roll = randf()
					if roll <= odds[0]:
						result = RESULT_SUCCESS
						recent_turn.PlayerSuccess += 1
						recent_turn.EnemyLosses += 1
						enemyside[targettype] -= 1
					elif roll <= odds[0]+odds[1]:
						result = RESULT_NONE
						recent_turn.PlayerNothing += 1
					else:
						result = RESULT_FAILURE
						recent_turn.PlayerFail += 1
						recent_turn.PlayerLosses += 1
						playerside[unittype] -= 1
		1:
			var targettype = -1
			var validtarget = false
			var odds = [0,0,0]
			var odds_base = [0,0,0]
			var result = RESULT_NONE
			for unittype in 4:
				for unit in enemyside[unittype]:
					if playerside[0] <= 0 and playerside[1] <= 0 and playerside[2] <= 0 and playerside[3] <= 0:
						break
					targettype = -1
					validtarget = false
					while !validtarget:
						targettype = randi()%4
						if playerside[targettype] > 0:
							validtarget = true
					match targettype:
						U_FOOTMAN:
							odds_base = unitdata[unittype].VersusFootman
						U_ARCHER:
							odds_base = unitdata[unittype].VersusArcher
						U_CAVALRY:
							odds_base = unitdata[unittype].VersusCavalry
						U_ELEPHANT:
							odds_base = unitdata[unittype].VersusElephant
					odds = odds_base.duplicate(true)
					if player_tactic == 1:
						odds[0] -= 0.1
						odds[2] -= 0.1
						odds[1] += 0.2
					var roll = randf()
					if roll <= odds[0]:
						result = RESULT_SUCCESS
						recent_turn.PlayerLosses += 1
						playerside[targettype] -= 1
					elif roll <= odds[0]+odds[1]:
						result = RESULT_NONE
					else:
						result = RESULT_FAILURE
						recent_turn.EnemyLosses += 1
						enemyside[unittype] -= 1

func _on_RoundButton_pressed():
	if battle_state == 0:
		$UI/Panel/RoundButton.disabled = true
		$UI/Panel/Defense.disabled = true
		recent_turn = {
			"PlayerLosses": 0,
			"PlayerSuccess": 0,
			"PlayerNothing": 0,
			"PlayerFail": 0,
			"EnemyLosses": 0,
		}
		run_turn(0)
		run_turn(1)
		$UI/Panel/StatusInfo.text = "..."
		battle_round += 1
		$RoundTimer.start(1)
		$UI/Panel/RoundButton.text = "Running Round..."
	else:
		if battle_state == 1:
			for participant in Global.combattants:
				if participant.type == "Enemy":
					participant.queue_free()
					break
				if participant.type == "Town":
					participant.ownership = 0
					Global.emit_signal("update_borders")
				if participant.type == "Player":
					participant.footmen = playerside[0]
					participant.archers = playerside[1]
					participant.cavalry = playerside[2]
					participant.elephants = playerside[3]
		if battle_state == 2:
			for participant in Global.combattants:
				if participant.type == "Player":
					participant.queue_free()
					break
		Global.in_combat = false
		Global.display_type = Global.display.NONE
		queue_free()
			
func _on_RoundTimer_timeout():
	$RoundTimer.stop()
	$UI/Panel/RoundButton.text = "Start Round"
	$UI/Panel/RoundButton.disabled = false
	$UI/Panel/Defense.disabled = false
	var successrate = 100
	if recent_turn.EnemyLosses == 0:
		successrate = 0
	elif recent_turn.PlayerFail > 0 or recent_turn.PlayerNothing > 0:
		successrate = 100*float(recent_turn.PlayerSuccess)/(float(recent_turn.PlayerSuccess)+float(recent_turn.PlayerFail)+float(recent_turn.PlayerNothing))
	$UI/Panel/StatusInfo.text = "Player Losses: "+String(recent_turn.PlayerLosses)+"\nEnemy Losses: "+String(recent_turn.EnemyLosses)+"\n\nAttack Success Rate: "+String(successrate).pad_decimals(1)+"%"
	if playerside[0] <= 0 and playerside[1] <= 0 and playerside[2] <= 0 and playerside[3] <= 0:
		$UI/Panel/StatusInfo.text += "\nYou Lose..."
		$UI/Panel/RoundButton.text = "Conclude Battle"
		battle_state = 2
		$UI/Panel/Defense.disabled = true
	elif enemyside[0] <= 0 and enemyside[1] <= 0 and enemyside[2] <= 0 and enemyside[3] <= 0:
		$UI/Panel/StatusInfo.text += "\nYou Win!"
		$UI/Panel/RoundButton.text = "Conclude Battle"
		battle_state = 1
		$UI/Panel/Defense.disabled = true

func _on_Defense_pressed():
	if player_tactic == 0:
		player_tactic = 1
	else:
		player_tactic = 0
