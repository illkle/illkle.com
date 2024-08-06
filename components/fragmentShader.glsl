precision mediump float;

uniform vec2 uLightPos;
varying float vLifePercent;
varying vec3 vPosition;

#define PI 3.141592
#define PI_2 6.283185

void main() {
    float shadowStren = distance(gl_PointCoord, vec2(0.5));
    float strength2 = distance(gl_PointCoord, vec2(0.5));
    strength2 = 1.0 - step(0.2, strength2);

    vec4 backShadow = vec4(vec3(0.0), (1.0 - shadowStren - 0.5));

    float distanceFromLight = distance(vPosition.xy, uLightPos);
    float lightness = 1.0 - distanceFromLight / 750.0;

    vec4 mainParticle = vec4(vec3(lightness), strength2);

    // Making shadow mask to fake lighting
    // Angle in particle
    float pixelInTexture = atan(gl_PointCoord.y - 0.5, gl_PointCoord.x - 0.5);
    float pixelInTextureMod = mod(0.0 - pixelInTexture, PI_2) / PI_2;
    // Angle on screen
    float pointInGlobal = atan(vPosition.y - uLightPos.y, vPosition.x - uLightPos.x);
    float pointInglobalMod = 1.0 - mod(0.0 - pointInGlobal, PI_2) / PI_2;

    float angleDistance = distance(pointInglobalMod, pixelInTextureMod);

    float s1 = 0.3;
    float s2 = 0.01;
    // We'll need to combine two values becuase sometimes the correct values are someting like 0-10 350-360 
    float lightConeA = smoothstep(s1, s2, angleDistance);
    float lightConeB = smoothstep(1.0 - s1, 1.0 - s2, angleDistance);

    vec4 maskedShadow = mix(vec4(0.0) + backShadow * 0.4, backShadow, lightConeA + lightConeB);

   // gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
    gl_FragColor = maskedShadow * 1.25 + mainParticle * strength2;
}