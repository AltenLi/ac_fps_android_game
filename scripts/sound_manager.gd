extends Node

## 音乐/音效管理器 — 用 GDScript 代码生成原创音乐与音效，不需要任何外部音频文件
##
## 使用方式：
##   SoundManager.play_menu_music()
##   SoundManager.play_combat_music()
##   SoundManager.play_shot("m416")
##   SoundManager.play_shot("barrett")
##   SoundManager.play_shot("rpg")
##   SoundManager.play_explosion()
##   SoundManager.play_reload()
##   SoundManager.play_empty_click()
##   SoundManager.play_pickup()
##   SoundManager.play_hurt()
##   SoundManager.play_death()
##   SoundManager.play_victory()
##   SoundManager.play_defeat()

const SAMPLE_RATE: int = 22050
const MAX_CHANNELS: int = 8  ## 最多同时播放几个音效（防止太多声音叠加）
const GUNSHOT_NEAR_DISTANCE := 3.0
const GUNSHOT_FAR_DISTANCE := 72.0
const ENABLE_MUSIC := true
## Android 上避免使用 AudioStreamWAV 原生循环，改为单段播放结束后重启，降低 OpenSL/AudioTrack 风险。
const ENABLE_ANDROID_LOOPING_BGM := false
const ENABLE_FOOTSTEP_SFX := false
const EMPTY_CLICK_MIN_INTERVAL_MSEC := 180

var _pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0
var _bgm_player: AudioStreamPlayer = null
var _stream_cache: Dictionary = {}
var _last_empty_click_msec := -999999
var _music_key := ""


func _ready() -> void:
	## 创建音效播放器池
	for i in MAX_CHANNELS:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_pool.append(player)

	## 创建独立的音乐播放器（不占用音效池）
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	_bgm_player.volume_db = -10.0
	_bgm_player.finished.connect(_on_music_finished)
	add_child(_bgm_player)


# ---------------------------------------------------------------------------
# 公开接口
# ---------------------------------------------------------------------------

func play_shot(weapon_id: String, source_position: Vector3 = Vector3.ZERO, spatialized: bool = false) -> void:
	var volume_db := _gunshot_volume_db(weapon_id, source_position, spatialized)
	match weapon_id:
		"m416":
			_play_stream(_get_cached_stream("m416_shot"), volume_db)
		"barrett":
			_play_stream(_get_cached_stream("barrett_shot"), volume_db)
		"rpg":
			_play_stream(_get_cached_stream("rpg_shot"), volume_db)
		_:
			_play_stream(_get_cached_stream("m416_shot"), volume_db)


func play_explosion() -> void:
	_play_stream(_get_cached_stream("explosion"))


func play_reload() -> void:
	_play_stream(_get_cached_stream("reload"))


func play_empty_click() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_empty_click_msec < EMPTY_CLICK_MIN_INTERVAL_MSEC:
		return
	_last_empty_click_msec = now
	_play_stream(_get_cached_stream("empty_click"))


func play_pickup() -> void:
	_play_stream(_get_cached_stream("pickup"))


func play_hurt() -> void:
	_play_stream(_get_cached_stream("hurt"))


func play_death() -> void:
	_play_stream(_get_cached_stream("death"))


func play_victory() -> void:
	_play_stream(_get_cached_stream("victory"))


func play_defeat() -> void:
	_play_stream(_get_cached_stream("defeat"))


func play_footstep() -> void:
	if not ENABLE_FOOTSTEP_SFX:
		return
	_play_stream(_get_cached_stream("footstep"))


func play_menu_music() -> void:
	_play_music("menu_music", -13.0)


func play_combat_music() -> void:
	_play_music("combat_music", -9.5)


func play_bgm() -> void:
	play_combat_music()


func stop_bgm() -> void:
	stop_music()


func stop_music() -> void:
	_music_key = ""
	if _bgm_player != null:
		_bgm_player.stop()


