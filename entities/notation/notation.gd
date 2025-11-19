class_name Notation
extends PanelContainer


@export var move_scene: PackedScene

@export var game: Game

var resource: NotationResource

@onready var moves: = %Moves


func add_move(move_resource_: MoveResource) -> void:
	var move = move_scene.instantiate()
	move.resource = move_resource_
	moves.add_child(move)
	resource.record_move(move_resource_)
	#game.referee.pass_initiative()
	
func reset() -> void:
	while moves.get_child_count() > 0:
		var move = moves.get_child(0)
		moves.remove_child(move)
		move.queue_free()
	
	resource.reset()
