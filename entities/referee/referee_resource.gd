class_name RefereeResource
extends Resource


var game: GameResource

var players: Array[PlayerResource]
var fox_swap_players: Array[PlayerResource]
var color_to_player: Dictionary

var active_player: PlayerResource
var winner_player: PlayerResource = null

#var is_spy_action: bool = false


func _init(game_: GameResource) -> void:
	game = game_
	
	init_players()
	
func init_players() -> void:
	for piece_color in FrameworkSettings.DEFAULT_COLORS:
		add_player(piece_color)
	
	active_player = players.front()
	
	for _i in players.size():
		var _j = (_i + 1) % players.size()
		players[_i].opponent = players[_j]
	
func add_player(piece_color_: FrameworkSettings.PieceColor) -> void:
	var player = PlayerResource.new(self, piece_color_)
	players.append(player)
	color_to_player[piece_color_] = player
	
#func pass_turn_to_opponent() -> void:
	#if !active_player.initiatives.size() > active_player.initiative_index: return
	#print([MultiplayerManager.move_index, MultiplayerManager.user_color, active_player.initiative_index, active_player.initiatives.size()])
	#switch_active_player()
	
func reset() -> void:
	for player in players:
		player.reset()
	
	active_player = players.front()
	winner_player = null
	
func switch_active_player() -> void:
	active_player.reset_initiatives()
	MultiplayerManager.switch_active_color()
	active_player = active_player.opponent
	game.recalc_piece_environment()
