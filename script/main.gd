## Main scene orchestrator.
## Sets up A* nav grid and starts WaveManager.
extends Node2D

@export var zombie_scene: PackedScene
@export var survivor_count: int = 3

@onready var _tilemap:        TileMap = $TileMap
@onready var _nav_grid_node:  NavGrid = $NavGrid
@onready var _player:         Player  = $Player

func _ready() -> void:
	if _tilemap and _nav_grid_node:
		_nav_grid_node.setup(_tilemap)
		_nav_grid_node.add_to_group("nav_grid")

	var surv_scene := preload("res://scene/survivor.tscn")
	for i in survivor_count:
		var s: Node = surv_scene.instantiate()
		add_child(s)
		var angle := TAU * i / survivor_count
		(s as Node2D).global_position = _player.global_position + Vector2.from_angle(angle) * 60.0

	var spawn_points: Array[Node2D] = []
	for sp in get_children():
		if sp.name.begins_with("SpawnPoint"):
			spawn_points.append(sp as Node2D)

	if zombie_scene:
		WaveManager.init(self, zombie_scene, spawn_points)
