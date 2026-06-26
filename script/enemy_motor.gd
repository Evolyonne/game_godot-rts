## Steering motor for zombies — seek, arrive, and wander.
## Uses quadratic easing like CharacterMotor.
class_name EnemyMotor
extends Node

@export var max_speed: float = 70.0
@export var acceleration: float = 400.0
@export var friction: float = 300.0
@export var arrive_radius: float = 80.0
@export var stop_radius: float = 45.0

var _body: CharacterBody2D
var _current_path: Array[Vector2] = []
var _path_index: int = 0

func _ready() -> void:
	_body = get_parent() as CharacterBody2D

func follow_path(path: Array[Vector2], delta: float) -> void:
	if path.is_empty():
		brake(delta)
		return
	_current_path = path
	_path_index = 0
	_advance_path(delta)

func seek(target_pos: Vector2, delta: float) -> void:
	var to_target := target_pos - _body.global_position
	var dist := to_target.length()
	if dist < stop_radius:
		brake(delta)
		return
	var desired_speed := max_speed
	if dist < arrive_radius:
		# Quadratic arrive: speed tapers as square of distance ratio
		var t := dist / arrive_radius
		desired_speed = max_speed * t * t
	var desired_vel := to_target.normalized() * desired_speed
	_apply_steering(desired_vel, delta)

var _wander_angle: float = 0.0
func wander(delta: float) -> void:
	_wander_angle += randf_range(-0.8, 0.8)
	var circle_center := _body.velocity.normalized() * 60.0
	var displacement := Vector2.from_angle(_wander_angle) * 30.0
	var desired_vel := (circle_center + displacement).normalized() * (max_speed * 0.4)
	_apply_steering(desired_vel, delta)

func brake(delta: float) -> void:
	_apply_steering(Vector2.ZERO, delta)

func _apply_steering(desired_vel: Vector2, delta: float) -> void:
	var diff := desired_vel - _body.velocity
	var step := acceleration * delta
	# Quadratic easing: larger correction = faster response
	var ease_factor := clampf(diff.length() / max_speed, 0.0, 1.0)
	ease_factor = ease_factor * ease_factor
	_body.velocity += diff.normalized() * minf(diff.length(), step * (0.5 + ease_factor))
	_body.velocity = _body.velocity.limit_length(max_speed)
	_body.move_and_slide()

func _advance_path(delta: float) -> void:
	if _path_index >= _current_path.size():
		brake(delta)
		return
	var target := _current_path[_path_index]
	if _body.global_position.distance_squared_to(target) < 36.0 * 36.0:
		_path_index += 1
	if _path_index < _current_path.size():
		seek(_current_path[_path_index], delta)
	else:
		brake(delta)
