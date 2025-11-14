class_name PieceResource
extends Resource


var board: BoardResource
var player: PlayerResource
var template: PieceTemplateResource
var tile: TileResource

var moves: Array[MoveResource]
var pin_tiles: Array[TileResource]
var pin_source_piece: PieceResource
var pin_target_piece: PieceResource
var assist_pieces: Array[PieceResource]

var is_inactive: bool = true
var is_fresh: bool = false


#region init
func _init(board_: BoardResource, player_: PlayerResource, template_: PieceTemplateResource, tile_: TileResource) -> void:
	board = board_
	player = player_
	template = template_
	player.pieces.append(self)
	tile_.place_piece(self)
	
	if template.type == FrameworkSettings.PieceType.KING:
		player.king_piece = self
	pass
	
func get_type() -> String:
	match template.type:
		FrameworkSettings.PieceType.KING:
			return "king"
		FrameworkSettings.PieceType.PAWN:
			return "pawn"
		FrameworkSettings.PieceType.BISHOP:
			return "bishop"
		FrameworkSettings.PieceType.KNIGHT:
			return "knight"
		FrameworkSettings.PieceType.ROOK:
			return "rook"
		FrameworkSettings.PieceType.QUEEN:
			return "queen"
		FrameworkSettings.PieceType.HELLHORSE:
			return "hellhorse"
	
	return ""
	
func get_color() -> String:
	match template.color:
		FrameworkSettings.PieceColor.WHITE:
			return "white"
		FrameworkSettings.PieceColor.BLACK:
			return "black"
	
	return ""
#endregion

#region moves
func generate_moves() -> void:
	if is_fresh: return
	is_fresh = true
	moves.clear()
	assist_pieces.clear()
	
	if template.type == FrameworkSettings.PieceType.PAWN:
		geterate_pawn_moves()
		return
	if template.type == FrameworkSettings.PieceType.KNIGHT or template.type == FrameworkSettings.PieceType.HELLHORSE:
		geterate_knight_moves()
		return
	
	geterate_sliding_moves()
	
	if template.type == FrameworkSettings.PieceType.KING:
		generate_king_castling_moves()
		return
	
func generate_king_castling_moves() -> void:
	if !is_inactive: return
	var castling_direction_indexs = [2, 6]
	
	for castling_direction_index in castling_direction_indexs:
		var castling_direction = FrameworkSettings.QUEEN_DIRECTIONS[castling_direction_index]
		
		if !tile.direction_to_sequence[castling_direction].is_empty():
			var last_tile_in_sequence = tile.direction_to_sequence[castling_direction].back()
			
			if last_tile_in_sequence.piece != null:
				var castling_rook = last_tile_in_sequence.piece
				
				if castling_rook.is_inactive:
					if tile.direction_to_sequence[castling_direction].size() < 2: return
					var target_tile = tile.direction_to_sequence[castling_direction][1]
					if target_tile.piece != null: return
					var sequence_index = tile.direction_to_sequence[castling_direction].size() - 3
					var king_neighbor_tile = tile.direction_to_sequence[castling_direction][sequence_index]
					if king_neighbor_tile.piece != null: return
					
					if !check_castling_under_threat(target_tile):
						add_move(target_tile, null)
	
func geterate_pawn_moves() -> void:
	geterate_pawn_advance_moves()
	geterate_pawn_capture_moves()
	geterate_pawn_passant_capture_move()
	
func geterate_pawn_advance_moves() -> void:
	var direction_index = 0
	var step_count = 1
	
	if board.buttom_color == template.color:
		direction_index = 4
	
	match template.color:
		FrameworkSettings.PieceColor.WHITE:
			if tile.coord.y == FrameworkSettings.BOARD_SIZE.y - 2:
				step_count = 2
		FrameworkSettings.PieceColor.BLACK:
			if tile.coord.y == 1:
				step_count = 2
	
	var direction = FrameworkSettings.QUEEN_DIRECTIONS[direction_index]
	
	for _i in step_count:
		var coord = tile.coord + direction * (_i + 1)
		var target_tile = board.get_tile_based_on_coord(coord)
	
		if target_tile:
			if target_tile.piece != null: return
			add_move(target_tile)
	
