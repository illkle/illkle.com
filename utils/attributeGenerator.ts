import * as THREE from 'three';

type gFunc<T> = (args: T) => number[];

export class AttributeGenerator<T> {
  ba: THREE.BufferAttribute;
  generator: gFunc<T>;
  dimensions: number;
  constructor(length: number, dimension: number, generator: gFunc<T>, initialArgs?: T) {
    this.generator = generator;
    this.dimensions = dimension;
    this.ba = new THREE.BufferAttribute(new Float32Array([...Array(length * dimension)]), dimension);
    this.updateRange(0, length, initialArgs);
  }

  updateIndex(index: number, args?: any) {
    const a = this.ba.array;
    const real = index * this.dimensions;

    const res = this.generator(args);
    for (let o = 0; o < this.dimensions; o++) {
      a[real + o] = res[o];
    }
  }

  updateRange(start: number, end: number, args?: any) {
    for (let i = start; i < end; i++) {
      this.updateIndex(i, args);
    }
  }
}
