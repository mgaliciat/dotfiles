// ═══════════════════════════════════════════════════════════════
//  E-Ink — pantalla de papel electrónico para Ghostty
//
//  Look objetivo: reMarkable / Kindle Paperwhite. Fondo cream
//  cálido (NO blanco puro — el blanco puro lastima en ambientes
//  iluminados y rompe la ilusión de papel), texto charcoal warm
//  (NO negro puro — la tinta carbón nunca llega a #000), grano
//  de fibra estático, dithering ordenado Bayer 4x4 en mid-tones
//  para imitar la cuantización de partículas, leve softening por
//  difusión de pigmento, vignette sutil de bezel de tablet.
//
//  Lo que NO hace y por qué:
//    - Sin bloom: e-ink es reflectivo, no emisivo.
//    - Sin scanlines/curvatura/aberración: no es un tubo.
//    - Sin flicker / refresh flash: sería molesto en terminal y
//      sin frame buffer no podemos simularlo bien.
//    - Sin animación de grano: e-ink es ESTÁTICO entre refreshes,
//      ese es el punto. Noise temporal lo arruina.
//
//  IMPORTANTE: respeta la paleta del theme pero la desatura casi
//  a grayscale y remapea al rango paper→charcoal. Por eso este
//  shader queda raro con themes oscuros — los colores se invierten
//  conceptualmente. Pairing recomendado: theme claro tipo `paper`
//  o `github-light`. Con dark themes el resultado es legible pero
//  pierde la metáfora (texto cream sobre charcoal, no al revés).
//
//  Ghostty convención shadertoy:
//    iChannel0   = textura del terminal renderizado
//    iResolution = (width, height, _)
//    iTime       = no se usa (static look)
// ═══════════════════════════════════════════════════════════════

// paleta de papel — colores en linear-ish sRGB.
// PAPER_BG: fondo gris tipo newsprint / e-reader low-power. Más
// alto = más claro (1.0 = blanco), más bajo = más gris oscuro.
// PAPER_INK: tinta del texto. (0.02..) es negro pleno; subí a
// (0.10..) si el contraste se siente muy duro.
const vec3 PAPER_BG  = vec3(0.780, 0.780, 0.780);
const vec3 PAPER_INK = vec3(0.020, 0.020, 0.020);

// Polaridad del theme: 1.0 para DARK themes (bg oscuro, texto claro
// en la fuente) — invierte el mapeo para que el bg del theme caiga
// en PAPER_BG y el texto en PAPER_INK. 0.0 para LIGHT themes (donde
// el bg fuente ya es claro y no necesita inversión). Si los colores
// te salen al revés (bg negro, texto gris), flipeá este valor.
const float DARK_THEME_INVERT  = 1.0;

// desaturación: 1.0 = grayscale total. E-ink real tiene matices
// imperceptibles, así que dejamos un 8% para que algún hint de
// color del theme se cuele (útil para syntax highlighting suave).
const float DESAT_AMOUNT       = 0.92;

// contraste — e-ink no muestra gradientes finos con gracia, las
// partículas son binarias (negro o blanco) y los grises salen
// por dithering. Subir contraste hace honor a esa naturaleza.
const float CONTRAST           = 1.18;

// dithering Bayer 4x4: cuantización ordenada que mimica cómo los
// e-paper displays representan grises (no pueden hacer alpha, solo
// patterns). 0.020 = sutil, sólo visible en mid-tones. 0.05+ se ve
// como impresión de baja resolución, divertido pero arruina la
// legibilidad del texto.
const float DITHER_AMOUNT      = 0.022;

// grano de fibra de papel — ruido espacial estático (no temporal).
// Multi-octava para que se vea fibra orgánica, no TV-noise.
const float GRAIN_AMOUNT       = 0.028;

// softening por difusión de partícula — los pigmentos cargados
// no caen en pixels exactos, hay halo de ~0.4px. Demasiado y el
// texto se ve borroso (anti e-ink: e-ink es famoso por ser nítido).
const float SOFTNESS_PIXELS    = 0.4;

// vignette del bezel de la tablet — muy sutil, solo para hint de
// que es una pantalla y no un PDF. 0.0 = desactivado.
const float VIGNETTE_AMOUNT    = 0.12;

// preserve-color por saturación — pixels más saturados que el
// threshold conservan su color original en lugar de mapearse al
// rango paper/charcoal. Pensado para que el spinner naranja de
// Claude Code (#d97757, S≈0.45) NO se evapore a blanco/gris.
// Side-effect: errores rojos, prompts coloreados y syntax highlight
// fuerte también conservan color. Eso es bug o feature según gusto.
//   LO ≈ donde EMPIEZA a conservar (más bajo = más cosas coloradas)
//   HI ≈ donde conserva 100% (más bajo = colores más vivos)
// Default sintonizado para preservar el naranja Claude sin que
// la mayoría del syntax highlight muted se cuele.
const float SAT_PRESERVE_LO    = 0.30;
const float SAT_PRESERVE_HI    = 0.55;

