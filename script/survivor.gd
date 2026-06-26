## Allied survivor — follows the player using flocking + seek.
class_name Survivor
extends CharacterBody2D

const FOLLOW_DIST    := 80.0
const ATTACK_RANGE   := 55.0
const ATTACK_DAMAGE  := 20
const ATTACK_COOLDOWN := 1.0

@export var max_health: int = 60

var health: int
var _attack_timer: float = 0.0

@onready var _motor:    CharacterMotor = $CharacterMotor
@onready var _flocking: Flocking       = $Flocking

signal died()

func _ready() -> void:
	health = max_health
	add_to_group("survivors")

func _physics_process(delta: float) -> void:
	_attack_timer -= delta

	var player := _find_player()
	var move_dir := Vector2.ZERO

	if player:
		var to_player := player.global_position - global_position
		if to_player.length() > FOLLOW_DIST:
			move_dir = to_player.normalized()

	var peers := get_tree().get_nodes_in_group("survivors")
	var flock := _flocking.compute(self, peers)
	if move_dir.length() > 0.01:
		move_dir = (move_dir + flock * 0.6).normalized()
	elif flock.length() > 0.01:
		move_dir = flock.normalized()

	_motor.move(move_dir if move_dir.length() > 0.1 else Vector2.ZERO, delta)

	if _attack_timer <= 0.0:
		var zombie := _find_nearest_enemy()
		if zombie and global_position.distance_to(zombie.global_position) <= ATTACK_RANGE:
			zombie.take_damage(ATTACK_DAMAGE)
			_attack_timer = ATTACK_COOLDOWN

func take_damage(amount: int) -> void:
	health = clampi(health - amount, 0, max_health)
	if health <= 0:
		died.emit()
		queue_free()

func get_health_ratio() -> float:
	return float(health) / float(max_health)

func _find_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		return players[0] as Node2D
	return null

func _find_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist := INF
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var d := global_position.distance_squared_to((e as Node2D).global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e as Node2D
	return nearest
