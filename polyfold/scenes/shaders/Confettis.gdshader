shader_type canvas_item;

// Confetti + feux d'artifice simples (sans glow) - Godot 4.x
// Marche sur ColorRect, PanelContainer, etc.
// La taille du noeud est détectée automatiquement (pas de script nécessaire).

uniform int mode : hint_enum("Confetti", "Feu d'artifice") = 0;
uniform bool side_fireworks = true; // 2 petits feux d'artifice sur les côtés (mode Confetti)

// ---------- Confetti (valeurs en pixels) ----------
const int PARTICLE_COUNT = 40;

uniform float speed         : hint_range(20.0, 500.0) = 120.0;
uniform float sway_strength : hint_range(0.0, 200.0)  = 40.0;
uniform float sway_speed    : hint_range(0.1, 5.0)    = 1.4;
uniform float spin_speed    : hint_range(0.0, 10.0)   = 3.5;
uniform float piece_size    : hint_range(2.0, 30.0)   = 6.0;
uniform float aspect_ratio  : hint_range(0.2, 3.0)    = 1.6;

// ---------- Feux d'artifice (valeurs relatives à la hauteur du noeud) ----------
const int BURSTS = 4;
const int MAX_SPARKS = 90;
uniform int side_sparks : hint_range(10, 90) = 50;
uniform int main_sparks : hint_range(10, 90) = 80;

uniform float firework_period : hint_range(1.0, 6.0)    = 3.0;
uniform float burst_radius    : hint_range(0.1, 0.8)    = 0.4;
uniform float side_radius     : hint_range(0.05, 0.5)   = 0.22;
uniform float gravity         : hint_range(0.0, 0.5)    = 0.15;
uniform float spark_size      : hint_range(0.002, 0.03) = 0.011;

const vec3 COLORS[8] = vec3[8](
	vec3(1.00, 0.20, 0.20),
	vec3(1.00, 0.75, 0.10),
	vec3(0.10, 0.80, 0.30),
	vec3(0.15, 0.55, 1.00),
	vec3(0.85, 0.20, 1.00),
	vec3(1.00, 0.40, 0.70),
	vec3(0.10, 0.90, 0.95),
	vec3(1.00, 1.00, 1.00)
);

