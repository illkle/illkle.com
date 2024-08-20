import * as THREE from 'three';

export const useCanvasContext = (
  canvas: Ref<HTMLCanvasElement | null>,
  screenWidth: Ref<number>,
  screenHeight: Ref<number>
) => {
  const context = ref<WebGL2RenderingContext>();

  watchEffect(() => {
    if (!canvas.value) return;
    context.value = canvas.value?.getContext('webgl2') as WebGL2RenderingContext;
  });

  watch([context, screenWidth, screenHeight], (upd) => {
    if (!upd[0] || !canvas.value) return;

    canvas.value.width = upd[1] * devicePixelRatio;
    canvas.value.height = upd[2] * devicePixelRatio;
    canvas.value.style.transform = `scale(${1 / devicePixelRatio})`;
    canvas.value.style.transformOrigin = 'top left';
    //upd[0].scale(devicePixelRatio, devicePixelRatio);
  });

  return context;
};

export const useMousePos = () => {
  const mouseX = ref(0);
  const mouseY = ref(0);
  const hasMouse = ref(false);

  const updateMousePos = (e: MouseEvent) => {
    mouseX.value = e.clientX;
    mouseY.value = e.clientY;
    hasMouse.value = true;
  };

  onMounted(() => {
    addEventListener('mousemove', updateMousePos);
  });

  onUnmounted(() => {
    removeEventListener('mousemove', updateMousePos);
  });

  return { mouseX, mouseY, hasMouse };
};

export const lerp = (x: number, y: number, a: number) => x * (1 - a) + y * a;
export const clamp = (a: number, min = 0, max = 1) => Math.min(max, Math.max(min, a));
export const invlerp = (x: number, y: number, a: number) => clamp((a - x) / (y - x));
export const range = (x1: number, y1: number, x2: number, y2: number, a: number) => lerp(x2, y2, invlerp(x1, y1, a));

export type Point = { x: number; y: number };

export const fillTexture = (
  texture: THREE.DataTexture,
  generator: (numberOfPixel: number) => [number, number, number, number]
) => {
  const theArray = texture.image.data;

  for (let k = 0, kl = theArray.length; k < kl; k += 4) {
    const [x, y, z, w] = generator(k / 4);

    theArray[k + 0] = x;
    theArray[k + 1] = y;
    theArray[k + 2] = z;
    theArray[k + 3] = w;
  }
};