// Brillo de los pixels con color preservado — los amortigua para
// que matcheen el dim general del e-ink sin perder identidad
// cromática. 1.0 = color tal cual del theme, valores menores lo
// apagan. 0.75 ≈ se ve "pintado" sobre papel, no neón.
const float PRESERVED_BRIGHTNESS = 0.75;

// ───────────────────────────────────────────────────────────────

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// noise 2-octava para fibra de papel orgánica. Mezcla un grano
// fino (pixel-level) con uno más grueso (2x2) que simula las
// fibras de celulosa visibles en papel real.
float paperNoise(vec2 p) {
    float fine   = hash(p);
    float coarse = hash(floor(p * 0.5));
    return mix(fine, coarse, 0.4) - 0.5;
}

// Bayer 4x4 ordered dither matrix sin array literals — algunos
// drivers GLSL viejos chokean con `float[16](...)`, así que lo
// resolvemos con un switch en función del índice. Patrón estándar
// normalizado a [-0.5, 0.5].
float bayer4(vec2 p) {
    int x = int(mod(p.x, 4.0));
    int y = int(mod(p.y, 4.0));
    int i = x + y * 4;
    float v = 0.0;
         if (i ==  0) v =  0.0;
    else if (i ==  1) v =  8.0;
    else if (i ==  2) v =  2.0;
    else if (i ==  3) v = 10.0;
    else if (i ==  4) v = 12.0;
    else if (i ==  5) v =  4.0;
    else if (i ==  6) v = 14.0;
    else if (i ==  7) v =  6.0;
    else if (i ==  8) v =  3.0;
    else if (i ==  9) v = 11.0;
    else if (i == 10) v =  1.0;
    else if (i == 11) v =  9.0;
    else if (i == 12) v = 15.0;
    else if (i == 13) v =  7.0;
    else if (i == 14) v = 13.0;
    else if (i == 15) v =  5.0;
    return v / 16.0 - 0.5;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;

    // softening: 5-tap promedio cross-shaped. Cheap blur que mimica
    // la difusión de pigmento sin destruir bordes. Si subes mucho,
    // mejor cambiar a 9-tap gaussiano.
    vec2 px = vec2(SOFTNESS_PIXELS) / iResolution.xy;
    vec3 color = texture(iChannel0, uv).rgb;
    color += texture(iChannel0, uv + vec2( px.x, 0.0)).rgb;
    color += texture(iChannel0, uv + vec2(-px.x, 0.0)).rgb;
    color += texture(iChannel0, uv + vec2(0.0,  px.y)).rgb;
    color += texture(iChannel0, uv + vec2(0.0, -px.y)).rgb;
    color /= 5.0;

    // saturación HSV-S del pixel softeneado. Define qué tan
    // "cromático" es respecto al gris equivalente — pixels muy
    // saturados (spinner naranja, errores) brincan el remap a paper.
    float mx  = max(max(color.r, color.g), color.b);
    float mn  = min(min(color.r, color.g), color.b);
    float sat = mx > 0.001 ? (mx - mn) / mx : 0.0;
    float preserve = smoothstep(SAT_PRESERVE_LO, SAT_PRESERVE_HI, sat);

    // ── e-ink path (lo que se aplica a texto/UI desaturada) ──
    float lum  = dot(color, vec3(0.299, 0.587, 0.114));
    vec3 desat = mix(color, vec3(lum), DESAT_AMOUNT);
    float gray = dot(desat, vec3(1.0/3.0));

    // contraste alrededor de 0.5 — empuja oscuros a tinta y claros
    // a papel. Pivot en 0.5 asume mid-luminance razonable del theme.
    gray = (gray - 0.5) * CONTRAST + 0.5;

    // dithering ordenado ANTES de saturar para que los extremos también
    // dithereen; grano de fibra estático (sin iTime intencionalmente).
    gray += bayer4(fragCoord) * DITHER_AMOUNT;
    gray += paperNoise(fragCoord) * GRAIN_AMOUNT;
    gray = clamp(gray, 0.0, 1.0);

    // invertimos gray en dark themes: el bg del theme (luminance baja)
    // debe mapear al PAPER_BG (luminance alta), y el texto del theme
    // (luminance alta) al PAPER_INK (luminance baja).
    gray = mix(gray, 1.0 - gray, DARK_THEME_INVERT);

    vec3 paper = mix(PAPER_INK, PAPER_BG, gray);

    // blend final: pixels saturados conservan color (amortiguado
    // por PRESERVED_BRIGHTNESS para no contrastar con el e-ink dim),
    // el resto va al pipeline e-ink completo.
    vec3 final = mix(paper, color * PRESERVED_BRIGHTNESS, preserve);

    // vignette del bezel — radial cuadrático, sutil. Multiplicativo
    // sobre el resultado final para que afecte ambos paths por igual.
    vec2 vuv  = uv * 2.0 - 1.0;
    float vig = 1.0 - dot(vuv, vuv) * VIGNETTE_AMOUNT * 0.5;
    final *= vig;

    fragColor = vec4(final, 1.0);
}
