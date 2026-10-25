#version 300 es
// Look ofrenda: luz de vela — un toque tibio (más rojo/naranja, menos azul),
// negros apenas morados y una viñeta suave como el borde de la luz del altar.
// Estático y sutil a propósito.
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 c = texture(tex, v_texcoord);
    vec3 col = c.rgb;

    // tibio
    col *= vec3(1.04, 1.0, 0.93);
    // negros con un dejo morado
    col += vec3(0.012, 0.0, 0.02) * (1.0 - col);
    // viñeta de vela: el centro iluminado, los bordes en penumbra
    vec2 d = v_texcoord - 0.5;
    col *= 1.0 - dot(d, d) * 0.5;

    fragColor = vec4(clamp(col, 0.0, 1.0), c.a);
}