func _play_music(key: String, volume_db: float) -> void:
	if not ENABLE_MUSIC or _bgm_player == null:
		return
	if _music_key == key and _bgm_player.playing:
		return
	if _bgm_player.playing:
		_bgm_player.stop()
	_music_key = key
	var music := _get_cached_stream(key)
	_configure_music_loop(music)
	_bgm_player.volume_db = volume_db
	_bgm_player.stream = music
	_bgm_player.play()


func _configure_music_loop(music: AudioStreamWAV) -> void:
	if music == null:
		return
	if OS.has_feature("android") and not ENABLE_ANDROID_LOOPING_BGM:
		music.loop_mode = AudioStreamWAV.LOOP_DISABLED
		return
	music.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music.loop_begin = 0
	music.loop_end = int(music.data.size() / 2.0)  ## 16-bit = 2 bytes per sample


func _on_music_finished() -> void:
	if _music_key == "" or _bgm_player == null:
		return
	## Android 禁用 WAV 原生循环时，播放完一段后重启同一 stream，避免使用 LOOP_FORWARD。
	if OS.has_feature("android") and not ENABLE_ANDROID_LOOPING_BGM:
		_bgm_player.call_deferred("play")


# ---------------------------------------------------------------------------
# 内部：播放器池
# ---------------------------------------------------------------------------

func _get_cached_stream(key: String) -> AudioStreamWAV:
	if _stream_cache.has(key):
		return _stream_cache[key]
	var stream: AudioStreamWAV
	match key:
		"m416_shot":
			stream = _make_m416_shot()
		"barrett_shot":
			stream = _make_barrett_shot()
		"rpg_shot":
			stream = _make_rpg_shot()
		"explosion":
			stream = _make_explosion()
		"footstep":
			stream = _make_footstep()
		"reload":
			stream = _make_reload()
		"empty_click":
			stream = _make_empty_click()
		"pickup":
			stream = _make_pickup()
		"hurt":
			stream = _make_hurt()
		"death":
			stream = _make_death()
		"victory":
			stream = _make_victory()
		"defeat":
			stream = _make_defeat()
		"menu_music":
			stream = _make_menu_music()
		"combat_music", "bgm":
			stream = _make_combat_music()
		_:
			stream = _make_empty_click()
	_stream_cache[key] = stream
	return stream

func _play_stream(stream: AudioStreamWAV, volume_db: float = 0.0) -> void:
	if stream == null or _pool.is_empty():
		return
	var player := _pool[_pool_index]
	_pool_index = (_pool_index + 1) % MAX_CHANNELS
	if player.playing:
		player.stop()
	player.volume_db = volume_db
	player.stream = stream
	player.play()


func _gunshot_volume_db(weapon_id: String, source_position: Vector3, spatialized: bool) -> float:
	var base_db := 0.0
	match weapon_id:
		"m416":
			base_db = -1.0
		"barrett":
			base_db = 1.5
		"rpg":
			base_db = 0.5
	if not spatialized:
		return base_db
	var listener := _get_listener_position()
	var distance := source_position.distance_to(listener)
	var t := clampf((distance - GUNSHOT_NEAR_DISTANCE) / (GUNSHOT_FAR_DISTANCE - GUNSHOT_NEAR_DISTANCE), 0.0, 1.0)
	var attenuation_db := lerpf(0.0, -24.0, pow(t, 0.72))
	return clampf(base_db + attenuation_db, -28.0, 2.0)


func _get_listener_position() -> Vector3:
	var viewport := get_viewport()
	if viewport != null:
		var camera := viewport.get_camera_3d()
		if camera != null:
			return camera.global_position
	var scene := get_tree().current_scene if get_tree() != null else null
	if scene is Node3D:
		return (scene as Node3D).global_position
	return Vector3.ZERO


# ---------------------------------------------------------------------------
# 内部：波形生成工具
# ---------------------------------------------------------------------------

## 把浮点数样本（-1.0 ~ 1.0）转成 AudioStreamWAV
func _make_wav(samples: PackedFloat32Array, stereo: bool = false) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = stereo
	wav.format = AudioStreamWAV.FORMAT_16_BITS

	var byte_array := PackedByteArray()
	byte_array.resize(samples.size() * 2)
	for i in samples.size():
		var s := clampf(samples[i], -1.0, 1.0)
		var v := int(s * 32767.0)
		byte_array[i * 2]     = v & 0xFF
		byte_array[i * 2 + 1] = (v >> 8) & 0xFF
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_array
	return wav


