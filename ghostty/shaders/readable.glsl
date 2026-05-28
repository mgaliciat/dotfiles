// readable.glsl — shader de LEGIBILIDAD para Ghostty (no efectos).
//
// Diseñado para leer, no para lucir: cero animación, cero CRT/scanlines/
// glow. Cuatro pasadas sutiles que hacen el texto más fácil de leer sobre
// el theme oled-neon (true black #000 + acentos saturados):
//
//   1. unsharp mask  → bordes de glifo más definidos (la mayor ganancia
//                      de legibilidad; el ojo lee "nitidez" como contraste
//                      local en los bordes).
//   2. domar el neón → baja la saturación SÓLO de lo coloreado, para que
//                      verde láser / magenta / cyan dejen de "vibrar"
//                      contra el #000 (aberración cromática en la retina).
//   3. gamma lift    → levanta dim grays para que no se evaporen, sin tocar
//                      el punto negro OLED (pow(0)=0 → #000 queda intacto).
//   4. domar blanco  → baja el techo de brillo del texto casi-blanco, que
//                      a máximo contraste + sharpen deslumbra.
//
// Formato Shadertoy (lo que Ghostty espera): el contenido del terminal
// llega en iChannel0; escribimos el pixel final en fragColor.
//
// Tuning: ver parámetros abajo. Ghostty recarga el shader al guardar config
// (⌘⇧R), pero un cambio de .glsl suele necesitar reabrir la ventana.

// ─── parámetros ───────────────────────────────────────────────
const float SHARPEN      = 1.20;  // intensidad del unsharp mask (0 = off)
const float SATURATION   = 0.50;  // <1 desatura lo coloreado (neón)
const float GAMMA        = 0.85;  // <1 levanta sombras; 1.0 = neutro
// Domar el blanco: el texto #f8f8f2 a máximo contraste + sharpen deslumbra.
// Bajamos su techo de brillo SÓLO en los pixeles casi-blancos.
const float WHITE_LEVEL  = 0.88;  // techo del blanco (1.0 = sin tocar)
const float WHITE_THRESH = 0.70;  // desde qué "blancura" empieza a bajar

// luma perceptual Rec.709 — el verde pesa más que rojo/azul, que es como
// el ojo realmente percibe brillo.
float luma(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv    = fragCoord / iResolution.xy;
    vec2 texel = 1.0 / iResolution.xy;

    // Sample central. Preservamos su alpha al final para NO romper la
    // transparencia/blur de background-opacity = 0.95.
    vec4 center = texture(iChannel0, uv);
    vec3 color  = center.rgb;

    // ── 1. unsharp mask ──
    // Box blur 3x3 (9 taps, barato) y reinyectamos el detalle perdido:
    // detalle = original - blur; sumarlo de vuelta engrosa el contraste
    // local en los bordes de cada glifo. max(...,0) en el pow de abajo
    // evita NaN si el overshoot empuja un canal por debajo de 0.
    vec3 blur = vec3(0.0);
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            blur += texture(iChannel0, uv + vec2(float(x), float(y)) * texel).rgb;
        }
    }
    blur /= 9.0;
    color += (color - blur) * SHARPEN;

    // ── 2. domar el neón ──
    // mix(luma, color, k) con k<1 desatura PROPORCIONAL a la saturación
    // existente: blanco/grises/negro (que ya son su propia luma) no cambian;
    // sólo los acentos saturados pierden el "zumbido" sobre #000.
    float l = luma(color);
    color   = mix(vec3(l), color, SATURATION);

    // ── 3. gamma lift en sombras ──
    // pow(c, g<1) levanta dim grays sin levantar el #000 (pow(0)=0), así el
    // negro OLED queda real y los grays tenues no desaparecen.
    color = pow(max(color, 0.0), vec3(GAMMA));

    // ── 4. domar el blanco (highlight rolloff) ──
    // min(r,g,b) es alto SÓLO en blancos/grises (un color saturado siempre
    // tiene al menos un canal bajo), así bajamos el brillo del texto blanco
    // sin tocar el neón ni las sombras. smoothstep = transición suave.
    float white = min(color.r, min(color.g, color.b));
    color *= mix(1.0, WHITE_LEVEL, smoothstep(WHITE_THRESH, 1.0, white));

    fragColor = vec4(color, center.a);
}
