uniform float uSize;
uniform float uTime;

attribute float aSize;
attribute float aTimeBorn;
attribute float aTimeWhenDead;
attribute vec3 aVelocity;
attribute vec3 aAttractions;

//#define PI 3.14159265359

varying float vLifePercent;

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

    gl_Position = projectedPosition;
    gl_PointSize = aSize * uSize * (1.0 / -viewPosition.z);

    vLifePercent = percentOfLife;
}