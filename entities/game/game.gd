class_name Game
extends PanelContainer


signal fox_swap_pieces_finished

@export var world: World
@export var cursor: CustomCursor

var resource: GameResource = GameResource.new()

@onready var board: Board = %Board
@onready var referee: Referee = %Referee
@onready var notation: Notation = %Notation
@onready var menu = %Menu
@onready var handbook: Handbook = %Handbook

var on_pause: bool = true


#region basic
func _ready() -> void:
	board.resource = resource.board
	referee.resource = resource.referee
	notation.resource = resource.notation
	
	board.initial_tile_state_update()
	#await get_tree().create_timer(0.05).timeout
	#start()
	
func start() -> void:
	MultiplayerManager.reset()
	update_visible_flags_on_start()
	
	FrameworkSettings.BOARD_SIZE = FrameworkSettings.mod_to_board_size[FrameworkSettings.active_mode]
	
	if FrameworkSettings.BOARD_SIZE.x * FrameworkSettings.BOARD_SIZE.y != board.resource.tiles.size():
		board.resize()
	
	if referee.resource.winner_player != null:
		reset()
	elif board.resource.start_fen != FrameworkSettings.mod_to_fen[FrameworkSettings.active_mode]:
		reset()
	else :
		#resource.recalc_piece_environment()
		recalc_piece_environment()
		#board.resource.load_start_position()
	
	on_pause = true
	
	match FrameworkSettings.active_mode:
		FrameworkSettings.ModeType.FOX:
			referee.fox_mod_preparation()
			handbook.fox_mod_display(true)
			await fox_swap_pieces_finished
			handbook.fox_mod_display(false)
			await get_tree().create_timer(0.05).timeout
	
	on_pause = false
	referee.start_game()
	menu.update_bots()
	
	if referee.resource.active_player.is_bot:
		referee.apply_bot_move()
	
func update_visible_flags_on_start() -> void:
	menu.mods.visible = false
	menu.start_game_button.visible = false
	menu.surrender_game_button.visible = true
	handbook.visible = true
	handbook.altar.visible = FrameworkSettings.active_mode == FrameworkSettings.ModeType.GAMBIT
	board.visible = true
	board.checkmate_panel.visible = false
	notation.visible = true
	
func end() -> void:
	MultiplayerManager.reset()
	handbook.visible = false
	menu.mods.visible = true
	menu.start_game_button.visible = MultiplayerManager.user_color == FrameworkSettings.PieceColor.WHITE
	menu.surrender_game_button.visible = false
	referee.visible = false
	var notification_text = ""
	
	match referee.resource.winner_player.color:
		FrameworkSettings.PieceColor.BLACK:
			notification_text = "Black"
		FrameworkSettings.PieceColor.WHITE:
			notification_text = "White"
	
	notification_text += " is winner"
	board.checkmate_panel.visible = true
	board.checkmate_label.text = notification_text
	
	for clock in referee.clocks.get_children():
		clock.tick_timer.stop()
	
func reset() -> void:
	referee.reset()
	notation.reset()
	board.reset()
	menu.update_bots()
	resource.recalc_piece_environment()
	
func surrender() -> void:
	resource.referee.winner_player = MultiplayerManager.player.opponent #resource.referee.active_player.opponent
	handbook.surrender_reset()
	end()
#endregion

func recalc_piece_environment() -> void:
	resource.recalc_piece_environment()
	board.reset_focus_tile()
	
func receive_move(move_resource_: MoveResource, is_local_: bool = true) -> void:
	if move_resource_ == null: return
	if move_resource_.type == FrameworkSettings.MoveType.FOX:
		apply_fox_swap(move_resource_)
		return
	
	var moved_piece = board.get_piece(move_resource_.piece)
	var initiative = moved_piece.resource.player.get_initiative()
	
	if initiative == FrameworkSettings.InitiativeType.PLAN:
		referee.resource.active_player.spy_move = move_resource_
		move_resource_.is_postponed = true
	
	if moved_piece.resource.is_inactive:
		moved_piece.resource.is_inactive = move_resource_.is_postponed
		
	if move_resource_.captured_piece != null:
		var captured_piece = board.get_piece(move_resource_.captured_piece)
		
		if !move_resource_.is_postponed:
			captured_piece.capture(moved_piece)
	
	match move_resource_.type:
		FrameworkSettings.MoveType.PROMOTION:
			if !move_resource_.is_postponed:
				move_resource_.pawn_promotion()
				moved_piece.promotion()
		FrameworkSettings.MoveType.CASTLING:
			moved_piece.complement_castling_move(move_resource_)
	
	#check on Gambit Altar
	moved_piece.sacrifice(move_resource_)
	
	if move_resource_.is_postponed:
		var move_start_tile = board.get_tile(move_resource_.start_tile)
		moved_piece.global_position = move_start_tile.global_position
	else:
		if !is_local_:
			var move_end_tile = board.get_tile(move_resource_.end_tile)
			moved_piece.global_position = move_end_tile.global_position
			move_end_tile.resource.place_piece(moved_piece.resource)
			notation.add_move(move_resource_)
			pass
		else:
			var move_start_tile = board.get_tile(move_resource_.start_tile)
			moved_piece.global_position = move_start_tile.global_position
	
	if move_resource_.type == FrameworkSettings.MoveType.HELLHORSE and !is_local_:
		referee.insert_hellhorse_initiative()
		
	if !is_local_:
		consequence_of_piece_placement(moved_piece, is_local_)
	
	if !move_resource_.is_postponed and is_local_:
		world.send_move_resource(move_resource_)
	
func consequence_of_piece_placement(piece_: Piece, is_local_: bool) -> void:
	if piece_.resource.player != referee.resource.active_player: return
	#if is_local_: return
	
	piece_.resource.king_unpin()
	referee.apply_mods()
	
	var is_passing_turn = referee.resource.active_player.is_last_initiative()
	var initiative = referee.resource.active_player.get_initiative()
	piece_.resource.player.update_initiative()
	#print([referee.resource.active_player.initiative_index, referee.resource.active_player.initiatives])
	
	if is_passing_turn:
		referee.pass_turn_to_opponent(is_local_)
	else:
		board.reset_focus_tile()
	
	match FrameworkSettings.active_mode:
		FrameworkSettings.ModeType.SPY:
			if initiative == FrameworkSettings.InitiativeType.BASIC:
				referee.apply_opponent_spy_move()
	
func apply_fox_swap(move_resource_: MoveResource) -> void:
	var moved_piece = board.get_piece(move_resource_.start_tile.piece)
	moved_piece.is_holden = false
	var move_end_tile = board.get_tile(move_resource_.end_tile)
	moved_piece.global_position = move_end_tile.global_position
	move_end_tile.resource.place_piece(moved_piece.resource)
	
func set_piece_color(color_: FrameworkSettings.PieceColor) -> void:
	for player in referee.resource.players:
		if player.color == color_:
			MultiplayerManager.player = player
			break
	
	if MultiplayerManager.user_color == color_: return
	MultiplayerManager.user_color = color_
	
	if color_ == FrameworkSettings.PieceColor.BLACK:
		board.swap_on_black_color()
	else:
		board.swap_on_white_color()
