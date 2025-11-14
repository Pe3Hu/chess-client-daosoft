class_name World 
extends Node


@onready var game: Game = %Game

var multiplayer_peer = ENetMultiplayerPeer.new()

func _ready():
	join("127.0.0.1", 9999)

func join(ip, port):
	multiplayer_peer.create_client(ip, port)
	multiplayer.multiplayer_peer = multiplayer_peer
	
func send_move_resource(move_resource_: MoveResource) -> void:
	var start_tile_id = move_resource_.start_tile.id
	var end_tile_id = move_resource_.end_tile.id
	var move_type = move_resource_.type
	send_move_parameters.rpc_id(1, start_tile_id, end_tile_id, move_type)
	game.receive_move(move_resource_, false)
	MultiplayerManager.switch_active_color()

func send_try_start_game() -> void:
	try_start_game.rpc_id(1)

@rpc("any_peer")
func send_move_parameters(_start_tile_id_: int, _end_tile_id_: int, _move_type_: FrameworkSettings.MoveType):
	pass

@rpc("any_peer")
func return_enemy_move(active_color_: FrameworkSettings.PieceColor, start_tile_id_: int, end_tile_id_: int, move_type_: FrameworkSettings.MoveType) -> void:
	print([MultiplayerManager.user_color, MultiplayerManager.active_color, active_color_])
	#MultiplayerManager.switch_active_color()
	if active_color_ == MultiplayerManager.active_color: 
		#MultiplayerManager.switch_active_color()
		return
	MultiplayerManager.switch_active_color()
	#var c = MultiplayerManager.user_color
	var start_tile = game.board.tiles.get_child(start_tile_id_)
	var end_tile = game.board.tiles.get_child(end_tile_id_)
	var moved_piece = game.board.get_piece(start_tile.resource.piece)
	if moved_piece == null:
		return
	
	var move_resource = MoveResource.new(moved_piece.resource, start_tile.resource, end_tile.resource)
	if move_resource.type != move_type_:
		move_resource.type = move_type_
	game.receive_move(move_resource, false)
	
	#game.referee.pass_turn_to_opponent()

@rpc("any_peer")
func give_color(color_: FrameworkSettings.PieceColor):
	game.set_piece_color(color_)

@rpc("any_peer")
func try_start_game():
	pass

@rpc("any_peer")
func start_game():
	game.start()


func _input(event) -> void:
	if event is InputEventKey:
		match event.keycode:
			KEY_ESCAPE:
				get_tree().quit()
	
