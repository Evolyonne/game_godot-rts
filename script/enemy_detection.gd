## Handles zombie perception: sight cone + hearing radius.
class_name EnemyDetection
extends Node

@export var sight_range: float = 700.0
@export var sight_angle_deg: float = 200.0
@export var hearing_range: float = 600.0

var _owner_body: Node2D

func _ready() -> void:
	_owner_body = get_parent() as Node2D

## Returns the closest detected target (player or survivor), or null.
func find_target() -> Node2D:
	# Fast path: use horde shared memory
	if HordeMemory.is_alerted:
		var mem_target := _find_any_in_group("players")
		if mem_target == null:
			mem_target = _find_any_in_group("survivors")
		return mem_target

	var target := _check_group("players")
	if target:
		return target
	return _check_group("survivors")

func _check_group(group: String) -> Node2D:
	var nodes := _owner_body.get_tree().get_nodes_in_group(group)
	for node in nodes:
		if not is_instance_valid(node):
			continue
		var n := node as Node2D
		if _can_see(n) or _can_hear(n):
			HordeMemory.trigger_alert(n.global_position)
			return n
	return null

func _can_see(target: Node2D) -> bool:
	var to_target := target.global_position - _owner_body.global_position
	if to_target.length_squared() > sight_range * sight_range:
		return false
	var owner_forward := Vector2.from_angle(_owner_body.rotation)
	var angle := rad_to_deg(owner_forward.angle_to(to_target.normalized()))
	if absf(angle) > sight_angle_deg * 0.5:
		return false
	return _has_line_of_sight(target.global_position)

func _can_hear(target: Node2D) -> bool:
	return _owner_body.global_position.distance_squared_to(target.global_position) \
		   < hearing_range * hearing_range

func _has_line_of_sight(target_pos: Vector2) -> bool:
	var space := _owner_body.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		_owner_body.global_position, target_pos
	)
	query.exclude = [_owner_body.get_rid()]
	query.collision_mask = 1  # only walls
	var result := space.intersect_ray(query)
	return result.is_empty()

func _find_any_in_group(group: String) -> Node2D:
	var nodes := _owner_body.get_tree().get_nodes_in_group(group)
	for n in nodes:
		if is_instance_valid(n):
			return n as Node2D
	return null
