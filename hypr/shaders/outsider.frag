#version 300 es
// Look outsider: grano de película estático, negros levantados (foto
// deslavada), un toque cálido y viñeta leve. Sutil a propósito.
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

float hash(vec2 p) {
    p = fract(p * vec2(443.897, 441.423));
    p += dot(p, p.yx + 19.19);
    return fract((p.x + p.y) * p.x);
}

void main() {
    vec4 c = texture(tex, v_texcoord);
    vec3 col = c.rgb;

    // negros levantados y blancos apenas bajados
    col = col * 0.94 + vec3(0.035, 0.03, 0.022);
    // cálido: un poco más de rojo, menos azul
    col *= vec3(1.02, 1.0, 0.95);
    // grano
    float g = hash(floor(gl_FragCoord.xy)) - 0.5;
    col += g * 0.035;
    // viñeta
    vec2 d = v_texcoord - 0.5;
    col *= 1.0 - dot(d, d) * 0.35;

    fragColor = vec4(clamp(col, 0.0, 1.0), c.a);
}
