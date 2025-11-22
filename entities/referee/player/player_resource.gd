class_name PlayerResource
extends Resource


var referee: RefereeResource
var board: BoardResource
var opponent: PlayerResource
var clock: ClockResource = ClockResource.new(self)

var color: FrameworkSettings.PieceColor = FrameworkSettings.PieceColor.WHITE

var pieces: Array[PieceResource]
var fox_swap_pieces: Array[PieceResource]
var king_piece: PieceResource

var legal_moves: Array[MoveResource]
var threat_moves: Array[MoveResource]
var threat_tiles: Array[TileResource]
var pawn_threat_tiles: Array[TileResource]
var capture_moves: Array[MoveResource]
var pin_moves: Array[MoveResource]
var pin_pieces: Array[PieceResource]
var check_moves: Array[MoveResource]
var check_tiles: Array[TileResource]
var sacrifice_moves: Array[MoveResource]
var piece_to_assist: Dictionary

var is_winner: bool = false
var is_bot: bool = false

var initiatives: Array[FrameworkSettings.InitiativeType]
var initiative_index: int = 0

#var hellhorse_bonus_move: bool = false
#var spy_bonus_move: bool = false:
	#set(value_):
		#spy_bonus_move = value_
var spy_move: MoveResource:
	set(value_):
		spy_move = value_
		pass


func _init(referee_: RefereeResource, color_: FrameworkSettings.PieceColor) -> void:
	referee = referee_
	color = color_ 
	
	reset_initiatives()

#region moves
func generate_moves() -> Array:
	var moves = []
	
	for piece in pieces:
		piece.generate_moves()
		moves.append_array(piece.moves)
	
	return moves
	
func generate_legal_moves() -> void:
	if referee.game.board == null: return
	unfresh_all_pieces()
	legal_moves.clear()
	
	match FrameworkSettings.active_mode:
		FrameworkSettings.ModeType.HELLHORSE:
			if is_not_last_initiative():
				generate_hellhorse_bonus_moves()
	
	piece_to_assist = {}
	
	generate_king_legal_moves()
	if opponent.check_moves.size() > 1: return
	
	for piece in pieces:
		if piece != king_piece:
			add_piece_legal_moves(piece)
	
func generate_king_legal_moves() -> void:
	king_piece.generate_moves()
	
	var behind_check_tiles = []
	for check_move in opponent.check_moves:
		var check_direction = BoardHelper.get_unit_vector(king_piece.tile.coord - check_move.start_tile.coord)
		var behind_check_coord = king_piece.tile.coord + check_direction
		var behind_check_tile = board.get_tile_based_on_coord(behind_check_coord)
		behind_check_tiles.append(behind_check_tile)
	
	var king_legal_moves = king_piece.moves.filter(func (a): return !opponent.threat_tiles.has(a.end_tile))
	king_legal_moves = king_legal_moves.filter(func (a): return !opponent.piece_to_assist.keys().has(a.captured_piece))
	king_legal_moves = king_legal_moves.filter(func (a): return !behind_check_tiles.has(a.end_tile))
	
	match FrameworkSettings.active_mode:
		FrameworkSettings.ModeType.GAMBIT:
			var altar_moves = king_piece.moves.filter(func (a): return a.end_tile == board.altar_tile)
			legal_moves.append_array(altar_moves)
	
	legal_moves.append_array(king_legal_moves)
	
func add_piece_legal_moves(piece_: PieceResource) -> void:
	piece_.generate_moves()
	var piece_legal_moves = piece_.moves
	
	if !piece_.pin_tiles.is_empty():
		piece_legal_moves = piece_legal_moves.filter(func (a): return piece_.pin_tiles.has(a.end_tile))
	if !opponent.check_tiles.is_empty():
		piece_legal_moves = piece_legal_moves.filter(func (a): return opponent.check_tiles.has(a.end_tile))
	legal_moves.append_array(piece_legal_moves)
	
func is_legal_move(move_: MoveResource) -> bool:
	for move in legal_moves:
		if move.start_tile == move_.start_tile and move.end_tile == move_.end_tile and move.piece == move_.piece:
			return true
		#if move.start_tile != move_.start_tile:
			#break
		#elif move.end_tile != move_.end_tile:
			#break
	
	return false
	
func unfresh_all_pieces() -> void:
	for piece in pieces:
		piece.is_fresh = false
	
func find_threat_moves() -> void:
	unfresh_all_pieces()
	threat_moves.clear()
	threat_tiles.clear()
	pawn_threat_tiles.clear()
	capture_moves.clear()
	
	for piece in pieces:
		if !opponent.pin_pieces.has(piece):
			piece.generate_moves()
			threat_moves.append_array(piece.moves)
			
			for move in piece.moves:
				if !threat_tiles.has(move.end_tile):
					threat_tiles.append(move.end_tile)
			
			var piece_capture_moves = piece.get_capture_moves()
			capture_moves.append_array(piece_capture_moves)
	
	threat_tiles.append_array(pawn_threat_tiles)
	find_check_moves()
	find_pin_moves()
	
func find_check_moves() -> void:
	check_moves.clear()
	
	for capture_move in capture_moves:
		if capture_move.captured_piece == opponent.king_piece:
			check_moves.append(capture_move)
	
	find_check_tiles()
	
