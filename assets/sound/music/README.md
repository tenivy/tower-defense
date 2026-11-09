# Music routing

`MusicManager` is a persistent autoload; scene changes do not destroy its players.

- Main menu and loading: `menu_sound.mp3`.
- Gameplay and defeat: `base.mp3`.
- At least one living enemy past the first large bridge: `napryag.mp3`.

`Map/MusicDangerStart` marks the northern exit of that first large bridge,
following the enemies' travel direction (world position approximately 716, 132).
Main projects this marker onto the enemy route. Enemies count throughout the
remaining route to the castle, including the upper loop and the second bridge.
Dying and queued-for-deletion enemies do not keep the tension music active.

All three MP3 streams loop at runtime. Track changes use a 1.2-second equal-power
crossfade. Inactive tracks pause at their current playback position, and resume
there when selected again. Repeated danger checks do not restart tracks/fades;
rapid changes blend from the current mix.

Players use pitch 1.0 and keep processing during pause. Crossfades ignore
Engine.time_scale, so the game's 3x speed affects neither music tempo nor fades.
The default music level is -12 dB in `scripts/music_manager.gd`.
