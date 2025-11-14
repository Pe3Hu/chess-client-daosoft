class_name Clock
extends PanelContainer



@export var referee: Referee

var resource: ClockResource:
	set(value_):
		resource = value_
		
		if resource.player.color == FrameworkSettings.PieceColor.WHITE:
			%ColorRect.color = Color.GHOST_WHITE
		else:
			%ColorRect.color = Color.BLACK

@onready var tick_timer: Timer = %TickTimer
@onready var time_label: Label = %TimeLabel
@onready var sacrifice_label: Label = %SacrificeLabel
@onready var sacrifice_box: HBoxContainer = %Sacrifice


func _on_tick_timer_timeout() -> void:
	resource.seconds -= 1
	update_time_label()
	
func update_time_label() -> void:
	var minutes = str(resource.minutes)
	var seconds = str(resource.seconds)
	
	if resource.seconds < 10:
		seconds = "0" + seconds
	
	time_label.text = minutes + ":" + seconds
	
	if resource.minutes == 0 and resource.seconds == 0:
		referee.resource.winner_player = resource.player.opponent
		referee.check_gameover()
	
func update_sacrifice_label() -> void:
	sacrifice_label.text = str(resource.sacrifices)
	
func _on_switch() -> void:
	if tick_timer.is_stopped():
		tick_timer.start()
	else:
		tick_timer.stop()
