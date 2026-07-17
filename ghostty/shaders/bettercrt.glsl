// bettercrt — barrel-distortion CRT + scanlines. NO colour tint (the
// "tint removed" fork), so it rides on top of whatever stack theme is active.
//
// Original: https://www.shadertoy.com/view/WsVSzV (CC BY-NC-SA 3.0)
// Fork by April Hall (arithefirst), tint removed + boundaries matched to
// Ghostty's bg. Vendored from github.com/0xhckr/ghostty-shaders.
//
// Two knobs — edit and save, Ghostty reloads live:
float warp = 0.25; // curvature of the CRT glass (0 = flat)
float scan = 0.50; // darkness between scanlines (0 = off)

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // squared distance from center
    vec2 uv = fragCoord / iResolution.xy;
    vec2 dc = abs(0.5 - uv);
    dc *= dc;

    // warp the fragment coordinates
    uv.x -= 0.5; uv.x *= 1.0 + (dc.y * (0.3 * warp)); uv.x += 0.5;
    uv.y -= 0.5; uv.y *= 1.0 + (dc.x * (0.4 * warp)); uv.y += 0.5;

    // determine if we are drawing in a scanline
    float apply = abs(sin(fragCoord.y) * 0.25 * scan);

    // sample the texture
    vec3 color = texture(iChannel0, uv).rgb;

    // mix the sampled color with the scanline intensity
    fragColor = vec4(mix(color, vec3(0.0), apply), 1.0);
}
