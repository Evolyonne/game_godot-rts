class_name PlayerInput
extends Node

func get_move_vector() -> Vector2:
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	return direction.normalized()

func is_attacking() -> bool:
	return Input.is_action_just_pressed("attack")
