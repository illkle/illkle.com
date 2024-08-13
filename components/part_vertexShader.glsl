uniform float uSize;
uniform float uTime;

uniform sampler2D uPosition;
uniform sampler2D uVelocity;

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

//
// Description : Array and textureless GLSL 2D simplex noise function.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : stegu
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//               https://github.com/stegu/webgl-noise
// 

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

void main() {
    float progressTime = uTime - aTimeBorn;
    float willLiveForTime = aTimeWhenDead - aTimeBorn;
    float percentOfLife = progressTime / willLiveForTime;
    float percentPi = percentOfLife * PI / 0.5;

    // Animate size when particle spawns and when fades aout
    float sizeAnimateInFactor = exponentialOut(range(0.0, 0.25, 0.0, 1.0, percentOfLife));
    float sizeBaseSize = (aSize.x + (aSize.y * percentOfLife));
    float sizeAnimateOutFactor = (1.0 - percentOfLife);
    float sizeVal = sizeBaseSize * sizeAnimateInFactor * sizeAnimateOutFactor;

    // Calculate position with velocity applied
    vec3 velVect = aVelocity * cubicOut(percentOfLife);

    vec2 finalPosA = position.xy + vec2(0.1, 0.0) * percentOfLife;

    vec3 vvv = aVelocity;

    vec4 ss = texture2D(uPosition, vec2(0.5, 0.5));
    vec3 finalPosition = ss.xyz;

    // Generic transforms to account for 3d space and camera 
    vec4 modelPosition = modelMatrix * vec4(finalPosition, 1.0);
    vec4 viewPosition = viewMatrix * modelPosition;
    vec4 projectedPosition = projectionMatrix * viewPosition;

    gl_Position = projectedPosition;
    gl_PointSize = sizeVal * uSize * (1.0 / -viewPosition.z);

    // Aliveness turnes off particle color in fragment shader.
    // We need to also make it zero when size is zero
    vAliveness = step(0.0, progressTime) * step(0.00001, sizeVal);
    vLifePercent = percentOfLife;
    vDistance = distance(finalPosition.z, 0.0);
    vPosition = projectedPosition.xyz;
}