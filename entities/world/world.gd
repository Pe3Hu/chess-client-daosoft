class_name World 
extends Node


@onready var game: Game = %Game

var multiplayer_peer = ENetMultiplayerPeer.new()


func _ready():
	join("127.0.0.1", 9999)
	
func join(ip, port):
	multiplayer_peer.create_client(ip, port)
	multiplayer.multiplayer_peer = multiplayer_peer
	
func _input(event) -> void:
	if event is InputEventKey:
		match event.keycode:
			KEY_ESCAPE:
				get_tree().quit()


#region start
#@rpc("authority")
#func recive_opponent_peer_id(opponent_peer_id_: int):
	#opponent_peer_id = opponent_peer_id_

@rpc("authority")
func recive_color(color_: FrameworkSettings.PieceColor):
	game.set_piece_color(color_)

@rpc("authority")
func try_start_game():
	pass

@rpc("authority")
func start_game():
	game.start()

@rpc("authority")
func send_mode_parameters(_mode_type_: FrameworkSettings.ModeType):
	pass

@rpc("authority")
func recive_mode_parameters(mode_type_: FrameworkSettings.ModeType):
	FrameworkSettings.active_mode = mode_type_
	game.menu.update_mode_buttons()
#endregion


#region move
func send_move_resource(move_resource_: MoveResource) -> void:
	var start_tile_id = move_resource_.start_tile.id
	var end_tile_id = move_resource_.end_tile.id
	var move_type = move_resource_.type
	MultiplayerManager.move_index += 1
	server_recive_move_parameters.rpc_id(1, start_tile_id, end_tile_id, MultiplayerManager.move_index, move_type)
	game.receive_move(move_resource_, false)
	
@rpc("authority")
func server_recive_move_parameters(_start_tile_id_: int, _end_tile_id_: int, _move_index_: int, _move_type_: FrameworkSettings.MoveType, _lost_initiative_: bool):
	pass

@rpc("authority")
func client_recive_move_parameters(start_tile_id_: int, end_tile_id_: int, move_index_: int, move_type_: FrameworkSettings.MoveType) -> void:
	print([FrameworkSettings.color_to_str[MultiplayerManager.user_color], "recive, next move is", move_index_ + 1])
	
	if MultiplayerManager.move_index + 1 != move_index_: return
	MultiplayerManager.move_index = move_index_
	
	var start_tile = game.board.tiles.get_child(start_tile_id_)
	var end_tile = game.board.tiles.get_child(end_tile_id_)
	var moved_piece = game.board.get_piece(start_tile.resource.piece)
	if moved_piece == null: return
	
	var move_resource = MoveResource.new(moved_piece.resource, start_tile.resource, end_tile.resource)
	if move_resource.type != move_type_:
		move_resource.type = move_type_
		
		if FrameworkSettings.CAPTURE_TYPES.has(move_type_):
			move_resource.captured_piece = end_tile.resource.piece
	
	if move_resource.piece.template.type == FrameworkSettings.PieceType.HELLHORSE:
		var is_hellhorse = game.notation.resource.moves.is_empty()
		
		if !is_hellhorse:
			var last_move = game.notation.resource.moves.back()
			is_hellhorse = last_move.piece.template.type != FrameworkSettings.PieceType.HELLHORSE or last_move.piece.template.color != move_resource.piece.template.color
		
		if is_hellhorse:
			move_resource.type = FrameworkSettings.MoveType.HELLHORSE
		
	game.receive_move(move_resource, false)

@rpc("authority")
func server_recive_initiative_switch():
	print([FrameworkSettings.color_to_str[MultiplayerManager.user_color], "send initiative"])
	#MultiplayerManager.switch_active_color()
	#server_send_initiative_switch.rpc_id(1)

@rpc("authority")
func client_recive_initiative_switch():
	print([FrameworkSettings.color_to_str[MultiplayerManager.user_color], "recive initiative"])
	game.referee.pass_turn_to_opponent(false)
#endregion


@rpc("authority")
func server_recive_fox_swap_parameters(_focus_tile_id_: int, _swap_tile_id_: int):
	pass

@rpc("authority")
func client_recive_fox_swap_parameters(focus_tile_id_: int, swap_tile_id_: int):
	game.board.fox_swap_from_server(focus_tile_id_, swap_tile_id_)

@rpc("any_peer")
func client_recive_void_tile_id_fatigue(tile_id_: int):
	print(["clinet recive void fatigue tile", tile_id_])
	game.board.apply_tile_fatigue(tile_id_)


@rpc("authority")
func declare_defeat():
	pass

@rpc("authority")
func declare_victory():
	game.resource.referee.winner_player = MultiplayerManager.player
	game.handbook.surrender_reset()
	game.end()
