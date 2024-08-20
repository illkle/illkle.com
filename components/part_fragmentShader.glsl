precision mediump float;

uniform float uLightPosX;
uniform float uLightPosY;
uniform float uLightPower;
uniform float uShadowRound;
uniform float uShadowDirectional;

varying vec3 vPosition;

#define PI 3.141592
#define PI_2 6.283185

float cubicOut(float t) {
    float f = t - 1.0;
    return f * f * f + 1.0;
}

void main() {
    float rawStren = distance(gl_PointCoord, vec2(0.5));
    float strength = 1.0 - step(0.2, rawStren);

    vec2 lightPos = vec2(uLightPosX, uLightPosY);

    vec4 backShadow = vec4(vec3(0.0), (1.0 - rawStren - 0.5));

    float distanceFromLight = distance(vPosition.xy, lightPos);
    float lightness = 1.0 - cubicOut(distanceFromLight / uLightPower);

    vec3 particleColor = vec3(lightness);
    vec4 mainParticle = vec4(particleColor, strength);

    // Making shadow mask to fake lighting
    // Angle in particle(current pixel relative to center of particle)
    float pixelInTexture = atan(gl_PointCoord.y - 0.5, gl_PointCoord.x - 0.5);
    float pixelInTextureMod = mod(0.0 - pixelInTexture, PI_2) / PI_2;
    // Angle on screen(current particle relative to center of screen)
    float pointInGlobal = atan(vPosition.y - lightPos.y, vPosition.x - lightPos.x);
    float pointInglobalMod = 1.0 - mod(0.0 - pointInGlobal, PI_2) / PI_2;

    float angleDistance = distance(pointInglobalMod, pixelInTextureMod);

    float s1 = 0.3;
    float s2 = 0.01;
    // We'll need to combine two values becuase sometimes the correct values are someting like 0-10 350-360 
    float lightConeA = smoothstep(s1, s2, angleDistance);
    float lightConeB = smoothstep(1.0 - s1, 1.0 - s2, angleDistance);

    vec4 maskedShadow = mix(vec4(0.0) + backShadow * uShadowRound, backShadow * uShadowDirectional, lightConeA + lightConeB);

    gl_FragColor = maskedShadow + mainParticle * strength;
}