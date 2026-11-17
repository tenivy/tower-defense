extends Node
## Bus gains are separate from the music crossfade and never change playback speed.

signal changed

const SAVE_PATH = "user://audio_settings.cfg"
var music_volume: float = 1.0
var sounds_volume: float = 0.8
var music_muted: bool = false
var sounds_muted: bool = false
var _save_timer: Timer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus_name: StringName in [&"Music", &"SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, &"Master")
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = 0.3
	_save_timer.ignore_time_scale = true
	add_child(_save_timer)
	_save_timer.timeout.connect(save_settings)
	load_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		music_volume = _read_volume(config, "music_volume", 1.0)
		sounds_volume = _read_volume(config, "sounds_volume", 0.8)
		music_muted = config.get_value("audio", "music_muted", false) == true
		sounds_muted = config.get_value("audio", "sounds_muted", false) == true
	_apply()


func _read_volume(config: ConfigFile, key: String, fallback: float) -> float:
	var value: Variant = config.get_value("audio", key, fallback)
	if (value is float or value is int) and is_finite(float(value)):
		return clampf(float(value), 0.0, 1.0)
	return fallback


func set_volume(channel: StringName, value: float) -> void:
	if not is_finite(value):
		return
	if channel == &"Music":
		music_volume = clampf(value, 0.0, 1.0)
	elif channel == &"SFX":
		sounds_volume = clampf(value, 0.0, 1.0)
	else:
		return
	_apply()
	_save_timer.start()


func set_muted(channel: StringName, muted: bool) -> void:
	if channel == &"Music":
		music_muted = muted
	elif channel == &"SFX":
		sounds_muted = muted
	else:
		return
	_apply()
	_save_timer.start()


func _apply() -> void:
	var music_bus := AudioServer.get_bus_index(&"Music")
	var sounds_bus := AudioServer.get_bus_index(&"SFX")
	# A perceptual volume curve gives useful control over quiet listening levels.
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(maxf(music_volume * music_volume, 0.0001)))
	AudioServer.set_bus_volume_db(sounds_bus, linear_to_db(maxf(sounds_volume * sounds_volume, 0.0001)))
	AudioServer.set_bus_mute(music_bus, music_muted or music_volume <= 0.0)
	AudioServer.set_bus_mute(sounds_bus, sounds_muted or sounds_volume <= 0.0)
	changed.emit()


func save_settings() -> void:
	_save_timer.stop()
	var config := ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sounds_volume", sounds_volume)
	config.set_value("audio", "music_muted", music_muted)
	config.set_value("audio", "sounds_muted", sounds_muted)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Не удалось сохранить громкость: " + error_string(error))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _save_timer != null:
		save_settings()
