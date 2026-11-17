extends Node
## A bounded pool prevents a large, accelerated army from flooding the mixer.

signal sound_played(cue: StringName)

const UI_CLICK = preload("res://assets/sound/effects/ui-click.wav")
const SOUNDS = {
	&"sword": preload("res://assets/sound/effects/sword.wav"),
	&"arrow": preload("res://assets/sound/effects/arrow.wav"),
	&"spell": preload("res://assets/sound/effects/spell.wav"),
	&"catapult": preload("res://assets/sound/effects/catapult.wav"),
	&"ogre": preload("res://assets/sound/effects/ogre.wav"),
	&"werewolf": preload("res://assets/sound/effects/werewolf.wav"),
}
const LEVELS = {&"sword": -12.0, &"arrow": -11.0, &"spell": -16.0,
	&"catapult": -11.0, &"ogre": -13.0, &"werewolf": -15.0}
const MAX_PLAYERS = 16
const MAX_SAME_CUE = 3
var _players: Array[AudioStreamPlayer] = []
var _last_played: Dictionary = {}
var _last_voice_msec: int = -10000
var _preview_player: AudioStreamPlayer
var _ui_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in MAX_PLAYERS:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_players.append(player)
	_preview_player = AudioStreamPlayer.new()
	_preview_player.bus = &"SFX"
	add_child(_preview_player)
	# Keep interface feedback separate so scene changes cannot cut off a click.
	_ui_player = AudioStreamPlayer.new()
	_ui_player.name = "InterfaceClick"
	_ui_player.bus = &"SFX"
	_ui_player.stream = UI_CLICK
	_ui_player.volume_db = -12.0
	add_child(_ui_player)
	get_tree().node_added.connect(_register_ui_button)
	_register_existing_buttons(get_tree().root)


func _register_existing_buttons(node: Node) -> void:
	_register_ui_button(node)
	for child: Node in node.get_children():
		_register_existing_buttons(child)


func _register_ui_button(node: Node) -> void:
	if node is BaseButton and not node.button_down.is_connected(play_ui_click):
		# Button-down runs before actions such as mute, pause, reload or quit.
		# It supports mouse and keyboard activation; disabled buttons stay silent.
		node.button_down.connect(play_ui_click)


func play_ui_click() -> void:
	if AudioSettings.sounds_muted or AudioSettings.sounds_volume <= 0.0:
		return
	_ui_player.play()
	sound_played.emit(&"ui_click")


func play(cue: StringName) -> bool:
	if not SOUNDS.has(cue) or AudioSettings.sounds_muted or AudioSettings.sounds_volume <= 0.0:
		return false
	var now := Time.get_ticks_msec()
	var voice := cue == &"ogre" or cue == &"werewolf"
	# Real-time spacing also works at 3x. Roars never overlap each other.
	if now - int(_last_played.get(cue, -10000)) < (7000 if voice else 65):
		return false
	if voice and now - _last_voice_msec < 3500:
		return false
	var free_player: AudioStreamPlayer
	var same_count := 0
	for player: AudioStreamPlayer in _players:
		if player.playing:
			if player.get_meta(&"cue", &"") == cue:
				same_count += 1
		elif free_player == null:
			free_player = player
	if free_player == null or same_count >= MAX_SAME_CUE:
		return false
	_last_played[cue] = now
	if voice:
		_last_voice_msec = now
	free_player.set_meta(&"cue", cue)
	free_player.stream = SOUNDS[cue]
	free_player.volume_db = LEVELS[cue]
	# Pitch variation is subtle and independent of Engine.time_scale.
	free_player.pitch_scale = randf_range(0.96, 1.04)
	free_player.play()
	sound_played.emit(cue)
	return true


func preview(cue: StringName) -> void:
	if not SOUNDS.has(cue) or AudioSettings.sounds_muted or AudioSettings.sounds_volume <= 0.0:
		return
	_preview_player.stop()
	_preview_player.stream = SOUNDS[cue]
	_preview_player.volume_db = LEVELS[cue]
	_preview_player.pitch_scale = 1.0
	_preview_player.play()


func stop_preview() -> void:
	_preview_player.stop()


func stop_game_sounds() -> void:
	for player: AudioStreamPlayer in _players:
		player.stop()
	_last_played.clear()
	_last_voice_msec = -10000
