## A* navigation grid built from the TileMap at runtime.
class_name NavGrid
extends Node

const TILE_SIZE := 64

var _astar: AStarGrid2D
var _map_rect: Rect2i
var _tilemap: TileMap

func setup(tilemap: TileMap) -> void:
	_tilemap = tilemap
	_map_rect = tilemap.get_used_rect()

	_astar = AStarGrid2D.new()
	_astar.region = _map_rect
	_astar.cell_size = Vector2(TILE_SIZE, TILE_SIZE)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.update()

	_mark_physics_walls()

func _mark_physics_walls() -> void:
	if _tilemap == null:
		return
	for cell in _tilemap.get_used_cells(0):
		var td := _tilemap.get_cell_tile_data(0, cell)
		if td == null:
			continue
		# Tiles with collision polygons are walls
		if td.get_collision_polygons_count(0) > 0:
			_astar.set_point_solid(cell, true)

## Returns a world-space path from start to goal.
func find_path(from_world: Vector2, to_world: Vector2) -> Array[Vector2]:
	if _astar == null:
		return []
	var from_cell := world_to_cell(from_world)
	var to_cell   := world_to_cell(to_world)

	if _astar.is_in_boundsv(from_cell) and _astar.is_in_boundsv(to_cell):
		var cell_path := _astar.get_id_path(from_cell, to_cell)
		var world_path: Array[Vector2] = []
		for cp in cell_path:
			world_path.append(cell_to_world(cp))
		return world_path
	return []

func world_to_cell(world_pos: Vector2) -> Vector2i:
	return _tilemap.local_to_map(_tilemap.to_local(world_pos))

func cell_to_world(cell: Vector2i) -> Vector2:
	return _tilemap.to_global(_tilemap.map_to_local(cell))
