class_name CustomCursor
extends Sprite2D


var current_state: FrameworkSettings.CursorState = FrameworkSettings.CursorState.IDLE:
	set(value_):
		current_state = value_
		
		match current_state:
			FrameworkSettings.CursorState.IDLE:
				frame = 0
			FrameworkSettings.CursorState.SELECT:
				frame = 1
			FrameworkSettings.CursorState.HOLD:
				frame = 2


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
func _physics_process(delta_: float) -> void:
	global_position = lerp(global_position, get_global_mouse_position(), 16.5 * delta_)
