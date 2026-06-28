extends Node2D

@export var zombie_scene: PackedScene
@export var survivor_count: int = 3

@onready var _nav_grid_node: NavGrid = $NavGrid
@onready var _player:        Player  = $Player

const _WORLD_SCENE := preload("res://scene/world.tscn")

func _ready() -> void:
	var world := _WORLD_SCENE.instantiate()
	add_child(world)
	move_child(world, 0)

	var surv_scene := preload("res://scene/survivor.tscn")
	for i in survivor_count:
		var s: Node = surv_scene.instantiate()
		add_child(s)
		var angle := TAU * i / survivor_count
		(s as Node2D).global_position = _player.global_position + Vector2.from_angle(angle) * 80.0

	var spawn_points: Array[Node2D] = []
	for sp in get_children():
		if sp.name.begins_with("SpawnPoint"):
			spawn_points.append(sp as Node2D)

	if zombie_scene:
		WaveManager.init(self, zombie_scene, spawn_points)