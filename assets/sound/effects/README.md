# Character effects

Original, procedurally layered WAVs, built by `build_effects.py` using only
Python's standard library. No third-party samples or licensing dependencies.
32 kHz mono PCM, 16 bit, no looping. Files can be replaced with recordings using
the same names; the exported attack/voice keys in character scenes stay valid.

- `sword.wav`: blade swish, metal impact and inharmonic ring.
- `arrow.wav`: bow string, wooden snap and short flight.
- `spell.wav`: airy release and descending magical shimmer.
- `catapult.wav`: wooden mechanism, rope, heavy release and stone flight.
- `ogre.wav`: throaty low growl for the green monster (`goblin.tscn`).
- `werewolf.wav`: sustained rising and falling howl.
- `ui-click.wav`: short wooden/brass interface click, automatically attached to
  buttons and checkboxes, including controls created at runtime. It uses a separate
  persistent player on SFX, so pausing or changing scenes does not cut it off.

Mix levels and voice rate limits are in `scripts/sound_manager.gd`. Effects use
the SFX bus, music uses Music. Settings are stored in `user://audio_settings.cfg`.
