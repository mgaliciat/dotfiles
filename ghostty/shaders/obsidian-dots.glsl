// ═══════════════════════════════════════════════════════════════
//  Obsidian Dots — halftone phosphor matrix cyan, high contrast
//
//  Pensado para el theme `obsidian`: fondo #000 puro + acento
//  cyan eléctrico (#00e5ff). Misma técnica que el viejo
//  anthropic-dots (grilla regular de puntos circulares monocromos
//  que iluminan el frame aditivamente) pero la paleta es FRÍA en
//  vez de cálida → no compite con ningún warm en el código y
//  pega con el tono "production / tech" del theme.
//
//  Capas:
//    1. ambient dots  punto cyan tenue aditivo en cada celda
//                     → grilla visible incluso sobre fondo plano
//    2. text dotting  los gaps entre dots oscurecen las celdas con
//                     texto → el carácter se ve "compuesto de
//                     puntos phosphor"
//    3. vignette dark vignette neutral (no warm) hacia los bordes
//
//  Calibrado para fondo MUY OSCURO (#000-#0a0a0a). Sobre fondo
//  claro o medio se ve mal.
//
//  Sin iTime → estático. No distrae en sesiones largas.
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
//   4.0 = sweet spot
//   6.0 = puntos grandes, look retro
const float DOT_SCALE      = 4.0;

// DOT_RADIUS: tamaño del punto dentro de cada celda (0..0.5).
const float DOT_RADIUS     = 0.35;

// DOT_EDGE: ancho del antialiasing del borde.
const float DOT_EDGE       = 0.10;

// ─── 1. ambient dots (sobre fondo dark) ───────────────────────
// Punto cyan aditivo en cada celda — visible sobre #000 incluso
// donde no hay texto. El cyan oscuro no compite con texto blanco;
// solo "ilumina" el vacío.
//
// AMBIENT_AMOUNT: intensidad del aditivo.
//   0.018 = textura presente pero la grilla no domina (actual)
//   0.04  = grilla visible cómodamente
//   0.08  = grilla protagonista
const float AMBIENT_AMOUNT = 0.018;

// AMBIENT_COLOR: color del punto. Cyan profundo — coherente con
// el acento #00e5ff del theme pero más oscuro (porque va aditivo
// sobre #000, no queremos puntos blancos brillantes).
const vec3  AMBIENT_COLOR  = vec3(0.00, 0.55, 0.70);

// ─── 2. text dotting (sobre celdas con texto) ─────────────────
// Atenúa los GAPS entre dots cuando hay un carácter brillante
// debajo → el char queda visiblemente "compuesto de puntos".
//
// TEXT_DARKEN: cuánto oscurecer los gaps entre dots.
//   0.12 = texto apenas puntilleado, look "phosphor leve" (actual)
//   0.25 = puntilleado claro, look dotmask
//   0.45 = puntilleado intenso, revisar legibilidad
const float TEXT_DARKEN    = 0.12;

// Range de bgLuma donde aplicamos el efecto.
const float TEXT_LUMA_LOW  = 0.08;
const float TEXT_LUMA_HIGH = 0.45;

// ─── vignette dark neutral ────────────────────────────────────
// Oscurecimiento radial sutil hacia bordes — sin tinte warm
// (no queremos sumar calidez al theme cool).
const float VIGNETTE_AMOUNT = 0.20;
const float VIGNETTE_INNER  = 0.30;
const float VIGNETTE_OUTER  = 0.95;

// ───────────────────────────────────────────────────────────────

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv    = fragCoord / iResolution.xy;
    vec3 color = texture(iChannel0, uv).rgb;

    // ─── dot mask base ──────────────────────────────────────
    vec2  cellPos = mod(fragCoord, DOT_SCALE) / DOT_SCALE;
    float dist    = length(cellPos - 0.5);
    float dotMask = smoothstep(DOT_RADIUS, DOT_RADIUS - DOT_EDGE, dist);

    // ─── 1. ambient dots aditivos ───────────────────────────
    color += AMBIENT_COLOR * dotMask * AMBIENT_AMOUNT;

    // ─── 2. text dotting ────────────────────────────────────
    float bgLuma = dot(texture(iChannel0, uv).rgb, vec3(0.299, 0.587, 0.114));
    float effect = smoothstep(TEXT_LUMA_LOW, TEXT_LUMA_HIGH, bgLuma);
    float gap    = 1.0 - dotMask;
    color *= 1.0 - gap * TEXT_DARKEN * effect;

    // ─── 3. vignette neutral ────────────────────────────────
    vec2  vc       = uv - 0.5;
    float d        = length(vc) * 1.4142;
    float vfalloff = smoothstep(VIGNETTE_INNER, VIGNETTE_OUTER, d) * VIGNETTE_AMOUNT;
    color *= 1.0 - vfalloff;

    fragColor = vec4(color, 1.0);
}
