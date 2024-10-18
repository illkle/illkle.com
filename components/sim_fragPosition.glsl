precision lowp float;

uniform float time;
uniform float delta;
uniform vec3 uEmitter;

void main() {

    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec4 position = texture2D(texturePosition, uv);
    vec4 infoData = texture2D(textureInfo, uv);

    if(infoData.z > 0.9) {
        position.x = uEmitter.x;
        position.y = uEmitter.y;
        position.z = uEmitter.z;
    }

    vec3 velocity = texture2D(textureVelocity, uv).xyz;

    gl_FragColor = vec4(position.xyz + velocity * delta * 70.0, 0.0);

}