func geterate_pawn_capture_moves() -> void:
	var direction_indexs = []
	
	match template.color:
		FrameworkSettings.PieceColor.WHITE:
			direction_indexs = [1, 7]
		FrameworkSettings.PieceColor.BLACK:
			direction_indexs = [3, 5]
	
	for direction_index in direction_indexs:
		var direction = FrameworkSettings.QUEEN_DIRECTIONS[direction_index]
		var coord = tile.coord + direction
		var target_tile = board.get_tile_based_on_coord(coord)
	
		if target_tile:
			if target_tile.piece != null:
				if target_tile.piece.template.color != template.color:
					add_move(target_tile)
				else:
					assist_pieces.append(target_tile.piece)
			elif !player.pawn_threat_tiles.has(target_tile):
				player.pawn_threat_tiles.append(target_tile)
	
	update_assists()
	
func geterate_pawn_passant_capture_move() -> void:
	if board.game.notation.moves.is_empty(): return
	var last_move = board.game.notation.moves.back()
	if last_move.piece.template.type != FrameworkSettings.PieceType.PAWN: return
	
	var passant_direction_indexs = [2, 6]
	var capture_direction_indexs = []
	
	match template.color:
		FrameworkSettings.PieceColor.WHITE:
			capture_direction_indexs = [1, 7]
		FrameworkSettings.PieceColor.BLACK:
			capture_direction_indexs = [3, 5]
	
	for _i in passant_direction_indexs.size():
		var passant_direction_index = passant_direction_indexs[_i]
		var passant_direction = FrameworkSettings.QUEEN_DIRECTIONS[passant_direction_index]
		var passant_coord = tile.coord + passant_direction
		var passant_tile = board.get_tile_based_on_coord(passant_coord)
		
		if abs(last_move.start_tile.coord.y - last_move.end_tile.coord.y) != 2: continue
		if !passant_tile: continue
		if passant_tile.piece == null: continue
		if passant_tile.piece != last_move.piece: continue
		if passant_tile.piece.template.color == template.color: continue
		var capture_direction_index = capture_direction_indexs[_i]
		var capture_direction = FrameworkSettings.QUEEN_DIRECTIONS[capture_direction_index]
		var capture_coord = tile.coord + capture_direction
		var capture_tile = board.get_tile_based_on_coord(capture_coord)
		add_move(capture_tile, passant_tile.piece)
		return
	
func geterate_knight_moves() -> void:
	for direction in FrameworkSettings.KNIGHT_DIRECTIONS:
		var coord = tile.coord + direction
		var target_tile = board.get_tile_based_on_coord(coord)
		
		if target_tile != null:
			if target_tile.piece != null:
				if target_tile.piece.template.color != template.color:
					add_move(target_tile)
				else:
					assist_pieces.append(target_tile.piece)
			else:
				add_move(target_tile)
	
	update_assists()
	
func geterate_sliding_moves() -> void:
	var start_direction_index: int = 0
	var end_direction_index: int = FrameworkSettings.QUEEN_DIRECTIONS.size()
	var direction_index_step: int = 1
	
	match template.type:
		FrameworkSettings.PieceType.BISHOP:
			start_direction_index = 1
			direction_index_step = 2
		FrameworkSettings.PieceType.ROOK:
			direction_index_step = 2
	
	for offset_index in range(start_direction_index, end_direction_index, direction_index_step):
		var direction = FrameworkSettings.QUEEN_DIRECTIONS[offset_index]
		
		for tile_in_sequence in tile.direction_to_sequence[direction]:
			if tile_in_sequence.piece == null:
				add_move(tile_in_sequence)
				
				if template.type == FrameworkSettings.PieceType.KING:
					break 
				else:
					continue
			
			#blocked by friendly Piece, so cant' move any further in this direction
			if tile_in_sequence.piece.template.color == template.color:
				assist_pieces.append(tile_in_sequence.piece)
				break
			
			add_move(tile_in_sequence)
			
			#can't move any further in this direction after capturing opponen's piece
			if tile_in_sequence.piece.template.color != template.color:
				break
	
	update_assists()
	
