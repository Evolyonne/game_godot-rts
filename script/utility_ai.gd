## Utility AI — scores potential targets for a zombie.
## Higher score = higher priority target.
class_name UtilityAI
extends Node

const WEIGHT_DISTANCE  := 0.5
const WEIGHT_ISOLATION := 0.3
const WEIGHT_HP        := 0.2
const MAX_SCORE_DIST   := 600.0

## Returns the best target from a list of CharacterBody2D nodes.
func pick_best_target(owner_pos: Vector2, candidates: Array) -> Node2D:
	var best_target: Node2D = null
	var best_score := -1.0

	for candidate in candidates:
		if not is_instance_valid(candidate):
			continue
		var score := _score_target(owner_pos, candidate, candidates)
		if score > best_score:
			best_score = score
			best_target = candidate

	return best_target

func _score_target(from: Vector2, target: Node2D, all_candidates: Array) -> float:
	var dist := from.distance_to(target.global_position)

	# Distance score: closer = higher (normalized 0-1)
	var dist_score := 1.0 - clampf(dist / MAX_SCORE_DIST, 0.0, 1.0)

	# Isolation score: fewer nearby allies = more isolated = easier prey
	var nearby_allies := 0
	for c in all_candidates:
		if c != target and is_instance_valid(c):
			if target.global_position.distance_to(c.global_position) < 120.0:
				nearby_allies += 1
	var isolation_score := 1.0 / (1.0 + nearby_allies)

	# HP score: lower HP target = better (finish them off)
	var hp_score := 0.5
	if target.has_method("get_health_ratio"):
		hp_score = 1.0 - target.get_health_ratio()

	return dist_score * WEIGHT_DISTANCE + isolation_score * WEIGHT_ISOLATION + hp_score * WEIGHT_HP
