import React, { useRef, useMemo } from 'react';
import { useFrame } from '@react-three/fiber';
import { Points } from 'three';
import * as THREE from 'three';

interface ParticleEffectsProps {
  position: [number, number, number];
  trigger: boolean;
  color?: string;
  count?: number;
}

export const ParticleEffects: React.FC<ParticleEffectsProps> = ({ 
  position, 
  trigger, 
  color = '#FFD700', 
  count = 20 
}) => {
  const pointsRef = useRef<Points>(null);
  const particlesRef = useRef<{
    positions: Float32Array;
    velocities: Float32Array;
    life: Float32Array;
    active: boolean;
    startTime: number;
  }>({
    positions: new Float32Array(count * 3),
    velocities: new Float32Array(count * 3),
    life: new Float32Array(count),
    active: false,
    startTime: 0
  });

  const geometry = useMemo(() => {
    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(particlesRef.current.positions, 3));
    return geo;
  }, [count]);

  // Initialize particles when triggered
  React.useEffect(() => {
    if (trigger && !particlesRef.current.active) {
      const particles = particlesRef.current;
      particles.active = true;
      particles.startTime = performance.now();

      // Initialize particle positions and velocities
      for (let i = 0; i < count; i++) {
        const i3 = i * 3;
        
        // Start at effect position
        particles.positions[i3] = position[0];
        particles.positions[i3 + 1] = position[1];
        particles.positions[i3 + 2] = position[2];

        // Random velocities
        particles.velocities[i3] = (Math.random() - 0.5) * 4;
        particles.velocities[i3 + 1] = Math.random() * 3 + 1;
        particles.velocities[i3 + 2] = (Math.random() - 0.5) * 4;

        // Initial life
        particles.life[i] = 1.0;
      }
    }
  }, [trigger, position, count]);

  useFrame((_, delta) => {
    if (!particlesRef.current.active || !pointsRef.current) return;

    const particles = particlesRef.current;
    const positions = particles.positions;
    const velocities = particles.velocities;
    const life = particles.life;

    let anyAlive = false;

    for (let i = 0; i < count; i++) {
      const i3 = i * 3;
      
      if (life[i] > 0) {
        anyAlive = true;

        // Update positions
        positions[i3] += velocities[i3] * delta;
        positions[i3 + 1] += velocities[i3 + 1] * delta;
        positions[i3 + 2] += velocities[i3 + 2] * delta;

        // Apply gravity
        velocities[i3 + 1] -= 9.8 * delta;

        // Decay life
        life[i] -= delta * 2;
      }
    }

    // Update geometry
    pointsRef.current.geometry.attributes.position.needsUpdate = true;

    // Deactivate if all particles are dead
    if (!anyAlive) {
      particles.active = false;
    }
  });

  if (!particlesRef.current.active) return null;

  return (
    <points ref={pointsRef} geometry={geometry}>
      <pointsMaterial
        color={color}
        size={0.1}
        transparent
        opacity={0.8}
        blending={THREE.AdditiveBlending}
      />
    </points>
  );
};
