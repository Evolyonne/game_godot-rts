class_name Player
extends CharacterBody2D

const ATTACK_RANGE := 50.0
const ATTACK_DAMAGE := 30
const ATTACK_COOLDOWN := 0.5

@export var max_health: int = 100

var health: int
var _attack_timer: float = 0.0

@onready var _input: PlayerInput = $PlayerInput
@onready var _motor: CharacterMotor = $CharacterMotor
@onready var _health_bar: ProgressBar = $HealthBar

signal health_changed(current: int, maximum: int)
signal died()

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
		_do_attack()
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

func _do_attack() -> void:
	var space := get_world_2d().direct_space_state
	var params := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = ATTACK_RANGE
	params.shape = shape
	params.transform = Transform2D(0.0, global_position)
	params.collision_mask = 4
	var results := space.intersect_shape(params)
	for r in results:
		var body = r["collider"]
		if body.has_method("take_damage"):
			body.take_damage(ATTACK_DAMAGE)
