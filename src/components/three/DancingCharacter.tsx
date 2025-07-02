import React, { useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import { Box, Sphere, Cylinder } from '@react-three/drei';
import { Player } from '../../types/GameTypes';
import * as THREE from 'three';

interface DancingCharacterProps {
  player: Player;
  position: [number, number, number];
  isHit: boolean;
  hitDirection?: string;
  currentBeat: number;
}

const DancingCharacter: React.FC<DancingCharacterProps> = ({ 
  player, 
  position, 
  isHit, 
  hitDirection, 
  currentBeat 
}) => {
  const characterRef = useRef<THREE.Group>(null);
  const headRef = useRef<THREE.Mesh>(null);
  const leftArmRef = useRef<THREE.Group>(null);
  const rightArmRef = useRef<THREE.Group>(null);
  const leftLegRef = useRef<THREE.Group>(null);
  const rightLegRef = useRef<THREE.Group>(null);
  const torsoRef = useRef<THREE.Mesh>(null);
  
  // Get character colors based on player
  const getCharacterColors = (playerType: Player) => {
    if (playerType === 'player1') {
      return {
        skin: '#D2B48C',
        shirt: '#FF6B6B',
        pants: '#2C3E50',
        shoes: '#34495E'
      };
    } else {
      return {
        skin: '#DEB887',
        shirt: '#4ECDC4',
        pants: '#8E44AD',
        shoes: '#2C3E50'
      };
    }
  };

  const colors = getCharacterColors(player);

  // Dancing animation based on beat
  useFrame((state) => {
    if (!characterRef.current) return;

    const time = state.clock.elapsedTime;
    const beatTime = currentBeat * 0.5; // Beat timing
    
    // Base idle dancing animation
    const baseBounce = Math.sin(time * 4) * 0.1;
    characterRef.current.position.y = position[1] + baseBounce;
    
    // Head movement - nod to the beat
    if (headRef.current) {
      headRef.current.rotation.x = Math.sin(beatTime) * 0.2;
      headRef.current.rotation.y = Math.sin(time * 2) * 0.1;
    }
    
    // Arm movements - dancing gestures
    if (leftArmRef.current && rightArmRef.current) {
      const armSwing = Math.sin(time * 3);
      leftArmRef.current.rotation.z = armSwing * 0.5 + 0.3;
      rightArmRef.current.rotation.z = -armSwing * 0.5 - 0.3;
      
      // Add some shoulder movement
      leftArmRef.current.rotation.x = Math.sin(time * 2 + Math.PI/4) * 0.2;
      rightArmRef.current.rotation.x = Math.sin(time * 2 - Math.PI/4) * 0.2;
    }
    
    // Leg movements - stepping to the beat
    if (leftLegRef.current && rightLegRef.current) {
      const legMovement = Math.sin(beatTime + Math.PI);
      leftLegRef.current.rotation.x = legMovement * 0.3;
      rightLegRef.current.rotation.x = -legMovement * 0.3;
    }
    
    // Torso movement - sway with the music
    if (torsoRef.current) {
      torsoRef.current.rotation.z = Math.sin(time * 1.5) * 0.1;
      torsoRef.current.rotation.y = Math.sin(time * 0.8) * 0.05;
    }
    
    // Special hit animations
    if (isHit && hitDirection) {
      const hitIntensity = 1.5;
      const hitTime = time % 1; // Reset every second
      
      switch (hitDirection) {
        case 'left':
          if (leftArmRef.current) {
            leftArmRef.current.rotation.z += Math.sin(hitTime * 10) * hitIntensity;
          }
          break;
        case 'right':
          if (rightArmRef.current) {
            rightArmRef.current.rotation.z -= Math.sin(hitTime * 10) * hitIntensity;
          }
          break;
        case 'up':
          if (characterRef.current) {
            characterRef.current.position.y += Math.sin(hitTime * 8) * 0.3;
          }
          break;
        case 'down':
          if (leftLegRef.current && rightLegRef.current) {
            leftLegRef.current.rotation.x += Math.sin(hitTime * 12) * 0.5;
            rightLegRef.current.rotation.x += Math.sin(hitTime * 12) * 0.5;
          }
          break;
      }
    }
  });

  return (
    <group ref={characterRef} position={position}>
      {/* Head */}
      <Sphere 
        ref={headRef}
        position={[0, 1.7, 0]} 
        args={[0.25, 16, 16]}
      >
        <meshLambertMaterial 
          color={colors.skin}
        />
      </Sphere>
      
      {/* Eyes */}
      <Sphere position={[-0.1, 1.75, 0.2]} args={[0.05, 8, 8]}>
        <meshBasicMaterial color="black" />
      </Sphere>
      <Sphere position={[0.1, 1.75, 0.2]} args={[0.05, 8, 8]}>
        <meshBasicMaterial color="black" />
      </Sphere>
      
      {/* Smile */}
      <Box position={[0, 1.65, 0.22]} args={[0.15, 0.02, 0.02]}>
        <meshBasicMaterial color="black" />
      </Box>

      {/* Torso */}
      <Box 
        ref={torsoRef}
        position={[0, 1, 0]} 
        args={[0.5, 0.8, 0.3]}
      >
        <meshLambertMaterial color={colors.shirt} />
      </Box>

      {/* Left Arm */}
      <group ref={leftArmRef} position={[-0.35, 1.3, 0]}>
        <Cylinder args={[0.08, 0.08, 0.6, 8]} rotation={[0, 0, 0]}>
          <meshLambertMaterial color={colors.skin} />
        </Cylinder>
        {/* Hand */}
        <Sphere position={[0, -0.4, 0]} args={[0.1, 8, 8]}>
          <meshLambertMaterial color={colors.skin} />
        </Sphere>
      </group>

      {/* Right Arm */}
      <group ref={rightArmRef} position={[0.35, 1.3, 0]}>
        <Cylinder args={[0.08, 0.08, 0.6, 8]} rotation={[0, 0, 0]}>
          <meshLambertMaterial color={colors.skin} />
        </Cylinder>
        {/* Hand */}
        <Sphere position={[0, -0.4, 0]} args={[0.1, 8, 8]}>
          <meshLambertMaterial color={colors.skin} />
        </Sphere>
      </group>

      {/* Hips */}
      <Box position={[0, 0.4, 0]} args={[0.4, 0.3, 0.3]}>
        <meshLambertMaterial color={colors.pants} />
      </Box>

      {/* Left Leg */}
      <group ref={leftLegRef} position={[-0.15, 0.2, 0]}>
        <Cylinder args={[0.1, 0.1, 0.7, 8]} rotation={[0, 0, 0]}>
          <meshLambertMaterial color={colors.pants} />
        </Cylinder>
        {/* Foot */}
        <Box position={[0, -0.45, 0.1]} args={[0.15, 0.1, 0.25]}>
          <meshLambertMaterial color={colors.shoes} />
        </Box>
      </group>

      {/* Right Leg */}
      <group ref={rightLegRef} position={[0.15, 0.2, 0]}>
        <Cylinder args={[0.1, 0.1, 0.7, 8]} rotation={[0, 0, 0]}>
          <meshLambertMaterial color={colors.pants} />
        </Cylinder>
        {/* Foot */}
        <Box position={[0, -0.45, 0.1]} args={[0.15, 0.1, 0.25]}>
          <meshLambertMaterial color={colors.shoes} />
        </Box>
      </group>

      {/* Venezuelan cultural accessories */}
      {player === 'player1' && (
        <>
          {/* Venezuelan flag colors on shirt */}
          <Box position={[0, 1.2, 0.16]} args={[0.52, 0.1, 0.01]}>
            <meshBasicMaterial color="#FCDD09" />
          </Box>
          <Box position={[0, 1.1, 0.16]} args={[0.52, 0.1, 0.01]}>
            <meshBasicMaterial color="#00247D" />
          </Box>
          <Box position={[0, 1.0, 0.16]} args={[0.52, 0.1, 0.01]}>
            <meshBasicMaterial color="#CF142B" />
          </Box>
        </>
      )}
      
      {player === 'player2' && (
        <>
          {/* Different Venezuelan cultural element */}
          <Sphere position={[0, 1.9, 0]} args={[0.28, 8, 8]}>
            <meshLambertMaterial 
              color="#8B4513" 
              transparent 
              opacity={0.7}
            />
          </Sphere>
        </>
      )}

      {/* Glow effect when hitting notes */}
      {isHit && (
        <mesh position={[0, 1, 0]}>
          <sphereGeometry args={[1, 16, 16]} />
          <meshBasicMaterial 
            color={player === 'player1' ? '#FF6B6B' : '#4ECDC4'}
            transparent
            opacity={0.2}
          />
        </mesh>
      )}
    </group>
  );
};

export default DancingCharacter;
