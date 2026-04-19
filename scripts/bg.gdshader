shader_type canvas_item;

uniform float speed : hint_range(0.1, 5.0) = 2.0;
uniform float scale : hint_range(0.1, 10.0) = 3.0;
uniform vec4 color_a : source_color = vec4(0.1, 0.3, 0.8, 1.0);
uniform vec4 color_b : source_color = vec4(0.0, 0.05, 0.2, 1.0);

vec2 hash(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(dot(hash(i + vec2(0,0)), f - vec2(0,0)),
            dot(hash(i + vec2(1,0)), f - vec2(1,0)), u.x),
        mix(dot(hash(i + vec2(0,1)), f - vec2(0,1)),
            dot(hash(i + vec2(1,1)), f - vec2(1,1)), u.x), u.y);
}

float bayer8(vec2 pos) {
    int x = int(mod(pos.x, 8.0));
    int y = int(mod(pos.y, 8.0));
    int bayer[64] = int[64](
         0, 32,  8, 40,  2, 34, 10, 42,
        48, 16, 56, 24, 50, 18, 58, 26,
        12, 44,  4, 36, 14, 46,  6, 38,
        60, 28, 52, 20, 62, 30, 54, 22,
         3, 35, 11, 43,  1, 33,  9, 41,
        51, 19, 59, 27, 49, 17, 57, 25,
        15, 47,  7, 39, 13, 45,  5, 37,
        63, 31, 55, 23, 61, 29, 53, 21
    );
    return float(bayer[y * 8 + x]) / 64.0;
}

void fragment() {
    vec2 uv = UV * scale;
    float t = TIME * speed;
    
    float n = 0.0;
    n += 0.500 * noise(uv + vec2(t * 0.3, t * 0.2));
    n += 0.250 * noise(uv * 2.0 + vec2(t * 0.5, t * 0.4));
    n += 0.125 * noise(uv * 4.0 + vec2(t * 0.7, t * 0.6));
    n = n * 0.5 + 0.5;

    // apply bayer dither before color mix
    vec2 screen_pos = FRAGCOORD.xy;
    float threshold = bayer8(screen_pos);
    float dithered = step(threshold, n);

    COLOR = mix(color_a, color_b, dithered);
}