class_name Board
extends PanelContainer


@export var tile_scene: PackedScene
@export var piece_scene: PackedScene

@export var game: Game
var resource: BoardResource:
	set(value_):
		resource = value_
		
		position = FrameworkSettings.TILE_SIZE * 0.5 + FrameworkSettings.AXIS_OFFSET
		init_tiles()
		init_pieces()

#@onready var map_layer: TileMapLayer = %BoardMapLayer
@onready var tiles: Node2D = %Tiles
@onready var pieces: Node2D = %Pieces

@onready var hellhorse_pass_ask: PanelContainer = %HellHorsePassAsk
@onready var fox_panel: PanelContainer = %FoxPanel
@onready var checkmate_panel = %CheckmatePanel
@onready var checkmate_label = %CheckmateLabel

var resource_to_piece: Dictionary

var focus_tiles: Array[Tile]
var legal_tiles: Array[Tile]
var capture_tiles: Array[Tile]
var check_tiles: Array[Tile]
var pin_tiles: Array[Tile]
var altar_tiles: Array[Tile]

var state_tiles = [
	focus_tiles,
	legal_tiles,
	capture_tiles,
	check_tiles,
	pin_tiles,
	altar_tiles
]


#region init
func _ready() -> void:
	#map_layer.position = FrameworkSettings.TILE_SIZE * 0.5
	update_board_position()
	
func update_board_position() -> void:
	%Board.position = %BoardContainer.size / 2
	%BoardMapLayer.position = -%BoardContainer.size / 2 + FrameworkSettings.TILE_SIZE * 0.5
	
func init_tiles() -> void:
	for tile_resource in resource.tiles:
		add_tile(tile_resource)
	
	if resource.altar_tile != null:
		var altar_tile = get_tile(resource.altar_tile)
		altar_tile.update_state()
	
func add_tile(tile_resource_: TileResource) -> void:
	var tile = tile_scene.instantiate()
	tile.board = self
	tile.resource = tile_resource_
	tiles.add_child(tile)
	
func get_tile(tile_resource_: TileResource) -> Tile:
	return tiles.get_child(tile_resource_.id)
	
func init_pieces() -> void:
	while pieces.get_child_count() > 0:
		var piece = pieces.get_child(0)
		pieces.remove_child(piece)
		piece.queue_free()
	
	for piece_resource in resource.pieces:
		add_piece(piece_resource)
	
func add_piece(piece_resource_: PieceResource) -> void:
	var piece = piece_scene.instantiate()
	piece.board = self
	piece.resource = piece_resource_
	pieces.add_child(piece)
	resource_to_piece[piece_resource_] = piece
	
func get_piece(piece_resource_: PieceResource) -> Variant:
	if resource_to_piece.has(piece_resource_): return resource_to_piece[piece_resource_]
	#get_tree().quit()
	return null
	
#endregion

#region hold
func hold_piece_on_tile(tile_: Tile) -> void:
	reset_focus_tile()
	resource.focus_tile = tile_.resource
	set_tile_state(tile_, FrameworkSettings.TileState.FOCUS)
	#update_focus_tile(tile_)
	hold_piece()
	
func hold_piece() -> void:
	var piece = get_piece(resource.focus_tile.piece)
	piece.is_holden = true
	game.cursor.current_state = FrameworkSettings.CursorState.HOLD
#endregion

#region tile state
func set_tile_state(tile_: Tile, state_: FrameworkSettings.TileState) -> void:
	tile_.set_state(state_)
	
	match state_:
		FrameworkSettings.TileState.FOCUS:
			focus_tiles.append(tile_)
			update_focus_tile()
		FrameworkSettings.TileState.LEGAL:
			legal_tiles.append(tile_)
		FrameworkSettings.TileState.CAPTURE:
			capture_tiles.append(tile_)
		FrameworkSettings.TileState.CHECK:
			check_tiles.append(tile_)
		FrameworkSettings.TileState.PIN:
			pin_tiles.append(tile_)
		FrameworkSettings.TileState.AlTAR:
			altar_tiles.append(tile_)
	
func reset_tile_state(tile_: Tile) -> void:
	tile_.set_state(FrameworkSettings.TileState.NONE)
	
	match tile_.resource.current_state:
		FrameworkSettings.TileState.FOCUS:
			focus_tiles.erase(tile_)
		FrameworkSettings.TileState.LEGAL:
			legal_tiles.erase(tile_)
		FrameworkSettings.TileState.CAPTURE:
			capture_tiles.erase(tile_)
		FrameworkSettings.TileState.CHECK:
			check_tiles.erase(tile_)
		FrameworkSettings.TileState.PIN:
			pin_tiles.erase(tile_)
		FrameworkSettings.TileState.AlTAR:
			altar_tiles.erase(tile_)
	
