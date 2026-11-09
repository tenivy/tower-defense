# Level 01 placement contours

`level-01-placement.tres` traces water, visible tree canopies, the monster cave
and the castle silhouette in the original 1280 x 720 background's pixel space.
Twenty named polygons cover the irregular terrain; they do not add a global
padding around objects. The castle includes the rear tower, battlements and the
foreground tower, with the grass indentation on its left kept clear.

`scripts/placement_map.gd` converts world positions through the actual map sprite
transform and centered texture rectangle. Moving/scaling the sprite or Main does
not offset the contours. Positions outside the map are rejected too.

The placement anchor is checked, matching the existing placement convention.
Main's existing enemy-path clearance and defender spacing remain separate and
unchanged. Both the ghost preview and actual purchase use can_place_defender().

Edit the named polygon coordinates when changing the background art. The data is
a preloaded Godot resource so it is included with the scene in exported games.
