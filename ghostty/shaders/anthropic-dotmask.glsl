// ═══════════════════════════════════════════════════════════════
//  Anthropic Dot Mask — variante "grilla visible" del minimal
//
//  Mismo lenguaje visual que anthropic-minimal (bloom phosphor
//  cálido + grain + vignette sutil), pero reemplaza el aperture
//  grille (stripes verticales RGB tipo Trinitron) por un dot mask
//  2×2 — el otro tipo histórico de máscara CRT, más típica de
//  monitores de PC que de TVs Sony.
//
//  Diferencia visual práctica: el aperture grille en Retina se
//  funde y se percibe casi solo como un leve shift de color. El
//  dot mask tiene estructura en X y en Y a la vez → se ve como
//  una grilla fina permanente en el fondo, incluso sobre celdas
//  sin texto. Es lo que da esa sensación de "pantalla con textura"
//  en screenshots del splash de Claude Code.
//
//  Si la textura termina siendo demasiado presente para sesiones
//  largas, bajá MASK_OPACITY a 0.10 o cambiá la línea custom-shader
//  en config.ghostty para volver al minimal.
//
//  Ghostty convención shadertoy:
//    iChannel0   = textura del terminal renderizado
//    iResolution = (width, height, _)
//    iTime       = segundos desde que Ghostty abrió
// ═══════════════════════════════════════════════════════════════

// curvatura del tubo — sutil para sentir "monitor" sin pecera.
//   0.00 = totalmente plano (digital moderno) ← default minimal
//   0.02 = curvatura apenas perceptible
//   0.05 = visible, look CRT real
const vec2  CURVATURE          = vec2(0.0, 0.0);

// scanlines horizontales. En esta variante las bajamos respecto
// al minimal (0.18 → 0.10) porque el dot mask ya aporta bastante
// textura — sumar scanlines fuertes encima cansa.
const float SCANLINE_OPACITY   = 0.10;
const float SCANLINE_THICKNESS = 1.0;

// roll vertical lento — el shift de las scanlines con iTime.
const float ROLL_SPEED         = 0.04;

// dot mask 2×2: opacidad del oscurecimiento de canales NO-dominantes
// en cada celda. Trabaja igual que MASK_OPACITY del aperture grille
// minimal, pero como el patrón es 2D, el efecto neto es más visible
// a la misma magnitud. Sweet spot:
//   0.10 = grilla apenas perceptible
//   0.18 = grilla presente pero discreta
//   0.28 = grilla claramente visible (sweet spot dotmask)
//   0.40 = grilla pesada, look monitor PC vintage
const float MASK_OPACITY       = 0.28;

// phosphor bloom — halo cálido sutil. Idéntico al minimal.
const float BLOOM_AMOUNT       = 0.18;
const float BLOOM_RADIUS       = 1.8;
const vec3  BLOOM_TINT         = vec3(1.05, 0.97, 0.85);

// grain de fondo permanente — estático (sin iTime) para no distraer.
const float BASE_NOISE         = 0.006;

// vignette MUY ligero — focal sin oscurecer trabajo real.
const float VIGNETTE_AMOUNT    = 0.12;

