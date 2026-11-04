#version 300 es
// Look obsidiana: piedra — le quita un poco de color a todo (no lo apaga) y
// le da un frío leve a las sombras, como vidrio volcánico. Estático y sutil.
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 c = texture(tex, v_texcoord);
    vec3 col = c.rgb;

    // un 22% menos de color
    float l = dot(col, vec3(0.2126, 0.7152, 0.0722));
    col = mix(col, vec3(l), 0.22);
    // sombras frías, con el dejo violeta del reflejo
    col += vec3(-0.004, -0.002, 0.012) * (1.0 - l);

    fragColor = vec4(clamp(col, 0.0, 1.0), c.a);
}
