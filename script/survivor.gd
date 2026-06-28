## Allied survivor — follows the player using flocking + seek.
class_name Survivor
extends CharacterBody2D

const FOLLOW_DIST     := 80.0
const ATTACK_RANGE    := 200.0
const BULLET_DAMAGE   := 20
const BULLET_SPEED    := 460.0
const ATTACK_COOLDOWN := 0.8

@export var max_health: int = 60

var health: int
var _attack_timer: float = 0.0

@onready var _motor:    CharacterMotor = $CharacterMotor
@onready var _flocking: Flocking       = $Flocking

signal died()

const _BULLET_SCENE := preload("res://scene/bullet.tscn")

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

	var zombie := _find_nearest_enemy()
	if zombie:
		look_at(zombie.global_position)
		if _attack_timer <= 0.0 and global_position.distance_to(zombie.global_position) <= ATTACK_RANGE:
			_shoot(zombie)
			_attack_timer = ATTACK_COOLDOWN
	elif move_dir.length() > 0.1:
		look_at(global_position + move_dir)

func take_damage(amount: int) -> void:
	health = clampi(health - amount, 0, max_health)
	if health <= 0:
		died.emit()
		queue_free()

func get_health_ratio() -> float:
	return float(health) / float(max_health)

func _shoot(target: Node2D) -> void:
	var b: Bullet = _BULLET_SCENE.instantiate()
	b.damage = BULLET_DAMAGE
	b.speed = BULLET_SPEED
	b.direction = (target.global_position - global_position).normalized()
	b.collision_mask = 4
	get_tree().current_scene.add_child(b)
	b.global_position = global_position
	b.body_entered.connect(b._on_body_entered)

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