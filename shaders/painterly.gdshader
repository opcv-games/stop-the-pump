// Impressionist look for the station world (art direction: Hopper's "Gas", DESIGN.md 9b).
// 1. Brush wobble: sample through flowing noise so straight 3D edges become hand-drawn strokes.
// 2. Kuwahara filter: each pixel takes the calmest of four neighbouring patches -> soft brush dabs.
// 3. Colour dabs: small patches shift a little in value and temperature, like oil on canvas.
// 4. Canvas grain and a gentle vignette. Refs #22
shader_type canvas_item;

uniform int radius : hint_range(1, 8) = 5;
uniform float wobble : hint_range(0.0, 8.0) = 2.5;      // in texture pixels
uniform float stroke_scale = 0.09;                       // brush noise frequency
uniform float dab_size = 12.0;                           // in texture pixels
uniform float dab_strength : hint_range(0.0, 0.4) = 0.08;
uniform float dab_temperature : hint_range(0.0, 0.2) = 0.05;
uniform float grain : hint_range(0.0, 0.2) = 0.025;
uniform float vignette : hint_range(0.0, 1.0) = 0.35;
uniform float saturation : hint_range(0.0, 2.0) = 1.1;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE;
	vec2 p = UV / px;  // texture pixel coordinates

	// 1. Brush wobble: strokes run mostly diagonally, like the isometric ground.
	vec2 flow = vec2(noise(p * stroke_scale), noise(p * stroke_scale + 17.3)) - 0.5;
	vec2 uv = UV + flow * wobble * px * 2.0;

	// 2. Kuwahara over four quadrants.
	vec3 best = vec3(0.0);
	float best_var = 1e9;
	for (int q = 0; q < 4; q++) {
		vec2 dir = vec2(q == 1 || q == 3 ? 1.0 : -1.0, q >= 2 ? 1.0 : -1.0);
		vec3 sum = vec3(0.0);
		vec3 sum2 = vec3(0.0);
		float n = 0.0;
		for (int x = 0; x <= radius; x++) {
			for (int y = 0; y <= radius; y++) {
				vec3 c = texture(TEXTURE, uv + vec2(float(x), float(y)) * dir * px).rgb;
				sum += c;
				sum2 += c * c;
				n += 1.0;
			}
		}
		vec3 mean = sum / n;
		vec3 v = sum2 / n - mean * mean;
		float var = v.r + v.g + v.b;
		if (var < best_var) {
			best_var = var;
			best = mean;
		}
	}

	// 3. Colour dabs: elongated patches, each a little lighter/darker and warmer/cooler.
	vec2 dab_uv = vec2(p.x + p.y * 0.6, p.y - p.x * 0.3) / dab_size;
	float d1 = noise(dab_uv);
	float d2 = noise(dab_uv * 1.7 + 31.0);
	best *= 1.0 + (d1 - 0.5) * dab_strength * 2.0;
	best += vec3(d2 - 0.5) * vec3(1.0, 0.4, -0.8) * dab_temperature;

	float luma = dot(best, vec3(0.299, 0.587, 0.114));
	best = mix(vec3(luma), best, saturation);

	// 4. Canvas grain and vignette.
	float weave = noise(p / 2.2) * 0.6 + noise(p * 0.1 + 7.0) * 0.4;
	best *= 1.0 + (weave - 0.5) * grain * 2.0;
	float d = distance(UV, vec2(0.5, 0.52));
	best *= 1.0 - vignette * smoothstep(0.35, 0.85, d);
	COLOR = vec4(clamp(best, 0.0, 1.0), 1.0);
}
