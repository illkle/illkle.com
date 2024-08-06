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

export const useScroll = () => {
  const scroll = ref(0);

  const updateScroll = () => {
    scroll.value = window.scrollY;
  };

  onMounted(() => {
    addEventListener('scroll', updateScroll);
    updateScroll();
  });

  onUnmounted(() => {
    removeEventListener('scroll', updateScroll);
  });

  return { scroll };
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

export const interpolatePoints = (a: Point, b: Point, progress: number): Point => {
  const x = (a.x - b.x) * progress + b.x;
  const y = (a.y - b.y) * progress + b.y;

  return { x, y };
};

export const getDistanceBetweenPoints = (a: Point, b: Point) => {
  return Math.abs(Math.sqrt(Math.pow(a.x - b.x, 2) + Math.pow(a.y - b.y, 2)));
};

// Takes shape as 4 coordinates and returns random point on it's perimeter
export const getRandomPointOnQuadrilateral = (p1: Point, p2: Point, p3: Point, p4: Point): Point => {
  const lines: [Point, Point][] = [
    [p1, p2],
    [p2, p3],
    [p3, p4],
    [p4, p1],
  ];

  const linesLen = lines.map((v) => getDistanceBetweenPoints(v[0], v[1]));

  const randomRes = getRandomNumber(
    0,
    linesLen.reduce((a, b) => a + b)
  );

  let lenStart = 0;
  for (let li = 0; li < lines.length; li++) {
    const end = lenStart + linesLen[li];
    if (end < randomRes) {
      lenStart += linesLen[li];
      continue;
    }
    const progress = range(lenStart, end, 0, 1, randomRes);

    return interpolatePoints(...lines[li], progress);
  }

  // This should never happen
  console.error('getRandomPointOnQuadrilateral returning fallback value');
  return p1;
};
