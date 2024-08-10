uniform float uSize;
uniform float uTime;

attribute vec2 aSize;
attribute float aTimeBorn;
attribute float aTimeWhenDead;
attribute vec3 aVelocity;
attribute vec3 aAttractions;

#define PI 3.14159265359

varying float vLifePercent;
varying float vDistance;
varying vec2 vUv;
varying vec3 vPosition;
varying float vAliveness;

/*

export const lerp = (x: number, y: number, a: number) => x * (1 - a) + y * a;
export const clamp = (a: number, min = 0, max = 1) => Math.min(max, Math.max(min, a));
export const invlerp = (x: number, y: number, a: number) => clamp((a - x) / (y - x));
export const range = (x1: number, y1: number, x2: number, y2: number, a: number) => lerp(x2, y2, invlerp(x1, y1, a));
*/

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

float exponentialOut(float t) {
    return t == 1.0 ? t : 1.0 - pow(2.0, -10.0 * t);
}

void main() {
    float progressTime = uTime - aTimeBorn;
    float willLiveForTime = aTimeWhenDead - aTimeBorn;
    float percentOfLife = progressTime / willLiveForTime;
    float percentPi = percentOfLife * PI * 0.5;

    vec3 velVect = aVelocity * cubicOut(percentOfLife);
    vec3 rotVect = vec3(sin(percentPi) * aAttractions.x, sin(percentPi) * aAttractions.y, 0.0) * aAttractions.z;
    vec3 modifiedPosition = position + velVect;

    vec4 modelPosition = modelMatrix * vec4(modifiedPosition, 1.0);
    vec4 viewPosition = viewMatrix * modelPosition;
    vec4 projectedPosition = projectionMatrix * viewPosition;

    float sizeVal = exponentialOut(range(0.0, 0.25, 0.0, 1.0, percentOfLife)) * (aSize.x + (aSize.y * percentOfLife)) * (1.0 - percentOfLife);

    gl_Position = projectedPosition;
    gl_PointSize = sizeVal * uSize * (1.0 / -viewPosition.z);

    vAliveness = step(0.0, progressTime);
    vLifePercent = percentOfLife;
    vDistance = distance(modifiedPosition.z, 0.0);
    vPosition = projectedPosition.xyz;
}