// ───────────────────────────────────────────────────────────────

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 curveUV(vec2 uv) {
    uv = uv * 2.0 - 1.0;
    vec2 offset = abs(uv.yx) * CURVATURE;
    uv = uv + uv * offset * offset;
    return uv * 0.5 + 0.5;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv  = fragCoord / iResolution.xy;
    vec2 cuv = curveUV(uv);

    // bezel: pixels fuera del "tubo" virtual se ven negros para
    // que la curvatura se note como bisel. Con CURVATURE=0 el
    // branch nunca se toma, pero lo dejamos por si subís el valor.
    if (cuv.x < 0.0 || cuv.x > 1.0 || cuv.y < 0.0 || cuv.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    vec3 color = texture(iChannel0, cuv).rgb;

    // ─── bloom phosphor ─────────────────────────────────────
    // Blur 8-tap alrededor del pixel; solo brillan los muy bright.
    // smoothstep(0.50, 0.95) filtra el fondo para no glow-earlo.
    vec3 bloom = vec3(0.0);
    vec2 bs    = vec2(BLOOM_RADIUS) / iResolution.xy;
    bloom += texture(iChannel0, cuv + bs * vec2( 1.0,  1.0)).rgb;
    bloom += texture(iChannel0, cuv + bs * vec2(-1.0,  1.0)).rgb;
    bloom += texture(iChannel0, cuv + bs * vec2( 1.0, -1.0)).rgb;
    bloom += texture(iChannel0, cuv + bs * vec2(-1.0, -1.0)).rgb;
    bloom += texture(iChannel0, cuv + bs * vec2( 1.4,  0.0)).rgb;
    bloom += texture(iChannel0, cuv + bs * vec2(-1.4,  0.0)).rgb;
    bloom += texture(iChannel0, cuv + bs * vec2( 0.0,  1.4)).rgb;
    bloom += texture(iChannel0, cuv + bs * vec2( 0.0, -1.4)).rgb;
    bloom /= 8.0;
    bloom *= smoothstep(0.50, 0.95, max(max(bloom.r, bloom.g), bloom.b));
    color += bloom * BLOOM_AMOUNT * BLOOM_TINT;

    // ─── scanlines horizontales con roll lento ──────────────
    // Multiplicativo; preserva el color y solo modula brillo.
    float scanY = fragCoord.y - iTime * ROLL_SPEED * iResolution.y;
    float scan  = sin(scanY * 3.14159 / SCANLINE_THICKNESS) * 0.5 + 0.5;
    color *= 1.0 - scan * SCANLINE_OPACITY;

    // ─── dot mask 2×2 (vs aperture grille del minimal) ──────
    // Cada bloque de 2×2 píxeles físicos asigna un canal dominante
    // a cada subpixel siguiendo el patrón:
    //
    //     ┌───┬───┐
    //     │ R │ G │
    //     ├───┼───┤
    //     │ G │ B │
    //     └───┴───┘
    //
    // El canal dominante queda en 1.0; los otros dos se atenúan por
    // MASK_OPACITY. Como el patrón tiene estructura en X y en Y a la
    // vez (no solo X como el aperture grille), el ojo lo percibe
    // como una *grilla* visible incluso en Retina, no como un leve
    // shift de color. Es el efecto "screen door" sutil que se nota
    // en screenshots del splash de Claude Code.
    //
    // La duplicación del verde en (1,0) y (0,1) imita la mayor
    // sensibilidad del ojo humano al verde — los CRTs reales tenían
    // más fósforos verdes que rojos o azules por la misma razón.
    vec2 cell = mod(floor(fragCoord), 2.0);
    vec3 mask;
    if      (cell.x < 0.5 && cell.y < 0.5) mask = vec3(1.0,                 1.0 - MASK_OPACITY, 1.0 - MASK_OPACITY); // R
    else if (cell.x > 0.5 && cell.y < 0.5) mask = vec3(1.0 - MASK_OPACITY, 1.0,                 1.0 - MASK_OPACITY); // G
    else if (cell.x < 0.5 && cell.y > 0.5) mask = vec3(1.0 - MASK_OPACITY, 1.0,                 1.0 - MASK_OPACITY); // G
    else                                   mask = vec3(1.0 - MASK_OPACITY, 1.0 - MASK_OPACITY, 1.0);                 // B
    color *= mask;

    // ─── grain de fondo ─────────────────────────────────────
    // Sin iTime → estático, cero distracción en sesiones largas.
    color += (hash(fragCoord) - 0.5) * BASE_NOISE;

    // ─── vignette en coords curvadas ────────────────────────
    vec2  vc       = cuv - 0.5;
    float vignette = 1.0 - dot(vc, vc) * VIGNETTE_AMOUNT * 2.0;
    color *= clamp(vignette, 0.0, 1.0);

    fragColor = vec4(color, 1.0);
}
