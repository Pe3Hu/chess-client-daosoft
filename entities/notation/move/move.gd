class_name Move
extends PanelContainer


var resource: MoveResource:
	set(value_):
		resource = value_
		
		var action_str = FrameworkSettings.move_to_symbol[resource.type]
		if resource.castling_rook != null:
			%ReversibleAlgebraic.text = action_str
			return
		
		var start_str = FrameworkSettings.AXIS_X[resource.start_tile.coord.x] + FrameworkSettings.AXIS_Y[resource.start_tile.coord.y]
		var end_str = FrameworkSettings.AXIS_X[resource.end_tile.coord.x] + FrameworkSettings.AXIS_Y[resource.end_tile.coord.y]
		var type_str = resource.piece.get_type()[0].capitalize()
		
		if resource.piece.template.type == FrameworkSettings.PieceType.KNIGHT:
			type_str = "N"
		
		if type_str == "P":
			type_str = ""
		
		%ReversibleAlgebraic.text = type_str + start_str + action_str + end_str
