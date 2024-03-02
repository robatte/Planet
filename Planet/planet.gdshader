shader_type spatial;

uniform float min_height;
uniform float max_height;
uniform sampler2D height_color: source_color;
varying float height;


void fragment() {
	float height_range = max_height - min_height;
	float t = height / height_range - (min_height / height_range);
	vec3 color = texture(height_color, vec2(t,0.0)).xyz;
	ALBEDO = color;
}

void vertex() {
	height = length(VERTEX);
}