class_name Player
extends CharacterBody2D

const ATTACK_COOLDOWN := 0.25
const BULLET_DAMAGE   := 30
const BULLET_SPEED    := 520.0

@export var max_health: int = 100

var health: int
var _attack_timer: float = 0.0

@onready var _input: PlayerInput = $PlayerInput
@onready var _motor: CharacterMotor = $CharacterMotor
@onready var _health_bar: ProgressBar = $HealthBar

signal health_changed(current: int, maximum: int)
signal died()

const _BULLET_SCENE := preload("res://scene/bullet.tscn")

func _ready() -> void:
	health = max_health
	add_to_group("players")
	_health_bar.max_value = max_health
	_health_bar.value = health

func _physics_process(delta: float) -> void:
	var dir := _input.get_move_vector()
	_motor.move(dir, delta)

	_attack_timer -= delta
	if _input.is_attacking() and _attack_timer <= 0.0:
		_shoot()
		_attack_timer = ATTACK_COOLDOWN

	look_at(get_global_mouse_position())

func take_damage(amount: int) -> void:
	health = clampi(health - amount, 0, max_health)
	_health_bar.value = health
	health_changed.emit(health, max_health)
	GameManager.on_player_damaged(amount)
	if health == 0:
		died.emit()
		GameManager.game_over()
		queue_free()

func heal(amount: int) -> void:
	health = clampi(health + amount, 0, max_health)
	_health_bar.value = health
	health_changed.emit(health, max_health)

func get_health_ratio() -> float:
	return float(health) / float(max_health)

func _shoot() -> void:
	var b: Bullet = _BULLET_SCENE.instantiate()
	b.damage = BULLET_DAMAGE
	b.speed = BULLET_SPEED
	b.direction = (get_global_mouse_position() - global_position).normalized()
	b.collision_mask = 4
	get_tree().current_scene.add_child(b)
	b.global_position = global_position
	b.body_entered.connect(b._on_body_entered)