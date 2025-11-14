class_name Piece
extends Sprite2D


var board: Board
var resource: PieceResource:
	set(value_):
		resource = value_
		
		update_sprite()
		position = Vector2(resource.tile.coord) * FrameworkSettings.TILE_SIZE

@export_enum("pawn", "king", "queen", "rook", "bishop", "knight", "hellhorse") var type:
	set(value_):
		type = value_
		
		if color != null:
			texture = load("res://entities/piece/images/{color}_{type}.png".format({"color": color, "type": type}))
		if type == "hellhorse":
			offset.y = 5
@export_enum("black", "white") var color:
	set(value_):
		color = value_
		
		if type != null:
			texture = load("res://entities/piece/images/{color}_{type}.png".format({"color": color, "type": type}))

var is_holden: bool:
	set(value_):
		is_holden = value_
		
		if is_holden:
			z_index = 1
		else:
			z_index = 0


func update_sprite() -> void:
	type = resource.get_type()
	color = resource.get_color()
	
func _process(_delta: float) -> void:
	if is_holden:
		global_position = get_global_mouse_position()
	
func place_on_tile(tile_: Tile, _skip_recieve_move: bool = false) -> void:
	if tile_.resource.current_state == FrameworkSettings.TileState.FOCUS:
		return_piece_to_original_tile()
		return
	
	board.game.cursor.current_state = FrameworkSettings.CursorState.SELECT
	is_holden = false
	board.reset_focus_tile()
	var move_resource = resource.get_move(tile_.resource)
	board.game.receive_move(move_resource)
	
func return_piece_to_original_tile() -> void:
	var start_tile = board.get_tile(resource.tile)
	global_position = start_tile.global_position
	board.game.cursor.current_state = FrameworkSettings.CursorState.SELECT
	is_holden = false
	board.reset_focus_tile()
	
	var initiative = resource.player.get_initiative()
	
	match initiative:
		FrameworkSettings.InitiativeType.HELLHORSE:
			board.show_hellhorse_pass_ask()
	
func capture(source_piece_: Piece = null, _is_admin: bool = false) -> void:
	#if !is_admin_:
		#if resource.player.spy_move == null and FrameworkSettings.active_mode == FrameworkSettings.ModeType.SPY: return 
	if source_piece_ != null:
		if FrameworkSettings.active_mode == FrameworkSettings.ModeType.VOID:
			if resource.success_on_stand_trial():
				source_piece_.capture()
				return
	
	board.resource.capture_piece(resource)
	remove_self()
	
func remove_self() -> void:
	#board.resource_to_piece.erase(resource)
	board.pieces.remove_child(self)
	queue_free()
	
func promotion() -> void:
	update_sprite()
	
func complement_castling_move(move_resource_: MoveResource) -> void:
	if move_resource_.is_postponed: return
	var rook_direction = BoardHelper.get_unit_vector(move_resource_.end_tile.coord - move_resource_.start_tile.coord)
	var rook_resource = move_resource_.piece.tile.direction_to_sequence[rook_direction].back().piece
	if rook_resource == null: return
	var rook_piece = board.get_piece(rook_resource)
	#rook_direction *= -1
	var next_rook_tile_coord = resource.tile.coord + Vector2i(rook_direction)
	var next_rook_tile_id = FrameworkSettings.BOARD_SIZE.x * next_rook_tile_coord.y + next_rook_tile_coord.x
	var next_rook_tile_resource = board.resource.tiles[next_rook_tile_id]
	var next_rook_tile = board.get_tile(next_rook_tile_resource)
	#rook_piece.place_on_tile(next_rook_tile)
	#var move_end_tile = board.get_tile(move_resource_.end_tile)
	rook_piece.global_position = next_rook_tile.global_position
	next_rook_tile.resource.place_piece(rook_piece.resource)
	
func sacrifice(move_resource_: MoveResource) -> void:
	match FrameworkSettings.active_mode:
		FrameworkSettings.ModeType.GAMBIT:
			if move_resource_.end_tile != board.resource.altar_tile: return
			resource.player.clock.sacrifices -= 1
			if resource.template.type == FrameworkSettings.PieceType.KING:
				resource.player.clock.sacrifices = 0
			
			var clock = board.game.referee.get_player_clock(resource.player)
			clock.update_sacrifice_label()
			board.game.referee.check_gameover()
			remove_self()
			#var altar_tile = board.get_tile(board.resource.altar_tile)
			#board.resource.altar_tile.piece = null
	
func cancel_move(move_resource_: MoveResource) -> void:
	match FrameworkSettings.active_mode:
		FrameworkSettings.ModeType.SPY:
			resource.player.spy_move = move_resource_
			#resource.player.initiative_index += 1
	
	board.game.resource.notation.cancel_move(move_resource_)
	var old_tile = board.get_tile(move_resource_.start_tile)
	place_on_tile(old_tile)
	
