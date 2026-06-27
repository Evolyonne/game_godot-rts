## Zombie orchestrator — decision tree + flocking + utility AI.
##
## Decision tree:
##   WANDER → (hears/sees target) → ALERTED → CHASE → ATTACK
##                                                  ↓
##                                            CALL_HORDE (broadcast)
class_name Enemy
extends CharacterBody2D

enum State { WANDER, ALERTED, CHASE, ATTACK, CALL_HORDE, DEAD }

const ATTACK_RANGE    := 38.0
const ATTACK_DAMAGE   := 10
const ATTACK_COOLDOWN := 1.2
const CALL_HORDE_DIST := 300.0
const PATH_REFRESH_T  := 0.4
const WANDER_CHANGE_T := 2.5

@export var max_health: int = 60

var health: int
var state: State = State.WANDER
var _target: Node2D = null
var _attack_timer: float = 0.0
var _path_timer: float = 0.0
var _wander_timer: float = 0.0
var _current_path: Array[Vector2] = []

@onready var _motor:     EnemyMotor     = $EnemyMotor
@onready var _detection: EnemyDetection = $EnemyDetection
@onready var _flocking:  Flocking       = $Flocking
@onready var _utility:   UtilityAI      = $UtilityAI
@onready var _health_bar: ProgressBar   = $HealthBar

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	HordeMemory.alert_triggered.connect(_on_horde_alerted)
	_health_bar.max_value = max_health
	_health_bar.value = health

func _physics_process(delta: float) -> void:
	_attack_timer -= delta
	_path_timer   -= delta
	_wander_timer -= delta

	match state:
		State.WANDER:     _tick_wander(delta)
		State.ALERTED:    _tick_alerted(delta)
		State.CHASE:      _tick_chase(delta)
		State.ATTACK:     _tick_attack(delta)
		State.CALL_HORDE: _tick_call_horde(delta)
		State.DEAD:       pass

	if state != State.ATTACK and velocity.length() > 10.0:
		look_at(global_position + velocity)

func _tick_wander(delta: float) -> void:
	if HordeMemory.is_alerted:
		_transition(State.ALERTED)
		return
	var found := _detection.find_target()
	if found:
		_target = found
		_transition(State.CHASE)
		return
	if _wander_timer <= 0.0:
		_wander_timer = WANDER_CHANGE_T + randf() * 2.0
	_apply_flocking_and_move(delta)

func _tick_alerted(delta: float) -> void:
	var candidates := _get_all_targets()
	if candidates.size() > 0:
		_target = _utility.pick_best_target(global_position, candidates)
	if _target and is_instance_valid(_target):
		_transition(State.CHASE)
		return
	_navigate_toward(HordeMemory.last_known_player_pos, delta)
	if global_position.distance_squared_to(HordeMemory.last_known_player_pos) < 80.0 * 80.0:
		_transition(State.WANDER)

func _tick_chase(delta: float) -> void:
	if not is_instance_valid(_target):
		_target = null
		_transition(State.ALERTED)
		return
	HordeMemory.update_player_position(_target.global_position)
	var dist := global_position.distance_to(_target.global_position)
	if dist <= ATTACK_RANGE:
		_transition(State.ATTACK)
		return
	if dist >= CALL_HORDE_DIST:
		_transition(State.CALL_HORDE)
		return
	_navigate_toward(_target.global_position, delta)

func _tick_attack(delta: float) -> void:
	if not is_instance_valid(_target):
		_transition(State.CHASE)
		return
	var dist := global_position.distance_to(_target.global_position)
	if dist > ATTACK_RANGE * 1.3:
		_transition(State.CHASE)
		return
	look_at(_target.global_position)
	if _attack_timer <= 0.0:
		if _target.has_method("take_damage"):
			_target.take_damage(ATTACK_DAMAGE)
		_attack_timer = ATTACK_COOLDOWN

func _tick_call_horde(_delta: float) -> void:
	if is_instance_valid(_target):
		_transition(State.CHASE)
	else:
		_transition(State.ALERTED)

func _navigate_toward(world_pos: Vector2, delta: float) -> void:
	var dist := global_position.distance_to(world_pos)
	if dist < 90.0:
		_motor.seek(world_pos, delta)
	else:
		if _path_timer <= 0.0:
			_path_timer = PATH_REFRESH_T
			var nav: NavGrid = get_tree().get_first_node_in_group("nav_grid")
			if nav:
				_current_path = nav.find_path(global_position, world_pos)
		_motor.follow_path(_current_path, delta)

	var peers := get_tree().get_nodes_in_group("enemies")
	var flock_vel := _flocking.compute(self, peers)
	velocity += flock_vel * 40.0 * delta
	velocity = velocity.limit_length(_motor.max_speed)

func _apply_flocking_and_move(delta: float) -> void:
	var peers := get_tree().get_nodes_in_group("enemies")
	var flock_vel := _flocking.compute(self, peers)
	_motor.wander(delta)
	velocity += flock_vel * 40.0 * delta
	velocity = velocity.limit_length(_motor.max_speed)

func _get_all_targets() -> Array:
	var targets: Array = []
	targets.append_array(get_tree().get_nodes_in_group("players"))
	targets.append_array(get_tree().get_nodes_in_group("survivors"))
	targets = targets.filter(func(n): return is_instance_valid(n))
	return targets

func _transition(new_state: State) -> void:
	state = new_state

func _on_horde_alerted(_pos: Vector2) -> void:
	if state == State.WANDER:
		_transition(State.ALERTED)

func take_damage(amount: int) -> void:
	health = clampi(health - amount, 0, max_health)
	_health_bar.value = health
	HordeMemory.trigger_alert(global_position)
	if health <= 0:
		_die()

func get_health_ratio() -> float:
	return float(health) / float(max_health)

func _die() -> void:
	state = State.DEAD
	GameManager.on_enemy_killed()
	queue_free()
