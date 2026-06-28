## Autoload — radio commentary. Uses llama.cpp if installed, fallback messages otherwise.
extends Node

signal commentary_ready(text: String)

const LLAMA_PATH := "C:/llama/llama-cli.exe"
const MODEL_PATH := "C:/llama/models/phi-2.Q4_K_M.gguf"
const MAX_TOKENS := 60

var _is_busy: bool = false

const _WAVE_START_LINES := [
	"Attention ! Une horde approche, restez groupés !",
	"Zombies détectés à l'horizon, préparez vos armes !",
	"La horde arrive, ne les laissez pas vous encercler !",
	"Contact ! Vague ennemie en approche !",
]

const _WAVE_END_GOOD := [
	"Bien joué, vague éliminée. Profitez-en pour souffler.",
	"Zone sécurisée temporairement. Rechargez vos armes.",
	"Excellent travail, survivants. Tenez bon.",
]

const _WAVE_END_BAD := [
	"Vous avez survécu de justesse... La prochaine sera pire.",
	"Trop de dégâts reçus. Restez mobiles !",
	"La horde vous a coûté cher. Soyez plus prudents.",
]

func comment_wave_start(wave: int, count: int) -> void:
	var line: String = _WAVE_START_LINES[(wave - 1) % _WAVE_START_LINES.size()]
	var text := "[Vague %d] %d zombies — %s" % [wave, count, line]
	if FileAccess.file_exists(LLAMA_PATH):
		var prompt := "[Radio static] Wave %d incoming! %d zombies spotted. Brief survival tip in one sentence:" % [wave, count]
		_generate_async(prompt)
	else:
		commentary_ready.emit(text)

func comment_wave_end(wave: int, perf: float) -> void:
	var lines := _WAVE_END_GOOD if perf > 0.4 else _WAVE_END_BAD
	var text: String = lines[wave % lines.size()]
	if FileAccess.file_exists(LLAMA_PATH):
		var rating := "good" if perf > 0.6 else ("average" if perf > 0.3 else "poor")
		var prompt := "[Radio static] Wave %d cleared. Survivor performance: %s. Encouraging comment in one sentence:" % [wave, rating]
		_generate_async(prompt)
	else:
		commentary_ready.emit(text)

func comment_player_low_health() -> void:
	if FileAccess.file_exists(LLAMA_PATH):
		_generate_async("[Radio static] Survivor critically injured! One urgent warning:")
	else:
		commentary_ready.emit("Survivant blessé ! Reculez et couvrez-vous !")

func _generate_async(prompt: String) -> void:
	if _is_busy:
		return
	_is_busy = true
	var thread := Thread.new()
	thread.start(_run_llm.bind(prompt, thread))

func _run_llm(prompt: String, thread: Thread) -> void:
	var output: Array = []
	var args := [
		"-m", MODEL_PATH,
		"-p", prompt,
		"-n", str(MAX_TOKENS),
		"--temp", "0.8",
		"--no-display-prompt",
		"-c", "512"
	]
	var exit_code := OS.execute(LLAMA_PATH, args, output, true, false)
	var text := ""
	if exit_code == 0 and output.size() > 0:
		text = (output[0] as String).strip_edges()
	else:
		text = "[Radio] No signal..."
	call_deferred("_on_llm_done", text, thread)

func _on_llm_done(text: String, thread: Thread) -> void:
	thread.wait_to_finish()
	_is_busy = false
	commentary_ready.emit(text)
	print("[LLM Radio] ", text)