// crt — a still CRT: scanlines, aperture grille, phosphor bloom, vignette.
//
// Shadertoy-compatible, loaded by `custom-shader` in config.ghostty and run
// after Ghostty's own passes over iChannel0 (the rendered terminal).
//
// Deliberately STATIC. No screen curvature and no rolling band: nothing here
// reads iTime, so `custom-shader-animation = false` in the config keeps the
// render loop idle until the terminal itself changes. A curvature pass would
// also resample the text and blur every glyph edge, which on a light canvas
// reads as a dirty screen rather than an old one.
//
// fragCoord is in device pixels (2× on Retina), so the periods below are
// device pixels: a 4px scanline is two logical pixels, about a fifth of a
// text row at the current font size. iResolution is the surface size in the
// same units.
//
// Tuned on typesafe's sage canvas (#98a6a5). Every effect darkens, so on a
// light background the strengths sit lower than a dark-theme CRT would use;
// raise SCANLINE and MASK first if a dark theme comes back.
//
// Brightness-neutral on average. The shader covers the terminal surface only:
// the titlebar (`macos-titlebar-style = transparent`) is painted in the bare
// background colour, so any net darkening shows as a seam under it. GAIN
// undoes the mean loss of the scanlines (1 - S/2) and the grille (1 - 2M/3),
// and the vignette is radial with a dead zone, so the edge centres — where the
// surface meets the titlebar — stay at 1.0 and only the corners fall off.
// Whites above ~0.87 clip at scanline peaks; the canvas itself does not.

const float SCANLINE_PERIOD   = 4.0;   // device px between scanline centres
const float SCANLINE_STRENGTH = 0.16;  // 0 = off, 1 = black gaps
const float MASK_STRENGTH     = 0.08;  // aperture grille: how much the two off-channels dim per stripe
const float BLOOM             = 0.22;  // blend of the 4-tap neighbour average into the pixel
const float VIGNETTE          = 0.22;  // darkening reached at the corners
const float VIGNETTE_START    = 0.55;  // radius (0 centre … ~0.85 corner) where the falloff begins
const float GAIN              = 1.0 / ((1.0 - SCANLINE_STRENGTH * 0.5) * (1.0 - MASK_STRENGTH * 2.0 / 3.0));

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 src = texture(iChannel0, uv);
    vec3 col = src.rgb;

    // Phosphor bloom: a cheap cross blur, mixed in lightly so glyph edges
    // glow a little instead of smearing.
    vec2 px = 1.0 / iResolution.xy;
    vec3 around = texture(iChannel0, uv + vec2( px.x, 0.0)).rgb
                + texture(iChannel0, uv + vec2(-px.x, 0.0)).rgb
                + texture(iChannel0, uv + vec2(0.0,  px.y)).rgb
                + texture(iChannel0, uv + vec2(0.0, -px.y)).rgb;
    col = mix(col, around * 0.25, BLOOM);

    // Scanlines: a cosine per period, 1.0 on the line, 0.0 in the gap.
    float line = 0.5 + 0.5 * cos(fragCoord.y * 6.28318530718 / SCANLINE_PERIOD);
    col *= 1.0 - SCANLINE_STRENGTH * (1.0 - line);

    // Aperture grille: three-pixel RGB stripes. The stripe's own channel
    // passes at full, the other two are dimmed.
    float stripe = mod(fragCoord.x, 3.0);
    vec3 mask = vec3(1.0 - MASK_STRENGTH);
    if (stripe < 1.0)      mask.r = 1.0;
    else if (stripe < 2.0) mask.g = 1.0;
    else                   mask.b = 1.0;
    col *= mask;

    // Vignette: radial, aspect-corrected so the falloff is round rather than
    // stretched, with nothing happening inside VIGNETTE_START. A corner sits
    // at radius ~0.85 for a 3:2 surface, an edge centre at 0.5 or less.
    vec2 centred = (uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0);
    float r = length(centred) / 1.2;
    float vig = smoothstep(VIGNETTE_START, 1.0, r);
    col *= 1.0 - VIGNETTE * vig;

    col *= GAIN;

    fragColor = vec4(col, src.a);
}
