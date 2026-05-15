// ═══════════════════════════════════════════════════════════════
//  Anthropic Heavy CRT — phosphor-tube terminal for Ghostty
//
//  Look objetivo: monitor de tubo de los 80s (Apple II / IBM 5151 /
//  arcade vintage). Curvatura barrel, scanlines marcadas, aperture
//  grille RGB, phosphor bloom cálido, flicker y vignette pesado.
//
//  Todas las constantes abajo son tweakeables. Bajar valores hacia
//  cero para un CRT más suave; subirlos para parecer un VT220.
//
//  Ghostty convención shadertoy:
//    iChannel0   = textura del terminal renderizado
//    iResolution = (width, height, _)
//    iTime       = segundos desde que Ghostty abrió
// ═══════════════════════════════════════════════════════════════

// curvatura del tubo (0.0 = plano, 0.08+ = pecera)
const vec2  CURVATURE          = vec2(0.06, 0.08);

// scanlines horizontales
const float SCANLINE_OPACITY   = 0.28;
const float SCANLINE_THICKNESS = 1.0;
const float ROLL_SPEED         = 0.04;

// aperture grille (phosphor stripes RGB verticales, estilo Trinitron)
const float MASK_OPACITY       = 0.18;

// aberración cromática — medida en PIXELES (no en UV) para que
// no escale absurdamente en pantallas Retina. ~0.6 = sutil pero visible.
const float CHROMATIC_PIXELS   = 0.6;

// phosphor bloom (halo cálido alrededor del texto)
const float BLOOM_AMOUNT       = 0.40;
const float BLOOM_RADIUS       = 2.5;
const vec3  BLOOM_TINT         = vec3(1.08, 0.92, 0.72);

// vignette pesado (esquinas oscuras)
const float VIGNETTE_AMOUNT    = 0.55;

// grano de fósforo
const float NOISE_AMOUNT       = 0.020;

// flicker de luminosidad (lento, no epiléptico)
const float FLICKER_AMOUNT     = 0.020;

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

    // bezel: pixels fuera del tubo se ven negros
    if (cuv.x < 0.0 || cuv.x > 1.0 || cuv.y < 0.0 || cuv.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // aberración cromática: cada canal samplea desplazado.
    // Shift convertido de pixels a UV → independiente de resolución.
    vec2 cshift = vec2(CHROMATIC_PIXELS / iResolution.x, 0.0);
    float r = texture(iChannel0, cuv + cshift).r;
    float g = texture(iChannel0, cuv).g;
    float b = texture(iChannel0, cuv - cshift).b;
    vec3 color = vec3(r, g, b);

    // phosphor bloom: blur 8-tap, sólo sobre pixels brillantes
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
    bloom *= smoothstep(0.30, 0.95, max(max(bloom.r, bloom.g), bloom.b));
    color += bloom * BLOOM_AMOUNT * BLOOM_TINT;

    // scanlines con roll vertical lento
    float scanY = cuv.y * iResolution.y - iTime * ROLL_SPEED * iResolution.y;
    float scan  = sin(scanY * 3.14159 / SCANLINE_THICKNESS) * 0.5 + 0.5;
    color *= 1.0 - scan * SCANLINE_OPACITY;

    // aperture grille — phosphor stripes RGB
    float sub = mod(fragCoord.x, 3.0);
    vec3 mask;
    if      (sub < 1.0) mask = vec3(1.0, 1.0 - MASK_OPACITY, 1.0 - MASK_OPACITY);
    else if (sub < 2.0) mask = vec3(1.0 - MASK_OPACITY, 1.0, 1.0 - MASK_OPACITY);
    else                mask = vec3(1.0 - MASK_OPACITY, 1.0 - MASK_OPACITY, 1.0);
    color *= mask;

    // grano de fósforo (animado por iTime)
    color += (hash(fragCoord + iTime) - 0.5) * NOISE_AMOUNT;

    // flicker lento — dos senos desfasados
    float flicker = 1.0 + sin(iTime * 1.7) * FLICKER_AMOUNT
                       + sin(iTime * 5.3) * FLICKER_AMOUNT * 0.35;
    color *= flicker;

    // vignette en coordenadas curvadas
    vec2 vc = cuv - 0.5;
    float vignette = 1.0 - dot(vc, vc) * VIGNETTE_AMOUNT * 2.5;
    color *= clamp(vignette, 0.0, 1.0);

    fragColor = vec4(color, 1.0);
}
