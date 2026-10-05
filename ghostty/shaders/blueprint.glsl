// blueprint — the terminal as a night blueprint sheet: a minor/major grid, a
// margin frame with registration marks, ink bleed around the glyphs and the
// uneven exposure of cyanotype paper.
//
// Shadertoy-compatible, loaded by `custom-shader` in config.ghostty and run
// after Ghostty's own passes over iChannel0 (the rendered terminal). Meant for
// the `blueprint` stack theme: the ink colours below are chosen for its navy
// canvas (#04172c). The canvas itself is NOT a constant here — it is read from
// Ghostty's `iBackgroundColor` uniform (sRGB, 0–1), so retuning the theme's
// `background` can never leave the shader looking for the old colour.
//
// Deliberately STATIC. Nothing reads iTime, so `custom-shader-animation =
// false` keeps the render loop idle until the terminal itself changes. The
// grain is a hash of the pixel position, not of time: a sheet of paper does
// not crawl.
//
// fragCoord is in device pixels, so every period and width below is device
// pixels, tuned at 2× (Retina): the 24px minor cell is 12 logical pixels, a
// little over half a text row at font-size 17. Ghostty passes no scale
// factor, so on a 1× display everything is twice as large in logical terms
// and the frame (20px in) lands just inside the 18px top padding's first text
// row. iResolution is the surface size in the same units. Ghostty 1.3 hands
// fragCoord with the origin at the TOP-left, unlike Shadertoy; the frame and
// grid are laid out from the surface centre, so they come out the same
// whichever way y runs.
//
// What iChannel0 holds (measured on Ghostty 1.3.1, macOS, glass on): linear
// light, PREMULTIPLIED alpha. The default background is not in the texture at
// all — those pixels are (0,0,0,0) and the window's glass, already tinted with
// the background colour, shows through them. A cell that sets its own
// background arrives at alpha 0.9 (`background-opacity-cells`), a
// reverse-video cell at 1.0, a glyph core at 1.0. Two consequences:
//   · Line work cannot be "added" to a transparent pixel without either
//     raising its alpha or writing rgb > alpha, which the compositor turns
//     into light added on top of the glass — a fringe that glows over bright
//     wallpaper. So every effect is a premultiplied layer (rgb <= alpha),
//     composited UNDER the source on transparent pixels: a 4% line is 4% ink
//     on the glass, and a glyph's own antialiased edge covers it correctly.
//     Where nothing is drawn, src passes through untouched, alpha included.
//   · A TUI that paints the canvas colour explicitly (an editor's Normal
//     background) arrives at alpha 0.9 but still IS the sheet, so there the
//     layers go OVER the source instead. Those pixels are picked out by
//     colour; anything else with a background of its own (selection, diff
//     rows, panels, the cursorline) gets no ink at all, and glyphs never do —
//     including a canvas-coloured glyph, like the letter inside the block
//     cursor, which is told apart from a canvas cell by being opaque.
//
// Brightness-neutral at the edges. The titlebar (`macos-titlebar-style =
// transparent`) is the bare glass in the background colour, and the surface's
// first rows are the same glass seen through transparent pixels, so any net
// change there shows as a seam. Nothing darkens on purpose: there is no
// vignette, the grain and the mottling are zero-mean and fade to nothing
// across the outer PAPER_FADE pixels, so at the edge the surface is exactly
// the titlebar's glass. (The grain is exactly zero-mean only over a
// canvas-coloured backdrop; over the glass a bright wallpaper tips it a hair
// darker, which is the other reason it fades out at the edges.) The frame is
// line work, not a tone: it sits in the top padding, 20px below the seam,
// and the grid only starts inside it.
//
// window-padding-color = extend paints the padding with the nearest row's
// background, so where an edge row has a background of its own (a status
// line, a tabline) the frame along that edge is masked like any other ink.

const float CANVAS_TOL_LO   = 0.02;    // sRGB distance from the canvas still fully counted as sheet
const float CANVAS_TOL_HI   = 0.05;    // ...and where it stops counting (blueprint's cursorline, #0d2137, sits at ~0.07)

const vec3  LINE_COLOR      = vec3(71.0, 176.0, 255.0) / 255.0;  // #47b0ff, sRGB: the cyan-blue of the grid
const vec3  MARK_COLOR      = vec3(75.0, 228.0, 255.0) / 255.0;  // #4be4ff, sRGB: blueprint's accent, for frame and marks
const vec3  BLEED_COLOR     = vec3(165.0, 240.0, 255.0) / 255.0; // #a5f0ff, sRGB: accent toward white, the halo's tint

