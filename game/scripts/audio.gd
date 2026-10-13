class_name AnimalAudio
extends Node

var effects := AudioStreamPlayer.new()
var music_player := AudioStreamPlayer.new()
var enabled: bool = true
var music_enabled: bool = true

func _ready() -> void:
	add_child(effects)
	add_child(music_player)
	music_player.stream = melody()
	music_player.volume_db = -24
	music_player.finished.connect(func():
		if music_enabled:
			music_player.play())

func tone(frequency: float, duration: float = 0.15) -> void:
	if not enabled:
		return
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var data := PackedByteArray()
	data.resize(int(duration * 22050) * 2)
	for i in range(data.size() / 2):
		var t := float(i) / 22050
		var value := int(sin(t * frequency * TAU) * 8000 * sin(PI * t / duration))
		data.encode_s16(i * 2, value)
	wav.data = data
	effects.stream = wav
	effects.play()

func melody() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var notes := [261.63, 329.63, 392.0, 329.63, 293.66, 349.23, 440.0, 392.0, 329.63, 392.0, 523.25, 440.0, 349.23, 293.66, 329.63, 261.63]
	var samples := 22050 * 8
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var note_index := int(float(i) / 11025)
		var t := float(i % 11025) / 22050
		var value := int((sin(t * notes[note_index] * TAU) + 0.25 * sin(t * notes[note_index] * TAU * 2)) * 2400 * exp(-t * 7))
		data.encode_s16(i * 2, value)
	wav.data = data
	# Replay completed clips rather than using native PCM loop endpoints.
	# This avoids the engine's exclusive/inclusive loop-end overread on Android.
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return wav
