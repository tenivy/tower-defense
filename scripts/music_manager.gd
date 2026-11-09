extends Node
## Persistent music playback. Audio clock and fades are independent of game speed.

const TRACKS = {
	&"menu": preload("res://assets/sound/music/menu_sound.mp3"),
	&"base": preload("res://assets/sound/music/base.mp3"),
	&"napryag": preload("res://assets/sound/music/napryag.mp3"),
}
const FADE_SECONDS = 1.2
const VOLUME_DB = -12.0

var current_track: StringName = &""
var _in_game: bool = false
var _players: Dictionary = {}
var _weights: Dictionary = {}
var _fade: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for track: StringName in TRACKS:
		var stream: AudioStreamMP3 = TRACKS[track].duplicate()
		stream.loop = true
		stream.loop_offset = 0.0
		var player := AudioStreamPlayer.new()
		player.name = String(track).capitalize() + "Music"
		player.stream = stream
		player.pitch_scale = 1.0
		player.volume_db = -80.0
		add_child(player)
		_players[track] = player
		_weights[track] = 0.0


func play_menu() -> void:
	_in_game = false
	_switch_to(&"menu")


func play_gameplay() -> void:
	_in_game = true
	_switch_to(&"base")


func set_danger_active(active: bool) -> void:
	if _in_game:
		_switch_to(&"napryag" if active else &"base")


func _switch_to(track: StringName) -> void:
	if current_track == track:
		return
	current_track = track
	if _fade and _fade.is_valid():
		_fade.kill()
	var player: AudioStreamPlayer = _players[track]
	# Resume a track at its previous position instead of repeating its intro.
	if player.stream_paused:
		player.stream_paused = false
	elif not player.playing:
		player.play()
	var initial_weights := _weights.duplicate()
	_fade = create_tween()
	_fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade.set_ignore_time_scale(true)
	_fade.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_fade.tween_method(_blend.bind(initial_weights, track), 0.0, 1.0, FADE_SECONDS)
	_fade.tween_callback(_finish_fade.bind(track))


func _blend(amount: float, initial_weights: Dictionary, target: StringName) -> void:
	for track: StringName in _players:
		var weight := lerpf(initial_weights[track], 1.0 if track == target else 0.0, amount)
		_weights[track] = weight
		# Equal-power crossfade avoids a quiet dip between two different tracks.
		var gain := sqrt(maxf(weight, 0.0))
		var player: AudioStreamPlayer = _players[track]
		player.volume_db = VOLUME_DB + linear_to_db(maxf(gain, 0.0001))


func _finish_fade(target: StringName) -> void:
	if current_track != target:
		return
	for track: StringName in _players:
		var player: AudioStreamPlayer = _players[track]
		_weights[track] = 1.0 if track == target else 0.0
		player.volume_db = VOLUME_DB if track == target else -80.0
		if track != target and player.playing:
			player.stream_paused = true