const float GRID_PERIOD     = 24.0;    // device px between minor lines
const float MAJOR_EVERY     = 5.0;     // minor cells per major line
const float MINOR_WIDTH     = 1.0;     // device px
const float MAJOR_WIDTH     = 2.0;     // device px; a 1px core with half-covered neighbours
const float MINOR_ALPHA     = 0.038;   // ink coverage of a minor line: over the canvas it lands near #0b2a45
const float MAJOR_ALPHA     = 0.075;   // ink coverage of a major line

const float FRAME_INSET     = 20.0;    // device px from the surface edge; at 2× the padding is 36–44 px, so text starts ~16 px inside
const float FRAME_WIDTH     = 1.5;     // device px
const float FRAME_ALPHA     = 0.30;    // frame and registration marks, the brightest ink on the sheet
const float OVERSHOOT       = 10.0;    // device px the frame lines run past each corner, drafting-style
const float MARK_RADIUS     = 8.0;     // device px, registration circle at each frame corner
const float TICK_LENGTH     = 8.0;     // device px, centring tick at the middle of each frame edge, pointing outward

const float BLEED_RADIUS    = 2.5;     // device px, mean radius of the halo taps
const float BLEED_THRESHOLD = 0.10;    // linear luma a tap must exceed to bleed: dark cell backgrounds (selection, search, panels) stay out, a bright block (the cursor) glows like a glyph
const float BLEED           = 0.08;    // halo coverage per unit of luma above the threshold
const float KNOCKOUT        = 0.06;    // mean tap excess at which grid and frame are fully lifted near a glyph

const float GRAIN           = 0.10;    // per-pixel paper grain, ± fraction of the canvas (linear)
const float MOTTLE          = 0.16;    // low-frequency exposure unevenness, ± fraction of the canvas (linear)
const float MOTTLE_SCALE    = 220.0;   // device px per value-noise cell
const float PAPER_FADE      = 20.0;    // device px over which grain and mottle fade in from each surface edge

// Eight unit directions at 45°, on alternating radii (0.7 / 1.2 × BLEED_RADIUS)
// so the halo has no ring.
const vec2 TAPS[8] = vec2[8](
    vec2( 0.7,     0.0),    vec2( 0.8485,  0.8485),
    vec2( 0.0,     0.7),    vec2(-0.8485,  0.8485),
    vec2(-0.7,     0.0),    vec2(-0.8485, -0.8485),
    vec2( 0.0,    -0.7),    vec2( 0.8485, -0.8485)
);

// The exact sRGB curve, not a 2.2 power: Ghostty linearises with it, and on a
// canvas this dark the power law misplaces #04172c by ~0.04 — enough to make
// the sheet test fail to recognise the canvas itself.
vec3 toLinear(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}
vec3 toGamma(vec3 c) {
    c = max(c, 0.0);
    return mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, step(0.0031308, c));
}
float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

// premultiplied a OVER b
vec4 over(vec4 a, vec4 b) { return a + (1.0 - a.a) * b; }

// Box-filtered coverage of a line of width w at distance d from its centre.
float stroke(float d, float w) { return clamp(w * 0.5 + 0.5 - d, 0.0, 1.0); }

