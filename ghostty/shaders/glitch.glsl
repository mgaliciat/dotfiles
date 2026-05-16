// ═══════════════════════════════════════════════════════════════
//  Glitch / Data Corruption — terminal con signal interference
//
//  Look objetivo: Mr. Robot / Matrix / película hacker — la mayor
//  parte del tiempo el terminal se ve casi limpio, pero cada cierto
//  rato hay un "glitch" que combina tears horizontales, RGB split,
//  bloques corruptos y un frame drop simulado.
//
//  La estética se basa en que la corrupción sea RARA — si está
//  glitcheando todo el tiempo se vuelve ruido distractor en vez de
//  un acento dramático. Para sesiones largas baja GLITCH_FREQUENCY.
//
//  Ghostty convención shadertoy:
//    iChannel0   = textura del terminal renderizado
//    iResolution = (width, height, _)
//    iTime       = segundos desde que Ghostty abrió
// ═══════════════════════════════════════════════════════════════

// frecuencia promedio de glitches (eventos / segundo).
// 0.3 ≈ uno cada 3 segundos. Subir a 1.0+ para demo / screenshot;
// bajar a 0.1 (uno cada 10s) para sesión de trabajo larga.
const float GLITCH_FREQUENCY     = 0.3;

// intensidad global — multiplica TODOS los efectos del glitch.
// 0.0 = shader desactivado, 1.0 = normal, 2.0 = dramático.
const float GLITCH_INTENSITY     = 1.0;

// tears horizontales: cuántas bandas y cuánto se desplazan.
// Más bandas = tears más finitos (look "tape").
const float TEAR_BANDS           = 14.0;
const float TEAR_AMOUNT          = 0.04;

// aberración cromática base (siempre activa) + extra durante glitch.
// Medida en UV, no pixels — escala con la resolución.
const float CHROMA_BASE          = 0.0010;
const float CHROMA_GLITCH        = 0.012;

// bandas de noise que scrollean lentamente — un toque "señal débil"
// presente todo el tiempo. Bajar opacidad a 0 para apagar.
const float NOISE_BAND_SPEED     = 0.18;
const float NOISE_BAND_OPACITY   = 0.10;

// block corruption: bloques cuadrados desplazados durante glitch.
// BLOCK_SIZE en pixels — bloques más chicos = corrupción más fina.
const float BLOCK_SIZE           = 12.0;
const float BLOCK_CORRUPT_CHANCE = 0.35;
const float BLOCK_DISPLACE_AMT   = 0.018;

// frame drop: durante el pico del glitch hay ~3% chance por frame
// de mostrar un cuadro casi-negro (sensación de "señal perdida").
const float FRAME_DROP_THRESHOLD = 0.85;
const float FRAME_DROP_DARKNESS  = 0.45;

// grano de fondo permanente — sutil, tipo CRT noise.
const float BASE_NOISE           = 0.018;

// ───────────────────────────────────────────────────────────────

float hash1(float p) {
    return fract(sin(p * 91.3458) * 47453.5453);
}

float hash2(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Pulso de glitch: dispara un evento corto a intervalos pseudo-random.
// Devuelve 0.0 la mayor parte del tiempo, sube a ~1.0 durante el glitch
// y decae exponencialmente. Duración total ~0.25s.
float glitchPulse(float t) {
    float interval = 1.0 / GLITCH_FREQUENCY;
    float seg      = floor(t / interval);
    float jitter   = hash1(seg) * interval * 0.85;
    float dt       = t - (seg * interval + jitter);
    if (dt < 0.0 || dt > 0.4) return 0.0;
    return exp(-dt * 10.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2  uv     = fragCoord / iResolution.xy;
    float t      = iTime;
    float glitch = glitchPulse(t) * GLITCH_INTENSITY;

    // ─── tears horizontales ──────────────────────────────────
    // Cada banda se desplaza random; el seed refresca varias veces
    // por segundo para que se vea inestable durante el glitch.
    float bandY    = floor(uv.y * TEAR_BANDS);
    float bandSeed = hash1(bandY + floor(t * 6.0));
    uv.x += (bandSeed - 0.5) * TEAR_AMOUNT * glitch;

    // ─── block corruption ────────────────────────────────────
    // Discretiza la pantalla en bloques BLOCK_SIZE × BLOCK_SIZE.
    // Bloques con hash bajo (umbral escalado por glitch) se mueven
    // a una posición offset random — efecto "ventana rota".
    vec2  block  = floor(fragCoord / BLOCK_SIZE);
    float bRand  = hash2(block + floor(t * 8.0));
    if (bRand < BLOCK_CORRUPT_CHANCE * glitch) {
        vec2 blockShift = vec2(
            hash2(block + 17.0) - 0.5,
            hash2(block + 31.0) - 0.5
        ) * BLOCK_DISPLACE_AMT * glitch;
        uv += blockShift;
    }

    // ─── aberración cromática ────────────────────────────────
    // Base mínima siempre + spike grande durante el glitch.
    float chroma = CHROMA_BASE + CHROMA_GLITCH * glitch;
    float r = texture(iChannel0, uv + vec2(chroma, 0.0)).r;
    float g = texture(iChannel0, uv).g;
    float b = texture(iChannel0, uv - vec2(chroma, 0.0)).b;
    vec3  color = vec3(r, g, b);

    // ─── noise band scrolleando ──────────────────────────────
    // Una franja delgada que sube por la pantalla constantemente;
    // dentro de la franja, el píxel se mezcla con noise random.
    float bandPos  = fract(uv.y - t * NOISE_BAND_SPEED);
    float bandMask = smoothstep(0.00, 0.03, bandPos)
                   * (1.0 - smoothstep(0.03, 0.08, bandPos));
    float bandNoise = (hash2(fragCoord + t * 13.0) - 0.5);
    color += vec3(bandNoise) * bandMask * NOISE_BAND_OPACITY;

    // ─── grano de fondo permanente ──────────────────────────
    color += (hash2(fragCoord + t * 7.0) - 0.5) * BASE_NOISE;

    // ─── frame drop durante pico del glitch ─────────────────
    // Cuando el pulso está cerca del peak, hay ~30% chance por frame
    // de oscurecer la imagen (señal perdida momentánea).
    if (glitch > FRAME_DROP_THRESHOLD) {
        float dropRand = hash1(floor(t * 28.0));
        if (dropRand < 0.30) {
            color = mix(color, vec3(0.0), FRAME_DROP_DARKNESS);
        }
    }

    fragColor = vec4(color, 1.0);
}
