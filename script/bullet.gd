class_name Bullet
extends Area2D

var speed: float = 500.0
var damage: int = 0
var direction: Vector2 = Vector2.ZERO
var _lifetime: float = 1.2

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()