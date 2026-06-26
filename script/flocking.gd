## Flocking / Boid behaviors shared by zombies and survivors.
## Call compute() each frame and add the result to steering.
class_name Flocking
extends Node

@export var separation_radius: float = 40.0
@export var alignment_radius:  float = 80.0
@export var cohesion_radius:   float = 120.0

@export var weight_separation: float = 1.8
@export var weight_alignment:  float = 0.8
@export var weight_cohesion:   float = 0.6

## Returns a steering velocity contribution for this agent.
func compute(owner_body: CharacterBody2D, peers: Array) -> Vector2:
	var sep := Vector2.ZERO
	var ali := Vector2.ZERO
	var coh := Vector2.ZERO
	var sep_count := 0
	var ali_count := 0
	var coh_count := 0

	for peer in peers:
		if peer == owner_body or not is_instance_valid(peer):
			continue
		var offset := owner_body.global_position - peer.global_position
		var dist := offset.length()

		if dist < separation_radius and dist > 0.0:
			sep += offset.normalized() / dist
			sep_count += 1

		if dist < alignment_radius:
			ali += peer.velocity
			ali_count += 1

		if dist < cohesion_radius:
			coh += peer.global_position
			coh_count += 1

	var result := Vector2.ZERO
	if sep_count > 0:
		result += (sep / sep_count).normalized() * weight_separation
	if ali_count > 0:
		result += (ali / ali_count).normalized() * weight_alignment
	if coh_count > 0:
		var center := coh / coh_count
		result += (center - owner_body.global_position).normalized() * weight_cohesion

	return result
