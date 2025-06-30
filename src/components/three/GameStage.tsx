import React, { useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import { Plane, Text, Box } from '@react-three/drei';
import * as THREE from 'three';

const GameStage: React.FC = () => {
  const stageRef = useRef<THREE.Group>(null);
  const backgroundRef = useRef<THREE.Mesh>(null);

  // Animate the background
  useFrame((state) => {
    if (backgroundRef.current) {
      backgroundRef.current.rotation.z = Math.sin(state.clock.elapsedTime * 0.1) * 0.1;
    }
    
    if (stageRef.current) {
      // Subtle breathing effect for the entire stage
      stageRef.current.scale.setScalar(1 + Math.sin(state.clock.elapsedTime * 0.5) * 0.02);
    }
  });

  return (
    <group ref={stageRef}>
      {/* Main Stage Platform */}
      <Box 
        position={[0, -1, 0]} 
        args={[12, 0.2, 20]}
        receiveShadow
      >
        <meshLambertMaterial 
          color="#1a1a2e" 
          transparent 
          opacity={0.8}
        />
      </Box>

      {/* Venezuelan-inspired Background */}
      <Plane
        ref={backgroundRef}
        position={[0, 0, -10]}
        args={[20, 15]}
      >
        <meshBasicMaterial 
          color="#0f3460"
          transparent
          opacity={0.3}
        />
      </Plane>

      {/* Hit Zone Indicators */}
      <group position={[0, 0, 2]}>
        {/* Player 1 hit zones */}
        <group position={[-3, 0, 0]}>
          {[-1.5, -0.5, 0.5, 1.5].map((x, index) => (
            <Box
              key={`p1-${index}`}
              position={[x, 0, 0]}
              args={[0.8, 0.1, 0.8]}
            >
              <meshLambertMaterial 
                color="#FF6B6B"
                transparent
                opacity={0.3}
                emissive="#FF6B6B"
                emissiveIntensity={0.1}
              />
            </Box>
          ))}
        </group>

        {/* Player 2 hit zones */}
        <group position={[3, 0, 0]}>
          {[-1.5, -0.5, 0.5, 1.5].map((x, index) => (
            <Box
              key={`p2-${index}`}
              position={[x, 0, 0]}
              args={[0.8, 0.1, 0.8]}
            >
              <meshLambertMaterial 
                color="#4ECDC4"
                transparent
                opacity={0.3}
                emissive="#4ECDC4"
                emissiveIntensity={0.1}
              />
            </Box>
          ))}
        </group>
      </group>

      {/* Lane Dividers */}
      {[-3, 3].map((groupX, groupIndex) => (
        <group key={groupIndex} position={[groupX, 0, 0]}>
          {[-1, 0, 1].map((x, index) => (
            <Box
              key={index}
              position={[x, 0, 0]}
              args={[0.05, 2, 20]}
            >
              <meshLambertMaterial 
                color="white"
                transparent
                opacity={0.1}
              />
            </Box>
          ))}
        </group>
      ))}

      {/* Venezuelan Cultural Elements */}
      <Text
        position={[0, 3, -5]}
        fontSize={0.8}
        color="#FCDD09"
        anchorX="center"
        anchorY="middle"
        font="/fonts/venezuelan-font.woff"
      >
        TUKI TUKI
      </Text>

      <Text
        position={[0, 2.2, -5]}
        fontSize={0.3}
        color="#cccccc"
        anchorX="center"
        anchorY="middle"
      >
        Venezuelan Rhythm Revolution
      </Text>

      {/* Barrio-inspired decorative elements */}
      <group position={[-8, 2, -8]}>
        {Array.from({ length: 5 }).map((_, i) => (
          <Box
            key={i}
            position={[i * 0.5, Math.random() * 2, Math.random() * 2]}
            args={[0.2, Math.random() * 1 + 0.5, 0.2]}
          >
            <meshLambertMaterial 
              color={`hsl(${Math.random() * 60 + 40}, 70%, 60%)`}
              transparent
              opacity={0.4}
            />
          </Box>
        ))}
      </group>

      <group position={[8, 2, -8]}>
        {Array.from({ length: 5 }).map((_, i) => (
          <Box
            key={i}
            position={[-i * 0.5, Math.random() * 2, Math.random() * 2]}
            args={[0.2, Math.random() * 1 + 0.5, 0.2]}
          >
            <meshLambertMaterial 
              color={`hsl(${Math.random() * 60 + 200}, 70%, 60%)`}
              transparent
              opacity={0.4}
            />
          </Box>
        ))}
      </group>

      {/* Particle system placeholder */}
      <group position={[0, 5, 0]}>
        {Array.from({ length: 20 }).map((_, i) => (
          <mesh
            key={i}
            position={[
              (Math.random() - 0.5) * 20,
              (Math.random() - 0.5) * 10,
              (Math.random() - 0.5) * 20
            ]}
          >
            <sphereGeometry args={[0.02, 8, 8]} />
            <meshBasicMaterial 
              color={Math.random() > 0.5 ? "#FCDD09" : "#FF6B6B"}
              transparent
              opacity={0.6}
            />
          </mesh>
        ))}
      </group>
    </group>
  );
};

export default GameStage;
