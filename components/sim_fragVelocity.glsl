uniform float time;
uniform float delta; // about 0.016

uniform float uBaseMult;
uniform float uBaseTimeScale;

uniform float uVelPositionScale;
uniform float uVelRandomScale;
uniform float uVelTimeScale;
uniform float uVelMult;

uniform float uNoiseScale;

uniform vec2 uEmitter;
uniform vec2 uEmitTowards;

const float width = resolution.x;
const float height = resolution.y;

const float PI = 3.141592653589793;
const float PI_2 = PI * 2.0;

#include "/lygiaR/generative/fbm.glsl"

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
        float d3 = fbm(random.xy * time * 1.0) * uBaseMult;
        float d4 = fbm(random.yx * time * 1.0) * uBaseMult;

        vec2 baseDirection = uEmitTowards - uEmitter;
        gl_FragColor = vec4((baseDirection * 0.005 + vec2(d3, d4)) * uBaseMult, 0.0, 100.0);

    } else {
        float d1 = fbm((selfPosition.xy * uVelPositionScale + random.yx * uVelRandomScale + time * uVelTimeScale) * uNoiseScale) * uVelMult;
        float d2 = fbm((selfPosition.yx * uVelPositionScale + random.xy * uVelRandomScale + time * uVelTimeScale) * uNoiseScale) * uVelMult;

        float d3 = fbm(selfPosition.xy * uVelPositionScale + random.xy * uVelRandomScale + time * uVelTimeScale) * uVelMult;
        float d4 = fbm(selfPosition.yx * uVelPositionScale + random.yx * uVelRandomScale + time * uVelTimeScale) * uVelMult;
        gl_FragColor = vec4(selfVelocity.x + (d1) * delta, selfVelocity.y + (d2) * delta, 0.0, 100.0);
    }

}