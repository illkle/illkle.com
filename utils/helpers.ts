export const useCanvasContext = (
  canvas: Ref<HTMLCanvasElement | null>,
  screenWidth: Ref<number>,
  screenHeight: Ref<number>
) => {
  const context = ref<CanvasRenderingContext2D>();

  watchEffect(() => {
    if (!canvas.value) return;
    context.value = canvas.value?.getContext('2d') as CanvasRenderingContext2D;
  });

  watch([context, screenWidth, screenHeight], (upd) => {
    if (!upd[0] || !canvas.value) return;

    canvas.value.width = upd[1] * devicePixelRatio;
    canvas.value.height = upd[2] * devicePixelRatio;
    canvas.value.style.transform = `scale(${1 / devicePixelRatio})`;
    canvas.value.style.transformOrigin = 'top left';
    upd[0].scale(devicePixelRatio, devicePixelRatio);
  });

  return context;
};

export const useScreenSize = () => {
  const screenWidth = ref(0);
  const screenHeight = ref(0);

  const updateScreenSize = () => {
    screenWidth.value = window.innerWidth;
    screenHeight.value = window.innerHeight;
  };

  onMounted(() => {
    addEventListener('resize', updateScreenSize);
    updateScreenSize();
  });

  onUnmounted(() => {
    removeEventListener('resize', updateScreenSize);
  });

  return { screenHeight, screenWidth };
};

export const useMousePos = () => {
  const mouseX = ref(0);
  const mouseY = ref(0);

  const updateMousePos = (e: MouseEvent) => {
    mouseX.value = e.clientX;
    mouseY.value = e.clientY;
  };

  onMounted(() => {
    addEventListener('mousemove', updateMousePos);
  });

  onUnmounted(() => {
    removeEventListener('mousemove', updateMousePos);
  });

  return { mouseX, mouseY };
};

export const getRandomNumber = (min: number, max: number) => {
  return Math.random() * (max - min) + min;
};

export const lerp = (x: number, y: number, a: number) => x * (1 - a) + y * a;
export const clamp = (a: number, min = 0, max = 1) =>
  Math.min(max, Math.max(min, a));
export const invlerp = (x: number, y: number, a: number) =>
  clamp((a - x) / (y - x));
export const range = (
  x1: number,
  y1: number,
  x2: number,
  y2: number,
  a: number
) => lerp(x2, y2, invlerp(x1, y1, a));

export type Point = { x: number; y: number };

export const interpolatePoints = (
  a: Point,
  b: Point,
  progress: number
): Point => {
  const x = (a.x - b.x) * progress + b.x;
  const y = (a.y - b.y) * progress + b.y;

  return { x, y };
};

export const getDistanceBetweenPoints = (a: Point, b: Point) => {
  return Math.abs(Math.sqrt(Math.pow(a.x - b.x, 2) + Math.pow(a.y - b.y, 2)));
};
