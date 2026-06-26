## Autoload singleton — shared horde awareness.
## One zombie sees the player → all zombies know.
extends Node

signal alert_triggered(position: Vector2)
signal alert_cleared()

var is_alerted: bool = false
var last_known_player_pos: Vector2 = Vector2.ZERO
var alert_decay_timer: float = 0.0

const ALERT_DECAY_DURATION := 15.0

func _process(delta: float) -> void:
	if is_alerted:
		alert_decay_timer -= delta
		if alert_decay_timer <= 0.0:
			_clear_alert()

## Called by any zombie that spots/hears the player.
func trigger_alert(world_position: Vector2) -> void:
	last_known_player_pos = world_position
	alert_decay_timer = ALERT_DECAY_DURATION
	if not is_alerted:
		is_alerted = true
		alert_triggered.emit(world_position)

## Called when horde loses track entirely.
func _clear_alert() -> void:
	is_alerted = false
	alert_cleared.emit()

## Update the known position (called when a zombie is actively chasing).
func update_player_position(pos: Vector2) -> void:
	last_known_player_pos = pos
	alert_decay_timer = ALERT_DECAY_DURATION
