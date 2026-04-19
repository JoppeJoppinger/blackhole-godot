extends Node

# Synthesizes all game audio procedurally — no external audio files

var engine_player: AudioStreamPlayer
var thrust_player: AudioStreamPlayer
var alarm_player: AudioStreamPlayer
var stress_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var horizon_player: AudioStreamPlayer

var engine_pitch: float = 1.0
var engine_volume: float = -20.0

const SAMPLE_RATE: int = 22050

func _ready() -> void:
	_setup_players()
	_start_ambient()
	_start_engine()

func _setup_players() -> void:
	engine_player = AudioStreamPlayer.new()
	engine_player.name = "EnginePlayer"
	add_child(engine_player)

	thrust_player = AudioStreamPlayer.new()
	thrust_player.name = "ThrustPlayer"
	add_child(thrust_player)

	alarm_player = AudioStreamPlayer.new()
	alarm_player.name = "AlarmPlayer"
	add_child(alarm_player)

	stress_player = AudioStreamPlayer.new()
	stress_player.name = "StressPlayer"
	add_child(stress_player)

	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	add_child(ambient_player)

	horizon_player = AudioStreamPlayer.new()
	horizon_player.name = "HorizonPlayer"
	add_child(horizon_player)

func _generate_wav(frames: int, callback: Callable) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = frames
	var data = PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var t = float(i) / float(SAMPLE_RATE)
		var s = clamp(callback.call(i, t), -1.0, 1.0)
		var s16 = int(s * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	wav.data = data
	return wav

func generate_engine_hum() -> AudioStreamWAV:
	var dur = 2.0
	var frames = int(SAMPLE_RATE * dur)
	return _generate_wav(frames, func(i: int, t: float) -> float:
		var s = sin(TAU * 80.0 * t) * 0.40
		s += sin(TAU * 160.0 * t) * 0.20
		s += sin(TAU * 240.0 * t) * 0.10
		s += sin(TAU * 320.0 * t) * 0.05
		s += sin(TAU * 40.0 * t) * 0.15  # sub-harmonic rumble
		# slight noise
		s += (sin(t * 1337.7 + sin(t * 500.3)) * 0.5) * 0.04
		return s * 0.7
	)

func generate_thrust_sound() -> AudioStreamWAV:
	var dur = 1.5
	var frames = int(SAMPLE_RATE * dur)
	return _generate_wav(frames, func(i: int, t: float) -> float:
		var freq = 120.0 + sin(t * 3.0) * 40.0
		var s = sin(TAU * freq * t) * 0.3
		s += sin(TAU * freq * 2.0 * t) * 0.15
		s += sin(TAU * freq * 3.0 * t) * 0.07
		# white noise component
		s += (fmod(sin(t * 7919.0) * 43758.5, 1.0) * 2.0 - 1.0) * 0.12
		return s * 0.8
	)

func generate_proximity_alarm() -> AudioStreamWAV:
	var dur = 1.0
	var frames = int(SAMPLE_RATE * dur)
	return _generate_wav(frames, func(i: int, t: float) -> float:
		var pulse = float(int(t * 4.0) % 2)  # 4 beeps/sec
		var s = sin(TAU * 800.0 * t) * 0.6
		s += sin(TAU * 1200.0 * t) * 0.3  # minor third
		return s * pulse
	)

func generate_structural_stress() -> AudioStreamWAV:
	var dur = 3.0
	var frames = int(SAMPLE_RATE * dur)
	return _generate_wav(frames, func(i: int, t: float) -> float:
		# Low crackling/grinding
		var crack_phase = fmod(t * 37.3, TAU)
		var s = sin(crack_phase) * 0.2
		s += sin(TAU * 45.0 * t + sin(t * 7.0) * 5.0) * 0.3
		# grinding noise
		s += (fmod(sin(t * 3000.0) * 43758.5, 1.0) * 2.0 - 1.0) * 0.15
		s += sin(TAU * 22.0 * t) * 0.4  # deep resonance
		# crackling pops
		var pop = sin(t * 91.0)
		if pop > 0.98:
			s += (pop - 0.98) * 20.0
		return s * 0.6
	)

func generate_ambient_space() -> AudioStreamWAV:
	var dur = 4.0
	var frames = int(SAMPLE_RATE * dur)
	return _generate_wav(frames, func(i: int, t: float) -> float:
		# Very subtle low drone 20-40 Hz
		var s = sin(TAU * 22.0 * t) * 0.3
		s += sin(TAU * 33.0 * t + 0.7) * 0.2
		s += sin(TAU * 11.0 * t + 1.3) * 0.15
		s += sin(TAU * 17.0 * t + 2.1) * 0.1
		return s * 0.08  # nearly inaudible
	)

func generate_horizon_warning() -> AudioStreamWAV:
	var dur = 2.0
	var frames = int(SAMPLE_RATE * dur)
	return _generate_wav(frames, func(i: int, t: float) -> float:
		# Dramatic descending alarm
		var sweep = 600.0 - t * 200.0
		var pulse_env = (sin(t * TAU * 2.5) + 1.0) * 0.5
		var s = sin(TAU * sweep * t) * 0.5
		s += sin(TAU * sweep * 1.5 * t) * 0.3
		s += sin(TAU * sweep * 2.0 * t) * 0.15
		# dramatic bass thud
		s += sin(TAU * 55.0 * t) * 0.4 * exp(-t * 2.0)
		return s * pulse_env * 0.8
	)

func _start_engine() -> void:
	var wav = generate_engine_hum()
	engine_player.stream = wav
	engine_player.volume_db = -18.0
	engine_player.pitch_scale = 1.0
	engine_player.play()

	var wav2 = generate_ambient_space()
	ambient_player.stream = wav2
	ambient_player.volume_db = -30.0
	ambient_player.play()

func _start_ambient() -> void:
	pass  # started in _start_engine

func set_engine_thrust(thrust_factor: float, boosting: bool) -> void:
	# thrust_factor 0-1
	if boosting:
		engine_player.pitch_scale = lerp(engine_player.pitch_scale, 1.8, 0.05)
		engine_player.volume_db = lerp(engine_player.volume_db, -8.0, 0.05)
	elif thrust_factor > 0.05:
		engine_player.pitch_scale = lerp(engine_player.pitch_scale, 1.0 + thrust_factor * 0.4, 0.05)
		engine_player.volume_db = lerp(engine_player.volume_db, -18.0 + thrust_factor * 8.0, 0.05)
	else:
		engine_player.pitch_scale = lerp(engine_player.pitch_scale, 0.8, 0.02)
		engine_player.volume_db = lerp(engine_player.volume_db, -28.0, 0.02)

func play_proximity_alarm(active: bool) -> void:
	if active and not alarm_player.playing:
		alarm_player.stream = generate_proximity_alarm()
		alarm_player.volume_db = -6.0
		alarm_player.play()
	elif not active and alarm_player.playing:
		alarm_player.stop()

func set_structural_stress(stress_level: float) -> void:
	# stress_level 0-1
	if stress_level > 0.2:
		if not stress_player.playing:
			stress_player.stream = generate_structural_stress()
			stress_player.volume_db = -20.0
			stress_player.play()
		stress_player.volume_db = lerp(stress_player.volume_db, -20.0 + stress_level * 14.0, 0.05)
		stress_player.pitch_scale = 0.8 + stress_level * 0.6
	else:
		if stress_player.playing:
			stress_player.volume_db = lerp(stress_player.volume_db, -40.0, 0.05)
			if stress_player.volume_db < -38.0:
				stress_player.stop()

func play_horizon_warning(active: bool) -> void:
	if active and not horizon_player.playing:
		horizon_player.stream = generate_horizon_warning()
		horizon_player.volume_db = 0.0
		horizon_player.play()
