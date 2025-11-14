class_name Handbook
extends PanelContainer


@export var game: Game

@onready var current = %CurrentHBoxContainer
@onready var legal = %LegalCurrentHBoxContainer
@onready var pin = %PinHBoxContainer
@onready var capture = %CaptureHBoxContainer
@onready var check = %CheckHBoxContainer
@onready var altar = %AltarHBoxContainer


func reset() -> void:
	current.visible = true
	legal.visible = true
	pin.visible = true
	capture.visible = true
	check.visible = true
	altar.visible = false
	
func fox_mod_display(is_on_: bool) -> void:
	#option_buttons.visible = !is_on_
	game.board.fox_panel.visible = is_on_
	pin.visible = !is_on_
	capture.visible = !is_on_
	check.visible = !is_on_
	
func surrender_reset() -> void:
	game.board.fox_panel.visible = false
	game.board.set_fox_swap_tiles_as_none_state()
	reset()
