shader_type canvas_item;
// Recolour the final sprite, preserving its alpha, pixel edges and damage flashes.
void fragment() {
	vec4 source = COLOR;
	float light = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	vec3 rage = vec3(min(light * 1.25, 1.0), light * 0.52, light * 0.42);
	COLOR = vec4(mix(source.rgb, rage, 0.45), source.a);
}
