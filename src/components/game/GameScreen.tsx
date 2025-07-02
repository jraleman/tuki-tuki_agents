import React, { useRef, useEffect } from 'react';
import { useFrame, useThree } from '@react-three/fiber';
import { useGameStore } from '../../store/gameStore';
import GameStage from '../three/GameStage';
import ArrowLane from '../three/ArrowLane';
import FallingArrow from '../three/FallingArrow';
import InputHandler from './InputHandler';
import * as THREE from 'three';

const GameScreen: React.FC = () => {
  const { 
    gameState, 
    arrows, 
    players, 
    isMultiplayer, 
    updateArrows
  } = useGameStore();
  
  const { camera } = useThree();
  const groupRef = useRef<THREE.Group>(null);
  const timeRef = useRef(0);

  // Set up camera position for optimal view
  useEffect(() => {
    // Position camera to see bottom-to-top arrow movement better
    camera.position.set(0, 3, 6);
    camera.lookAt(0, 0, 0);
  }, [camera]);

  // Game loop
  useFrame((_state, delta) => {
    if (!gameState.isPlaying || gameState.isPaused) return;
    
    timeRef.current += delta * 1000; // Convert to milliseconds
    updateArrows(delta * 1000);
    
    // Update game time
    useGameStore.getState().setGameState({ 
      currentTime: timeRef.current 
    });
  });

  return (
    <group ref={groupRef}>
      {/* Input Handler */}
      <InputHandler />
      
      {/* Game Stage - 3D Environment */}
      <GameStage />
      
      {/* Player 1 Lanes (Left side) */}
      <group position={[-3, 0, 0]}>
        <ArrowLane 
          direction="left" 
          player="player1" 
          position={[-1.5, 0, 0]}
          color={players[0].color}
        />
        <ArrowLane 
          direction="down" 
          player="player1" 
          position={[-0.5, 0, 0]}
          color={players[0].color}
        />
        <ArrowLane 
          direction="up" 
          player="player1" 
          position={[0.5, 0, 0]}
          color={players[0].color}
        />
        <ArrowLane 
          direction="right" 
          player="player1" 
          position={[1.5, 0, 0]}
          color={players[0].color}
        />
      </group>

      {/* Player 2 Lanes (Right side) - Only in multiplayer */}
      {isMultiplayer && (
        <group position={[3, 0, 0]}>
          <ArrowLane 
            direction="left" 
            player="player2" 
            position={[-1.5, 0, 0]}
            color={players[1].color}
          />
          <ArrowLane 
            direction="down" 
            player="player2" 
            position={[-0.5, 0, 0]}
            color={players[1].color}
          />
          <ArrowLane 
            direction="up" 
            player="player2" 
            position={[0.5, 0, 0]}
            color={players[1].color}
          />
          <ArrowLane 
            direction="right" 
            player="player2" 
            position={[1.5, 0, 0]}
            color={players[1].color}
          />
        </group>
      )}

      {/* Falling Arrows */}
      {arrows.map((arrow) => (
        <FallingArrow
          key={arrow.id}
          arrow={arrow}
          player={arrow.player}
        />
      ))}

      {/* Lighting */}
      <ambientLight intensity={0.6} />
      <pointLight 
        position={[0, 10, 5]} 
        intensity={1} 
        color="#ffffff" 
        castShadow
      />
      <pointLight 
        position={[-5, 5, 0]} 
        intensity={0.8} 
        color={players[0].color}
      />
      {isMultiplayer && (
        <pointLight 
          position={[5, 5, 0]} 
          intensity={0.8} 
          color={players[1].color}
        />
      )}
      
      {/* Background gradient lighting */}
      <pointLight
        position={[0, -5, -10]}
        intensity={0.5}
        color="#4A90E2"
      />
      
      {/* Venezuelan-themed accent lighting */}
      <pointLight
        position={[-10, 0, 0]}
        intensity={0.3}
        color="var(--venezuela-yellow)"
      />
      <pointLight
        position={[10, 0, 0]}
        intensity={0.3}
        color="var(--venezuela-red)"
      />
    </group>
  );
};

export default GameScreen;
