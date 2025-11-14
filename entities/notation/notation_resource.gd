class_name NotationResource
extends Resource


var game: GameResource
var moves: Array[MoveResource]


func _init(game_: GameResource) -> void:
	game = game_
	
func record_move(move_: MoveResource) -> bool:
	#ignoring rook move after king castling
	if !moves.is_empty():
		if moves.back().type == FrameworkSettings.MoveType.CASTLING:
			if moves.back().piece.template.color == game.referee.active_player.color:
				return false
	
	moves.append(move_)
	return true
	
func reset() -> void:
	moves.clear()
	
func cancel_move(move_: MoveResource) -> void:
	moves.erase(move_)
