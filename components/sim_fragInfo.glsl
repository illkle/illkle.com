uniform float time;
uniform float delta;

uniform float uSizeMod;

#define PARTICLE_TTL  5.0

void main() {

  vec2 uv = gl_FragCoord.xy / resolution.xy;

  vec4 infoData = texture2D(textureInfo, uv);
  vec4 random = texture2D(textureRandom, uv);

  float timeBorn = infoData.x;
  float timeDead = infoData.y;

  float progressTime = time - timeBorn;
  float willLiveForTime = timeDead - timeBorn;
  float percentOfLife = progressTime / willLiveForTime;

  if(time > timeDead) {
    // If patricle should be dead mark it for reset
    gl_FragColor = vec4(time, time + PARTICLE_TTL, 1.0, random.w * uSizeMod);
  } else {
    gl_FragColor = vec4(timeBorn, timeDead, 0.0, infoData.w);
  }

}