extends CanvasLayer

func _ready() -> void:
	GameManager.game_over_triggered.connect(_show)
	$Panel/VBox/RestartButton.pressed.connect(_restart)

func _show() -> void:
	visible = true
	$Panel/VBox/ScoreLabel.text = "Score: %d" % GameManager.score
	get_tree().paused = true

func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
