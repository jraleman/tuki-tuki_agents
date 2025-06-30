import React, { useEffect, useCallback } from 'react';
import { useGameStore } from '../../store/gameStore';

const InputHandler: React.FC = () => {
  const { 
    gameState, 
    players, 
    isMultiplayer, 
    registerHit 
  } = useGameStore();

  const handleKeyPress = useCallback((event: KeyboardEvent) => {
    if (!gameState.isPlaying || gameState.isPaused) return;

    const key = event.key.toLowerCase();
    
    // Prevent default to avoid browser shortcuts
    event.preventDefault();
    
    // Player 1 controls (WASD)
    const player1Keys = players[0].keys;
    if (key === player1Keys.left.toLowerCase()) {
      registerHit('player1', 'left', performance.now());
    } else if (key === player1Keys.down.toLowerCase()) {
      registerHit('player1', 'down', performance.now());
    } else if (key === player1Keys.up.toLowerCase()) {
      registerHit('player1', 'up', performance.now());
    } else if (key === player1Keys.right.toLowerCase()) {
      registerHit('player1', 'right', performance.now());
    }

    // Player 2 controls (Arrow keys) - only in multiplayer
    if (isMultiplayer) {
      const player2Keys = players[1].keys;
      if (event.key === player2Keys.left) {
        registerHit('player2', 'left', performance.now());
      } else if (event.key === player2Keys.down) {
        registerHit('player2', 'down', performance.now());
      } else if (event.key === player2Keys.up) {
        registerHit('player2', 'up', performance.now());
      } else if (event.key === player2Keys.right) {
        registerHit('player2', 'right', performance.now());
      }
    }

    // Pause game with Escape
    if (event.key === 'Escape') {
      if (gameState.isPaused) {
        useGameStore.getState().resumeGame();
      } else {
        useGameStore.getState().pauseGame();
      }
    }

    // Settings with F1
    if (event.key === 'F1') {
      useGameStore.getState().toggleSettings();
    }
  }, [gameState.isPlaying, gameState.isPaused, players, isMultiplayer, registerHit]);

  useEffect(() => {
    window.addEventListener('keydown', handleKeyPress);
    
    return () => {
      window.removeEventListener('keydown', handleKeyPress);
    };
  }, [handleKeyPress]);

  // Show key bindings hint
  const showKeyHints = !gameState.isPlaying;

  return (
    <>
      {showKeyHints && (
        <div className="key-hints">
          <div className="key-hint-section player1">
            <h3>Player 1</h3>
            <div className="key-grid">
              <div className="key-hint">{players[0].keys.up.toUpperCase()}</div>
              <div className="key-hint">{players[0].keys.left.toUpperCase()}</div>
              <div className="key-hint">{players[0].keys.down.toUpperCase()}</div>
              <div className="key-hint">{players[0].keys.right.toUpperCase()}</div>
            </div>
          </div>
          
          {isMultiplayer && (
            <div className="key-hint-section player2">
              <h3>Player 2</h3>
              <div className="key-grid">
                <div className="key-hint">↑</div>
                <div className="key-hint">←</div>
                <div className="key-hint">↓</div>
                <div className="key-hint">→</div>
              </div>
            </div>
          )}
        </div>
      )}

      <style>{`
        .key-hints {
          position: fixed;
          bottom: 40px;
          left: 50%;
          transform: translateX(-50%);
          display: flex;
          gap: 60px;
          z-index: 100;
          pointer-events: none;
        }

        .key-hint-section {
          text-align: center;
        }

        .key-hint-section h3 {
          margin-bottom: 15px;
          font-size: 1.2rem;
          text-shadow: 0 0 10px rgba(255, 255, 255, 0.5);
        }

        .key-hint-section.player1 h3 {
          color: var(--neon-pink);
        }

        .key-hint-section.player2 h3 {
          color: var(--neon-blue);
        }

        .key-grid {
          display: grid;
          grid-template-columns: repeat(2, 1fr);
          grid-template-rows: repeat(2, 1fr);
          gap: 10px;
          width: 120px;
          height: 120px;
        }

        .key-hint {
          background: rgba(0, 0, 0, 0.7);
          border: 2px solid;
          border-radius: 10px;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: bold;
          font-size: 1.1rem;
          backdrop-filter: blur(5px);
          transition: all 0.3s ease;
        }

        .player1 .key-hint {
          border-color: var(--neon-pink);
          color: var(--neon-pink);
          box-shadow: 0 0 15px rgba(255, 107, 107, 0.3);
        }

        .player2 .key-hint {
          border-color: var(--neon-blue);
          color: var(--neon-blue);
          box-shadow: 0 0 15px rgba(78, 205, 196, 0.3);
        }

        .key-hint:nth-child(1) {
          grid-column: 2;
          grid-row: 1;
        }

        .key-hint:nth-child(2) {
          grid-column: 1;
          grid-row: 2;
        }

        .key-hint:nth-child(3) {
          grid-column: 2;
          grid-row: 2;
        }

        .key-hint:nth-child(4) {
          grid-column: 3;
          grid-row: 2;
        }

        @media (max-width: 768px) {
          .key-hints {
            flex-direction: column;
            gap: 30px;
            bottom: 20px;
          }
          
          .key-grid {
            width: 100px;
            height: 100px;
          }
          
          .key-hint {
            font-size: 0.9rem;
          }
        }
      `}</style>
    </>
  );
};

export default InputHandler;