func find_pin_moves() -> void:
	pin_moves.clear()
	pin_pieces.clear()
	
	for capture_move in capture_moves:
		var pin_tiles = is_king_behind_piece(capture_move)
		
		if !pin_tiles.is_empty():
			pin_moves.append(capture_move)
			pin_pieces.append(capture_move.captured_piece)
			capture_move.captured_piece.set_pin_tiles(pin_tiles)
			capture_move.captured_piece.pin_source_piece = capture_move.piece
			capture_move.piece.pin_target_piece = capture_move.captured_piece
	
func unpin_all_pieces() -> void:
	for piece in pieces:
		if opponent.pin_pieces.has(piece):
			piece.pin_source_piece.unpin()
			#piece.unpin()
#endregion

func can_apply_checkmate() -> bool:#moves_: Array) -> bool:
	var moves_ = generate_moves()
	for move in moves_:#legal_moves:#moves_:
		if move.captured_piece != null:
			if move.captured_piece.template.type == FrameworkSettings.PieceType.KING:
				return true
	
	return false
	
func is_king_behind_piece(capture_move_: MoveResource) -> Array:
	if !FrameworkSettings.SLIDE_PIECES.has(capture_move_.piece.template.type): return []
	if capture_move_.captured_piece == opponent.king_piece: return []
	
	var king_direction = opponent.king_piece.tile.coord - capture_move_.start_tile.coord
	if !BoardHelper.check_on_axis(king_direction): return []
	var unit_king_direction = BoardHelper.get_unit_vector(king_direction)
	var unit_pin_direction = BoardHelper.get_unit_vector(capture_move_.end_tile.coord - capture_move_.start_tile.coord)
	if unit_king_direction != unit_pin_direction: return []
	
	var tile_on_way_to_king = capture_move_.start_tile
	var pint_tiles = []
	
	while tile_on_way_to_king != opponent.king_piece.tile:
		pint_tiles.append(tile_on_way_to_king)
		var next_tile_coord = tile_on_way_to_king.coord + unit_king_direction
		tile_on_way_to_king = board.get_tile_based_on_coord(next_tile_coord)
		if tile_on_way_to_king == null: break
		
		if tile_on_way_to_king.piece == capture_move_.captured_piece: continue
		elif tile_on_way_to_king.piece != null:
			if tile_on_way_to_king.piece != opponent.king_piece: return []
	
	return pint_tiles
	
func find_check_tiles() -> void:
	check_tiles.clear()
	if check_moves.size() != 1: return
	var check_move = check_moves.front()
	
	if !FrameworkSettings.SLIDE_PIECES.has(check_move.piece.template.type):
		check_tiles.append(check_move.start_tile)
		return
	
	var check_direction = BoardHelper.get_unit_vector(check_move.end_tile.coord - check_move.start_tile.coord)
	var tile_on_way_to_king = check_move.start_tile
	
	while tile_on_way_to_king != opponent.king_piece.tile:
		check_tiles.append(tile_on_way_to_king)
		var next_tile_coord = tile_on_way_to_king.coord + check_direction
		tile_on_way_to_king = board.get_tile_based_on_coord(next_tile_coord)
	
func reset() -> void:
	clock.reset()
	
	fox_swap_pieces.clear()
	legal_moves.clear()
	threat_moves.clear()
	threat_tiles.clear()
	pawn_threat_tiles.clear()
	capture_moves.clear()
	pin_moves.clear()
	pin_pieces.clear()
	check_moves.clear()
	check_tiles.clear()
	piece_to_assist = {}
	
	is_winner = false
	is_bot = false
	#hellhorse_bonus_move = false
	#spy_bonus_move = false
	spy_move = null
	
	reset_initiatives()
	
#region mods
func fill_fox_swap_pieces() -> void:
	fox_swap_pieces = pieces.filter(func(a): return a.template.type != FrameworkSettings.PieceType.PAWN)
	
	for piece in fox_swap_pieces:
		piece.tile.current_state = FrameworkSettings.TileState.LEGAL
	
func generate_hellhorse_bonus_moves() -> void:
	#if get_initiative() != FrameworkSettings.InitiativeType.HELLHORSE: return
	#if !hellhorse_bonus_move: return
	#if !board.game.notation.moves.is_empty():
	var last_move = board.game.notation.moves.back()
	var piece = last_move.piece
	if piece.template.type != FrameworkSettings.PieceType.HELLHORSE: return
	piece.is_fresh = false
	add_piece_legal_moves(piece)
	
	for move in legal_moves:
		if move.captured_piece != null:
			if move.captured_piece.template.type == FrameworkSettings.PieceType.KING:
				legal_moves.erase(move)
				return
#endregion

#region initiative
func reset_initiatives() -> void:
	initiatives.clear()
	initiatives.append_array(FrameworkSettings.mod_to_initiatives[FrameworkSettings.active_mode])
	initiative_index = 0
	
func get_initiative() -> FrameworkSettings.InitiativeType:
	return initiatives[initiative_index]
	
func is_last_initiative() -> bool:
	return initiatives.size() == initiative_index + 1#get_initiative() == FrameworkSettings.InitiativeType.BASIC 

func is_not_last_initiative() -> bool:
	return initiatives.size() > initiative_index + 1
	
func update_initiative() -> void:
	if self != board.game.referee.active_player: return
	initiative_index += 1
	board.game.recalc_piece_environment()
	
	if initiatives.size() == initiative_index:
		reset_initiatives()
#endregion
