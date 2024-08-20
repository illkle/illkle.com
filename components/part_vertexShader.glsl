precision lowp float;

uniform float uSize;
uniform float uTime;

uniform sampler2D uPosition;
uniform sampler2D uVelocity;
uniform sampler2D uInfo;
uniform sampler2D uRandom;

varying float vLightness;
varying float vPointInGlobalMod;

uniform float uLightPosX;
uniform float uLightPosY;
uniform float uLightPower;

attribute vec2 aTarget;

#define PI 3.141592
#define PI_2 6.283185
#define HALF_PI 1.5707963267948966

varying vec2 vUv;
varying vec3 vPosition;

float sineOut(float t) {
    return sin(t * HALF_PI);
}

float lerp(float x, float y, float a) {
    return x * (1.0 - a) + y * a;
}

float invlerp(float x, float y, float a) {
    return clamp((a - x) / (y - x), 0.0, 1.0);
}

float range(float x1, float y1, float x2, float y2, float a) {
    return lerp(x2, y2, invlerp(x1, y1, a));
}

float cubicOut(float t) {
    float f = t - 1.0;
    return f * f * f + 1.0;
}

float cubicIn(float t) {
    return t * t * t;
}

float exponentialOut(float t) {
    return t == 1.0 ? t : 1.0 - pow(2.0, -10.0 * t);
}

void main() {

    vec4 myRandom = texture2D(uRandom, aTarget);
    vec4 myInfo = texture2D(uInfo, aTarget);
    vec4 myVelocity = texture2D(uVelocity, aTarget);

    float timeBorn = myInfo.x;
    float timeWhenDead = myInfo.y;

    float progressTime = uTime - timeBorn;
    float percentOfLife = progressTime / (timeWhenDead - timeBorn);

    // Animate size when particle spawns and when fades aout
    float sizeAnimateInFactor = exponentialOut(range(0.0, 0.25, 0.0, 1.0, percentOfLife));
    float sizeBaseSize = myInfo.w;
    float sizeAnimateOutFactor = exponentialOut(1.0 - percentOfLife);
    float sizeVal = sizeBaseSize * sizeAnimateInFactor * sizeAnimateOutFactor;

    vec4 ss = texture2D(uPosition, aTarget);
    vec3 finalPosition = vec3(ss.xy, 0.0);

    // Generic transforms to account for 3d space and camera 
    vec4 modelPosition = modelMatrix * vec4(finalPosition, 1.0);
    vec4 viewPosition = viewMatrix * modelPosition;
    vec4 projectedPosition = projectionMatrix * viewPosition;

    gl_Position = projectedPosition;

    gl_PointSize = sizeVal * uSize * (1.0 / -viewPosition.z);

    // Aliveness turnes off particle color in fragment shader.
    // We need to also make it zero when size is zero
    vPosition = projectedPosition.xyz;

    // Calculations for lighting
    float distanceFromLight = distance(projectedPosition.xy, vec2(uLightPosX, uLightPosY));
    vLightness = max(1.0 - sineOut(distanceFromLight / uLightPower), 0.2);

    float pointInGlobal = atan(vPosition.y - uLightPosY, vPosition.x - uLightPosX);
    vPointInGlobalMod = 1.0 - mod(0.0 - pointInGlobal, PI_2) / PI_2;

}