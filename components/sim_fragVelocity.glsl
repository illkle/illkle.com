uniform float time;
uniform float delta; // about 0.016

const float width = resolution.x;
const float height = resolution.y;

const float PI = 3.141592653589793;
const float PI_2 = PI * 2.0;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {

    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec3 birdPosition, birdVelocity;

    vec3 selfPosition = texture2D(texturePosition, uv).xyz;
    vec3 selfVelocity = texture2D(textureVelocity, uv).xyz;

    gl_FragColor = vec4(vec3(1.0), 1.0);

}