shader_type canvas_item;

uniform vec4 color_top : source_color = vec4(0.04, 0.10, 0.24, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.29, 0.48, 1.0, 1.0);
uniform float cell_size = 48.0;
uniform float speed = 12.0;
uniform float line_width = 1.5;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec4 col = mix(color_top, color_bottom, UV.y);

	vec2 p = FRAGCOORD.xy + vec2(TIME * speed);
	vec2 cell = floor(p / cell_size);
	vec2 local = mod(p, cell_size);

	float line = step(local.x, line_width) + step(local.y, line_width);
	col.rgb += clamp(line, 0.0, 1.0) * 0.08;

	float h = hash(cell);
	if (h > 0.8) {
		float glow = clamp((sin(TIME * 0.8 + h * 6.28) * 0.5 + 0.5 - 0.6) / 0.4, 0.0, 1.0);
		col.rgb += glow * 0.14;
	}

	COLOR = col;
}