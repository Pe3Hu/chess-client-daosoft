class_name GameResource
extends Resource


var notation: NotationResource = NotationResource.new(self)
var referee: RefereeResource = RefereeResource.new(self)
var board: BoardResource = BoardResource.new(self)

#var current_mod: FrameworkSettings.ModeType = FrameworkSettings.ModeType.CLASSIC


func _init() -> void:
	for player in referee.players:
		player.board = board
	
	#var result = move_generation_test(2)
	
func move_generation_test(depth_: int) -> int:
	if depth_ == 0: return 1
	var count_positiions = 0
	referee.active_player.generate_legal_moves()
	var moves = referee.active_player.legal_moves
	moves.sort_custom(func (a, b): return a.end_tile.id < b.end_tile.id)
	
	for move in moves:
		board.make_move(move)
		#var _count_positiions = move_generation_test(depth_ - 1)
		#count_positiions += _count_positiions
		#if _count_positiions > 1:
		#	print([move.piece.template.type, move.start_tile.id, move.end_tile.id, _count_positiions])
		count_positiions += move_generation_test(depth_ - 1)
		board.unmake_move(move)
	
	return count_positiions
	
func recalc_piece_environment() -> void:
	#for player in referee.players:
	#	player.unfresh_all_pieces()
	
	referee.active_player.opponent.find_threat_moves()
	referee.active_player.generate_legal_moves()
	
func receive_move() -> void:
	pass
