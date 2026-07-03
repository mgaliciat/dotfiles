// crt.glsl — CRT sutil y 100% ESTÁTICO para Ghostty.
//
// Look objetivo: monitor de fósforo (Apple II / VT220), pero sin nada que
// se mueva. El repo ya pasó por un CRT "heavy" (curvatura, scanlines con
// roll vertical, flicker, grano animado) y terminó revertido a cero shaders
// — el roll de scanlines y el flicker leían como "temblor" molesto en
// sesiones largas de lectura de código. Esta versión es la lección
// aprendida: scanlines fijas (función de fragCoord, NUNCA de iTime),
// aperture grille tenue y bloom cálido. Sin curvatura (rompe legibilidad
// en los bordes de una terminal de código), sin vignette, sin flicker,
// sin grano — cero uso de iTime en todo el shader.
//
// Formato Shadertoy (lo que Ghostty espera): el contenido del terminal
// llega en iChannel0; escribimos el pixel final en fragColor.
//
// Tuning: bajar los *_OPACITY hacia 0 para un CRT más tenue, subirlos para
// más carácter retro. Ghostty recarga el shader al guardar config (⌘⇧R),
// pero conviene reabrir la ventana si el cambio no se nota.

// ─── parámetros ───────────────────────────────────────────────
// Scanlines horizontales fijas — SCANLINE_THICKNESS es el período en
// pixels de pantalla; sin término de iTime, no hay roll.
const float SCANLINE_OPACITY   = 0.22;
const float SCANLINE_THICKNESS = 2.0;

// Aperture grille (phosphor stripes RGB verticales, estilo Trinitron).
const float MASK_OPACITY       = 0.12;

// Phosphor bloom: halo cálido alrededor de pixels brillantes (texto).
// Sólo afecta a lo que ya es brillante (smoothstep abajo), así que el
// negro de fondo queda intacto.
const float BLOOM_AMOUNT       = 0.30;
const float BLOOM_RADIUS       = 2.0;
const vec3  BLOOM_TINT         = vec3(1.06, 0.95, 0.85);

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;

    // Sample central. Preservamos su alpha para no romper la
    // transparencia/blur de background-opacity + background-blur.
    vec4 center = texture(iChannel0, uv);
    vec3 color  = center.rgb;

    // ── phosphor bloom ──
    // Blur 8-tap barato, atenuado por smoothstep para que sólo el texto
    // brillante "sangre" luz — el fondo oscuro no se ve afectado.
    vec3 bloom = vec3(0.0);
    vec2 bs    = vec2(BLOOM_RADIUS) / iResolution.xy;
    bloom += texture(iChannel0, uv + bs * vec2( 1.0,  1.0)).rgb;
    bloom += texture(iChannel0, uv + bs * vec2(-1.0,  1.0)).rgb;
    bloom += texture(iChannel0, uv + bs * vec2( 1.0, -1.0)).rgb;
    bloom += texture(iChannel0, uv + bs * vec2(-1.0, -1.0)).rgb;
    bloom += texture(iChannel0, uv + bs * vec2( 1.4,  0.0)).rgb;
    bloom += texture(iChannel0, uv + bs * vec2(-1.4,  0.0)).rgb;
    bloom += texture(iChannel0, uv + bs * vec2( 0.0,  1.4)).rgb;
    bloom += texture(iChannel0, uv + bs * vec2( 0.0, -1.4)).rgb;
    bloom /= 8.0;
    bloom *= smoothstep(0.30, 0.95, max(max(bloom.r, bloom.g), bloom.b));
    color += bloom * BLOOM_AMOUNT * BLOOM_TINT;

    // ── scanlines fijas ──
    // Función pura de fragCoord.y: el mismo pixel de pantalla siempre cae
    // en la misma fase, así que no hay percepción de movimiento aunque el
    // contenido debajo scrollee.
    float scan = sin(fragCoord.y * 3.14159 / SCANLINE_THICKNESS) * 0.5 + 0.5;
    color *= 1.0 - scan * SCANLINE_OPACITY;

    // ── aperture grille ──
    // Stripes RGB por columna de pixel, igual que un shadow mask real.
    float sub = mod(fragCoord.x, 3.0);
    vec3 mask;
    if      (sub < 1.0) mask = vec3(1.0, 1.0 - MASK_OPACITY, 1.0 - MASK_OPACITY);
    else if (sub < 2.0) mask = vec3(1.0 - MASK_OPACITY, 1.0, 1.0 - MASK_OPACITY);
    else                mask = vec3(1.0 - MASK_OPACITY, 1.0 - MASK_OPACITY, 1.0);
    color *= mask;

    fragColor = vec4(color, center.a);
}
