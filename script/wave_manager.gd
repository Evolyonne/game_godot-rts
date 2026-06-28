## Autoload — spawns adaptive zombie waves.
## Difficulty adjusts based on GameManager.performance_score.
extends Node

signal wave_started(wave_number: int, zombie_count: int)
signal wave_ended(wave_number: int)

const BASE_ZOMBIES   := 12
const WAVE_DELAY     := 5.0
const SPAWN_INTERVAL := 0.3

var current_wave: int = 0
var zombies_this_wave: int = 0
var zombies_alive: int = 0
var _spawn_queue: int = 0
var _spawn_timer: float = 0.0
var _wave_timer: float = 0.0
var _wave_active: bool = false
var _scene_root: Node
var _zombie_scene: PackedScene
var _spawn_node_refs: Array[Node2D] = []

func _ready() -> void:
	GameManager.wave_performance_updated.connect(_on_performance_updated)

func init(scene_root: Node, z_scene: PackedScene, points: Array[Node2D]) -> void:
	_scene_root = scene_root
	_zombie_scene = z_scene
	_spawn_node_refs = points
	_wave_timer = 2.0  # short delay before first wave

func _process(delta: float) -> void:
	if GameManager.is_game_over or _scene_root == null:
		return

	if _wave_active:
		_tick_spawn(delta)
		if _spawn_queue == 0 and zombies_alive == 0:
			_end_wave()
	else:
		_wave_timer -= delta
		if _wave_timer <= 0.0:
			_start_next_wave()

func _start_next_wave() -> void:
	current_wave += 1
	zombies_this_wave = _calculate_zombie_count()
	zombies_alive = zombies_this_wave
	_spawn_queue = zombies_this_wave
	_wave_active = true
	wave_started.emit(current_wave, zombies_this_wave)
	LLMRadio.comment_wave_start(current_wave, zombies_this_wave)

func _calculate_zombie_count() -> int:
	var perf := GameManager.performance_score
	# Player doing well → more zombies; struggling → fewer
	var difficulty_mult := lerpf(0.7, 1.5, perf)
	var count := int(BASE_ZOMBIES * difficulty_mult + current_wave * 2)
	return clampi(count, 3, 40)

func _tick_spawn(delta: float) -> void:
	if _spawn_queue <= 0:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = SPAWN_INTERVAL
		_spawn_zombie()
		_spawn_queue -= 1

func _spawn_zombie() -> void:
	if _zombie_scene == null or _scene_root == null:
		return
	var point := _pick_spawn_point()
	var z: Node = _zombie_scene.instantiate()
	_scene_root.add_child(z)
	(z as Node2D).global_position = point
	z.tree_exited.connect(_on_zombie_died)

func _on_zombie_died() -> void:
	zombies_alive = maxi(zombies_alive - 1, 0)

func _end_wave() -> void:
	_wave_active = false
	_wave_timer = WAVE_DELAY
	GameManager.evaluate_wave_performance(zombies_this_wave)
	wave_ended.emit(current_wave)
	LLMRadio.comment_wave_end(current_wave, GameManager.performance_score)

func _pick_spawn_point() -> Vector2:
	if _spawn_node_refs.is_empty():
		return Vector2(randf_range(-400, 400), randf_range(-400, 400))
	return _spawn_node_refs[randi() % _spawn_node_refs.size()].global_position

func _on_performance_updated(_score: float) -> void:
	pass
