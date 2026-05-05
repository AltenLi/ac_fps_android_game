extends Node

## 音效管理器 — 用 GDScript 代码生成所有音效，不需要任何外部音频文件
##
## 使用方式：
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

var _pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0
var _bgm_player: AudioStreamPlayer = null


func _ready() -> void:
	## 创建音效播放器池
	for i in MAX_CHANNELS:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_pool.append(player)

	## 创建独立的 BGM 播放器（不占用音效池）
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	_bgm_player.volume_db = -6.0
	add_child(_bgm_player)


# ---------------------------------------------------------------------------
# 公开接口
# ---------------------------------------------------------------------------

func play_shot(weapon_id: String) -> void:
	match weapon_id:
		"m416":
			_play_stream(_make_m416_shot())
		"barrett":
			_play_stream(_make_barrett_shot())
		"rpg":
			_play_stream(_make_rpg_shot())
		_:
			_play_stream(_make_m416_shot())


func play_explosion() -> void:
	_play_stream(_make_explosion())


func play_reload() -> void:
	_play_stream(_make_reload())


func play_empty_click() -> void:
	_play_stream(_make_empty_click())


func play_pickup() -> void:
	_play_stream(_make_pickup())


func play_hurt() -> void:
	_play_stream(_make_hurt())


func play_death() -> void:
	_play_stream(_make_death())


func play_victory() -> void:
	_play_stream(_make_victory())


func play_defeat() -> void:
	_play_stream(_make_defeat())


func play_footstep() -> void:
	_play_stream(_make_footstep())


func play_bgm() -> void:
	## 开始循环播放战斗 BGM
	if _bgm_player.playing:
		return
	var bgm := _make_bgm()
	bgm.loop_mode = AudioStreamWAV.LOOP_FORWARD
	bgm.loop_begin = 0
	bgm.loop_end = bgm.data.size() / 2  ## 16-bit = 2 bytes per sample
	_bgm_player.stream = bgm
	_bgm_player.play()


func stop_bgm() -> void:
	_bgm_player.stop()


# ---------------------------------------------------------------------------
# 内部：播放器池
# ---------------------------------------------------------------------------

func _play_stream(stream: AudioStreamWAV) -> void:
	var player := _pool[_pool_index]
	_pool_index = (_pool_index + 1) % MAX_CHANNELS
	player.stream = stream
	player.play()


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
	## M416：快速清脆的枪声，短暂爆破 + 中频噪声
	var duration := 0.12
	var n := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)

	var rng := RandomNumberGenerator.new()
	rng.seed = 101

	for i in n:
		var t := float(i) / SAMPLE_RATE
		var env := _envelope(t, 0.001, 0.02, 0.0, 0.02, duration)
		## 白噪声 + 440Hz 瞬间音调让枪声有金属感
		var noise := rng.randf_range(-1.0, 1.0)
		var tone := sin(TAU * 440.0 * t) * 0.3
		samples[i] = (noise * 0.7 + tone) * env * 0.8
	return _make_wav(samples)


func _make_barrett_shot() -> AudioStreamWAV:
	## 巴雷特：低频重击 + 长尾衰减
	var duration := 0.35
	var n := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)

	var rng := RandomNumberGenerator.new()
	rng.seed = 202

	for i in n:
		var t := float(i) / SAMPLE_RATE
		var env := _envelope(t, 0.002, 0.05, 0.0, 0.05, duration)
		var noise := rng.randf_range(-1.0, 1.0)
		## 低频（80Hz）产生重击感
		var low := sin(TAU * 80.0 * t) * 0.6
		var crack := sin(TAU * 200.0 * t) * 0.4
		samples[i] = (noise * 0.4 + low + crack) * env
	return _make_wav(samples)


func _make_rpg_shot() -> AudioStreamWAV:
	## RPG 发射：低沉嗖嗖声
	var duration := 0.25
	var n := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)

	var rng := RandomNumberGenerator.new()
	rng.seed = 303

	for i in n:
		var t := float(i) / SAMPLE_RATE
		var env := _envelope(t, 0.01, 0.1, 0.2, 0.2, duration)
		var noise := rng.randf_range(-1.0, 1.0)
		## 频率随时间下滑（多普勒感）
		var freq := 120.0 - t * 80.0
		var whoosh := sin(TAU * freq * t) * 0.5
		samples[i] = (noise * 0.3 + whoosh) * env
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
	## 换弹匣：两声金属咔哒
	var duration := 0.3
	var n := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)

	var rng := RandomNumberGenerator.new()
	rng.seed = 505

	for i in n:
		var t := float(i) / SAMPLE_RATE
		## 第一声（弹匣取出）：t≈0.0
		## 第二声（弹匣插入）：t≈0.18
		var click1 := 0.0
		if t < 0.04:
			var env1 := _envelope(t, 0.002, 0.038, 0.0, 0.01, 0.04)
			click1 = (rng.randf_range(-1.0, 1.0) * 0.3 + sin(TAU * 900.0 * t) * 0.7) * env1

		var click2 := 0.0
		var t2 := t - 0.18
		if t2 >= 0.0 and t2 < 0.05:
			var env2 := _envelope(t2, 0.002, 0.048, 0.0, 0.01, 0.05)
			click2 = (rng.randf_range(-1.0, 1.0) * 0.2 + sin(TAU * 700.0 * t2) * 0.8) * env2

		samples[i] = clampf(click1 + click2, -1.0, 1.0)
	return _make_wav(samples)


func _make_empty_click() -> AudioStreamWAV:
	## 空仓：单次短促咔哒
	var duration := 0.06
	var n := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)

	for i in n:
		var t := float(i) / SAMPLE_RATE
		var env := _envelope(t, 0.001, 0.059, 0.0, 0.01, duration)
		samples[i] = sin(TAU * 1200.0 * t) * env * 0.5
	return _make_wav(samples)


func _make_pickup() -> AudioStreamWAV:
	## 拾取弹药：上升双音调（叮叮）
	var duration := 0.2
	var n := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)

	for i in n:
		var t := float(i) / SAMPLE_RATE
		var env: float
		if t < 0.1:
			env = _envelope(t, 0.005, 0.095, 0.0, 0.05, 0.1)
			samples[i] = sin(TAU * 880.0 * t) * env * 0.6
		else:
			var t2 := t - 0.1
			env = _envelope(t2, 0.005, 0.095, 0.0, 0.05, 0.1)
			samples[i] = sin(TAU * 1320.0 * t2) * env * 0.6
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

	## 战斗 BGM：4 小节循环，鼓点 + 低音贝斯 + 旋律线
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