## 生成线性包络（攻击-衰减-延音-释放）
func _envelope(t: float, attack: float, decay: float, sustain: float,
		release_start: float, total: float) -> float:
	if t < attack:
		return t / attack
	elif t < attack + decay:
		return 1.0 - (t - attack) / decay * (1.0 - sustain)
	elif t < release_start:
		return sustain
	else:
		return sustain * (1.0 - (t - release_start) / (total - release_start))


# ---------------------------------------------------------------------------
# 具体音效合成
# ---------------------------------------------------------------------------

func _make_m416_shot() -> AudioStreamWAV:
	## M416：更真实的短自动步枪声 = 枪口爆裂 + 机械金属感 + 远端短尾音。
	var duration := 0.22
	var n := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 101
	for i in n:
		var t := float(i) / SAMPLE_RATE
		var crack_env := exp(-t * 58.0)
		var body_env := exp(-t * 18.0)
		var tail_env := exp(-maxf(t - 0.028, 0.0) * 10.0)
		var noise := rng.randf_range(-1.0, 1.0)
		var low_body := sin(TAU * (145.0 - t * 90.0) * t) * body_env * 0.34
		var mid_snap := sin(TAU * 760.0 * t) * crack_env * 0.20
		var metal := sin(TAU * 1850.0 * t) * exp(-t * 95.0) * 0.10
		var tail := rng.randf_range(-1.0, 1.0) * tail_env * 0.12
		samples[i] = clampf(noise * crack_env * 0.72 + low_body + mid_snap + metal + tail, -1.0, 1.0) * 0.82
	return _make_wav(samples)


func _make_barrett_shot() -> AudioStreamWAV:
	## 巴雷特：重狙枪声 = 低频冲击 + 尖锐枪口裂响 + 更长空气回响。
	var duration := 0.55
	var n := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 202
	for i in n:
		var t := float(i) / SAMPLE_RATE
		var blast_env := exp(-t * 34.0)
		var boom_env := exp(-t * 7.0)
		var echo_env := exp(-maxf(t - 0.055, 0.0) * 5.0)
		var noise := rng.randf_range(-1.0, 1.0)
		var sub := sin(TAU * (72.0 - t * 35.0) * t) * boom_env * 0.62
		var crack := sin(TAU * 520.0 * t) * blast_env * 0.34
		var snap := rng.randf_range(-1.0, 1.0) * blast_env * 0.55
		var echo := rng.randf_range(-1.0, 1.0) * echo_env * 0.10
		samples[i] = clampf(sub + crack + snap + echo + noise * blast_env * 0.16, -1.0, 1.0) * 0.90
	return _make_wav(samples)


func _make_rpg_shot() -> AudioStreamWAV:
	## RPG 发射：助推火箭喷气 + 低频冲击 + 滑动尾音。
	var duration := 0.42
	var n := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 303
	for i in n:
		var t := float(i) / SAMPLE_RATE
		var blast_env := exp(-t * 18.0)
		var motor_env := _envelope(t, 0.012, 0.12, 0.35, 0.26, duration)
		var noise := rng.randf_range(-1.0, 1.0)
		var thump := sin(TAU * (95.0 - t * 55.0) * t) * blast_env * 0.45
		var motor_freq := 190.0 - t * 240.0
		var motor := sin(TAU * maxf(motor_freq, 42.0) * t) * motor_env * 0.32
		var flame := noise * motor_env * 0.30
		samples[i] = clampf(thump + motor + flame + noise * blast_env * 0.25, -1.0, 1.0) * 0.78
	return _make_wav(samples)


