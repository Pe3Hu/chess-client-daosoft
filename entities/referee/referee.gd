class_name Referee
extends PanelContainer


@export var game: Game

var resource: RefereeResource:
	set(value_):
		resource = value_
		init_clocks()

@onready var clocks = %Clocks


#region clock
func init_clocks() -> void:
	for player_resource in resource.players:
		match player_resource.color:
			FrameworkSettings.PieceColor.WHITE:
				%WhiteClock.resource = player_resource.clock
			FrameworkSettings.PieceColor.BLACK:
				%BlackClock.resource = player_resource.clock
	
	update_clocks()
	
func update_clocks() -> void:
	for clock in clocks.get_children():
		clock.update_time_label()
		clock.update_sacrifice_label()
		clock.sacrifice_box.visible = FrameworkSettings.active_mode == FrameworkSettings.ModeType.GAMBIT
		
func get_player_clock(player_resource_: PlayerResource) -> Variant:
	for clock in clocks.get_children():
		if clock.resource == player_resource_.clock:
			return clock
	
	return null
#endregion
	
func start_game() -> void:
	game.on_pause = false
	game.board.checkmate_panel.visible = false
	visible = true
	%WhiteClock._on_switch()
	
func pass_turn_to_opponent() -> void:
	#game.board.reset_state_tiles()
	#apply_mods()
	resource.pass_turn_to_opponent()
	
	if !check_gameover():
		game.board.reset_focus_tile()
		
		for clock in clocks.get_children():
			clock._on_switch()
		
		apply_bot_move()
	
func check_gameover() -> bool:
	var is_gameover = resource.winner_player != null
	
	if !is_gameover:
		is_gameover = resource.active_player.legal_moves.is_empty()
		
		if is_gameover:
			resource.winner_player = resource.active_player.opponent
	
	if is_gameover:
		game.end()
		return true
		
	return false
	
func apply_bot_move() -> void:
	if !resource.active_player.is_bot: return
	#while 
	#print("___")
	for initiative in resource.active_player.initiatives:
		var random_move = resource.active_player.legal_moves.pick_random()
		game.receive_move(random_move)
		#print(initiative)
		if resource.active_player.initiatives.size() > 1:
			resource.active_player.generate_legal_moves()
	
	
	#var initiave = resource.active_player.is_last_initiative()
	#var a = resource.active_player.initiatives
	#var b = resource.active_player.initiative_index
	#print(random_move)
	pass
	
func reset() -> void:
	resource.reset()
	update_clocks()
	
#region mod
func apply_mods() -> void:
	apply_void_mod()
	apply_hellhorse_mod()
	
func apply_void_mod() -> void:
	if FrameworkSettings.active_mode != FrameworkSettings.ModeType.VOID: return
	var escape_piece_resources = []
	
	for move_resource in resource.active_player.opponent.capture_moves:
		if !escape_piece_resources.has(move_resource.captured_piece):
			escape_piece_resources.append(move_resource.captured_piece)
	
	for piece_resource in escape_piece_resources:
		if piece_resource.failure_on_escape_trial():
			var piece = game.board.get_piece(piece_resource)
			piece.capture()
	
func apply_hellhorse_mod() -> void:
	if FrameworkSettings.active_mode != FrameworkSettings.ModeType.HELLHORSE: return
	var last_move = game.notation.resource.moves.back()
	if last_move.piece.template.type != FrameworkSettings.PieceType.HELLHORSE: return
	var initiative = last_move.piece.player.get_initiative()
	
	match initiative:
		FrameworkSettings.InitiativeType.BASIC:
			last_move.piece.player.initiatives.push_back(FrameworkSettings.InitiativeType.HELLHORSE)
		
			last_move.piece.player.generate_legal_moves()
			game.board.clear_phantom_hellhorse_captures()
		FrameworkSettings.InitiativeType.HELLHORSE:
			pass
	
func fox_mod_preparation() -> void:
	resource.fox_swap_players.append_array(resource.players)
	
	for player in resource.players:
		player.fill_fox_swap_pieces()
	
	game.menu.update_bots()
	game.board.fox_mod_tile_state_update()
	
func apply_opponent_spy_move() -> void:
	var move = resource.active_player.opponent.spy_move
	
	if move == null: return
	
	if !check_spy_move_is_legal():
		return
	
	move.is_postponed = false
	
	match move.type:
		FrameworkSettings.MoveType.CAPTURE:
			move.is_postponed = !check_spy_move_on_legal_capture()
		FrameworkSettings.MoveType.PASSANT:
			move.is_postponed = !check_spy_move_on_legal_capture()
	
	update_spy_move_on_slide_capture()
	
	game.receive_move(move)
	var spy_piece = game.board.get_piece(move.piece)
	
	if move.type == FrameworkSettings.MoveType.CASTLING:
		spy_piece.complement_castling_move(move)
	
	spy_piece.resource.king_unpin()
	game.resource.recalc_piece_environment()
	detect_spy_checkmate()
	
func check_spy_move_is_legal() -> bool:
	resource.active_player.find_threat_moves()
	resource.active_player.opponent.generate_legal_moves()
	var king_moves = resource.active_player.opponent.legal_moves.filter(func (a): return a.piece.template.type == FrameworkSettings.PieceType.KING)
	var king_tile_indexs =[]
	
	for king_move in king_moves:
		king_tile_indexs.append(king_move.end_tile.id)
	
	for move in resource.active_player.opponent.legal_moves:
		if resource.active_player.opponent.spy_move.check_is_equal(move):
			return true
	
	return false
	
func check_spy_move_on_legal_capture() -> bool:
	var move = resource.active_player.opponent.spy_move
	if move.end_tile.piece != move.captured_piece:
		move.type = FrameworkSettings.MoveType.BASIC
		move.captured_piece = null
	
	return move.piece.template.type != FrameworkSettings.PieceType.PAWN
	
func update_spy_move_on_slide_capture() -> void:
	var move = resource.active_player.opponent.spy_move
	var end_of_slide_tile_resource = move.get_tile_after_slide()
	
	if move.end_tile != end_of_slide_tile_resource:
		move.end_tile = end_of_slide_tile_resource
	
	if move.end_tile.piece != null:
		move.captured_piece = move.end_tile.piece
		move.type = FrameworkSettings.MoveType.CAPTURE
	
func detect_spy_checkmate() -> void:
	resource.active_player.opponent.find_threat_moves()
	if resource.active_player.opponent.can_apply_checkmate():
		resource.winner_player = resource.active_player.opponent
		game.end()
#endregion
