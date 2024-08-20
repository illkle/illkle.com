uniform float time;
uniform float delta; // about 0.016

uniform float uBaseMult;
uniform float uBaseTimeScale;

uniform float uVelPositionScale;
uniform float uVelRandomScale;
uniform float uVelTimeScale;
uniform float uVelMult;

uniform float uVel2PositionScale;
uniform float uVel2RandomScale;
uniform float uVel2TimeScale;
uniform float uVel2Mult;

uniform float uVel2SizeLowerBound;
uniform float uVel2SizeUpperBound;

uniform float uNoiseScale;

uniform float uNoise2Scale;

uniform vec2 uEmitter;
uniform vec2 uEmitTowards;

const float width = resolution.x;
const float height = resolution.y;

const float PI = 3.141592653589793;
const float PI_2 = PI * 2.0;

#include "/node_modules/lygia/generative/fbm.glsl"

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
    float mySize = infoData.w;

    if(infoData.z > 0.9) {
        // generate base velocity
        float d3 = fbm(random.xy * time * 1.0) * uBaseMult;
        float d4 = fbm(random.yx * time * 1.0) * uBaseMult;

        vec2 baseDirection = uEmitTowards - uEmitter;
        gl_FragColor = vec4((baseDirection * 0.001 + vec2(d3, d4)) * uBaseMult, 0.0, 100.0);

    } else {
        // This is primary noise
        float n1X = fbm((selfPosition.xy * uVelPositionScale + random.yx * uVelRandomScale + time * uVelTimeScale) * uNoiseScale) * uVelMult;
        float n1Y = fbm((selfPosition.yx * uVelPositionScale + random.xy * uVelRandomScale + time * uVelTimeScale) * uNoiseScale) * uVelMult;

        // This is secondary noise for smaller particles
        float secondNoiseValue = 1.0 - smoothstep(uVel2SizeLowerBound, uVel2SizeUpperBound, mySize);
        float n2X = fbm((selfPosition.xy * uVel2PositionScale + random.xy * uVel2RandomScale + time * uVel2TimeScale) * uNoise2Scale) * uVel2Mult * secondNoiseValue;
        float n2Y = fbm((selfPosition.yx * uVel2PositionScale + random.yx * uVel2RandomScale + time * uVel2TimeScale) * uNoise2Scale) * uVel2Mult * secondNoiseValue;

        gl_FragColor = vec4(selfVelocity.x + (n1X + n2X) * delta, selfVelocity.y + (n1Y + n2Y) * delta, 0.0, 100.0);
    }

}