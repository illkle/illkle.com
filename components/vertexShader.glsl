uniform float uSize;
uniform float uTime;

attribute float aSize;
attribute float aTimeBorn;
attribute float aTimeWhenDead;
attribute vec3 aVelocity;
attribute vec3 aAttractions;

varying float vLifePercent;

void main() {
    vec4 modelPosition = modelMatrix * vec4(position, 1.0);
    vec4 viewPosition = viewMatrix * modelPosition;
    vec4 projectedPosition = projectionMatrix * viewPosition;

    float progressTime = uTime - aTimeBorn;
    float willLiveForTime = aTimeWhenDead - aTimeBorn;
    float percentOfLife = progressTime / willLiveForTime;
    float percentPi = percentOfLife * 3.14159265359 * 0.5;

    vec4 velVect = vec4(aVelocity, 1.0);
    vec4 rotVect = vec4(sin(percentPi) * aAttractions.x * aAttractions.z, sin(percentPi) * aAttractions.y * aAttractions.z, 0.0, 1.0);
    gl_Position = projectedPosition + (velVect * progressTime) + rotVect;
    gl_PointSize = aSize * uSize * (1.0 / -viewPosition.z);

    vLifePercent = percentOfLife;
}