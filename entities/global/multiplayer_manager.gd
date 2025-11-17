extends Node



#var notation: NotationResource = NotationResource.new()
#var referee: RefereeResource = RefereeResource.new()
#var board: BoardResource = BoardResource.new()
var player: PlayerResource
var move_index: int = 0

var user_color: FrameworkSettings.PieceColor = FrameworkSettings.PieceColor.WHITE:
	set(value_):
		user_color = value_
var active_color: FrameworkSettings.PieceColor = FrameworkSettings.PieceColor.WHITE


func switch_active_color() -> void:
	var next_color_index = ( FrameworkSettings.DEFAULT_COLORS.find(active_color) + 1) % FrameworkSettings.DEFAULT_COLORS.size()
	active_color =  FrameworkSettings.DEFAULT_COLORS[next_color_index]
	
func reset() -> void:
	move_index = 0
