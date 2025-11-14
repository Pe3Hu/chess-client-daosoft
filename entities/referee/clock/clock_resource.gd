class_name ClockResource
extends Resource


var player: PlayerResource

var minutes: int = FrameworkSettings.CLOCK_START_MIN:
	set(value_):
		minutes = value_
var seconds: int = FrameworkSettings.CLOCK_START_SEC:
	set(value_):
		seconds = value_
		
		if seconds > 60:
			var plus_minutes = floor(seconds / 60)
			minutes += plus_minutes
			seconds -= plus_minutes * 60
		if seconds < 0:
			seconds += 60
			minutes -= 1
var sacrifices: int = FrameworkSettings.SACRIFICE_COUNT_FOR_VICTORY:
	set(value_):
		sacrifices = value_
		
		if sacrifices == 0:
			player.referee.winner_player = player


func _init(player_: PlayerResource) -> void:
	player = player_
	
func reset() -> void:
	minutes = FrameworkSettings.CLOCK_START_MIN
	seconds = FrameworkSettings.CLOCK_START_SEC
	sacrifices = FrameworkSettings.SACRIFICE_COUNT_FOR_VICTORY
	