func _make_explosion() -> AudioStreamWAV:
	## 爆炸：低频轰鸣 + 噪声爆破
	var duration := 0.8
	var n := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)

	var rng := RandomNumberGenerator.new()
	rng.seed = 404

	for i in n:
		var t := float(i) / SAMPLE_RATE
		## 快速攻击，缓慢衰减
		var env: float
		if t < 0.01:
			env = t / 0.01
		else:
			env = pow(1.0 - (t - 0.01) / (duration - 0.01), 2.0)
		var noise := rng.randf_range(-1.0, 1.0)
		var rumble := sin(TAU * 55.0 * t) * 0.5
		var mid := sin(TAU * 180.0 * t) * 0.3
		samples[i] = (noise * 0.6 + rumble + mid) * env
	return _make_wav(samples)


func _make_reload() -> AudioStreamWAV:
	## 换弹匣：两声噪声机械咔哒，避免高频纯音蜂鸣
	var duration := 0.3
	var n := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)

	var rng := RandomNumberGenerator.new()
	rng.seed = 505

	for i in n:
		var t := float(i) / SAMPLE_RATE
		var click1 := 0.0
		if t < 0.04:
			var env1 := _envelope(t, 0.002, 0.028, 0.0, 0.01, 0.04)
			click1 = rng.randf_range(-1.0, 1.0) * env1 * 0.28

		var click2 := 0.0
		var t2 := t - 0.18
		if t2 >= 0.0 and t2 < 0.05:
			var env2 := _envelope(t2, 0.002, 0.035, 0.0, 0.01, 0.05)
			click2 = rng.randf_range(-1.0, 1.0) * env2 * 0.24

		samples[i] = clampf(click1 + click2, -1.0, 1.0)
	return _make_wav(samples)


func _make_empty_click() -> AudioStreamWAV:
	## 空仓：短促机械咔哒，去掉高频纯音避免蜂鸣
	var duration := 0.045
	var n := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 909

	for i in n:
		var t := float(i) / SAMPLE_RATE
		var env := _envelope(t, 0.001, 0.03, 0.0, 0.008, duration)
		samples[i] = rng.randf_range(-1.0, 1.0) * env * 0.22
	return _make_wav(samples)


func _make_pickup() -> AudioStreamWAV:
	## 拾取弹药：短促低噪声提示，去掉叮叮纯音
	var duration := 0.12
	var n := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1001

	for i in n:
		var t := float(i) / SAMPLE_RATE
		var env := _envelope(t, 0.004, 0.06, 0.0, 0.04, duration)
		samples[i] = rng.randf_range(-1.0, 1.0) * env * 0.18
	return _make_wav(samples)


func _make_hurt() -> AudioStreamWAV:
	## 受伤：短促低频冲击
	var duration := 0.15
	var n := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)

	var rng := RandomNumberGenerator.new()
	rng.seed = 606

	for i in n:
		var t := float(i) / SAMPLE_RATE
		var env := _envelope(t, 0.003, 0.05, 0.0, 0.05, duration)
		var noise := rng.randf_range(-1.0, 1.0)
		var tone := sin(TAU * 160.0 * t) * 0.4
		samples[i] = (noise * 0.5 + tone) * env * 0.7
	return _make_wav(samples)


func _make_death() -> AudioStreamWAV:
	## 死亡：低沉下降音调
	var duration := 0.6
	var n := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)

	var rng := RandomNumberGenerator.new()
	rng.seed = 707

	for i in n:
		var t := float(i) / SAMPLE_RATE
		var env: float
		if t < 0.6:
			env = pow(1.0 - t / 0.6, 1.5)
		else:
			env = 0.0
		## 频率从 300Hz 降到 80Hz
		var freq := 300.0 - t * 366.0
		freq = maxf(freq, 80.0)
		var tone := sin(TAU * freq * t)
		var noise := rng.randf_range(-1.0, 1.0) * 0.2
		samples[i] = (tone * 0.8 + noise) * env * 0.7
	return _make_wav(samples)


