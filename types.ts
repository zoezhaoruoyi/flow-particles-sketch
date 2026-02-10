
export interface Point {
  x: number;
  y: number;
  pressure: number;
  timestamp: number;
}

export interface Particle {
  x: number;
  y: number;
  originX: number;
  originY: number;
  vx: number;
  vy: number;
  life: number;
  maxLife: number;
  size: number;
  hue: number;
  opacity: number;
}

export interface Stroke {
  id: string;
  points: Point[];
  isEvolving: boolean;
  particles: Particle[];
}
