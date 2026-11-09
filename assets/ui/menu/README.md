# Menu artwork edge cleanup

`clean-menu-art.tres` is applied only to the three main menu buttons and the
three pause menu buttons. Its canvas shader removes the neutral white matte
left in transparent PNG edges while preserving warm gold lettering and hover /
pressed tint. Nearest-neighbor sampling keeps the pixel outline crisp.

Focus uses an empty StyleBox so the original image is not painted a second time
on top of the active button. The original PNGs in `assets/menu/` are unchanged.
