// ═══════════════════════════════════════════════════════════════
//  LCD Dithered — terminal estilo pantalla LCD chunky (Game Boy)
//
//  Look objetivo: monitor LCD bicolor de fines de los 80s — pixels
//  visibles como cuadritos, paleta reducida, dithering ordenado tipo
//  Bayer, leve ghosting de tiempo de respuesta LCD, tint verdoso
//  característico del DMG (Dot Matrix Game).
//
//  Preserva los colores del theme actual pero los cuantiza y dithea
//  encima de la grilla LCD — el theme blueprint se ve azul-chunky,
//  el warm se ve sepia-chunky. Para perder los colores del theme y
//  forzar paleta Game Boy clásica, subir TINT_AMOUNT a ~0.7.
//
//  Ghostty convención shadertoy:
//    iChannel0   = textura del terminal renderizado
//    iResolution = (width, height, _)
//    iTime       = segundos desde que Ghostty abrió
// ═══════════════════════════════════════════════════════════════

// tamaño del "pixel LCD" en pixels FÍSICOS de pantalla.
// En Retina (2x), valores <6 son casi invisibles porque cada chunk
// queda <3 logical pixels. Pixel size sweet spot Retina:
//   6.0  = LCD denso pero lees normal
//   8.0  = Game Boy clásico (sweet spot)
//   12.0 = Game Boy XL muy chunky
const float PIXEL_SIZE       = 8.0;

// niveles de cuantización por canal (R, G, B independientes).
// 3 = bicolor estricto tipo DMG (Game Boy real, 4 niveles mono),
// 5 = retro saturado, 8 = 256 colores, 16 = casi continuo.
const float QUANT_LEVELS     = 4.0;

// intensidad del dithering Bayer 4x4 al cuantizar — suaviza los
// gradients en patrones cuadriculados visibles. 0 = bandas
// duras, 1 = dither completo.
const float DITHER_STRENGTH  = 0.8;

// "ghosting" tipo tiempo de respuesta LCD lento — mezcla con
// pixels vecinos. 0 = sin ghost (LCD moderno), 0.25 = LCD viejo
// notorio, 0.5 = STN ámbar de calculadora.
const float GHOST_AMOUNT     = 0.25;

// grid LCD: líneas oscuras entre pixels (gap del cristal).
// Con PIXEL_SIZE >= 6 esto se ve excelente. Bajar a 0.05 si
// el grid distrae.
const float GRID_OPACITY     = 0.22;

// tint del cristal LCD. Default = verde olive Game Boy DMG.
// Otros valores clásicos:
//   ámbar:  vec3(1.00, 0.84, 0.50)
//   azul:   vec3(0.70, 0.85, 1.00)
//   verde:  vec3(0.78, 0.95, 0.62)  ← default
const vec3  TINT             = vec3(0.78, 0.95, 0.62);

// cuánto del tint mezclar. 0.0 = preserva theme, 0.5 = clearly
// Game Boy-ish, 1.0 = paleta completamente reemplazada.
const float TINT_AMOUNT      = 0.35;

// vignette de borde — los LCD viejos perdían brillo en las esquinas.
// 0 = sin vignette, 0.6 = clásico Game Boy.
const float VIGNETTE_AMOUNT  = 0.35;

// ───────────────────────────────────────────────────────────────

// Bayer 4x4 ordered dither — patrón canónico para quantización con
// menor banding visible. Hardcoded como mat4 (no array initializer)
// para portabilidad: GLSL→Metal via SPIRV-Cross traduce mat4 bien
// pero `float[16](...)` rompe silently en algunas versiones.
// Devuelve aprox. [-0.5, +0.5].
const mat4 BAYER4 = mat4(
     0.0,  8.0,  2.0, 10.0,
    12.0,  4.0, 14.0,  6.0,
     3.0, 11.0,  1.0,  9.0,
    15.0,  7.0, 13.0,  5.0
);

float bayer4(vec2 p) {
    int x = int(mod(p.x, 4.0));
    int y = int(mod(p.y, 4.0));
    return BAYER4[y][x] / 16.0 - 0.46875;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;

    // ─── chunky pixel snap ─────────────────────────────────
    // Discretiza la posición de muestreo a bloques PIXEL_SIZE × PIXEL_SIZE.
    // Todos los pixels físicos dentro del bloque comparten el mismo color.
    vec2 chunkPos = floor(fragCoord / PIXEL_SIZE) * PIXEL_SIZE + PIXEL_SIZE * 0.5;
    vec2 chunkUV  = chunkPos / iResolution.xy;

    vec3 color = texture(iChannel0, chunkUV).rgb;

    // ─── LCD ghosting (motion blur lateral) ────────────────
    // No tenemos acceso al frame anterior, así que blureamos con
    // los chunks vecinos como proxy. Da la sensación de "el pixel
    // tarda en cambiar" típica de LCD viejo.
    if (GHOST_AMOUNT > 0.0) {
        vec2 step = vec2(PIXEL_SIZE / iResolution.x, PIXEL_SIZE / iResolution.y);
        vec3 ghost = (
            texture(iChannel0, chunkUV + vec2( step.x, 0.0)).rgb +
            texture(iChannel0, chunkUV + vec2(-step.x, 0.0)).rgb +
            texture(iChannel0, chunkUV + vec2(0.0,  step.y)).rgb +
            texture(iChannel0, chunkUV + vec2(0.0, -step.y)).rgb
        ) * 0.25;
        color = mix(color, ghost, GHOST_AMOUNT);
    }

    // ─── Bayer dither + quantización ───────────────────────
    // Sumamos el patrón Bayer al color antes de cuantizar — los
    // pixels en posiciones distintas del patrón redondean a niveles
    // diferentes, simulando un nivel intermedio visualmente.
    float dither = bayer4(fragCoord / PIXEL_SIZE) * DITHER_STRENGTH / QUANT_LEVELS;
    color += vec3(dither);
    color = floor(color * QUANT_LEVELS + 0.5) / QUANT_LEVELS;

    // ─── tint del cristal LCD ──────────────────────────────
    // Multiplicativo, no aditivo — el LCD literalmente filtra la luz
    // a través de su color. mix preserva theme cuando TINT_AMOUNT bajo.
    color = mix(color, color * TINT, TINT_AMOUNT);

    // ─── grid LCD entre pixels ─────────────────────────────
    // Dibuja líneas finitas en los bordes de cada chunky pixel.
    vec2 gridFrac = fract(fragCoord / PIXEL_SIZE);
    float gridX   = step(gridFrac.x, 1.0 / PIXEL_SIZE);
    float gridY   = step(gridFrac.y, 1.0 / PIXEL_SIZE);
    float grid    = clamp(gridX + gridY, 0.0, 1.0);
    color *= 1.0 - grid * GRID_OPACITY;

    // ─── vignette de borde ─────────────────────────────────
    vec2  vc       = uv - 0.5;
    float vignette = 1.0 - dot(vc, vc) * VIGNETTE_AMOUNT * 2.0;
    color *= clamp(vignette, 0.0, 1.0);

    fragColor = vec4(color, 1.0);
}
