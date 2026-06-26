class_name HUD
extends CanvasLayer

@onready var _health_label: Label = $MarginContainer/VBoxContainer/HBoxTop/HealthLabel
@onready var _wave_label:   Label = $MarginContainer/VBoxContainer/HBoxTop/WaveLabel
@onready var _score_label:  Label = $MarginContainer/VBoxContainer/HBoxTop/ScoreLabel
@onready var _radio_label:  Label = $MarginContainer/VBoxContainer/RadioLabel

var _radio_timer: float = 0.0
const RADIO_DISPLAY_DURATION := 8.0

func _ready() -> void:
	GameManager.score_changed.connect(_on_score)
	WaveManager.wave_started.connect(_on_wave_start)
	LLMRadio.commentary_ready.connect(_on_radio)

func _process(delta: float) -> void:
	if _radio_timer > 0.0:
		_radio_timer -= delta
		if _radio_timer <= 0.0:
			_radio_label.text = ""

	var players := get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		var p := players[0] as Player
		_health_label.text = "HP: %d / %d" % [p.health, p.max_health]

func _on_score(score: int) -> void:
	_score_label.text = "Score: %d" % score

func _on_wave_start(wave: int, count: int) -> void:
	_wave_label.text = "Vague: %d  (%d zombies)" % [wave, count]

func _on_radio(text: String) -> void:
	_radio_label.text = "[Radio] " + text
	_radio_timer = RADIO_DISPLAY_DURATION
