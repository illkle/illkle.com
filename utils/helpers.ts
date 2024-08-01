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
