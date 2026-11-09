shader_type canvas_item;
render_mode unshaded;

varying vec4 button_tint;

void vertex() {
	button_tint = COLOR;
}

void fragment() {
	vec4 art = texture(TEXTURE, UV);
	// Original PNG cutouts retain a white matte in partially transparent edges.
	// Remove that matte at draw time; keep original files and warm gold lettering.
	float lightest = max(art.r, max(art.g, art.b));
	float darkest = min(art.r, min(art.g, art.b));
	float neutral = 1.0 - smoothstep(0.02, 0.10, lightest - darkest);
	float white_fringe = smoothstep(0.24, 0.56, darkest) * neutral;
	if (art.a > 0.001 && art.a < 0.999) {
		art.rgb = clamp((art.rgb - vec3(1.0 - art.a)) / art.a, vec3(0.0), vec3(1.0));
	}
	art.a *= 1.0 - white_fringe;
	COLOR = art * button_tint;
}
