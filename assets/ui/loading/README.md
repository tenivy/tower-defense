# Loading screen

`castle-dawn-v1.png` was created with the built-in ImageGen tool, using the
existing main menu and level-one knight / female archer sprites as references.
The generated file is copied here unchanged; original artwork is preserved.

The scene overlays the existing logo, a gold nine-patch panel and a segmented
gold progress bar. Actual resource-loading progress drives the display, with
gentle visual smoothing, gameplay tips and a short fade-in. Cached loads retain
the presentation for 0.65 seconds to avoid a one-frame flash, then enter the game.
Loading UI does not alter gameplay speed or the gameplay scene.

## ImageGen prompt

```text
Use case: stylized-concept
Asset type: full-screen background illustration for the loading screen of an existing medieval pixel-art tower-defense game.
Input images: image 1 is the existing main-menu scene, used only as an art-direction and palette reference. Image 2 is the knight character-design reference. Image 3 is the female archer character-design reference. Create an original NEW scene, not an edit of the references.
Primary request: an exceptionally beautiful, atmospheric view of the player's stone castle at daybreak, as the two recognizable heroes approach to prepare its defenses. Hopeful, quiet anticipation before battle.
Composition: wide 16:9 landscape, 1920 x 1080. The castle occupies the upper-right / middle-right third, with crenellated walls, a warmly lit gate, towers and small navy banners with gold medieval motifs. A winding stone road and a small wooden bridge over a turquoise river lead to it. Mist between fir-covered hills, layered mountains, warm pale gold morning light and lavender-blue shadows. A large old oak frames the far left edge with a few mossy rocks and tiny wildflowers. The sky across the top center stays relatively quiet for a separately rendered logo.
Place the knight and female archer together in the left third of the composition, seen from behind or three-quarter back, watching or walking toward their castle, fully visible and resolute. Their heads and bodies must sit above the bottom quarter of the canvas. Knight has ivory shoulder armor, dark navy helmet, cream cloak, dark steel joints, sword and a brass-edged dark shield; archer is a chestnut-haired young woman with a pointed moss-green hood, olive leather outfit, brown boots, bow and quiver.
The BOTTOM QUARTER, especially the central 60% width, must be visually quiet and a little darker, primarily simple shadowed grass/stone foreground, because an actual loading panel will be overlaid there in the game. No critical subject or text in that zone.
Style: rich, cohesive hand-crafted pixel art matching the reference game's menu, consistent visible square pixel clusters, crisp silhouettes, restrained dithering and stepped color ramps, dark warm outlines, no smooth vector curves, no photorealism, no blurry airbrush gradients. Painterly richness achieved with pixels. Muted moss green, aged ivory, antique gold, slate navy, mauve sunrise and turquoise water.
Constraints: opaque full-bleed background; no lettering, text, UI, buttons, progress bars, frame, logo, watermarks, extra people, combat or defeated poses. Artwork only, all functional UI is drawn by Godot.
```
