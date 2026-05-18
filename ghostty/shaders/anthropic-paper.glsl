// ═══════════════════════════════════════════════════════════════
//  Anthropic Paper — halftone print dot mask para tema CLARO
//
//  Equivalente al dot mask CRT (anthropic-dotmask.glsl) pero
//  adaptado a fondo claro. La diferencia clave:
//
//    CRT dotmask:    cada subpíxel domina un canal R/G/B distinto
//                    → sobre cream genera bandas RGB feas.
//    Paper halftone: cada celda tiene un punto circular sepia
//                    → modula SOLO luminancia, no canales.
//                    → look "imprenta offset / periódico zoom in".
//
//  Es el mismo lenguaje histórico (grilla 2D regular que aporta
//  textura) pero usando el equivalente del medio: los printers
//  offset reales descomponen una imagen en dots circulares de
//  tinta sobre papel. Por eso pega con anthropic-paper sin pelearse.
//
//  Capas:
//    1. halftone dots   patrón circular en grilla DOT_SCALE px
//    2. vignette cream  mezcla a sepia warm en los bordes
//
//  Sin scanlines, sin RGB mask, sin iTime → estático, no distrae.
//
//  Ghostty convención shadertoy:
//    iChannel0   = textura del terminal renderizado
//    iResolution = (width, height, _)
//    iTime       = no se usa
// ═══════════════════════════════════════════════════════════════

// ─── halftone dot mask ────────────────────────────────────────
// DOT_SCALE: tamaño del bloque en pixels FÍSICOS. En Retina @2x,
// 4 px físicos = 2 px lógicos → grilla visible pero no agresiva.
// Subilo (6-8) para puntos más gordos tipo serigrafía, bajalo (2-3)
// para una textura más fina tipo papel fotográfico.
const float DOT_SCALE      = 4.0;

// DOT_RADIUS: tamaño del punto dentro de cada celda (0..0.5).
//   0.30 = puntos chicos, mucho aire (más papel, menos tinta)
//   0.38 = sweet spot, balance papel/tinta
//   0.45 = puntos casi tocándose (look serigrafía densa)
const float DOT_RADIUS     = 0.38;

// DOT_EDGE: ancho del antialiasing del borde del dot. Más grande
// = bordes más difusos (look tinta absorbida); más chico = bordes
// más nítidos (look impresión digital).
const float DOT_EDGE       = 0.10;

// DOT_INTENSITY: cuánto oscurece el centro del dot vs. fuera.
//   0.06 = apenas perceptible
//   0.12 = visible pero discreto (sweet spot)
//   0.22 = grilla fuerte, look newspaper print
const float DOT_INTENSITY  = 0.12;

// DOT_TINT: color al que tiende el centro del dot. Sepia warm =
// tinta que pegó con un cream kraft. Gris puro se vería digital.
const vec3  DOT_TINT       = vec3(0.55, 0.42, 0.28);

// DOT_TINT_AMOUNT: cuánto del color tiende al tint sepia. 0 = solo
// oscurecimiento monocromo (más seguro, sin shift de color). >0
// suma calidez al dot. Mantenelo bajo para no crear bandas.
const float DOT_TINT_AMOUNT = 0.35;

// ─── vignette cream → sepia warm ──────────────────────────────
// Mezcla los bordes hacia un cream más profundo (no a negro).
const float VIGNETTE_AMOUNT  = 0.12;
const float VIGNETTE_INNER   = 0.30;
const float VIGNETTE_OUTER   = 0.90;
const vec3  VIGNETTE_TINT    = vec3(0.86, 0.78, 0.64);

// ───────────────────────────────────────────────────────────────

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv    = fragCoord / iResolution.xy;
    vec3 color = texture(iChannel0, uv).rgb;

    // ─── halftone dot ───────────────────────────────────────
    // Posición dentro de la celda DOT_SCALE×DOT_SCALE (0..1):
    vec2  cellPos = mod(fragCoord, DOT_SCALE) / DOT_SCALE;
    // Distancia al centro de la celda (0 en centro, ~0.71 en esquina):
    float dist    = length(cellPos - 0.5);
    // smoothstep INVERTIDO (high→low) → 1 en el centro del dot,
    // 0 fuera, con un borde suave de ancho DOT_EDGE.
    float dotMask = smoothstep(DOT_RADIUS, DOT_RADIUS - DOT_EDGE, dist);

    // Aplicación dual:
    //  (a) oscurecimiento MONOCROMO uniforme → modula luminancia
    //      sin shiftear color (no crea bandas R/G/B).
    //  (b) leve mezcla a DOT_TINT → suma calidez al punto, como
    //      tinta sepia sobre papel. Modulado por DOT_TINT_AMOUNT.
    float darken = dotMask * DOT_INTENSITY;
    color *= (1.0 - darken);
    color  = mix(color, color * DOT_TINT, darken * DOT_TINT_AMOUNT);

    // ─── vignette cream ─────────────────────────────────────
    vec2  vc       = uv - 0.5;
    float d        = length(vc) * 1.4142;   // norm → 0..1 (esquina = 1)
    float vfalloff = smoothstep(VIGNETTE_INNER, VIGNETTE_OUTER, d) * VIGNETTE_AMOUNT;
    color = mix(color, color * VIGNETTE_TINT, vfalloff);

    fragColor = vec4(color, 1.0);
}