func _make_victory() -> AudioStreamWAV:
	## 胜利：三个上升音符（DO-MI-SOL）
	var duration := 0.7
	var n := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)

	## 音符频率：C5=523Hz, E5=659Hz, G5=784Hz
	var notes: Array[float] = [523.0, 659.0, 784.0]
	var note_len := 0.2
	var gap := 0.03

	for i in n:
		var t := float(i) / SAMPLE_RATE
		var val := 0.0
		for ni in notes.size():
			var t_start := ni * (note_len + gap)
			var t_local := t - t_start
			if t_local >= 0.0 and t_local < note_len:
				var env := _envelope(t_local, 0.01, 0.05, 0.7, note_len * 0.7, note_len)
				val += sin(TAU * notes[ni] * t_local) * env * 0.4
				## 加泛音增加亮度
				val += sin(TAU * notes[ni] * 2.0 * t_local) * env * 0.15
		samples[i] = clampf(val, -1.0, 1.0)
	return _make_wav(samples)


func _make_defeat() -> AudioStreamWAV:
	## 失败：两个下降音符（SOL-MI）
	var duration := 0.6
	var n := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)

	var notes: Array[float] = [392.0, 311.0]  # G4, Eb4
	var note_len := 0.25
	var gap := 0.02

	for i in n:
		var t := float(i) / SAMPLE_RATE
		var val := 0.0
		for ni in notes.size():
			var t_start := ni * (note_len + gap)
			var t_local := t - t_start
			if t_local >= 0.0 and t_local < note_len:
				var env := _envelope(t_local, 0.01, 0.08, 0.5, note_len * 0.6, note_len)
				val += sin(TAU * notes[ni] * t_local) * env * 0.45
		samples[i] = clampf(val, -1.0, 1.0)
	return _make_wav(samples)


func _make_footstep() -> AudioStreamWAV:
	## 脚步声：低频冲击 + 短暂沙沙噪声，模拟混凝土地面
	var duration := 0.085
	var n := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)

	var rng := RandomNumberGenerator.new()
	## 每次调用随机种子，让每步声音略有不同
	rng.seed = randi()

	for i in n:
		var t := float(i) / SAMPLE_RATE
		var env := _envelope(t, 0.002, 0.03, 0.0, 0.03, duration)
		var thud := sin(TAU * 90.0 * t) * 0.55   ## 低频撞击
		var scrape := rng.randf_range(-1.0, 1.0) * 0.35  ## 地面摩擦噪声
		samples[i] = (thud + scrape) * env * 0.65
	return _make_wav(samples)


func _make_menu_music() -> AudioStreamWAV:
	## 菜单音乐：原创冷静电子氛围，低音量循环，适合首页/地图/设置界面。
	var bpm := 96.0
	var beat := 60.0 / bpm
	var bar := beat * 4.0
	var loop_bars := 4
	var duration := bar * loop_bars
	var n := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var chords: Array[Array] = [
		[146.83, 220.00, 277.18],
		[164.81, 246.94, 329.63],
		[130.81, 196.00, 261.63],
		[174.61, 261.63, 349.23],
	]
	for i in n:
		var t := float(i) / SAMPLE_RATE
		var bar_index := int(t / bar) % chords.size()
		var bar_phase := fmod(t, bar)
		var env := _envelope(bar_phase, 0.18, 0.45, 0.72, bar * 0.72, bar)
		var val := 0.0
		var chord: Array = chords[bar_index]
		for freq_value in chord:
			var freq := float(freq_value)
			val += sin(TAU * freq * t) * 0.12
			val += sin(TAU * freq * 2.0 * t) * 0.025
		var pulse_phase := fmod(t, beat)
		if pulse_phase < 0.055:
			var pulse_env := _envelope(pulse_phase, 0.006, 0.040, 0.0, 0.025, 0.055)
			val += sin(TAU * 72.0 * pulse_phase) * pulse_env * 0.20
		samples[i] = clampf(val * env * 0.52, -1.0, 1.0)
	return _make_wav(samples)


