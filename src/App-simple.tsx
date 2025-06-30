import React from 'react';
import './App.css';

// Simple test version to debug
function App() {
  return (
    <div className="app">
      <div className="ui-overlay">
        <div className="story-screen">
          <div className="story-content">
            <h1 className="story-title glow">
              🇻🇪 TUKI TUKI 🇻🇪
            </h1>
            
            <p className="story-text">
              ¡Bienvenidos! Welcome to the Venezuelan Rhythm Revolution!
            </p>

            <div className="story-text">
              In the vibrant barrios of Venezuela, where music flows through concrete veins 
              and rhythm pulses in every heartbeat, a legendary competition emerges...
            </div>

            <div className="story-choices" style={{ marginTop: '30px' }}>
              <button 
                className="story-button pulse"
                onClick={() => alert('Multiplayer mode coming soon!')}
              >
                🎮 Start Multiplayer Battle
              </button>
              
              <button 
                className="story-button pulse"
                onClick={() => alert('Practice mode coming soon!')}
              >
                🎵 Practice Mode
              </button>
              
              <button 
                className="story-button pulse"
                onClick={() => alert('Learn about Venezuelan Tuki culture!')}
              >
                📖 Learn About Tuki
              </button>
            </div>

            <div style={{ 
              marginTop: '40px', 
              fontSize: '0.9rem', 
              opacity: 0.8,
              textAlign: 'center' 
            }}>
              <p><strong>Controls:</strong></p>
              <p>👥 Player 1: WASD keys | Player 2: Arrow keys</p>
              <p>🎹 ESC: Pause | F1: Settings</p>
            </div>

            <div className="cultural-elements" style={{
              marginTop: '30px',
              textAlign: 'center',
              opacity: 0.7,
              fontSize: '0.8rem'
            }}>
              <p>🎵 Celebrating Venezuelan Tuki Music Culture 🎵</p>
              <p>From Petare to Maracaibo, from Valencia to Barquisimeto</p>
            </div>
          </div>
        </div>

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
