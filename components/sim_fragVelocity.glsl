uniform float time;
uniform float delta; // about 0.016

const float width = resolution.x;
const float height = resolution.y;

const float PI = 3.141592653589793;
const float PI_2 = PI * 2.0;

#include "/lygiaR/generative/fbm.glsl"

/*

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
    return mod289(((x * 34.0) + 10.0) * x);
}

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
    vec2 i = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);

    vec2 i1;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);

    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    i = mod289(i);
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));

    vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
    m = m * m;
    m = m * m;

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);

    vec3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}
*/

#define TIME_MULTIPLIER 0.3
#define SCALE_MULTIPLER 1.0
#define CHANGE_MULT 1.0
#define BASE_MULT 0.1

void main() {

    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec4 random = texture2D(textureRandom, uv);

    vec3 selfVelocity = texture2D(textureVelocity, uv).xyz;
    vec3 selfPosition = texture2D(texturePosition, uv).xyz;
    vec4 infoData = texture2D(textureInfo, uv);

    if(infoData.z > 0.9) {
        // generate base velocity
        float d3 = fbm(random.xy * SCALE_MULTIPLER * time) * BASE_MULT;
        float d4 = fbm(random.yx * SCALE_MULTIPLER * time) * BASE_MULT;

        gl_FragColor = vec4(d3, d4, 0.0, 100.0);

    } else {
        float d3 = fbm(selfPosition.xy + random.xy * SCALE_MULTIPLER + time * TIME_MULTIPLIER) * CHANGE_MULT;
        float d4 = fbm(selfPosition.yx + random.yx * SCALE_MULTIPLER + time * TIME_MULTIPLIER) * CHANGE_MULT;
        gl_FragColor = vec4(selfVelocity.x + d3 * delta, selfVelocity.y + d4 * delta, 0.0, 100.0);

    }

}