func reset_state_tiles() -> void:
	for _state_tiles in state_tiles:
		while !_state_tiles.is_empty():
			var tile = _state_tiles.pop_back()
			if tile != null:
				reset_tile_state(tile)
	
func reset_focus_tile() -> void:
	if FrameworkSettings.active_mode == FrameworkSettings.ModeType.FOX and game.on_pause: return
	resource.focus_tile = null
	#var previous_active_tile_resources = []
	#
	#if resource.focus_tile != null:
		#previous_active_tile_resources.append(resource.focus_tile)
		#previous_active_tile_resources.append_array(resource.legal_tiles)
	#
	#for tile_resource in previous_active_tile_resources:
		#var tile = tiles.get_child(tile_resource.id)
		#tile.update_modulate(FrameworkSettings.TileState.NONE)
	reset_state_tiles()
	fill_state_tiles()
	
	match FrameworkSettings.active_mode:
		FrameworkSettings.ModeType.GAMBIT:
			var altar_tile = get_tile(resource.altar_tile)
			set_tile_state(altar_tile, FrameworkSettings.TileState.AlTAR)
	
func update_focus_tile() -> void:
	if FrameworkSettings.active_mode == FrameworkSettings.ModeType.FOX and game.on_pause: return
	#var focust_tile = tiles.get_child(resource.focus_tile.id)
	#focust_tile.update_state()
	
	for tile_resource in resource.legal_tiles:
		var tile = tiles.get_child(tile_resource.id)
		set_tile_state(tile, FrameworkSettings.TileState.LEGAL)
	
func initial_tile_state_update() -> void:
	fill_state_tiles()
	
func fill_state_tiles() -> void:
	for move in resource.game.referee.active_player.opponent.capture_moves:
		var tile = tiles.get_child(move.end_tile.id)
		set_tile_state(tile, FrameworkSettings.TileState.CAPTURE)
	
	for move in resource.game.referee.active_player.opponent.pin_moves:
		var tile = tiles.get_child(move.end_tile.id)
		set_tile_state(tile, FrameworkSettings.TileState.PIN)
	
	for tile_resource in resource.game.referee.active_player.opponent.check_tiles:
		var tile = tiles.get_child(tile_resource.id)
		set_tile_state(tile, FrameworkSettings.TileState.CHECK)
	
#func reset_initiative_tile() -> void:
	#for move in resource.game.referee.active_player.opponent.capture_moves:
		#var tile = tiles.get_child(move.end_tile.id)
		#tile.update_modulate(FrameworkSettings.TileState.NONE)
	#
	#for move in resource.game.referee.active_player.opponent.pin_moves:
		#var tile = tiles.get_child(move.end_tile.id)
		#tile.update_modulate(FrameworkSettings.TileState.NONE)
	#
	#for tile_resource in resource.game.referee.active_player.opponent.check_tiles:
		#var tile = tiles.get_child(tile_resource.id)
		#tile.update_modulate(FrameworkSettings.TileState.NONE)
	
#endregion

#region reset
func reset() -> void:
	resource_to_piece = {}
	resource.reset()
	
	for tile in tiles.get_children():
		tile.update_state()
	
	init_pieces()
	initial_tile_state_update()
	game.resource.recalc_piece_environment()
	
func resize() -> void:
	%BoardContainer.size = Vector2(FrameworkSettings.BOARD_SIZE) * FrameworkSettings.TILE_SIZE
	size = Vector2(FrameworkSettings.BOARD_SIZE + Vector2i(2, 2)) * FrameworkSettings.TILE_SIZE
	
	update_board_position()
	resource.resize()
	resource_to_piece = {}
	update_axis()
	
	remove_tiles()
	remove_pieces()
	
	init_tiles()
	init_pieces()
	reset()
	
func update_axis() -> void:
	var is_9_visible = FrameworkSettings.BOARD_SIZE != FrameworkSettings.DEFAULT_BOARD_SIZE
	%DigitLabel9.visible = is_9_visible
	%LetterLabel9.visible = is_9_visible
	
func remove_tiles() -> void:
	while tiles.get_child_count() > 0:
		var tile = tiles.get_child(0)
		tiles.remove_child(tile)
		tile.queue_free()
	
func remove_pieces() -> void:
	while pieces.get_child_count() > 0:
		var piece = pieces.get_child(0)
		pieces.remove_child(piece)
		piece.queue_free()
	
func reset_tiles(tile_resources_: Array) -> void:
	for tile_resource in tile_resources_:
		var tile = get_tile(tile_resource)
		tile.update_modulate(FrameworkSettings.TileState.NONE)
#endregion