func _make_combat_music() -> AudioStreamWAV:
	## 战斗 BGM：原创 4 小节循环，鼓点 + 低音贝斯 + 旋律线
	## 节拍：120 BPM，4/4 拍，每小节 2 秒，共 4 小节 = 8 秒循环
	var bpm := 120.0
	var beat := 60.0 / bpm          ## 0.5 秒一拍
	var bar := beat * 4.0           ## 2 秒一小节
	var loop_bars := 4
	var duration := bar * loop_bars  ## 8 秒
	var n := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)

	var rng := RandomNumberGenerator.new()
	rng.seed = 888

	## 低音贝斯音符序列（每小节 4 拍的根音）
	## 音符：A2=110, D3=147, E3=165, G3=196
	var bass_pattern: Array[float] = [110.0, 110.0, 147.0, 165.0,
									  110.0, 110.0, 196.0, 165.0,
									  147.0, 147.0, 165.0, 165.0,
									  110.0, 165.0, 196.0, 110.0]

	## 旋律线（每拍一个音，0 = 静音）
	var melody_pattern: Array[float] = [
		440.0, 0.0, 523.0, 0.0,   494.0, 0.0, 440.0, 523.0,
		587.0, 0.0, 523.0, 0.0,   494.0, 440.0, 0.0, 494.0,
		440.0, 0.0, 494.0, 523.0, 440.0, 0.0, 392.0, 0.0,
		440.0, 523.0, 0.0, 587.0, 523.0, 0.0, 494.0, 440.0
	]

	for i in n:
		var t := float(i) / SAMPLE_RATE
		var val := 0.0

		## ── 鼓点 ──────────────────────────────────────────────────
		var beat_phase := fmod(t, beat)
		var beat_index := int(t / beat) % 8

		## 底鼓：每小节第 1、3 拍（beat 0 和 2）
		if beat_index % 2 == 0 and beat_phase < 0.12:
			var env := _envelope(beat_phase, 0.002, 0.05, 0.0, 0.05, 0.12)
			var kick_freq := 80.0 - beat_phase * 300.0
			val += sin(TAU * maxf(kick_freq, 40.0) * beat_phase) * env * 0.7
			val += rng.randf_range(-1.0, 1.0) * env * 0.15

		## 军鼓：每小节第 2、4 拍（beat 1 和 3）
		if beat_index % 2 == 1 and beat_phase < 0.1:
			var env := _envelope(beat_phase, 0.001, 0.04, 0.0, 0.04, 0.1)
			val += rng.randf_range(-1.0, 1.0) * env * 0.5
			val += sin(TAU * 200.0 * beat_phase) * env * 0.2

		## 踩镲：每半拍（八分音符）
		var hihat_phase := fmod(t, beat * 0.5)
		if hihat_phase < 0.025:
			var env := _envelope(hihat_phase, 0.001, 0.024, 0.0, 0.01, 0.025)
			val += rng.randf_range(-1.0, 1.0) * env * 0.18

		## ── 低音贝斯 ──────────────────────────────────────────────
		var bass_beat_idx := int(t / beat) % bass_pattern.size()
		var bass_freq := bass_pattern[bass_beat_idx]
		var bass_phase := fmod(t, beat)
		var bass_env := _envelope(bass_phase, 0.01, 0.1, 0.6, beat * 0.8, beat)
		val += sin(TAU * bass_freq * t) * bass_env * 0.35
		## 加一点失真感（平方波混合）
		val += clampf(sin(TAU * bass_freq * t) * 3.0, -1.0, 1.0) * bass_env * 0.08

		## ── 旋律线 ────────────────────────────────────────────────
		var melody_beat_idx := int(t / (beat * 0.5)) % melody_pattern.size()
		var melody_freq := melody_pattern[melody_beat_idx]
		if melody_freq > 0.0:
			var mel_phase := fmod(t, beat * 0.5)
			var mel_env := _envelope(mel_phase, 0.01, 0.05, 0.6, beat * 0.4, beat * 0.5)
			## 正弦 + 三次谐波让旋律更有质感
			val += sin(TAU * melody_freq * t) * mel_env * 0.22
			val += sin(TAU * melody_freq * 3.0 * t) * mel_env * 0.06

		samples[i] = clampf(val, -1.0, 1.0)

	return _make_wav(samples)


func _make_bgm() -> AudioStreamWAV:
	return _make_combat_music()
