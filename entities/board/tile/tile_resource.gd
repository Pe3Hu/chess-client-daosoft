class_name TileResource
extends Resource


var board: BoardResource
var piece: PieceResource:
	set(value_):
		if board.altar_tile != self:
			piece = value_
var pin_piece: PieceResource
var coord: Vector2i

var id: int
var current_state: FrameworkSettings.TileState = FrameworkSettings.TileState.NONE

var direction_to_sequence: Dictionary


func _init(board_: BoardResource, coord_: Vector2i) -> void:
	board = board_
	coord = coord_
	id = FrameworkSettings.BOARD_SIZE.x * coord_.y + coord_.x
	
func find_all_sequences() -> void:
	for direction in FrameworkSettings.QUEEN_DIRECTIONS:
		direction_to_sequence[direction] = []
		var neighbour_coord = Vector2i(coord)
		var is_sequence_end = false
		
		while !is_sequence_end:
			neighbour_coord += direction
			is_sequence_end = !BoardHelper.is_valid_coord(neighbour_coord)
			
			if !is_sequence_end:
				var next_tile = board.get_tile_based_on_coord(neighbour_coord)
				direction_to_sequence[direction].append(next_tile)
	
func check_tile_on_same_axis(tile_: TileResource) -> bool:
	return coord.x == tile_.coord.x or coord.y == tile_.coord.y
	
func place_piece(piece_: PieceResource) -> void:
	if piece != null: return
	if piece_ == piece: return
	
	if piece_.tile != null:
		piece_.tile.piece = null
	
	piece = piece_
	piece_.tile = self
	piece_.unpin()
	
	if piece_.template.type == FrameworkSettings.PieceType.KING:
		for pinned_piece in piece_.player.pin_pieces:
			pinned_piece.unpin()
	
func reset() -> void:
	piece = null
	pin_piece = null
	current_state = FrameworkSettings.TileState.NONE