// Dave Hoskins' hash12: no sin(), so no banding at large pixel coordinates.
float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash12(i);
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 res = iResolution.xy;
    vec2 uv = fragCoord / res;
    vec4 src = texture(iChannel0, uv);
    vec3 canvas = iBackgroundColor;
    vec3 canvasLin = toLinear(canvas);

    // Frame: exactly symmetric about the true centre, its lines on pixel
    // centres (+0.5 from the edge) so a line covers whole pixels instead of
    // two halves.
    vec2 q = fragCoord - res * 0.5;
    vec2 aq = abs(q);
    vec2 halfFrame = res * 0.5 - FRAME_INSET - 0.5;
    vec2 edgeDist = halfFrame - aq;
    float insideFrame = step(1.5, min(edgeDist.x, edgeDist.y));

    // Grid, anchored on the pixel centre nearest the surface centre so the
    // middle lines are major and the leftover at opposite frame edges differs
    // by at most a pixel.
    vec2 cellPos = (fragCoord - (floor(res * 0.5) + 0.5)) / GRID_PERIOD;
    vec2 minorD = abs(fract(cellPos + 0.5) - 0.5) * GRID_PERIOD;
    vec2 majorD = abs(fract(cellPos / MAJOR_EVERY + 0.5) - 0.5) * GRID_PERIOD * MAJOR_EVERY;
    float minorK = max(stroke(minorD.x, MINOR_WIDTH), stroke(minorD.y, MINOR_WIDTH));
    float majorK = max(stroke(majorD.x, MAJOR_WIDTH), stroke(majorD.y, MAJOR_WIDTH));
    float gridK = max(minorK * MINOR_ALPHA, majorK * MAJOR_ALPHA) * insideFrame;

    // Four lines overshooting the corners, a circle on each corner, and an
    // outward tick at the middle of each edge.
    float hLine = stroke(abs(aq.y - halfFrame.y), FRAME_WIDTH) * step(aq.x, halfFrame.x + OVERSHOOT);
    float vLine = stroke(abs(aq.x - halfFrame.x), FRAME_WIDTH) * step(aq.y, halfFrame.y + OVERSHOOT);
    float ring = stroke(abs(length(aq - halfFrame) - MARK_RADIUS), FRAME_WIDTH);
    float tickH = stroke(aq.x, FRAME_WIDTH) * step(halfFrame.y, aq.y) * step(aq.y, halfFrame.y + TICK_LENGTH);
    float tickV = stroke(aq.y, FRAME_WIDTH) * step(halfFrame.x, aq.x) * step(aq.x, halfFrame.x + TICK_LENGTH);
    float markK = max(max(hLine, vLine), max(ring, max(tickH, tickV))) * FRAME_ALPHA;

    // Paper: grain + mottling as one signed fraction of the canvas. Darkening
    // is black at coverage -n; lightening is 2×canvas at coverage n, which
    // over a canvas backdrop is the same step the other way.
    vec2 edgeOfSurface = min(fragCoord, res - fragCoord);
    float paperFade = smoothstep(0.0, PAPER_FADE, min(edgeOfSurface.x, edgeOfSurface.y));
    float n = GRAIN * (hash12(floor(fragCoord)) * 2.0 - 1.0)
            + MOTTLE * (valueNoise(fragCoord / MOTTLE_SCALE) * 2.0 - 1.0);
    n *= paperFade;
    vec4 paper = n < 0.0 ? vec4(0.0, 0.0, 0.0, -n) : vec4(2.0 * canvasLin * n, n);

    // Ink bleed: how far above the threshold the neighbourhood is, as seen
    // over the canvas. It becomes a layer like the rest, so on a glyph core
    // (alpha 1) it is hidden and the glyph edge stays exactly as Ghostty
    // drew it.
    float excess = 0.0;
    vec2 px = BLEED_RADIUS / res;
    for (int i = 0; i < 8; i++) {
        vec4 t = texture(iChannel0, uv + TAPS[i] * px);
        excess += max(luma(t.rgb + (1.0 - t.a) * canvasLin) - BLEED_THRESHOLD, 0.0);
    }
    excess /= 8.0;
    float bleedK = clamp(excess * BLEED, 0.0, 1.0);

    // Drafting convention: a line breaks around the lettering instead of
    // running through it. The same neighbourhood that feeds the bleed lifts
    // the ink within ~3px of a glyph stroke, so the grid shows between words
    // and rows but never touches a stroke; inside the counter of a large
    // letter (an O, a 0) it can still show.
    float clearance = 1.0 - smoothstep(0.0, KNOCKOUT, excess);
    gridK *= clearance;
    markK *= clearance;

    vec4 ink = over(vec4(toLinear(MARK_COLOR) * markK, markK),
                    vec4(toLinear(LINE_COLOR) * gridK, gridK));
    vec4 layer = over(vec4(toLinear(BLEED_COLOR) * bleedK, bleedK), over(ink, paper));

    // Is this pixel a canvas-coloured cell? Only meaningful once it is
    // substantially covered; on a transparent pixel both paths below agree.
    // An opaque pixel in a bright neighbourhood is a canvas-coloured GLYPH
    // (cursor-text inside the block cursor, a status line's mode letters),
    // not sheet.
    vec3 straight = src.rgb / max(src.a, 1e-3);
    float dist = distance(toGamma(straight), canvas);
    float covered = smoothstep(0.5, 0.8, src.a);
    float glyphGuard = mix(1.0, clearance, smoothstep(0.93, 0.98, src.a));
    float sheet = (1.0 - smoothstep(CANVAS_TOL_LO, CANVAS_TOL_HI, dist)) * covered * glyphGuard;

    // Under a pixel with a background of its own the layer would leak through
    // at 1 - alpha (10% under a 0.9 cell): faint grid on the selection. It is
    // dropped there instead.
    vec4 under = over(src, layer * (1.0 - covered));
    vec4 onTop = over(layer, src);
    fragColor = mix(under, onTop, sheet);
}
