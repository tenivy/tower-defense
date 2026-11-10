# Werewolf visual calibration

The original photos and side-view transforms are unchanged. Only this scene's
AnimatedSprite2D uses `scripts/werewolf_visual.gd` to compensate for camera scale:

- `walk_down` (front): 1.45 times the original sprite scale; y offset -4.3.
- `walk_up` (back): 1.15 times the original sprite scale; y offset +2.4.
- `walk_left` / `walk_right`: exact original scale and position.

Across all frames, the side-view average visible height is 94.16 game pixels.
After correction, front/back averages are 93.26 / 93.36 pixels. Vertical offsets
match the median foot level to the side reference. Multipliers stay fixed within
each animation so a moving foot does not make the entire body grow and shrink.

Enemy movement, path coordinates, damage effects and combat statistics continue
to use the existing Enemy script. Changing direction restores from the captured
original transform, preventing cumulative scale drift.
