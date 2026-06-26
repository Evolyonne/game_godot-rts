## Autoload — global game state, scoring, performance tracking.
extends Node

signal score_changed(new_score: int)
signal game_over_triggered()
signal wave_performance_updated(score: float)

var score: int = 0
var kills_this_wave: int = 0
var damage_taken_this_wave: int = 0
var is_game_over: bool = false

# Performance score 0..1 (1 = perfect, 0 = struggling)
var performance_score: float = 0.5

func on_enemy_killed() -> void:
	kills_this_wave += 1
	score += 10
	score_changed.emit(score)

func on_player_damaged(amount: int) -> void:
	damage_taken_this_wave += amount

## Called by WaveManager at end of each wave.
func evaluate_wave_performance(zombies_spawned: int) -> void:
	if zombies_spawned == 0:
		return
	var kill_ratio := float(kills_this_wave) / float(zombies_spawned)
	var damage_penalty := clampf(float(damage_taken_this_wave) / 100.0, 0.0, 1.0)
	var new_score := clampf(kill_ratio - damage_penalty * 0.3, 0.0, 1.0)
	# Smooth toward new value
	performance_score = lerpf(performance_score, new_score, 0.4)
	wave_performance_updated.emit(performance_score)
	kills_this_wave = 0
	damage_taken_this_wave = 0

func game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	game_over_triggered.emit()
