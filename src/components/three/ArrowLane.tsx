import React, { useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import { Box } from '@react-three/drei';
import { ArrowDirection, Player } from '../../types/GameTypes';
import * as THREE from 'three';

interface ArrowLaneProps {
  direction: ArrowDirection;
  player: Player;
  position: [number, number, number];
  color: string;
}

const ArrowLane: React.FC<ArrowLaneProps> = ({ direction, player, position, color }) => {
  const laneRef = useRef<THREE.Group>(null);
  const glowRef = useRef<THREE.Mesh>(null);

  // Create lane glow effect
  useFrame((state) => {
    if (glowRef.current) {
      const intensity = 0.3 + Math.sin(state.clock.elapsedTime * 2) * 0.1;
      const material = glowRef.current.material as THREE.MeshLambertMaterial;
      if (material.emissiveIntensity !== undefined) {
        material.emissiveIntensity = intensity;
      }
    }
  });

  return (
    <group ref={laneRef} position={position}>
      {/* Lane Track */}
      <Box args={[0.9, 0.05, 20]} position={[0, -0.1, 0]}>
        <meshLambertMaterial 
          color={color}
          transparent
          opacity={0.3}
          emissive={color}
          emissiveIntensity={0.1}
        />
      </Box>

      {/* Lane Walls */}
      <Box args={[0.05, 1, 20]} position={[-0.45, 0.4, 0]}>
        <meshLambertMaterial 
          color={color}
          transparent
          opacity={0.2}
        />
      </Box>
      <Box args={[0.05, 1, 20]} position={[0.45, 0.4, 0]}>
        <meshLambertMaterial 
          color={color}
          transparent
          opacity={0.2}
        />
      </Box>

      {/* Hit Zone Indicator */}
      <Box 
        ref={glowRef}
        args={[0.8, 0.8, 0.1]} 
        position={[0, 0, 2]}
      >
        <meshLambertMaterial 
          color={color}
          transparent
          opacity={0.4}
          emissive={color}
          emissiveIntensity={0.3}
        />
      </Box>

      {/* Direction Indicator */}
      <mesh position={[0, 0.1, 2]}>
        <planeGeometry args={[0.4, 0.4]} />
        <meshBasicMaterial 
          color="white"
          transparent
          opacity={0.8}
        />
      </mesh>

      {/* Lane Grid Lines */}
      {Array.from({ length: 10 }).map((_, i) => (
        <Box
          key={i}
          args={[0.8, 0.01, 0.05]}
          position={[0, 0, i * 2 - 10]}
        >
          <meshBasicMaterial 
            color={color}
            transparent
            opacity={0.2}
          />
        </Box>
      ))}

      {/* Venezuelan-inspired lane decorations */}
      {player === 'player1' && (
        <>
          {/* Yellow accent (Venezuelan flag) */}
          <Box
            args={[0.1, 0.1, 20]}
            position={[-0.3, 0.2, 0]}
          >
            <meshBasicMaterial 
              color="#FCDD09"
              transparent
              opacity={0.4}
            />
          </Box>
        </>
      )}

      {player === 'player2' && (
        <>
          {/* Blue accent (Venezuelan flag) */}
          <Box
            args={[0.1, 0.1, 20]}
            position={[0.3, 0.2, 0]}
          >
            <meshBasicMaterial 
              color="#00247D"
              transparent
              opacity={0.4}
            />
          </Box>
        </>
      )}

      {/* Performance optimization: LOD for distant elements */}
      <group position={[0, 0, -15]}>
        <Box args={[0.8, 0.02, 0.02]}>
          <meshBasicMaterial 
            color={color}
            transparent
            opacity={0.1}
          />
        </Box>
      </group>
    </group>
  );
};

export default ArrowLane;
