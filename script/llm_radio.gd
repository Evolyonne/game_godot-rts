## Autoload — calls llama.cpp via OS.execute() to generate radio commentary.
## llama.cpp must be installed at the path below (no accents in path).
extends Node

signal commentary_ready(text: String)

const LLAMA_PATH := "C:/llama/llama-cli.exe"   # adjust to your install
const MODEL_PATH := "C:/llama/models/phi-2.Q4_K_M.gguf"
const MAX_TOKENS := 60

var _is_busy: bool = false

func comment_wave_start(wave: int, count: int) -> void:
	var prompt := "[Radio static] Wave %d incoming! %d zombies spotted. Brief survival tip in one sentence:" % [wave, count]
	_generate_async(prompt)

func comment_wave_end(wave: int, perf: float) -> void:
	var rating := "good" if perf > 0.6 else ("average" if perf > 0.3 else "poor")
	var prompt := "[Radio static] Wave %d cleared. Survivor performance: %s. Encouraging comment in one sentence:" % [wave, rating]
	_generate_async(prompt)

func comment_player_low_health() -> void:
	_generate_async("[Radio static] Survivor critically injured! One urgent warning:")

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
