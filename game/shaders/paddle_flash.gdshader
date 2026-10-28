// 擋板被擊中閃白 1 幀(D13):除 K 描邊與透明以外的像素全部變白。
shader_type canvas_item;

uniform bool flash = false;
const vec3 OUTLINE_K = vec3(27.0, 26.0, 46.0) / 255.0;

void fragment() {
	vec4 c = COLOR;
	if (flash && c.a > 0.0 && distance(c.rgb, OUTLINE_K) > 0.02) {
		c.rgb = vec3(1.0);
	}
	COLOR = c;
}
