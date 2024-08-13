uniform float time;
uniform float delta;

void main() {

    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec4 tmpPos = texture2D(texturePosition, uv);
    vec3 position = tmpPos.xyz;
    float leftToLive = tmpPos.w;
    if(leftToLive < 0.0) {
        position.x = 0.0;
        position.y = 0.0;
        position.z = 0.0;
        leftToLive = 2.0;
    } else {
        leftToLive -= delta;
    }

    vec3 velocity = texture2D(textureVelocity, uv).xyz;

   // gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
    gl_FragColor = vec4(position.x + 0.05, position.y, position.z, leftToLive);

}
