import React from 'react';
import { Canvas } from '@react-three/fiber';
import { useGameStore } from './store/gameStore';
import StoryScreen from './components/ui/StoryScreen';
import GameScreen from './components/game/GameScreen';
import SettingsPanel from './components/ui/SettingsPanel';
import './App.css';

function App() {
  const { 
    showStory, 
    showSettings, 
    gameState, 
    currentScene,
    initAudio 
  } = useGameStore();

  // Initialize audio context on first user interaction
  React.useEffect(() => {
    const handleUserInteraction = () => {
      initAudio();
      document.removeEventListener('click', handleUserInteraction);
      document.removeEventListener('keydown', handleUserInteraction);
    };

    document.addEventListener('click', handleUserInteraction);
    document.addEventListener('keydown', handleUserInteraction);

    return () => {
      document.removeEventListener('click', handleUserInteraction);
      document.removeEventListener('keydown', handleUserInteraction);
    };
  }, [initAudio]);

  return (
    <div className="app">
      {/* Background Canvas for 3D elements */}
      <div className="canvas-container">
        <Canvas
          camera={{ 
            position: [0, 0, 8], 
            fov: 75 
          }}
          dpr={[1, 2]}
          gl={{ 
            antialias: true,
            alpha: true,
            powerPreference: 'high-performance'
          }}
        >
          <ambientLight intensity={0.4} />
          <pointLight position={[10, 10, 10]} intensity={1} />
          <pointLight position={[-10, -10, -10]} intensity={0.5} color="#4ECDC4" />
          
          {/* 3D Game Scene */}
          {gameState.isPlaying && <GameScreen />}
        </Canvas>
      </div>

      {/* UI Overlays */}
      <div className="ui-overlay">
        {/* Story/Menu Screen */}
        {showStory && (
          <StoryScreen scene={currentScene} />
        )}

        {/* Settings Panel */}
        {showSettings && (
          <SettingsPanel />
        )}

        {/* Game HUD */}
        {gameState.isPlaying && !showStory && !showSettings && (
          <div className="game-hud">
            <div className="score-display">
              <div className="player-score player1">
                <h3>Player 1</h3>
                <div className="score">{gameState.score.player1.toLocaleString()}</div>
                <div className="combo">Combo: {gameState.combo.player1}</div>
                <div className="accuracy">Accuracy: {gameState.accuracy.player1.toFixed(1)}%</div>
              </div>
              
              <div className="song-info">
                <h2>{gameState.currentSong?.title || 'Tuki Tuki'}</h2>
                <p>{gameState.currentSong?.artist || 'Venezuelan Rhythm'}</p>
                <div className="difficulty">{gameState.difficulty.toUpperCase()}</div>
              </div>
              
              <div className="player-score player2">
                <h3>Player 2</h3>
                <div className="score">{gameState.score.player2.toLocaleString()}</div>
                <div className="combo">Combo: {gameState.combo.player2}</div>
                <div className="accuracy">Accuracy: {gameState.accuracy.player2.toFixed(1)}%</div>
              </div>
            </div>
          </div>
        )}

        {/* Venezuelan flag accent */}
        <div className="venezuelan-accent">
          <div className="flag-stripe yellow"></div>
          <div className="flag-stripe blue"></div>
          <div className="flag-stripe red"></div>
        </div>
      </div>
      
      {/* Audio element for background music */}
      <audio id="background-audio" loop />
    </div>
  );
}

export default App;
