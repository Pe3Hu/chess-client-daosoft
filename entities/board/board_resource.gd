class_name BoardResource
extends Resource


var game: GameResource
var tiles: Array[TileResource]
#var coord_to_tile: Dictionary
var legal_tiles: Array[TileResource]
var focus_tile: TileResource:
	set(value_):
		reset_tile_states()
		focus_tile = value_
		
		if focus_tile != null:
			update_tile_states()

var pieces: Array[PieceResource]
var captured_templates: Dictionary
var altar_tile: TileResource

var start_fen: String = ""


var buttom_color: FrameworkSettings.PieceColor = FrameworkSettings.PieceColor.BLACK


func _init(game_: GameResource) -> void:
	game = game_
	init_tiles()
	#add_piece(FrameworkSettings.PieceColor.BLACK | FrameworkSettings.PieceType.BISHOP, 25)
	#focus_tile = tiles[25]
	load_start_position()
	
func init_tiles() -> void:
	#FrameworkSettings.BOARD_SIZE = FrameworkSettings.mod_to_board_size[FrameworkSettings.active_mode]
	#coord_to_tile = {}
	for file in FrameworkSettings.BOARD_SIZE.y:
		for rank in FrameworkSettings.BOARD_SIZE.x:
			var coord = Vector2i(rank, file)
			add_tile(coord)
	
	for tile in tiles:
		tile.find_all_sequences()
	
func get_tile_based_on_coord(coord_: Vector2i) -> Variant:
	if BoardHelper.is_valid_coord(coord_):
		var id = coord_.y * FrameworkSettings.BOARD_SIZE.x + coord_.x
		return tiles[id]
	
	return null
	
func add_tile(coord_: Vector2i) -> void:
	var tile = TileResource.new(self, coord_)
	tiles.append(tile)
	#coord_to_tile[coord_] = tile
	
func load_position_from_fen(fen_: String) -> void:
	start_fen = fen_
	var fen_board: String = fen_.split(' ')[0]
	var file: int = 0
	var rank: int = FrameworkSettings.BOARD_SIZE.x - 1
	
	for symbol in fen_board:
		if symbol == "/":
			file = 0
			rank -= 1
		else:
			if symbol.is_valid_int():
				file += int(symbol)
			else:
				var piece_color = FrameworkSettings.PieceColor.BLACK
				var is_white = symbol.capitalize() == symbol
				if is_white:
					piece_color = FrameworkSettings.PieceColor.WHITE
				
				var piece_type =  FrameworkSettings.symbol_to_type[symbol.to_lower()]
				var tile_index = rank * FrameworkSettings.BOARD_SIZE.x + file
				var template_id = piece_type | piece_color
				add_piece(template_id, tile_index)
				file += 1
	
func add_piece(template_id_: int, tile_index_: int) -> void:
	var template = load("res://entities/piece/templates/{id}.tres".format({"id": template_id_}))
	var player = game.referee.color_to_player[template.color]
	var tile = tiles[tile_index_]
	var piece = PieceResource.new(self, player, template, tile)
	pieces.append(piece)
	
func update_tile_states() -> void:
	focus_tile.current_state = FrameworkSettings.TileState.FOCUS
	var legal_moves = focus_tile.piece.geterate_legal_moves()
	
	for move in legal_moves:
		move.end_tile.current_state = FrameworkSettings.TileState.LEGAL
		legal_tiles.append(move.end_tile)
	
func reset_tile_states() -> void:
	if focus_tile == null: return
	focus_tile.current_state = FrameworkSettings.TileState.NONE
	
	for legal_tile in legal_tiles:
		legal_tile.current_state = FrameworkSettings.TileState.NONE
	
	legal_tiles.clear()
	
func capture_piece(piece_: PieceResource) -> void:
	if !captured_templates.has(piece_.template):
		captured_templates[piece_.template] = 0
	
	piece_.unpin()
	captured_templates[piece_.template] += 1
	piece_.tile.piece = null
	pieces.erase(piece_)
	piece_.player.pieces.erase(piece_)
	
func make_move(move_: MoveResource) -> void:
	if move_.captured_piece != null:
		capture_piece(move_.captured_piece)
	
	move_.end_tile.place_piece(move_.piece)
	
	for piece in pieces:
		piece.is_fresh = false
	
	game.referee.pass_initiative()
	
func unmake_move(move_: MoveResource) -> void:
	move_.start_tile.place_piece(move_.piece)#, true)
	
	if move_.captured_piece != null:
		move_.end_tile.place_piece(move_.captured_piece)#, true)
		pieces.append(move_.captured_piece)
		move_.captured_piece.player.pieces.append(move_.captured_piece)
		captured_templates[move_.captured_piece.template] -= 1
	
	for piece in pieces:
		piece.is_fresh = false
	
	game.referee.pass_initiative()
	
func reset() -> void:
	while !pieces.is_empty():
		capture_piece(pieces.pop_back())
	
	for tile in tiles:
		tile.reset()
	
	captured_templates = {}
	load_start_position()
	
func load_start_position() -> void:
	start_fen = FrameworkSettings.mod_to_fen[FrameworkSettings.active_mode]
	load_position_from_fen(start_fen)
	
	match FrameworkSettings.active_mode:
		FrameworkSettings.ModeType.GAMBIT:
			altar_tile = get_tile_based_on_coord(FrameworkSettings.ALTAR_COORD)
			altar_tile.current_state = FrameworkSettings.TileState.AlTAR
	
func resize() -> void:
	remove_tiles()
	remove_pieces()
	
	init_tiles()
	load_start_position()
	
	game.recalc_piece_environment()
	
func remove_tiles() -> void:
	tiles.clear()
	legal_tiles.clear()
	focus_tile = null
	
func remove_pieces() -> void:
	captured_templates = {}
	pieces.clear()
	
	for player in game.referee.players:
		player.pieces.clear()
		player.reset()
