import React, { useState, useEffect, useCallback } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { motion } from 'framer-motion';
import { Box } from '@react-three/drei';
import { ComboPopup } from './components/ui/ComboPopup';
import { ParticleEffects } from './components/three/ParticleEffects';
import './App.css';

// Game modes
type GameMode = 'story' | 'multiplayer' | 'practice' | 'settings';
type ArrowDirection = 'left' | 'down' | 'up' | 'right';
type HitResult = 'PERFECT' | 'GREAT' | 'GOOD' | 'MISS';

// Arrow interface
interface GameArrow {
  id: string;
  direction: ArrowDirection;
  player: 1 | 2;
  position: number; // Z position (distance from hit zone)
  time: number;
  hit: boolean;
}

// Simple game state
interface GameState {
  mode: GameMode;
  isPlaying: boolean;
  isPaused: boolean;
  score1: number;
  score2: number;
  combo1: number;
  combo2: number;
  currentTime: number;
}

function App() {
  const [gameState, setGameState] = useState<GameState>({
    mode: 'story',
    isPlaying: false,
    isPaused: false,
    score1: 0,
    score2: 0,
    combo1: 0,
    combo2: 0,
    currentTime: 0
  });

  const [currentStoryStep, setCurrentStoryStep] = useState(0);
  const [arrows, setArrows] = useState<GameArrow[]>([]);
  const [lastArrowTime, setLastArrowTime] = useState(0);
  const [gameStartTime, setGameStartTime] = useState(0);
  const [pressedKeys, setPressedKeys] = useState<Set<string>>(new Set());
  const [currentSong] = useState("Ritmo del Barrio - Los Campeones del Tuki");
  
  // Effect state for visual feedback
  const [particleEffects, setParticleEffects] = useState<Array<{
    id: string;
    position: [number, number, number];
    type: HitResult;
    timestamp: number;
  }>>([]);
  
  const [comboPopups, setComboPopups] = useState<Array<{
    id: string;
    player: 1 | 2;
    combo: number;
    result: HitResult;
    score: number;
    timestamp: number;
  }>>([]);
  
  const [screenShake, setScreenShake] = useState(0);
  
  const [hitFeedback, setHitFeedback] = useState<Array<{
    id: string;
    player: 1 | 2;
    result: HitResult;
    score: number;
    position: { x: number; y: number };
    timestamp: number;
  }>>([]);

  // Enhanced beat simulation with better Tuki-style rhythm
  useEffect(() => {
    if (!gameState.isPlaying) return;

    const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
    let beatCount = 0;
    
    // Create a Tuki-style rhythm pattern (faster, more energetic)
    const beatInterval = setInterval(() => {
      if (gameState.isPlaying && !gameState.isPaused) {
        beatCount++;
        
        // Main kick drum sound (lower frequency)
        if (beatCount % 4 === 1 || beatCount % 4 === 3) {
          const kick = audioContext.createOscillator();
          const kickGain = audioContext.createGain();
          kick.connect(kickGain);
          kickGain.connect(audioContext.destination);
          
          kick.frequency.setValueAtTime(60, audioContext.currentTime);
          kick.frequency.exponentialRampToValueAtTime(40, audioContext.currentTime + 0.1);
          kickGain.gain.setValueAtTime(0.3, audioContext.currentTime);
          kickGain.gain.exponentialRampToValueAtTime(0.001, audioContext.currentTime + 0.15);
          
          kick.start();
          kick.stop(audioContext.currentTime + 0.15);
        }
        
        // Hi-hat sound (higher frequency)
        if (beatCount % 2 === 0) {
          const hihat = audioContext.createOscillator();
          const hihatGain = audioContext.createGain();
          hihat.connect(hihatGain);
          hihatGain.connect(audioContext.destination);
          
          hihat.frequency.setValueAtTime(8000, audioContext.currentTime);
          hihat.type = 'square';
          hihatGain.gain.setValueAtTime(0.1, audioContext.currentTime);
          hihatGain.gain.exponentialRampToValueAtTime(0.001, audioContext.currentTime + 0.05);
          
          hihat.start();
          hihat.stop(audioContext.currentTime + 0.05);
        }
        
        // Melodic accent every 8 beats
        if (beatCount % 8 === 0) {
          const melody = audioContext.createOscillator();
          const melodyGain = audioContext.createGain();
          melody.connect(melodyGain);
          melodyGain.connect(audioContext.destination);
          
          melody.frequency.setValueAtTime(220, audioContext.currentTime);
          melody.frequency.exponentialRampToValueAtTime(330, audioContext.currentTime + 0.2);
          melody.type = 'sawtooth';
          melodyGain.gain.setValueAtTime(0.15, audioContext.currentTime);
          melodyGain.gain.exponentialRampToValueAtTime(0.001, audioContext.currentTime + 0.3);
          
          melody.start();
          melody.stop(audioContext.currentTime + 0.3);
        }
      }
    }, 400); // Faster beat: 150 BPM (400ms intervals)

    return () => {
      clearInterval(beatInterval);
      try {
        audioContext.close();
      } catch (e) {
        // Handle cleanup errors silently
      }
    };
  }, [gameState.isPlaying, gameState.isPaused]);

  // Player controls
  const player1Keys = {
    left: 'a',
    down: 's', 
    up: 'w',
    right: 'd'
  };

  const player2Keys = {
    left: 'ArrowLeft',
    down: 'ArrowDown',
    up: 'ArrowUp', 
    right: 'ArrowRight'
  };

  // Enhanced arrow generation synchronized with the beat
  useEffect(() => {
    if (!gameState.isPlaying || gameState.isPaused) return;

    const interval = setInterval(() => {
      const currentTime = Date.now() - gameStartTime;
      
      // Generate arrows every 800ms (synchronized with beat at 150 BPM)
      // Every 2 beats = 800ms
      if (currentTime - lastArrowTime > 800) {
        const directions: ArrowDirection[] = ['left', 'down', 'up', 'right'];
        
        // Generate 1-3 arrows at once for more interesting patterns
        const arrowCount = Math.random() > 0.7 ? (Math.random() > 0.5 ? 2 : 3) : 1;
        const usedDirections: ArrowDirection[] = [];
        
        for (let i = 0; i < arrowCount; i++) {
          const availableDirections = directions.filter(d => !usedDirections.includes(d));
          if (availableDirections.length === 0) break;
          
          const direction = availableDirections[Math.floor(Math.random() * availableDirections.length)];
          usedDirections.push(direction);
          
          // Determine player based on game mode
          let player: 1 | 2 = 1;
          if (gameState.mode === 'multiplayer') {
            player = Math.random() > 0.5 ? 1 : 2;
          }

          const newArrow: GameArrow = {
            id: `${Date.now()}-${Math.random()}-${i}`,
            direction,
            player,
            position: -25, // Start further away for better visibility
            time: currentTime,
            hit: false
          };

          setArrows(prev => [...prev, newArrow]);
        }
        
        setLastArrowTime(currentTime);
      }

      // Update arrow positions with improved movement
      setArrows(prev => prev
        .map(arrow => ({
          ...arrow,
          position: arrow.position + 0.25 // Slightly slower for better gameplay
        }))
        .filter(arrow => arrow.position < 8 && !arrow.hit) // Remove arrows that passed far beyond
      );

      // Update game time
      setGameState(prev => ({ ...prev, currentTime }));
    }, 16); // ~60fps

    return () => clearInterval(interval);
  }, [gameState.isPlaying, gameState.isPaused, lastArrowTime, gameStartTime, gameState.mode]);

  // Keyboard input handling
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      // Pause/unpause with Escape or Space
      if (event.key === 'Escape' || event.key === ' ') {
        if (gameState.isPlaying) {
          setGameState(prev => ({ ...prev, isPaused: !prev.isPaused }));
          return;
        }
      }
      
      if (!gameState.isPlaying || gameState.isPaused) return;
      
      const key = event.key.toLowerCase();
      if (pressedKeys.has(key)) return; // Prevent key repeat
      
      setPressedKeys(prev => new Set(prev).add(key));
      
      // Check hit for player 1
      if (Object.values(player1Keys).includes(key)) {
        const direction = Object.keys(player1Keys).find(
          dir => player1Keys[dir as keyof typeof player1Keys] === key
        ) as ArrowDirection;
        
        checkHit(1, direction);
      }
      
      // Check hit for player 2 (only in multiplayer)
      if (gameState.mode === 'multiplayer' && Object.values(player2Keys).includes(event.key)) {
        const direction = Object.keys(player2Keys).find(
          dir => player2Keys[dir as keyof typeof player2Keys] === event.key
        ) as ArrowDirection;
        
        checkHit(2, direction);
      }
    };

    const handleKeyUp = (event: KeyboardEvent) => {
      const key = event.key.toLowerCase();
      setPressedKeys(prev => {
        const newSet = new Set(prev);
        newSet.delete(key);
        return newSet;
      });
    };

    window.addEventListener('keydown', handleKeyDown);
    window.addEventListener('keyup', handleKeyUp);

    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      window.removeEventListener('keyup', handleKeyUp);
    };
  }, [gameState.isPlaying, gameState.isPaused, gameState.mode, pressedKeys]);

  // Enhanced hit detection with better feedback and visual effects
  const checkHit = useCallback((player: 1 | 2, direction: ArrowDirection) => {
    const hitZone = 3; // Larger hit zone for better gameplay
    const playerArrows = arrows.filter(arrow => 
      arrow.player === player && 
      arrow.direction === direction && 
      !arrow.hit &&
      Math.abs(arrow.position - 2) < hitZone // Distance from hit zone position
    );

    if (playerArrows.length === 0) {
      // Miss - reset combo and create visual feedback
      setGameState(prev => ({
        ...prev,
        [`combo${player}`]: 0
      }));
      
      // Create miss particle effect
      const lanePositions = {
        'left': [-3, 0, 2],
        'down': [-1, 0, 2],
        'up': [1, 0, 2],
        'right': [3, 0, 2]
      };

      setParticleEffects(prev => [...prev, {
        id: `miss-particle-${Date.now()}-${Math.random()}`,
        position: lanePositions[direction] as [number, number, number],
        type: 'MISS',
        timestamp: Date.now()
      }]);
      
      // Visual feedback for miss
      console.log(`Player ${player} MISSED!`);
      return;
    }

    // Find closest arrow to the hit zone (position 2)
    const closestArrow = playerArrows.reduce((closest, current) => 
      Math.abs(current.position - 2) < Math.abs(closest.position - 2) ? current : closest
    );

    // Calculate hit quality based on distance from hit zone
    const distance = Math.abs(closestArrow.position - 2);
    let points = 0;
    let result: HitResult = 'MISS';

    if (distance < 0.5) {
      result = 'PERFECT';
      points = 100;
    } else if (distance < 1.0) {
      result = 'GREAT';
      points = 80;
    } else if (distance < 1.5) {
      result = 'GOOD';
      points = 50;
    } else {
      result = 'MISS';
    }

    // Mark arrow as hit
    setArrows(prev => prev.map(arrow => 
      arrow.id === closestArrow.id ? { ...arrow, hit: true } : arrow
    ));

    // Update score and combo
    setGameState(prev => {
      const newCombo = result === 'MISS' ? 0 : (prev[`combo${player}` as keyof GameState] as number) + 1;
      const comboMultiplier = Math.min(newCombo / 10, 2);
      const finalPoints = Math.floor(points * (1 + comboMultiplier));

      // Create particle effect at arrow position
      const lanePositions = {
        'left': [-3, 0, 2],
        'down': [-1, 0, 2],
        'up': [1, 0, 2],
        'right': [3, 0, 2]
      };

      setParticleEffects(prev => [...prev, {
        id: `particle-${Date.now()}-${Math.random()}`,
        position: lanePositions[direction] as [number, number, number],
        type: result,
        timestamp: Date.now()
      }]);

      // Create combo popup
      if (result !== 'MISS') {
        setComboPopups(prev => [...prev, {
          id: `combo-${Date.now()}-${Math.random()}`,
          player,
          combo: newCombo,
          result,
          score: finalPoints,
          timestamp: Date.now()
        }]);
      }

      // Screen shake for perfect hits
      if (result === 'PERFECT') {
        setScreenShake(5);
        setTimeout(() => setScreenShake(0), 100);
      }

      // Create hit feedback text
      setHitFeedback(prev => [...prev, {
        id: `feedback-${Date.now()}-${Math.random()}`,
        player,
        result,
        score: finalPoints,
        position: { 
          x: player === 1 ? 25 : 75, 
          y: 35 + Math.random() * 10 
        },
        timestamp: Date.now()
      }]);

      return {
        ...prev,
        [`score${player}`]: (prev[`score${player}` as keyof GameState] as number) + finalPoints,
        [`combo${player}`]: newCombo
      };
    });

    // Enhanced feedback
    console.log(`Player ${player} hit ${result}! +${points} points (Combo: ${gameState[`combo${player}` as keyof GameState]})`);
    
    // Create hit sound effect
    try {
      const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
      const hitSound = audioContext.createOscillator();
      const hitGain = audioContext.createGain();
      
      hitSound.connect(hitGain);
      hitGain.connect(audioContext.destination);
      
      // Different frequencies for different hit qualities
      const frequencies = {
        'PERFECT': 800,
        'GREAT': 600,
        'GOOD': 400,
        'MISS': 200
      };
      
      hitSound.frequency.setValueAtTime(frequencies[result], audioContext.currentTime);
      hitGain.gain.setValueAtTime(0.2, audioContext.currentTime);
      hitGain.gain.exponentialRampToValueAtTime(0.001, audioContext.currentTime + 0.2);
      
      hitSound.start();
      hitSound.stop(audioContext.currentTime + 0.2);
      
      setTimeout(() => audioContext.close(), 300);
    } catch (e) {
      // Handle audio errors silently
    }
  }, [arrows, gameState]);
  
  // Cleanup old effects periodically
  useEffect(() => {
    const cleanup = setInterval(() => {
      const now = Date.now();
      
      // Remove old particle effects (after 2 seconds)
      setParticleEffects(prev => prev.filter(effect => now - effect.timestamp < 2000));
      
      // Remove old combo popups (after 3 seconds)
      setComboPopups(prev => prev.filter(popup => now - popup.timestamp < 3000));
      
      // Remove old hit feedback (after 2 seconds)
      setHitFeedback(prev => prev.filter(feedback => now - feedback.timestamp < 2000));
    }, 1000);

    return () => clearInterval(cleanup);
  }, []);
  
  // Story content
  const storySteps = [
    {
      title: "🇻🇪 TUKI TUKI 🇻🇪",
      text: "¡Bienvenidos! Welcome to the Venezuelan Rhythm Revolution!",
      subtitle: "In the vibrant barrios of Venezuela, where music flows through concrete veins and rhythm pulses in every heartbeat, a legendary competition emerges..."
    },
    {
      title: "The Legend of Tuki",
      text: "TUKI - born from the streets, forged by the people, a rhythm that captures the heartbeat of a nation.",
      subtitle: "Fast, fierce, and unapologetically Venezuelan. From Petare to Maracaibo, from Valencia to Barquisimeto."
    },
    {
      title: "Choose Your Battle",
      text: "Four champions await. Each brings their unique style and the pride of their homeland.",
      subtitle: "Will you dance solo or challenge a friend? The rhythm calls!"
    }
  ];

  const handleStartGame = (mode: GameMode) => {
    if (mode === 'multiplayer' || mode === 'practice') {
      setGameState(prev => ({ ...prev, mode, isPlaying: true }));
      setGameStartTime(Date.now());
      setArrows([]);
      setLastArrowTime(0);
    } else {
      setGameState(prev => ({ ...prev, mode }));
    }
  };

  const handleNextStory = () => {
    if (currentStoryStep < storySteps.length - 1) {
      setCurrentStoryStep(prev => prev + 1);
    }
  };

  const handlePrevStory = () => {
    if (currentStoryStep > 0) {
      setCurrentStoryStep(prev => prev - 1);
    }
  };

  // Enhanced 3D Arrow Component with better visibility
  const Arrow3D: React.FC<{ arrow: GameArrow }> = ({ arrow }) => {
    const meshRef = React.useRef<any>();
    
    useFrame((state, delta) => {
      if (meshRef.current) {
        // Enhanced rotation for more dynamic visual
        meshRef.current.rotation.y += delta * 3;
        meshRef.current.rotation.x = Math.sin(state.clock.elapsedTime * 2) * 0.1;
        
        // Enhanced glow effect when near hit zone
        const distanceFromHitZone = Math.abs(arrow.position - 2);
        const glowIntensity = Math.max(0, 1 - distanceFromHitZone / 5);
        meshRef.current.material.emissiveIntensity = glowIntensity * 0.8;
        
        // Scale effect when approaching hit zone
        const scale = 1 + glowIntensity * 0.3;
        meshRef.current.scale.setScalar(scale);
        
        // Bounce effect
        meshRef.current.position.y = Math.sin(state.clock.elapsedTime * 4 + arrow.position) * 0.1;
      }
    });

    // Position based on direction and player
    const getPosition = (): [number, number, number] => {
      const playerOffset = arrow.player === 1 ? -2 : 2;
      let directionOffset = 0;
      
      switch (arrow.direction) {
        case 'left': directionOffset = -1.5; break;
        case 'down': directionOffset = -0.5; break;
        case 'up': directionOffset = 0.5; break;
        case 'right': directionOffset = 1.5; break;
      }
      
      return [playerOffset + directionOffset, 0, arrow.position];
    };

    const getColor = () => {
      const colors = {
        1: {
          left: '#FF6B6B',   // Red
          down: '#4ECDC4',   // Teal  
          up: '#45B7D1',     // Blue
          right: '#96CEB4'   // Green
        },
        2: {
          left: '#FFEAA7',   // Yellow
          down: '#DDA0DD',   // Plum
          up: '#98D8C8',     // Mint
          right: '#F7DC6F'   // Light Yellow
        }
      };
      return colors[arrow.player][arrow.direction];
    };

    // Create arrow shape based on direction
    const getArrowGeometry = () => {
      // Use a more distinctive shape for arrows
      switch (arrow.direction) {
        case 'up':
          return <coneGeometry args={[0.3, 0.8, 6]} />;
        case 'down':
          return <coneGeometry args={[0.3, 0.8, 6]} />;
        case 'left':
        case 'right':
          return <boxGeometry args={[0.8, 0.3, 0.3]} />;
        default:
          return <boxGeometry args={[0.4, 0.6, 0.4]} />;
      }
    };

    const getRotation = (): [number, number, number] => {
      switch (arrow.direction) {
        case 'up': return [0, 0, 0];
        case 'down': return [Math.PI, 0, 0];
        case 'left': return [0, 0, Math.PI / 2];
        case 'right': return [0, 0, -Math.PI / 2];
        default: return [0, 0, 0];
      }
    };

    return (
      <mesh
        ref={meshRef}
        position={getPosition()}
        rotation={getRotation()}
      >
        {getArrowGeometry()}
        <meshLambertMaterial 
          color={getColor()}
          emissive={getColor()}
          emissiveIntensity={0.3}
          transparent
          opacity={0.9}
        />
      </mesh>
    );
  };

  // Hit Zone Component with dynamic glow
  const HitZone: React.FC<{ player: 1 | 2; direction: ArrowDirection; x: number }> = ({ player, direction, x }) => {
    const color = player === 1 ? '#FF6B6B' : '#4ECDC4';
    const isPressed = React.useMemo(() => {
      const keys = player === 1 ? player1Keys : player2Keys;
      return pressedKeys.has(keys[direction]);
    }, [player, direction, pressedKeys]);

    // Check for nearby arrows for glow effect
    const nearbyArrows = React.useMemo(() => {
      return arrows.filter(arrow => 
        arrow.player === player &&
        arrow.direction === direction && 
        Math.abs(arrow.position - 2) < 3 &&
        !arrow.hit
      );
    }, [player, direction, arrows]);

    const hasNearbyArrow = nearbyArrows.length > 0;
    const glowIntensity = hasNearbyArrow ? 0.5 : (isPressed ? 0.3 : 0.1);

    return (
      <Box position={[x, -0.5, 2]} args={[0.8, 0.1, 0.8]}>
        <meshLambertMaterial 
          color={color}
          transparent
          opacity={isPressed ? 0.8 : hasNearbyArrow ? 0.6 : 0.3}
          emissive={color}
          emissiveIntensity={glowIntensity}
        />
      </Box>
    );
  };

  // Render game based on mode
  const renderContent = () => {
    if (gameState.isPlaying) {
      return (
        <div className="game-screen">
          {/* Pause Overlay */}
          {gameState.isPaused && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="pause-overlay"
              style={{
                position: 'fixed',
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                backgroundColor: 'rgba(0, 0, 0, 0.8)',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                zIndex: 2000,
                color: 'white',
                fontSize: '24px',
                textAlign: 'center'
              }}
            >
              <motion.h2
                initial={{ scale: 0.5 }}
                animate={{ scale: 1 }}
                style={{ marginBottom: '20px', fontSize: '48px', color: '#FFD700' }}
              >
                PAUSED
              </motion.h2>
              <motion.p
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 }}
                style={{ marginBottom: '30px', fontSize: '18px' }}
              >
                Press ESC or SPACE to resume
              </motion.p>
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.4 }}
                style={{ display: 'flex', gap: '20px' }}
              >
                <button 
                  className="story-button"
                  onClick={() => setGameState(prev => ({ ...prev, isPaused: false }))}
                >
                  Resume
                </button>
                <button 
                  className="story-button"
                  onClick={() => {
                    setGameState(prev => ({ ...prev, isPlaying: false, isPaused: false, mode: 'story' }));
                    setArrows([]);
                  }}
                >
                  Quit to Menu
                </button>
              </motion.div>
            </motion.div>
          )}
          
          {/* 3D Game Canvas */}
          <div className="canvas-container" style={{
            transform: `translate(${screenShake * (Math.random() - 0.5)}px, ${screenShake * (Math.random() - 0.5)}px)`,
            transition: screenShake > 0 ? 'none' : 'transform 0.1s ease-out'
          }}>
            <Canvas
              camera={{ position: [0, 3, 10], fov: 60 }}
              dpr={[1, 2]}
            >
              {/* Enhanced lighting setup */}
              <ambientLight intensity={0.4} />
              <directionalLight position={[10, 10, 5]} intensity={1} castShadow />
              <pointLight position={[0, 5, 5]} intensity={0.8} color="#ffffff" />
              
              {/* Dynamic colored lights for each player */}
              <pointLight position={[-3, 3, 3]} intensity={1.2} color="#FF6B6B" />
              {gameState.mode === 'multiplayer' && (
                <pointLight position={[3, 3, 3]} intensity={1.2} color="#4ECDC4" />
              )}
              
              {/* Background atmosphere */}
              <pointLight position={[0, -2, -10]} intensity={0.5} color="#6C5CE7" />
              
              {/* Enhanced game stage */}
              <Box position={[0, -1.5, 0]} args={[16, 0.3, 30]} receiveShadow>
                <meshLambertMaterial 
                  color="#0F0F23" 
                  transparent 
                  opacity={0.9}
                  emissive="#0F0F23"
                  emissiveIntensity={0.1}
                />
              </Box>

              {/* Enhanced lane markers with glow effect */}
              {[-3, -2, -1, 0, 1, 2, 3].map(x => (
                <Box key={x} position={[x, -1, 0]} args={[0.05, 0.1, 30]}>
                  <meshLambertMaterial 
                    color="#74B9FF" 
                    transparent 
                    opacity={0.3}
                    emissive="#74B9FF"
                    emissiveIntensity={0.2}
                  />
                </Box>
              ))}

              {/* Hit zone markers - more visible */}
              <Box position={[0, -1.2, 2]} args={[8, 0.05, 1]}>
                <meshLambertMaterial 
                  color="#00B894" 
                  transparent 
                  opacity={0.6}
                  emissive="#00B894"
                  emissiveIntensity={0.4}
                />
              </Box>

              {/* Enhanced Player Hit Zones with better visibility */}
              <HitZone player={1} direction="left" x={-3.5} />
              <HitZone player={1} direction="down" x={-2.5} />
              <HitZone player={1} direction="up" x={-1.5} />
              <HitZone player={1} direction="right" x={-0.5} />

              {/* Player 2 Hit Zones (only in multiplayer) */}
              {gameState.mode === 'multiplayer' && (
                <>
                  <HitZone player={2} direction="left" x={0.5} />
                  <HitZone player={2} direction="down" x={1.5} />
                  <HitZone player={2} direction="up" x={2.5} />
                  <HitZone player={2} direction="right" x={3.5} />
                </>
              )}

              {/* Falling Arrows with enhanced visibility */}
              {arrows.map(arrow => (
                <Arrow3D key={arrow.id} arrow={arrow} />
              ))}

              {/* Lane dividers - thicker and more visible */}
              {[-2, -1, 0, 1, 2, 3].map(x => (
                <Box key={x} position={[x, 0, 0]} args={[0.02, 3, 30]}>
                  <meshLambertMaterial 
                    color="white" 
                    transparent 
                    opacity={0.15}
                    emissive="white"
                    emissiveIntensity={0.1}
                  />
                </Box>
              ))}

              {/* Background elements for atmosphere */}
              <Box position={[0, 3, -15]} args={[20, 6, 1]}>
                <meshLambertMaterial 
                  color="#2D3436" 
                  transparent 
                  opacity={0.4}
                />
              </Box>

              {/* Venezuelan flag elements in background */}
              <Box position={[-8, 2, -12]} args={[2, 4, 0.5]}>
                <meshLambertMaterial color="#FCDD09" transparent opacity={0.3} />
              </Box>
              <Box position={[8, 2, -12]} args={[2, 4, 0.5]}>
                <meshLambertMaterial color="#CF142B" transparent opacity={0.3} />
              </Box>
              
              {/* Particle Effects */}
              {particleEffects.map(effect => (
                <ParticleEffects
                  key={effect.id}
                  position={effect.position}
                  trigger={true}
                  color={effect.type === 'PERFECT' ? '#FFD700' : 
                        effect.type === 'GREAT' ? '#4ECDC4' : 
                        effect.type === 'GOOD' ? '#95E1D3' : '#E74C3C'}
                  count={effect.type === 'PERFECT' ? 30 : 
                         effect.type === 'GREAT' ? 20 : 15}
                />
              ))}
            </Canvas>
          </div>

          {/* Game HUD */}
          <div className="game-hud">
            <div className="score-display">
              <div className="player-score player1">
                <h3>Player 1 (WASD)</h3>
                <div className="score">{gameState.score1.toLocaleString()}</div>
                <div className="combo">Combo: {gameState.combo1}</div>
              </div>
              
              <div className="song-info">
                <h2>Ritmo del Barrio</h2>
                <p>Los Campeones del Tuki</p>
                <div className="difficulty">STANDARD</div>
              </div>
              
              {gameState.mode === 'multiplayer' && (
                <div className="player-score player2">
                  <h3>Player 2 (Arrows)</h3>
                  <div className="score">{gameState.score2.toLocaleString()}</div>
                  <div className="combo">Combo: {gameState.combo2}</div>
                </div>
              )}
            </div>

            {/* Combo Popups */}
            {comboPopups.map(popup => (
              <ComboPopup
                key={popup.id}
                player={popup.player}
                combo={popup.combo}
                hitResult={popup.result}
                visible={true}
              />
            ))}

            {/* Hit Feedback */}
            {hitFeedback.map(feedback => (
              <motion.div
                key={feedback.id}
                initial={{ opacity: 1, scale: 1, y: 0 }}
                animate={{ opacity: 0, scale: 1.2, y: -50 }}
                transition={{ duration: 1.5, ease: 'easeOut' }}
                style={{
                  position: 'fixed',
                  left: `${feedback.position.x}%`,
                  top: `${feedback.position.y}%`,
                  transform: 'translateX(-50%)',
                  zIndex: 999,
                  fontSize: '18px',
                  fontWeight: 'bold',
                  pointerEvents: 'none',
                  color: feedback.result === 'PERFECT' ? '#FFD700' :
                         feedback.result === 'GREAT' ? '#4ECDC4' :
                         feedback.result === 'GOOD' ? '#95E1D3' : '#E74C3C',
                  textShadow: '0 0 10px rgba(0,0,0,0.8)'
                }}
              >
                {feedback.result} +{feedback.score}
              </motion.div>
            ))}

            <div className="game-controls" style={{
              position: 'absolute',
              bottom: '100px',
              left: '50%',
              transform: 'translateX(-50%)',
              textAlign: 'center'
            }}>
              <div style={{ marginBottom: '10px', fontSize: '14px', opacity: 0.7 }}>
                Press ESC or SPACE to pause
              </div>
              <button 
                className="story-button"
                onClick={() => {
                  setGameState(prev => ({ ...prev, isPlaying: false, mode: 'story' }));
                  setArrows([]);
                }}
              >
                Back to Menu
              </button>
            </div>

            {/* Key Indicators */}
            <div style={{
              position: 'absolute',
              bottom: '40px',
              left: '50%',
              transform: 'translateX(-50%)',
              display: 'flex',
              gap: '60px'
            }}>
              {/* Player 1 Keys */}
              <div style={{ textAlign: 'center' }}>
                <h4 style={{ marginBottom: '10px', color: '#FF6B6B' }}>Player 1</h4>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 40px)', gap: '5px', justifyContent: 'center' }}>
                  <div></div>
                  <div 
                    className={`key-indicator ${pressedKeys.has('w') ? 'pressed' : ''}`}
                    style={{ 
                      background: pressedKeys.has('w') ? '#FF6B6B' : 'rgba(255, 107, 107, 0.3)',
                      border: '2px solid #FF6B6B',
                      borderRadius: '5px',
                      padding: '8px',
                      color: 'white',
                      fontWeight: 'bold'
                    }}
                  >
                    W
                  </div>
                  <div 
                    className={`key-indicator ${pressedKeys.has('a') ? 'pressed' : ''}`}
                    style={{ 
                      background: pressedKeys.has('a') ? '#FF6B6B' : 'rgba(255, 107, 107, 0.3)',
                      border: '2px solid #FF6B6B',
                      borderRadius: '5px',
                      padding: '8px',
                      color: 'white',
                      fontWeight: 'bold'
                    }}
                  >
                    A
                  </div>
                  <div 
                    className={`key-indicator ${pressedKeys.has('s') ? 'pressed' : ''}`}
                    style={{ 
                      background: pressedKeys.has('s') ? '#FF6B6B' : 'rgba(255, 107, 107, 0.3)',
                      border: '2px solid #FF6B6B',
                      borderRadius: '5px',
                      padding: '8px',
                      color: 'white',
                      fontWeight: 'bold'
                    }}
                  >
                    S
                  </div>
                  <div 
                    className={`key-indicator ${pressedKeys.has('d') ? 'pressed' : ''}`}
                    style={{ 
                      background: pressedKeys.has('d') ? '#FF6B6B' : 'rgba(255, 107, 107, 0.3)',
                      border: '2px solid #FF6B6B',
                      borderRadius: '5px',
                      padding: '8px',
                      color: 'white',
                      fontWeight: 'bold'
                    }}
                  >
                    D
                  </div>
                </div>
              </div>

              {/* Player 2 Keys (only in multiplayer) */}
              {gameState.mode === 'multiplayer' && (
                <div style={{ textAlign: 'center' }}>
                  <h4 style={{ marginBottom: '10px', color: '#4ECDC4' }}>Player 2</h4>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 40px)', gap: '5px', justifyContent: 'center' }}>
                    <div></div>
                    <div 
                      className={`key-indicator ${pressedKeys.has('ArrowUp') ? 'pressed' : ''}`}
                      style={{ 
                        background: pressedKeys.has('ArrowUp') ? '#4ECDC4' : 'rgba(78, 205, 196, 0.3)',
                        border: '2px solid #4ECDC4',
                        borderRadius: '5px',
                        padding: '8px',
                        color: 'white',
                        fontWeight: 'bold'
                      }}
                    >
                      ↑
                    </div>
                    <div 
                      className={`key-indicator ${pressedKeys.has('ArrowLeft') ? 'pressed' : ''}`}
                      style={{ 
                        background: pressedKeys.has('ArrowLeft') ? '#4ECDC4' : 'rgba(78, 205, 196, 0.3)',
                        border: '2px solid #4ECDC4',
                        borderRadius: '5px',
                        padding: '8px',
                        color: 'white',
                        fontWeight: 'bold'
                      }}
                    >
                      ←
                    </div>
                    <div 
                      className={`key-indicator ${pressedKeys.has('ArrowDown') ? 'pressed' : ''}`}
                      style={{ 
                        background: pressedKeys.has('ArrowDown') ? '#4ECDC4' : 'rgba(78, 205, 196, 0.3)',
                        border: '2px solid #4ECDC4',
                        borderRadius: '5px',
                        padding: '8px',
                        color: 'white',
                        fontWeight: 'bold'
                      }}
                    >
                      ↓
                    </div>
                    <div 
                      className={`key-indicator ${pressedKeys.has('ArrowRight') ? 'pressed' : ''}`}
                      style={{ 
                        background: pressedKeys.has('ArrowRight') ? '#4ECDC4' : 'rgba(78, 205, 196, 0.3)',
                        border: '2px solid #4ECDC4',
                        borderRadius: '5px',
                        padding: '8px',
                        color: 'white',
                        fontWeight: 'bold'
                      }}
                    >
                      →
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      );
    }

    // Story/Menu mode
    return (
      <div className="story-screen">
        <motion.div
          className="story-content"
          initial={{ opacity: 0, y: 50 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
        >
          <motion.h1 
            className="story-title glow"
            initial={{ scale: 0.5, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ delay: 0.2, duration: 0.6 }}
          >
            {storySteps[currentStoryStep].title}
          </motion.h1>
          
          <motion.p 
            className="story-text"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.4, duration: 0.6 }}
          >
            {storySteps[currentStoryStep].text}
          </motion.p>

          <motion.div 
            className="story-text"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.6, duration: 0.6 }}
          >
            {storySteps[currentStoryStep].subtitle}
          </motion.div>

          {/* Navigation */}
          <div style={{ display: 'flex', gap: '20px', margin: '20px 0', justifyContent: 'center' }}>
            {currentStoryStep > 0 && (
              <button className="story-button" onClick={handlePrevStory}>
                ← Previous
              </button>
            )}
            {currentStoryStep < storySteps.length - 1 && (
              <button className="story-button" onClick={handleNextStory}>
                Next →
              </button>
            )}
          </div>

          {/* Game mode selection */}
          {currentStoryStep === storySteps.length - 1 && (
            <motion.div 
              className="story-choices"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.8, duration: 0.6 }}
            >
              <button 
                className="story-button pulse"
                onClick={() => handleStartGame('multiplayer')}
              >
                🎮 Multiplayer Battle
              </button>
              
              <button 
                className="story-button pulse"
                onClick={() => handleStartGame('practice')}
              >
                🎵 Solo Practice
              </button>
              
              <button 
                className="story-button pulse"
                onClick={() => setCurrentStoryStep(0)}
              >
                📖 Restart Story
              </button>
            </motion.div>
          )}

          {/* Controls info */}
          <div style={{ 
            marginTop: '40px', 
            fontSize: '0.9rem', 
            opacity: 0.8,
            textAlign: 'center' 
          }}>
            <p><strong>Game Controls:</strong></p>
            <div style={{ display: 'flex', gap: '40px', justifyContent: 'center', marginTop: '10px' }}>
              <div>
                <p><strong>Player 1:</strong> WASD</p>
                <div style={{ fontSize: '0.8rem', opacity: 0.7 }}>
                  W(↑) A(←) S(↓) D(→)
                </div>
              </div>
              <div>
                <p><strong>Player 2:</strong> Arrow Keys</p>
                <div style={{ fontSize: '0.8rem', opacity: 0.7 }}>
                  ↑ ← ↓ →
                </div>
              </div>
            </div>
          </div>

          {/* Cultural info */}
          <div className="cultural-elements" style={{
            marginTop: '30px',
            textAlign: 'center',
            opacity: 0.7,
            fontSize: '0.8rem'
          }}>
            <p>🎵 Celebrating Venezuelan Tuki Music Culture 🎵</p>
            <div style={{ fontSize: '0.7rem', marginTop: '5px' }}>
              From Petare to Maracaibo • From Valencia to Barquisimeto
            </div>
          </div>
        </motion.div>
      </div>
    );
  };

  return (
    <div className="app">
      <div className="ui-overlay">
        {renderContent()}
        
        {/* Venezuelan flag accent */}
        <div className="venezuelan-accent">
          <div className="flag-stripe yellow"></div>
          <div className="flag-stripe blue"></div>
          <div className="flag-stripe red"></div>
        </div>
      </div>
    </div>
  );
}

export default App;
