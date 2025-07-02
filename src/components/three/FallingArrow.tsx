import React, { useRef, useMemo } from 'react';
import { useFrame } from '@react-three/fiber';
import { Box, Cone } from '@react-three/drei';
import { Arrow, Player, ArrowDirection } from '../../types/GameTypes';
import * as THREE from 'three';

interface FallingArrowProps {
  arrow: Arrow;
  player: Player;
}

const FallingArrow: React.FC<FallingArrowProps> = ({ arrow, player }) => {
  const arrowRef = useRef<THREE.Group>(null);
  const meshRef = useRef<THREE.Mesh>(null);

  // Calculate lane positions based on player and direction
  const getLanePosition = (direction: ArrowDirection, playerType: Player): [number, number, number] => {
    const baseX = playerType === 'player1' ? -3 : 3;
    let laneX = 0;
    
    switch (direction) {
      case 'left': laneX = -1.5; break;
      case 'down': laneX = -0.5; break;
      case 'up': laneX = 0.5; break;
      case 'right': laneX = 1.5; break;
    }
    
    // Arrows now start from bottom and move up
    return [baseX + laneX, 0, arrow.position[2]];
  };

  // Get arrow color based on player
  const getArrowColor = (playerType: Player): string => {
    const baseColors = {
      'player1': '#FF6B6B',
      'player2': '#4ECDC4'
    };
    
    return baseColors[playerType];
  };

  // Get rotation for arrow direction
  const getArrowRotation = (direction: ArrowDirection): [number, number, number] => {
    switch (direction) {
      case 'left': return [0, 0, Math.PI / 2];
      case 'down': return [0, 0, Math.PI];
      case 'up': return [0, 0, 0];
      case 'right': return [0, 0, -Math.PI / 2];
      default: return [0, 0, 0];
    }
  };

  const position = getLanePosition(arrow.direction, player);
  const color = getArrowColor(player);
  const rotation = getArrowRotation(arrow.direction);

  // Animation and effects
  useFrame((state) => {
    if (arrowRef.current) {
      // Rotation animation
      arrowRef.current.rotation.y = Math.sin(state.clock.elapsedTime * 4) * 0.1;
      
      // Scale pulse effect when near hit zone
      const distanceToHitZone = Math.abs(arrow.position[2] - 2);
      if (distanceToHitZone < 1) {
        const scale = 1 + (1 - distanceToHitZone) * 0.2;
        arrowRef.current.scale.setScalar(scale);
      }
    }

    if (meshRef.current && arrow.hit) {
      // Hit effect - scale up and fade
      meshRef.current.scale.multiplyScalar(1.1);
      const material = meshRef.current.material as THREE.MeshLambertMaterial;
      material.opacity *= 0.9;
    }
  });

  // Memoize expensive calculations
  const arrowGeometry = useMemo(() => {
    return {
      shaft: [0.15, 0.6, 0.15] as [number, number, number],
      head: [0.3, 0.3, 4] as [number, number, number]
    };
  }, []);

  if (arrow.missed || arrow.hit) {
    return null; // Don't render hit or missed arrows
  }

  return (
    <group ref={arrowRef} position={position} rotation={rotation}>
      {/* Arrow Shaft */}
      <Box
        args={arrowGeometry.shaft}
        position={[0, -0.2, 0]}
      >
        <meshLambertMaterial 
          color={color}
          emissive={color}
          emissiveIntensity={0.3}
          transparent
          opacity={0.9}
        />
      </Box>

      {/* Arrow Head */}
      <Cone
        ref={meshRef}
        args={arrowGeometry.head}
        position={[0, 0.2, 0]}
      >
        <meshLambertMaterial 
          color={color}
          emissive={color}
          emissiveIntensity={0.4}
          transparent
          opacity={0.9}
        />
      </Cone>

      {/* Glow Effect */}
      <mesh position={[0, 0, 0]}>
        <sphereGeometry args={[0.4, 16, 16]} />
        <meshBasicMaterial 
          color={color}
          transparent
          opacity={0.1}
        />
      </mesh>

      {/* Trail Effect */}
      <group position={[0, 0, -0.5]}>
        {Array.from({ length: 3 }).map((_, i) => (
          <mesh 
            key={i} 
            position={[0, 0, -i * 0.2]}
            scale={[1 - i * 0.2, 1 - i * 0.2, 1 - i * 0.2]}
          >
            <sphereGeometry args={[0.1, 8, 8]} />
            <meshBasicMaterial 
              color={color}
              transparent
              opacity={0.3 - i * 0.1}
            />
          </mesh>
        ))}
      </group>

      {/* Venezuelan Cultural Accent */}
      {player === 'player1' && (
        <mesh position={[0.2, 0, 0]}>
          <sphereGeometry args={[0.05, 8, 8]} />
          <meshBasicMaterial color="#FCDD09" transparent opacity={0.6} />
        </mesh>
      )}
      
      {player === 'player2' && (
        <mesh position={[-0.2, 0, 0]}>
          <sphereGeometry args={[0.05, 8, 8]} />
          <meshBasicMaterial color="#00247D" transparent opacity={0.6} />
        </mesh>
      )}

      {/* Performance optimization: Simplified geometry at distance */}
      {Math.abs(arrow.position[2]) > 10 && (
        <mesh>
          <boxGeometry args={[0.2, 0.2, 0.2]} />
          <meshBasicMaterial color={color} />
        </mesh>
      )}
    </group>
  );
};

export default FallingArrow;
