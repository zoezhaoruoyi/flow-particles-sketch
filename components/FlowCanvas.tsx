
import React, { useRef, useEffect, useCallback } from 'react';
import { Point, Stroke, Particle } from '../types';

interface FlowCanvasProps {
  volume: number;
}

interface NebulaParticle extends Particle {
  offsetX: number;
  offsetY: number;
  spread: number;
  phase: number;
  freq: number;
  layer: 'core' | 'dust' | 'nebula';
  brightnessMultiplier: number;
}

const FlowCanvas: React.FC<FlowCanvasProps> = ({ volume }) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const strokesRef = useRef<Stroke[]>([]);
  const currentStrokeRef = useRef<Point[]>([]);
  const isDrawingRef = useRef(false);
  const animationFrameRef = useRef<number>();
  
  // 用于声音平滑
  const smoothVolumeRef = useRef(0);

  // 规格文档中的黄金常量
  const CONSTANTS = {
    FLOW_SPEED: 0.08,
    PARTICLE_DENSITY: 25.0,
    RIPPLE_FREQ: 0.015,
    RIPPLE_SPEED: 5.0,
    MAX_RIPPLE_AMP: 40,
    CORE_WIDTH: 5,
    NEBULA_WIDTH: 45
  };

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const resize = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    };

    window.addEventListener('resize', resize);
    resize();

    return () => window.removeEventListener('resize', resize);
  }, []);

  const dist = (p1: Point, p2: Point) => Math.sqrt((p2.x - p1.x) ** 2 + (p2.y - p1.y) ** 2);

  const generateParticlesFromStroke = (points: Point[]): NebulaParticle[] => {
    if (points.length < 2) return [];
    
    const particles: NebulaParticle[] = [];
    let totalLength = 0;
    for (let i = 1; i < points.length; i++) {
      totalLength += dist(points[i-1], points[i]);
    }

    const particleCount = Math.floor(totalLength * CONSTANTS.PARTICLE_DENSITY);
    
    for (let i = 0; i < particleCount; i++) {
      const t = i / Math.max(1, particleCount - 1);
      const targetDist = t * totalLength;
      
      let currentDist = 0;
      for (let j = 1; j < points.length; j++) {
        const d = dist(points[j-1], points[j]);
        if (currentDist + d >= targetDist || j === points.length - 1) {
          const localT = d === 0 ? 0 : (targetDist - currentDist) / d;
          const x = points[j-1].x + (points[j].x - points[j-1].x) * localT;
          const y = points[j-1].y + (points[j].y - points[j-1].y) * localT;
          
          const rand = Math.random();
          let layer: NebulaParticle['layer'] = 'dust';
          let spreadRadius = CONSTANTS.NEBULA_WIDTH;
          let opacity = 0.3 + Math.random() * 0.4;
          let sizeMultiplier = 0.2;

          if (rand > 0.7) {
            layer = 'core';
            spreadRadius = CONSTANTS.CORE_WIDTH;
            opacity = 0.8 + Math.random() * 0.2;
            sizeMultiplier = 0.15;
          } else if (rand < 0.2) {
            layer = 'nebula';
            spreadRadius = CONSTANTS.NEBULA_WIDTH * 1.5;
            opacity = 0.05 + Math.random() * 0.15;
            sizeMultiplier = 0.35;
          }

          const angle = Math.random() * Math.PI * 2;
          const radius = Math.random() * spreadRadius;

          particles.push({
            x, y,
            originX: x,
            originY: y,
            offsetX: Math.cos(angle) * radius,
            offsetY: Math.sin(angle) * radius,
            vx: 0,
            vy: 0,
            life: 1.0,
            maxLife: 1.0,
            size: (Math.random() * 2.0 + 0.5) * sizeMultiplier, 
            hue: 0,
            opacity: opacity,
            spread: spreadRadius,
            phase: Math.random() * Math.PI * 2,
            freq: 0.5 + Math.random() * 2,
            brightnessMultiplier: Math.random() < 0.2 ? 2.0 : 1.0,
            layer
          });
          break;
        }
        currentDist += d;
      }
    }
    return particles;
  };

  const drawLoop = useCallback(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // 声音平滑处理 (Lerp)
    smoothVolumeRef.current += (volume - smoothVolumeRef.current) * 0.15;
    const v = smoothVolumeRef.current;

    ctx.globalCompositeOperation = 'source-over';
    ctx.fillStyle = '#050505';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    const centerX = canvas.width / 2;
    const centerY = canvas.height / 2;

    // 1. 绘制手绘线 (实时绘制)
    if (isDrawingRef.current && currentStrokeRef.current.length > 1) {
      const points = currentStrokeRef.current;
      ctx.lineCap = 'round';
      ctx.lineJoin = 'round';
      ctx.strokeStyle = 'rgba(255, 255, 255, 0.8)'; 
      for (let i = 1; i < points.length; i++) {
        // 头宽尾细逻辑
        const width = Math.max(1, 10 * ((points.length - i) / points.length));
        ctx.lineWidth = width;
        ctx.beginPath();
        ctx.moveTo(points[i-1].x, points[i-1].y);
        ctx.lineTo(points[i].x, points[i].y);
        ctx.stroke();
      }
    }

    // 2. 绘制粒子系统 (Additive Blending)
    ctx.globalCompositeOperation = 'lighter';
    const now = Date.now();
    const time = now * 0.001;

    strokesRef.current.forEach((stroke) => {
      stroke.particles.forEach((p: NebulaParticle, idx) => {
        // A. 基础流体波动
        const flowX = Math.sin(time * CONSTANTS.FLOW_SPEED + p.phase + p.originY * 0.005) * 5;
        const flowY = Math.cos(time * (CONSTANTS.FLOW_SPEED * 0.7) + p.phase + p.originX * 0.005) * 8;

        // B. 水波纹位移 (根据文档公式)
        const dx = (p.originX + p.offsetX) - centerX;
        const dy = (p.originY + p.offsetY) - centerY;
        const distToCenter = Math.sqrt(dx * dx + dy * dy);
        
        const rippleOffset = Math.sin(distToCenter * CONSTANTS.RIPPLE_FREQ - time * CONSTANTS.RIPPLE_SPEED) * (v * CONSTANTS.MAX_RIPPLE_AMP);
        const rippleX = (dx / (distToCenter || 1)) * rippleOffset;
        const rippleY = (dy / (distToCenter || 1)) * rippleOffset;

        // C. 湍流 (细微波动)
        const turbX = Math.sin(time * 2 + idx * 0.1) * (2 + v * 10);
        const turbY = Math.cos(time * 1.5 + idx * 0.15) * (2 + v * 10);

        const drawX = p.originX + p.offsetX + flowX + rippleX + turbX;
        const drawY = p.originY + p.offsetY + flowY + rippleY + turbY;

        // D. 颜色与透明度映射
        let alpha = p.opacity;
        alpha *= (0.8 + Math.sin(time * 3 + p.phase) * 0.2); // 基础呼吸感
        alpha *= (1 + v * 0.6); // 随声音增亮
        
        ctx.beginPath();
        ctx.fillStyle = `rgba(255, 255, 255, ${Math.min(1.0, alpha)})`;
        const size = p.size * (1 + v * 1.5); // 随声音膨胀
        
        ctx.arc(drawX, drawY, size, 0, Math.PI * 2);
        ctx.fill();
      });
    });

    animationFrameRef.current = requestAnimationFrame(drawLoop);
  }, [volume, isDrawingRef]);

  useEffect(() => {
    animationFrameRef.current = requestAnimationFrame(drawLoop);
    return () => {
      if (animationFrameRef.current) cancelAnimationFrame(animationFrameRef.current);
    };
  }, [drawLoop]);

  const onPointerDown = (e: React.PointerEvent) => {
    isDrawingRef.current = true;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const rect = canvas.getBoundingClientRect();
    currentStrokeRef.current = [{ 
      x: e.clientX - rect.left, 
      y: e.clientY - rect.top, 
      pressure: 1, 
      timestamp: Date.now() 
    }];
  };

  const onPointerMove = (e: React.PointerEvent) => {
    if (!isDrawingRef.current) return;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const rect = canvas.getBoundingClientRect();
    const pos = { 
      x: e.clientX - rect.left, 
      y: e.clientY - rect.top, 
      pressure: 1, 
      timestamp: Date.now() 
    };
    const lastPoint = currentStrokeRef.current[currentStrokeRef.current.length - 1];
    if (dist(lastPoint, pos) > 2) {
      currentStrokeRef.current.push(pos);
    }
  };

  const onPointerUp = () => {
    if (!isDrawingRef.current) return;
    isDrawingRef.current = false;
    if (currentStrokeRef.current.length > 3) {
      const particles = generateParticlesFromStroke(currentStrokeRef.current);
      strokesRef.current.push({
        id: Math.random().toString(36).substr(2, 9),
        points: [...currentStrokeRef.current],
        isEvolving: true,
        particles: particles as any
      });
    }
    currentStrokeRef.current = [];
  };

  return (
    <canvas
      ref={canvasRef}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={onPointerUp}
      onPointerLeave={onPointerUp}
      onPointerCancel={onPointerUp}
      className="absolute inset-0 cursor-crosshair touch-none"
    />
  );
};

export default FlowCanvas;