// Hash sans sin() : pas de motifs répétés / de perte de précision
float rand(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

vec3 pick_color(float r) {
	return COLORS[clamp(int(r * 8.0), 0, 7)];
}

vec2 rotate2d(vec2 v, float a) {
	float s = sin(a);
	float c = cos(a);
	return vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

vec4 confetti(vec2 px, vec2 res) {
	vec4 out_col = vec4(0.0);
	float travel = res.y + piece_size * 8.0;

	for (int i = 0; i < PARTICLE_COUNT; i++) {
		float fi = float(i) * 10.0;

		float start_x  = rand(fi + 1.0) * res.x;
		float my_speed = speed * (0.5 + rand(fi + 2.0));
		float t_offset = rand(fi + 3.0) * travel / my_speed;
		float sway_str = sway_strength * (0.3 + rand(fi + 4.0) * 1.4);
		float sway_spd = sway_speed * (0.5 + rand(fi + 5.0) * 1.5);
		float phase    = rand(fi + 6.0) * TAU;
		float spin     = spin_speed * (0.5 + rand(fi + 7.0) * 1.5) * (rand(fi + 8.0) > 0.5 ? 1.0 : -1.0);
		float size     = piece_size * (0.6 + rand(fi + 9.0) * 0.8);
		float ar       = aspect_ratio * (0.7 + rand(fi + 10.0) * 0.6);

		float t  = mod(TIME + t_offset, travel / my_speed);
		float cy = -piece_size * 4.0 + t * my_speed;
		float cx = start_x + sway_str * sin(t * sway_spd + phase);

		vec2 d = rotate2d(px - vec2(cx, cy), -t * spin);
		vec2 local = d / vec2(size * ar, size);

		if (max(abs(local.x), abs(local.y)) <= 1.0) {
			float shimmer = 0.5 + 0.5 * sin(t * spin * 2.0);
			vec3 base = pick_color(rand(fi + 11.0));
			out_col = vec4(mix(base * 0.5, base, shimmer), 1.0);
		}
	}
	return out_col;
}

// Un feu d'artifice : fusée (t < 0.2) puis explosion
vec4 burst(vec2 p, vec2 center, float t, float id, float radius, int n) {
	vec4 o = vec4(0.0);
	vec3 base = pick_color(rand(id + 3.0));

	if (t < 0.2) {
		float k = t / 0.2;
		vec2 pos = vec2(center.x, mix(1.0, center.y, k));
		if (length(p - pos) <= 0.008) {
			o = vec4(1.0);
		}
	} else if (t < 0.2 + 0.8 * 0.85) {
		float tt = (t - 0.2) / 0.8;
		float e = 1.0 - (1.0 - tt) * (1.0 - tt);
		float size = spark_size * (1.0 - tt * 0.7);

		for (int i = 0; i < MAX_SPARKS; i++) {
			if (i >= n) break;
			float fi = float(i);
			// Répartition en spirale (angle d'or) : remplit tout le disque => une vraie boule
			float ang = fi * 2.39996 + rand(id) * TAU;
			float spd = radius * sqrt((fi + 0.5) / float(n)) * (0.9 + 0.2 * rand(id + fi * 3.0 + 1.0));

			vec2 pos = center + vec2(cos(ang), sin(ang)) * spd * e;
			pos.y += gravity * tt * tt;

			if (length(p - pos) <= size) {
				vec3 col = mix(base, pick_color(rand(id + fi * 3.0 + 2.0)), 0.25);
				o = vec4(col, 1.0);
			}
		}
	}
	return o;
}

// Grand feu d'artifice (mode 1) : 4 explosions réparties
vec4 fireworks(vec2 px, vec2 res) {
	vec2 p = px / res.y;
	float aspect = res.x / res.y;
	vec4 out_col = vec4(0.0);

	for (int b = 0; b < BURSTS; b++) {
		float seed = float(b) * 37.0;
		float T = TIME / firework_period + rand(seed);
		float id = seed + floor(T) * 101.0;
		vec2 center = vec2(
			mix(0.2, aspect - 0.2, rand(id + 1.0)),
			mix(0.15, 0.5, rand(id + 2.0))
		);
		vec4 o = burst(p, center, fract(T), id, burst_radius, main_sparks);
		if (o.a > 0.0) out_col = o;
	}
	return out_col;
}

// Deux petits feux d'artifice, un à gauche et un à droite (en alternance)
vec4 side_bursts(vec2 px, vec2 res) {
	vec2 p = px / res.y;
	float aspect = res.x / res.y;
	vec4 out_col = vec4(0.0);

	for (int s = 0; s < 2; s++) {
		float T = TIME / firework_period + float(s) * 0.5;
		float id = float(s) * 57.0 + floor(T) * 101.0;
		float x = mix(0.1, 0.2, rand(id + 1.0)) * aspect;
		if (s == 1) x = aspect - x;
		vec2 center = vec2(x, mix(0.3, 0.5, rand(id + 2.0)));
		vec4 o = burst(p, center, fract(T), id, side_radius, side_sparks);
		if (o.a > 0.0) out_col = o;
	}
	return out_col;
}

void fragment() {
	// Taille du noeud en pixels, détectée automatiquement
	vec2 res = 1.0 / max(fwidth(UV), vec2(0.000001));
	vec2 px = UV * res;

	vec4 fx;
	if (mode == 0) {
		fx = confetti(px, res);
		if (side_fireworks) {
			vec4 s = side_bursts(px, res);
			if (s.a > 0.0) fx = s;
		}
	} else {
		fx = fireworks(px, res);
	}

	// On garde le fond existant (ex : le style du PanelContainer)
	COLOR = mix(COLOR, fx, fx.a);
}