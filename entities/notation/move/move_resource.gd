class_name MoveResource
extends Resource


var piece: PieceResource
var start_tile: TileResource
var end_tile: TileResource
var captured_piece: PieceResource
var castling_rook: PieceResource
var type: FrameworkSettings.MoveType = FrameworkSettings.MoveType.BASIC
var initiative: FrameworkSettings.InitiativeType = FrameworkSettings.InitiativeType.BASIC

var is_postponed: bool = false


#region init
func _init(piece_: PieceResource, start_tile_: TileResource, end_tile_: TileResource, captured_piece_: PieceResource = null) -> void:
	piece = piece_
	start_tile = start_tile_
	end_tile = end_tile_
	captured_piece = captured_piece_
	
	check_capture()
	check_pawn_promotion()
	check_castling()
	check_fox()
	
func check_capture() -> void:
	if captured_piece != null:
		if captured_piece.tile == end_tile:
			type = FrameworkSettings.MoveType.CAPTURE
		else:
			type = FrameworkSettings.MoveType.PASSANT
	
func check_pawn_promotion() -> void:
	if piece == null: return
	if piece.template.type != FrameworkSettings.PieceType.PAWN: return
	if end_tile.coord.y == 0 and piece.template.color == FrameworkSettings.PieceColor.WHITE:
		type = FrameworkSettings.MoveType.PROMOTION
	if end_tile.coord.y == 7 and piece.template.color == FrameworkSettings.PieceColor.BLACK:
		type = FrameworkSettings.MoveType.PROMOTION
	
func pawn_promotion(new_piece_type_: FrameworkSettings.PieceType = FrameworkSettings.PieceType.QUEEN) -> void:
	var template_id = new_piece_type_ | piece.template.color
	var new_template = load("res://entities/piece/templates/" + str(template_id) + ".tres")
	piece.template = new_template
	
func check_castling() -> void:
	if piece == null: return
	if piece.template.type != FrameworkSettings.PieceType.KING: return
	var x = abs(start_tile.coord.x - end_tile.coord.x)
	var y = abs(start_tile.coord.y - end_tile.coord.y)
	var l = max(x, y)#start_tile.coord.distance_squared_to(end_tile.coord)
	if l > 1:
		type = FrameworkSettings.MoveType.CASTLING
	
func check_fox() -> void:
	if FrameworkSettings.active_mode != FrameworkSettings.ModeType.FOX: return
	if piece != null: return
	type = FrameworkSettings.MoveType.FOX
#endregion

func get_tile_after_slide() -> TileResource:
	#var end_of_slide_tile = active_player.opponent.spy_move.end_tile
	var end_of_slide_tile = end_tile
	#var active_player = piece.board.game.referee.active_player
	#if !FrameworkSettings.SLIDE_PIECES.has(active_player.opponent.spy_move.piece.template.type): return end_of_slide_tile
	if !FrameworkSettings.SLIDE_PIECES.has(piece.template.type): return end_of_slide_tile

	#var direction = active_player.opponent.spy_move.end_tile.coord - active_player.opponent.spy_move.start_tile.coord
	var direction = BoardHelper.get_unit_vector(end_tile.coord - start_tile.coord)
	
	#direction = Vector2i(Vector2(direction).normalized())
	
	#end_of_slide_tile = active_player.opponent.spy_move.start_tile
	end_of_slide_tile = start_tile
	
	#while active_player.opponent.spy_move.end_tile != end_of_slide_tile:
	while end_tile != end_of_slide_tile:
		end_of_slide_tile = end_of_slide_tile.direction_to_sequence[direction].front()
		if end_of_slide_tile.piece != null:
			return end_of_slide_tile
	
	return end_of_slide_tile

#region check
func check_slide_tiles_on_threat() -> bool:
	var end_of_slide_tile = end_tile
	if !FrameworkSettings.SLIDE_PIECES.has(piece.template.type): return end_of_slide_tile

	var direction = end_tile.coord - start_tile.coord
	
	direction = Vector2i(Vector2(direction).normalized())
	end_of_slide_tile = start_tile
	var all_threats = piece.player.opponent.threat_moves
	var moved_tile_ids = []
	var threat_tile_ids = []
	
	for move in all_threats:
		if !threat_tile_ids.has(move.end_tile.id):
			threat_tile_ids.append(move.end_tile.id)
	
	while end_tile != end_of_slide_tile:
		var threats = piece.player.opponent.threat_moves.filter(func (a): return a.end_tile == end_of_slide_tile)
		if !threats.is_empty(): return false
		end_of_slide_tile = end_of_slide_tile.direction_to_sequence[direction].front()
		if end_of_slide_tile.piece != null:
			return false
		moved_tile_ids.append(end_of_slide_tile.id)
	
	#var crossed_ids = moved_tile_ids.filter(func (a): return threat_tile_ids.has(a))
	moved_tile_ids.sort()
	threat_tile_ids.sort()
	return true
	
func check_is_equal(move_: MoveResource) -> bool:
	if move_.start_tile.id != start_tile.id: return false
	if move_.end_tile.id != end_tile.id: return false
	#if move_.piece.template.type != piece.template.type: return false
	return true
#endregion
