export const getRandomNumber = (min: number, max: number) => {
  return Math.random() * (max - min) + min;
};

export const getRandomNumber2 = (min: number, max: number) => {
  return min + getRandomNumber(0, (max - min) / 2) + getRandomNumber(0, (max - min) / 2);
};

export const customRandomness = (points: number[][]) => {
  const definer = Math.random();
  for (let i = 0; i < points.length; i++) {
    if (definer <= points[i][2]) {
      const res = getRandomNumber(points[i][0], points[i][1]);
      return res;
    }
  }

  return 0;
};

export const customRandomness2 = (min: number, max: number, interpolation: (v: number) => number) => {
  return interpolation(Math.random()) * (max - min) + min;
};

export const coolRandom = (min: number, max: number) => {
  const rMax = max - min;

  const path = Math.random();

  if (path > 0.99) {
    return Math.random() * rMax + min;
  }

  if (path > 0.95) {
    return (Math.random() * rMax) / 4 + min;
  }

  if (path > 0.75) {
    return (Math.random() * rMax) / 8 + min;
  }

  if (path > 0.5) {
    return (Math.random() * rMax) / 10 + min;
  }

  return (Math.random() * rMax) / 20 + min;
};
