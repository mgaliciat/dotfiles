// ═══════════════════════════════════════════════════════════════
//  Anthropic Minimal — para sesiones largas de lectura/SDD
//
//  Variante "reading-first" del anthropic-crt: mismo lenguaje visual
//  (bloom phosphor cálido + grain) pero SIN los efectos que afectan
//  legibilidad — sin curvatura, sin scanlines, sin aperture grille,
//  sin aberración cromática, sin flicker.
//
//  Look objetivo: el terminal se siente "vivo" y con personalidad
//  cálida, pero el texto se mantiene crisp y descansado para leer
//  specs largos, diffs densos, output de Claude Code, etc.
//
//  Si después de horas notas que cansa, baja BLOOM_AMOUNT y
//  BASE_NOISE a 0.0 — queda casi como un terminal pelado pero
//  con la consistencia de paleta del theme.
//
//  Ghostty convención shadertoy:
//    iChannel0   = textura del terminal renderizado
//    iResolution = (width, height, _)
//    iTime       = segundos desde que Ghostty abrió
// ═══════════════════════════════════════════════════════════════

// curvatura del tubo — sutil para sentir "monitor" sin pecera.
// 0.00 = totalmente plano (digital moderno)
// 0.02 = curvatura apenas perceptible (sweet spot lectura)
// 0.05 = visible, look CRT real
// 0.08+ = pecera dramática (cansa leyendo)
const vec2  CURVATURE          = vec2(0.0, 0.0);

// scanlines horizontales — la firma del CRT. Valores recomendados:
//   0.00 = sin scanlines
//   0.08 = apenas perceptible, no afecta lectura (sweet spot)
//   0.15 = visible pero suave (look retro presente)
//   0.28 = pesado tipo TV vintage (el del anthropic-crt clásico)
const float SCANLINE_OPACITY   = 0.18;
const float SCANLINE_THICKNESS = 1.0;

// aperture grille — bandas verticales R/G/B estilo Trinitron.
// Combinada con scanlines da la textura "fósforo CRT" visible que
// las scanlines solas pierden en Retina. Valores:
//   0.00 = desactivada
//   0.08 = sutil pero presente (sweet spot minimal)
//   0.15 = pesada tipo monitor de juegos
const float MASK_OPACITY       = 0.18;

// phosphor bloom — halo cálido sutil alrededor de pixels brillantes.
// El threshold alto (smoothstep 0.5→0.95) asegura que solo el texto
// brillante glow-ee, no el fondo. 0.18 es perceptible pero no fuzzy.
const float BLOOM_AMOUNT       = 0.18;
const float BLOOM_RADIUS       = 1.8;
const vec3  BLOOM_TINT         = vec3(1.05, 0.97, 0.85);

// grain de fondo permanente — sutil "texture" que evita el look
// plano LCD. 0.005 = casi invisible pero presente, 0.015 = notorio
// estilo film grain ligero.
const float BASE_NOISE         = 0.006;

// vignette MUY ligero — solo el ~8% de los píxeles extremos se ven
// atenuados. Foca la mirada al centro sin oscurecer trabajo real.
// 0.0 para desactivar completamente.
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
    // que la curvatura se note como bisel de monitor.
    if (cuv.x < 0.0 || cuv.x > 1.0 || cuv.y < 0.0 || cuv.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    vec3 color = texture(iChannel0, cuv).rgb;

    // ─── bloom phosphor ─────────────────────────────────────
    // Blur 8-tap alrededor del pixel; solo brillan los muy bright.
    // El smoothstep filtra pixels oscuros para no glow-ear el fondo.
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

    // ─── scanlines horizontales ─────────────────────────────
    // Patrón sinusoidal estático (sin roll) por fila de pixel.
    // Multiplicativo — preserva el color, solo modula el brillo.
    float scan = sin(fragCoord.y * 3.14159 / SCANLINE_THICKNESS) * 0.5 + 0.5;
    color *= 1.0 - scan * SCANLINE_OPACITY;

    // ─── aperture grille (RGB stripes verticales) ───────────
    // Cada columna de pixels favorece un canal (R, G o B) — los
    // otros dos se atenúan por MASK_OPACITY. Crea el patrón
    // "fósforo Trinitron" visible que las scanlines solas pierden.
    float sub = mod(fragCoord.x, 3.0);
    vec3  mask;
    if      (sub < 1.0) mask = vec3(1.0, 1.0 - MASK_OPACITY, 1.0 - MASK_OPACITY);
    else if (sub < 2.0) mask = vec3(1.0 - MASK_OPACITY, 1.0, 1.0 - MASK_OPACITY);
    else                mask = vec3(1.0 - MASK_OPACITY, 1.0 - MASK_OPACITY, 1.0);
    color *= mask;

    // ─── grain de fondo ─────────────────────────────────────
    // Sin iTime → estático en lugar de animado (cero distracción).
    color += (hash(fragCoord) - 0.5) * BASE_NOISE;

    // ─── vignette en coords curvadas ────────────────────────
    vec2  vc       = cuv - 0.5;
    float vignette = 1.0 - dot(vc, vc) * VIGNETTE_AMOUNT * 2.0;
    color *= clamp(vignette, 0.0, 1.0);

    fragColor = vec4(color, 1.0);
}
