import React from 'react';
import { motion } from 'framer-motion';
import { useGameStore } from '../../store/gameStore';

const SettingsPanel: React.FC = () => {
  const { 
    settings, 
    setSettings, 
    players, 
    setPlayer, 
    toggleSettings 
  } = useGameStore();

  const handleScrollSpeedChange = (value: number) => {
    setSettings({ scrollSpeed: value });
  };

  const handleAudioOffsetChange = (value: number) => {
    setSettings({ audioOffset: value });
  };

  const handleKeyBinding = (playerIndex: 0 | 1, direction: string, key: string) => {
    const newKeys = { ...players[playerIndex].keys, [direction]: key };
    setPlayer(playerIndex, { keys: newKeys });
    setSettings(playerIndex === 0 ? { player1Keys: newKeys } : { player2Keys: newKeys });
  };

  const resetToDefaults = () => {
    setSettings({
      scrollSpeed: 1.0,
      audioOffset: 0,
      soundEffects: true,
      backgroundEffects: true,
      player1Keys: {
        left: 'a',
        down: 's',
        up: 'w',
        right: 'd'
      },
      player2Keys: {
        left: 'ArrowLeft',
        down: 'ArrowDown',
        up: 'ArrowUp',
        right: 'ArrowRight'
      }
    });
    
    // Reset player keys
    setPlayer(0, {
      keys: {
        left: 'a',
        down: 's',
        up: 'w',
        right: 'd'
      }
    });
    
    setPlayer(1, {
      keys: {
        left: 'ArrowLeft',
        down: 'ArrowDown',
        up: 'ArrowUp',
        right: 'ArrowRight'
      }
    });
  };

  return (
    <motion.div
      className="settings-panel"
      initial={{ opacity: 0, scale: 0.8 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.8 }}
      transition={{ duration: 0.3 }}
    >
      <div className="settings-header">
        <h2 className="settings-title">Game Settings</h2>
        <button
          className="close-button"
          onClick={toggleSettings}
          style={{
            position: 'absolute',
            top: '15px',
            right: '15px',
            background: 'none',
            border: 'none',
            color: 'white',
            fontSize: '1.5rem',
            cursor: 'pointer'
          }}
        >
          ×
        </button>
      </div>

      <div className="settings-content">
        {/* Game Settings */}
        <div className="setting-section">
          <h3 className="section-title">Gameplay</h3>
          
          <div className="setting-group">
            <label className="setting-label">
              Arrow Scroll Speed: {settings.scrollSpeed.toFixed(1)}x
            </label>
            <input
              type="range"
              min="0.5"
              max="3.0"
              step="0.1"
              value={settings.scrollSpeed}
              onChange={(e) => handleScrollSpeedChange(parseFloat(e.target.value))}
              className="setting-slider"
            />
          </div>

          <div className="setting-group">
            <label className="setting-label">
              Audio Offset: {settings.audioOffset}ms
            </label>
            <input
              type="range"
              min="-200"
              max="200"
              step="10"
              value={settings.audioOffset}
              onChange={(e) => handleAudioOffsetChange(parseInt(e.target.value))}
              className="setting-slider"
            />
            <small style={{ opacity: 0.7, fontSize: '0.8rem' }}>
              Adjust if arrows don't sync with music
            </small>
          </div>

          <div className="setting-group">
            <label className="setting-checkbox">
              <input
                type="checkbox"
                checked={settings.soundEffects}
                onChange={(e) => setSettings({ soundEffects: e.target.checked })}
              />
              Sound Effects
            </label>
          </div>

          <div className="setting-group">
            <label className="setting-checkbox">
              <input
                type="checkbox"
                checked={settings.backgroundEffects}
                onChange={(e) => setSettings({ backgroundEffects: e.target.checked })}
              />
              Background Effects
            </label>
          </div>
        </div>

        {/* Player 1 Controls */}
        <div className="setting-section">
          <h3 className="section-title" style={{ color: 'var(--neon-pink)' }}>
            Player 1 Controls (WASD)
          </h3>
          
          <div className="key-bindings">
            {Object.entries(players[0].keys).map(([direction, key]) => (
              <div key={direction} className="key-binding">
                <label className="key-label">{direction.toUpperCase()}:</label>
                <input
                  type="text"
                  value={key}
                  onChange={(e) => handleKeyBinding(0, direction, e.target.value)}
                  className="key-input"
                  maxLength={1}
                />
              </div>
            ))}
          </div>
        </div>

        {/* Player 2 Controls */}
        <div className="setting-section">
          <h3 className="section-title" style={{ color: 'var(--neon-blue)' }}>
            Player 2 Controls (Arrow Keys)
          </h3>
          
          <div className="key-bindings">
            {Object.entries(players[1].keys).map(([direction, key]) => (
              <div key={direction} className="key-binding">
                <label className="key-label">{direction.toUpperCase()}:</label>
                <input
                  type="text"
                  value={key.replace('Arrow', '')}
                  readOnly
                  className="key-input readonly"
                  title="Use arrow keys for Player 2"
                />
              </div>
            ))}
          </div>
        </div>

        {/* Venezuelan Cultural Info */}
        <div className="setting-section cultural-info">
          <h3 className="section-title" style={{ color: 'var(--venezuela-yellow)' }}>
            About Venezuelan Tuki
          </h3>
          <p style={{ fontSize: '0.9rem', lineHeight: '1.4', opacity: 0.8 }}>
            Tuki is a Venezuelan electronic music genre that emerged in the late 1990s. 
            Characterized by its high BPM (often 180+), it represents the urban culture 
            of Venezuelan barrios. This game celebrates the rhythm, energy, and cultural 
            significance of Tuki music.
          </p>
        </div>

        {/* Action Buttons */}
        <div className="settings-actions">
          <button
            className="settings-button secondary"
            onClick={resetToDefaults}
          >
            Reset to Defaults
          </button>
          <button
            className="settings-button primary"
            onClick={toggleSettings}
          >
            Apply Settings
          </button>
        </div>
      </div>

      <style>{`
        .settings-header {
          position: relative;
          margin-bottom: 30px;
        }

        .setting-section {
          margin-bottom: 30px;
          padding-bottom: 20px;
          border-bottom: 1px solid rgba(255, 255, 255, 0.1);
        }

        .setting-section:last-child {
          border-bottom: none;
        }

        .section-title {
          font-size: 1.3rem;
          margin-bottom: 15px;
          color: var(--neon-purple);
          text-shadow: 0 0 10px rgba(168, 230, 207, 0.3);
        }

        .setting-slider {
          width: 100%;
          height: 6px;
          border-radius: 3px;
          background: rgba(255, 255, 255, 0.2);
          outline: none;
          margin-top: 5px;
        }

        .setting-slider::-webkit-slider-thumb {
          appearance: none;
          width: 20px;
          height: 20px;
          border-radius: 50%;
          background: var(--neon-purple);
          cursor: pointer;
          box-shadow: 0 0 10px rgba(168, 230, 207, 0.5);
        }

        .setting-checkbox {
          display: flex;
          align-items: center;
          gap: 10px;
          cursor: pointer;
          font-size: 1rem;
        }

        .setting-checkbox input[type="checkbox"] {
          width: 18px;
          height: 18px;
          accent-color: var(--neon-purple);
        }

        .key-bindings {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
          gap: 15px;
        }

        .key-binding {
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 5px;
        }

        .key-label {
          font-size: 0.9rem;
          font-weight: bold;
          text-transform: uppercase;
          letter-spacing: 1px;
        }

        .key-input {
          width: 50px;
          height: 50px;
          text-align: center;
          font-size: 1.2rem;
          font-weight: bold;
          border: 2px solid var(--neon-purple);
          border-radius: 10px;
          background: rgba(0, 0, 0, 0.5);
          color: white;
          text-transform: uppercase;
        }

        .key-input.readonly {
          border-color: rgba(255, 255, 255, 0.3);
          opacity: 0.7;
          cursor: not-allowed;
        }

        .key-input:focus {
          outline: none;
          box-shadow: 0 0 15px rgba(168, 230, 207, 0.4);
        }

        .cultural-info {
          background: rgba(252, 221, 9, 0.1);
          padding: 20px;
          border-radius: 15px;
          border: 1px solid var(--venezuela-yellow);
        }

        .settings-actions {
          display: flex;
          gap: 15px;
          justify-content: center;
          margin-top: 30px;
        }

        .settings-button {
          padding: 12px 25px;
          border: none;
          border-radius: 25px;
          font-weight: bold;
          font-size: 1rem;
          cursor: pointer;
          transition: all 0.3s ease;
          text-transform: uppercase;
          letter-spacing: 1px;
        }

        .settings-button.primary {
          background: linear-gradient(45deg, var(--neon-pink), var(--neon-blue));
          color: white;
        }

        .settings-button.secondary {
          background: transparent;
          color: var(--neon-purple);
          border: 2px solid var(--neon-purple);
        }

        .settings-button:hover {
          transform: translateY(-2px);
          box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
        }

        .settings-button:active {
          transform: translateY(0);
        }
      `}</style>
    </motion.div>
  );
};

export default SettingsPanel;
