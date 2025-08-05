shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
uniform bool active = false;
uniform vec2 black_hole_center = vec2(0.5, 0.5);
uniform float radius = 0.3;
uniform float strength = 0.5;
uniform float time : hint_range(0.0, 1.0);
uniform float spin_speed = 2.0;
uniform float spin_strength = 1.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	if (active) {

	    vec2 to_center = uv - black_hole_center;
	    float dist = length(to_center);

	    // Pull amount (fade in distortion toward center)
	    float pull = smoothstep(radius, 0.0, dist) * strength;

	    // Spin fade: strongest near center, fades out at edge of radius
	    float spin_fade = smoothstep(radius, 0.0, dist) * (1.0 - time);

	    // Calculate spinning angle based on distance
	    float angle = spin_speed * TIME * spin_fade * spin_strength;
	    float s = sin(angle);
	    float c = cos(angle);

	    // Rotate around center
	    vec2 rotated = vec2(
	        c * to_center.x - s * to_center.y,
	        s * to_center.x + c * to_center.y
	    );

	    // Displaced UV pulls toward center with spinning
	    vec2 displaced_uv = black_hole_center + normalize(rotated) * dist;
	    displaced_uv -= normalize(rotated) * pull;

	    // Zoom into the black hole
	    displaced_uv = mix(displaced_uv, black_hole_center, time * 0.5);

	    COLOR = textureLod(SCREEN_TEXTURE, displaced_uv, 0.0);
	} else {
		COLOR = textureLod(SCREEN_TEXTURE, uv, 0.0);
	}
}