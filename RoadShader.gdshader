shader_type spatial;

uniform float lane_width;
uniform float lane_count; // must be even

// properties of the striped line in the center
uniform float stripe_width;
uniform float stripe_dist;
uniform float stripe_len;

// properties of the lines at the edge
uniform float line_width;

void fragment() {
	float l = lane_width/2.0 - abs(mod(abs(UV.x - 0.5), lane_width) - lane_width/2.0);
	float lane = abs(UV.x - 0.5)/lane_width;
	if (l < stripe_width && round(lane) < lane_count/2.0 && mod(UV.y, stripe_dist) < stripe_len) {
		ALBEDO = vec3(1);
	} else if (l < line_width && round(lane) == lane_count/2.0) {
		ALBEDO = vec3(1);
	} else {
		ALBEDO = vec3(0.5)
	}
//	ALBEDO = vec3(l);
}