## Quadratic steering motor for player/survivors.
## Acceleration uses a squared easing curve for organic feel.
class_name CharacterMotor
extends Node

@export var max_speed: float = 160.0
@export var acceleration: float = 900.0
@export var friction: float = 700.0

var _body: CharacterBody2D

func _ready() -> void:
	_body = get_parent() as CharacterBody2D

## Move toward direction with quadratic easing (not linear lerp).
func move(direction: Vector2, delta: float) -> void:
	if direction.length_squared() > 0.01:
		var target_vel := direction * max_speed
		var diff := target_vel - _body.velocity
		# Quadratic ease-in: apply stronger force early, softer near target
		var t := clampf(acceleration * delta / max_speed, 0.0, 1.0)
		var ease_t := t * t * (3.0 - 2.0 * t)  # smoothstep
		_body.velocity += diff * ease_t * (acceleration * delta / max_speed).sqrt() * 2.0
		_body.velocity = _body.velocity.limit_length(max_speed)
	else:
		var brake := friction * delta
		if _body.velocity.length() <= brake:
			_body.velocity = Vector2.ZERO
		else:
			_body.velocity -= _body.velocity.normalized() * brake
	_body.move_and_slide()

func get_velocity() -> Vector2:
	return _body.velocity