func add_move(target_tile_: TileResource, captured_piece_: PieceResource = null) -> void:
	if captured_piece_ == null and target_tile_.piece != self:
		captured_piece_ = target_tile_.piece
	
	var move = MoveResource.new(self, tile, target_tile_, captured_piece_)
	moves.append(move)
#endregion

#region check
func is_valid_tile(tile_: TileResource) -> bool:
	for move in moves:
		if move.end_tile == tile_:
			if player.legal_moves.has(move):
				return true
	#var a = player.legal_moves.filter(func (a): a.piece == self)
	return false
	
func is_same_color(piece_resource_: PieceResource) -> bool:
	return piece_resource_.template.color == template.color
	
func check_castling_under_threat(target_tile_: TileResource) -> bool:
	var threat_moves = player.opponent.generate_moves()
	var castling_direction = Vector2i(Vector2(target_tile_.coord - tile.coord).normalized())
	var castling_coord = tile.coord
	
	while castling_coord != target_tile_.coord:
		for threat_move in threat_moves:
			if threat_move.end_tile.coord == castling_coord:
				return true
		
		castling_coord += castling_direction
	
	return false
	
func success_on_stand_trial() -> bool:
	if template.type == FrameworkSettings.PieceType.KING: return true
	var chance = randf()
	return chance < FrameworkSettings.VOID_CHANCE_TO_STAND
	
func failure_on_escape_trial() -> bool:
	if template.type == FrameworkSettings.PieceType.KING: return false
	var chance = randf()
	return chance < FrameworkSettings.VOID_CHANCE_TO_ESCAPE

#endregion

#region get
func get_move(target_tile_: TileResource) -> Variant:
	for move in moves:
		if move.end_tile == target_tile_:
			return move
	
	return null
	
func geterate_legal_moves() -> Array:
	generate_moves()
	var legal_moves = moves.filter(func(a): return player.is_legal_move(a))
	return legal_moves
	
func get_capture_moves() -> Array:
	generate_moves()
	var capture_moves = moves.filter(func(a): return a.type == FrameworkSettings.MoveType.CAPTURE or a.type == FrameworkSettings.MoveType.PASSANT)
	return capture_moves
#endregion

#region ping
func unpin() -> void:
	if pin_source_piece == null and pin_target_piece == null: return
	
	if pin_source_piece != null:
		unpin_source_piece()
		pin_source_piece.unpin_target_piece()
		pin_source_piece.pin_target_piece = null
		pin_source_piece = null
	if pin_target_piece != null:
		unpin_target_piece()
		pin_target_piece.unpin_source_piece()
		pin_target_piece.pin_source_piece = null
		pin_target_piece = null
	
func unpin_source_piece() -> void:
	for pin_tile in pin_tiles:
		pin_tile.pin_piece = null
	
	pin_tiles.clear()
	#if pin_source_piece == null: return
	#
	#pin_source_piece = null
	#pin_source_piece.pin_target_piece.unpin_target_piece()
	#pin_source_piece.pin_target_piece = null
	
func unpin_target_piece() -> void:
	player.pin_pieces.erase(self)
	#if pin_target_piece == null: return
	#
	#pin_source_piece.pin_source_piece.unpin_source_piece()
	#pin_target_piece = null
	#pin_target_piece.pin_source_piece = null
	
func set_pin_tiles(pin_tiles_: Array) -> void:
	for pin_tile in pin_tiles:
		pin_tile.pin_piece = null
	
	pin_tiles.clear()
	#pin_tiles.append_array(pin_tiles_)
	
	for pin_tile in pin_tiles_:
		pin_tiles.append(pin_tile)
		pin_tile.pin_piece = self
	
func king_unpin() -> void:
	if template.type != FrameworkSettings.PieceType.KING: return
	player.unpin_all_pieces()
	player.find_pin_moves()
#endregion

func update_assists() -> void:
	for assist_piece in assist_pieces:
		if !player.piece_to_assist.has(assist_piece):
			player.piece_to_assist[assist_piece] = 0
		
		player.piece_to_assist[assist_piece] += 1
	