#region fox
func fox_mod_tile_state_update() -> void:
	if game.referee.resource.fox_swap_players.is_empty():
		game.fox_swap_pieces_finished.emit()
		return
	
	var player = game.referee.resource.fox_swap_players.front()
	
	if player.is_bot:
		fox_random_swap()
	else:
		for piece in player.fox_swap_pieces:
			var tile = get_tile(piece.tile)
			tile.update_state()
	
func set_fox_swap_tiles_as_none_state() -> void:
	if game.referee.resource.fox_swap_players.is_empty(): return
	var player = game.referee.resource.fox_swap_players.front()
	for piece in player.fox_swap_pieces:
		var tile = get_tile(piece.tile)
		tile.resource.current_state = FrameworkSettings.TileState.NONE
		tile.update_state()
	
func fox_swap(piece_for_swap_: Piece) -> void:
	#var focus_piece = get_piece(resource.focus_tile.piece)
	var focus_tile = get_tile(resource.focus_tile).resource
	var swap_tile = get_tile(piece_for_swap_.resource.tile).resource
	var temp_tile = get_free_tile().resource
	var fox_move = MoveResource.new(null, focus_tile, temp_tile)
	game.receive_move(fox_move)
	#piece_for_swap_.place_on_tile(temp_tile)
	
	#focus_piece.place_on_tile(swap_tile)
	fox_move = MoveResource.new(null, swap_tile, focus_tile)
	game.receive_move(fox_move)
	
	#piece_for_swap_.place_on_tile(focus_tile)
	fox_move = MoveResource.new(null, temp_tile, swap_tile)
	game.receive_move(fox_move)
	
	reset_tile_state_after_swap()
	fox_mod_tile_state_update()
	#piece_for_swap_.is_holden = false
	
func fox_random_swap() -> void:
	var player = game.referee.resource.fox_swap_players.front()
	player.fox_swap_pieces.shuffle()
	var random_focus_resource = player.fox_swap_pieces.pop_back()
	var random_swap_resource = player.fox_swap_pieces.pop_back()
	resource.focus_tile = random_focus_resource.tile
	var swap_piece = get_piece(random_swap_resource)
	fox_swap(swap_piece)
	
func reset_tile_state_after_swap() -> void:
	resource.focus_tile = null
	var player = game.referee.resource.fox_swap_players.pop_front()
	for piece in player.fox_swap_pieces:
		var tile = get_tile(piece.tile)
		tile.resource.current_state = FrameworkSettings.TileState.NONE
		tile.update_state()
	
func get_free_tile() -> Tile:
	var tile_index = 17
	var option_tile = tiles.get_child(tile_index)
	
	while option_tile.resource.piece != null:
		tile_index += 1
		option_tile = tiles.get_child(tile_index)
	
	return option_tile
#endregion

#region hellhorse
func show_hellhorse_pass_ask() -> void:
	hellhorse_pass_ask.visible = true
	game.on_pause = true
	
func _on_hell_horse_yes_button_pressed() -> void:
	game.referee.pass_turn_to_opponent()
	hellhorse_pass_ask.visible = false
	game.on_pause = false
	
func _on_hell_horse_no_button_pressed() -> void:
	hellhorse_pass_ask.visible = false
	game.on_pause = false
	
func clear_phantom_hellhorse_captures() -> void:
	var last_move = game.notation.resource.moves.back()
	last_move.start_tile.current_state = FrameworkSettings.TileState.NONE
	var start_tile = game.board.get_tile(last_move.start_tile)
	start_tile.update_state()
	var phantom_captures = last_move.piece.player.opponent.capture_moves.filter(func (a): return a.captured_piece == last_move.piece)
	last_move.piece.player.opponent.capture_moves = last_move.piece.player.opponent.capture_moves.filter(func (a): !phantom_captures.has(a))
#endregion

#region ui buttons
func _on_mouse_entered() -> void:
	game.cursor.current_state = FrameworkSettings.CursorState.SELECT
	
func _on_mouse_exited() -> void:
	game.cursor.current_state = FrameworkSettings.CursorState.IDLE
#endregion

#region user color
func swap_on_black_color() -> void:
	%Board.rotation_degrees = 180
	%WhiteAxisDigits.visible = false
	%BlackAxisDigits.visible = true
	game.menu.start_game_button.visible = false
	
	for tile in tiles.get_children():
		tile.rotation_degrees = 180
		
	for piece in pieces.get_children():
		piece.rotation_degrees = 180
	
func swap_on_white_color() -> void:
	%Board.rotation_degrees = 0
	%WhiteAxisDigits.visible = true
	%BlackAxisDigits.visible = false
	game.menu.start_game_button.visible = true
	
	for tile in tiles.get_children():
		tile.rotation_degrees = 0
		
	for piece in pieces.get_children():
		piece.rotation_degrees = 0
#endregion
