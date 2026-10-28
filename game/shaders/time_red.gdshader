// 時間閃爍紅色版(D27 第十段):圖中的白 W 換成 r(#E8696B),K 描邊不變。
shader_type canvas_item;

uniform bool red = false;
const vec3 RED_R = vec3(232.0, 105.0, 107.0) / 255.0;

void fragment() {
	vec4 c = COLOR;
	if (red && c.a > 0.0 && min(c.r, min(c.g, c.b)) > 0.98) {
		c.rgb = RED_R;
	}
	COLOR = c;
}
