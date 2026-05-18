// ═══════════════════════════════════════════════════════════════
//  Anthropic Dots — halftone phosphor matrix para tema OSCURO
//
//  Hermano de anthropic-paper.glsl (halftone print para light).
//  Mismo lenguaje visual — grilla regular de puntos circulares
//  monocromos — pero invertido cromáticamente:
//
//    anthropic-paper:  puntos OSCUROS sepia sobre fondo cream
//                      (look "imprenta offset sobre papel")
//    anthropic-dots:   puntos CÁLIDOS ámbar sobre fondo oscuro
//                      (look "matrix de phosphor warm encendido")
//
//  Monocromo y circular: modula luminancia (no canales R/G/B),
//  por lo que evita las bandas RGB típicas del dot mask CRT clásico.
//
//  El shader tiene dos componentes:
//
//    1. ambient dots  punto cálido aditivo en cada celda del fondo
//                     → la grilla es visible incluso sobre vacío
//    2. text dotting  los gaps entre dots oscurecen las celdas con
//                     texto → el carácter se ve "compuesto de
//                     puntos phosphor"
//
//  Combinados: el frame entero respira como un panel matricial
//  warm, sin animación y sin bandas RGB. Sin iTime.
//
//  Calibrado para fondo OSCURO. Sobre cream se ve mal.
//
//  Ghostty convención shadertoy:
//    iChannel0   = textura del terminal renderizado
//    iResolution = (width, height, _)
//    iTime       = no se usa
// ═══════════════════════════════════════════════════════════════

// ─── geometría de la grilla ───────────────────────────────────
// DOT_SCALE: tamaño del bloque en pixels FÍSICOS. En Retina @2x,
// 4 px físicos = 2 px lógicos.
//   3.0 = grilla fina, casi imperceptible
//   4.0 = sweet spot, grilla visible sin agresión
//   6.0 = puntos grandes, look retro
const float DOT_SCALE      = 4.0;

// DOT_RADIUS: tamaño del punto dentro de cada celda (0..0.5).
//   0.28 = puntos chicos, mucho aire entre ellos
//   0.35 = sweet spot
//   0.45 = puntos casi tocándose
const float DOT_RADIUS     = 0.35;

// DOT_EDGE: ancho del antialiasing del borde.
const float DOT_EDGE       = 0.10;

// ─── 1. ambient dots (sobre fondo dark) ───────────────────────
// Punto cálido aditivo en cada celda — visible incluso donde no
// hay texto. Le da al frame esa sensación "panel encendido".
//
// AMBIENT_AMOUNT: intensidad del aditivo.
//   0.02 = sutilísimo, solo visible si te concentrás
//   0.04 = sweet spot, grilla visible cómodamente
//   0.08 = grilla protagonista
const float AMBIENT_AMOUNT = 0.04;

// AMBIENT_COLOR: color del punto. Warm sepia/ámbar — coherente
// con la paleta del setup (#d97757 / #d9a441 family).
const vec3  AMBIENT_COLOR  = vec3(0.85, 0.55, 0.28);

// ─── 2. text dotting (sobre celdas con texto) ─────────────────
// Atenúa los GAPS entre dots cuando hay un carácter brillante
// debajo → el char queda visiblemente "compuesto de puntos".
//
// TEXT_DARKEN: cuánto oscurecer los gaps entre dots en texto.
//   0.15 = atenuación leve, char apenas puntilleado
//   0.30 = sweet spot, look phosphor
//   0.50 = char muy puntilleado, revisar legibilidad
const float TEXT_DARKEN    = 0.30;

// Range de bgLuma donde aplicamos el efecto. Por debajo de LOW
// no hay texto (fondo dark), por encima de HIGH es char pleno.
const float TEXT_LUMA_LOW  = 0.08;
const float TEXT_LUMA_HIGH = 0.40;

// ─── vignette dark warm ───────────────────────────────────────
// Leve oscurecimiento radial hacia bordes; mantiene focal central
// sin crear túnel.
const float VIGNETTE_AMOUNT = 0.18;
const float VIGNETTE_INNER  = 0.30;
const float VIGNETTE_OUTER  = 0.95;

// ───────────────────────────────────────────────────────────────

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv    = fragCoord / iResolution.xy;
    vec3 color = texture(iChannel0, uv).rgb;

    // ─── dot mask base ──────────────────────────────────────
    // Posición dentro de la celda DOT_SCALE×DOT_SCALE (0..1):
    vec2  cellPos = mod(fragCoord, DOT_SCALE) / DOT_SCALE;
    // Distancia al centro de la celda (0 centro, ~0.71 esquina):
    float dist    = length(cellPos - 0.5);
    // 1 dentro del dot, 0 fuera, con borde suave AA:
    float dotMask = smoothstep(DOT_RADIUS, DOT_RADIUS - DOT_EDGE, dist);

    // ─── 1. ambient dots aditivos ───────────────────────────
    // Solo se ven sobre fondo dark; sobre carácter brillante se
    // pierden por contraste, lo cual está bien — no queremos que
    // los dots compitan con el texto.
    color += AMBIENT_COLOR * dotMask * AMBIENT_AMOUNT;

    // ─── 2. text dotting (gaps oscurecen el texto) ──────────
    // Luma del frame original (no afectado por el ambient, que
    // sumó un par de %). Sirve como detector de "¿hay texto acá?".
    float bgLuma = dot(texture(iChannel0, uv).rgb, vec3(0.299, 0.587, 0.114));
    // 0 si fondo dark, 1 si char brillante:
    float effect = smoothstep(TEXT_LUMA_LOW, TEXT_LUMA_HIGH, bgLuma);

    // gap = 1 - dotMask = 1 entre dots, 0 sobre dots
    float gap    = 1.0 - dotMask;
    // Atenúa proporcional a (gap × effect × darken):
    color *= 1.0 - gap * TEXT_DARKEN * effect;

    // ─── 3. vignette dark warm ──────────────────────────────
    vec2  vc       = uv - 0.5;
    float d        = length(vc) * 1.4142;
    float vfalloff = smoothstep(VIGNETTE_INNER, VIGNETTE_OUTER, d) * VIGNETTE_AMOUNT;
    color *= 1.0 - vfalloff;

    fragColor = vec4(color, 1.0);
}
