import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useGameStore } from '../../store/gameStore';
import { storyScenes } from '../../data/story';

interface StoryScreenProps {
  scene: string;
}

const StoryScreen: React.FC<StoryScreenProps> = ({ scene }) => {
  const { 
    setCurrentScene, 
    setMultiplayer, 
    toggleStory, 
    toggleSettings,
    playAudio,
    startGame
  } = useGameStore();
  
  const [currentDialogueIndex, setCurrentDialogueIndex] = useState(0);
  const [isTyping, setIsTyping] = useState(false);
  const [displayedText, setDisplayedText] = useState('');
  
  const currentScene = storyScenes.find(s => s.id === scene);

  // Typewriter effect for dialogue
  useEffect(() => {
    if (!currentScene?.dialogue[currentDialogueIndex]) return;
    
    const fullText = currentScene.dialogue[currentDialogueIndex].text;
    setIsTyping(true);
    setDisplayedText('');
    
    let index = 0;
    const interval = setInterval(() => {
      if (index < fullText.length) {
        setDisplayedText(fullText.slice(0, index + 1));
        index++;
      } else {
        setIsTyping(false);
        clearInterval(interval);
      }
    }, 30);
    
    return () => clearInterval(interval);
  }, [currentDialogueIndex, currentScene]);

  // Play background music when scene changes
  useEffect(() => {
    if (currentScene?.backgroundMusic) {
      playAudio(currentScene.backgroundMusic);
    }
  }, [scene, currentScene, playAudio]);

  const handleNextDialogue = () => {
    if (isTyping) {
      // Skip to end of current dialogue
      setDisplayedText(currentScene!.dialogue[currentDialogueIndex].text);
      setIsTyping(false);
      return;
    }
    
    if (currentDialogueIndex < (currentScene?.dialogue.length || 0) - 1) {
      setCurrentDialogueIndex(currentDialogueIndex + 1);
    }
  };

  const handleChoice = (nextScene: string) => {
    setCurrentDialogueIndex(0);
    
    if (nextScene === 'multiplayer_setup') {
      setMultiplayer(true);
      toggleStory();
    } else if (nextScene === 'practice_mode') {
      setMultiplayer(false);
      toggleStory();
    } else if (nextScene === 'settings') {
      toggleSettings();
    } else {
      setCurrentScene(nextScene);
    }
  };

  const isDialogueComplete = currentDialogueIndex >= (currentScene?.dialogue.length || 0) - 1 && !isTyping;

  if (!currentScene) {
    return (
      <div className="story-screen">
        <div className="story-content">
          <h1 className="story-title">Scene not found</h1>
          <button 
            className="story-button"
            onClick={() => setCurrentScene('opening')}
          >
            Return to Opening
          </button>
        </div>
      </div>
    );
  }

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
          {currentScene.title}
        </motion.h1>
        
        <motion.p 
          className="story-text"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.4, duration: 0.6 }}
        >
          {currentScene.description}
        </motion.p>

        {/* Dialogue System */}
        {currentScene.dialogue.length > 0 && (
          <div className="dialogue-container">
            <AnimatePresence mode="wait">
              <motion.div
                key={currentDialogueIndex}
                className="dialogue-line"
                initial={{ opacity: 0, x: -50 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 50 }}
                transition={{ duration: 0.5 }}
                onClick={handleNextDialogue}
                style={{ cursor: 'pointer' }}
              >
                <div className="dialogue-character">
                  {currentScene.dialogue[currentDialogueIndex].character}
                </div>
                <div className="dialogue-text">
                  {displayedText}
                  {isTyping && <span className="typing-cursor">|</span>}
                </div>
              </motion.div>
            </AnimatePresence>
            
            {!isDialogueComplete && (
              <motion.p
                className="continue-hint"
                style={{ 
                  textAlign: 'center', 
                  opacity: 0.6, 
                  fontSize: '0.8rem', 
                  marginTop: '10px' 
                }}
                animate={{ opacity: [0.6, 1, 0.6] }}
                transition={{ duration: 2, repeat: Infinity }}
              >
                Click to continue...
              </motion.p>
            )}
          </div>
        )}

        {/* Choices */}
        {isDialogueComplete && currentScene.choices && (
          <motion.div 
            className="story-choices"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.5, duration: 0.6 }}
          >
            {currentScene.choices.map((choice, index) => (
              <motion.button
                key={index}
                className="story-button pulse"
                onClick={() => handleChoice(choice.nextScene)}
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.7 + index * 0.1, duration: 0.4 }}
              >
                {choice.text}
              </motion.button>
            ))}
          </motion.div>
        )}

        {/* Special scene: Character selection */}
        {scene === 'character_selection' && isDialogueComplete && (
          <motion.div
            className="character-grid"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 1, duration: 0.6 }}
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
              gap: '20px',
              marginTop: '30px'
            }}
          >
            {/* Character cards would go here */}
            <div className="character-card" style={{
              background: 'rgba(255, 107, 107, 0.2)',
              border: '2px solid var(--neon-pink)',
              borderRadius: '15px',
              padding: '20px',
              textAlign: 'center',
              cursor: 'pointer'
            }}>
              <h3>María La Caraqueña</h3>
              <p>Petare, Caracas</p>
              <small>Tuki Clásico</small>
            </div>
            <div className="character-card" style={{
              background: 'rgba(78, 205, 196, 0.2)',
              border: '2px solid var(--neon-blue)',
              borderRadius: '15px',
              padding: '20px',
              textAlign: 'center',
              cursor: 'pointer'
            }}>
              <h3>Carlos El Zuliano</h3>
              <p>Maracaibo, Zulia</p>
              <small>Tuki Rápido</small>
            </div>
          </motion.div>
        )}

        {/* Venezuelan cultural elements */}
        <div className="cultural-elements" style={{
          position: 'absolute',
          bottom: '20px',
          left: '20px',
          right: '20px',
          textAlign: 'center',
          opacity: 0.6,
          fontSize: '0.8rem'
        }}>
          <p>🇻🇪 Celebrating Venezuelan Culture Through Rhythm 🇻🇪</p>
        </div>
      </motion.div>

      {/* Skip button and Game Start */}
      <div style={{
        position: 'absolute',
        top: '20px',
        right: '20px',
        display: 'flex',
        gap: '10px'
      }}>
        <motion.button
          className="start-game-button"
          style={{
            background: 'rgba(255, 107, 107, 0.8)',
            border: '1px solid #FF6B6B',
            color: 'white',
            padding: '10px 20px',
            borderRadius: '20px',
            cursor: 'pointer'
          }}
          onClick={() => {
            const testSong = {
              id: 'test_song',
              title: 'Test Tuki',
              artist: 'Test Artist',
              genre: 'Tuki Test',
              bpm: 120,
              duration: 30,
              audioFile: '/music/test.mp3',
              difficulties: {
                standard: {
                  difficulty: 'standard' as const,
                  level: 1,
                  totalNotes: 20,
                  arrows: []
                }
              }
            };
            startGame(testSong, false);
          }}
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
        >
          🎮 Start Game
        </motion.button>
        
        <motion.button
          className="skip-button"
          style={{
            background: 'rgba(0, 0, 0, 0.5)',
            border: '1px solid white',
            color: 'white',
            padding: '10px 20px',
            borderRadius: '20px',
            cursor: 'pointer'
          }}
          onClick={toggleStory}
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
        >
          Skip Story
        </motion.button>
      </div>

      <style>{`
        .typing-cursor {
          animation: blink 1s infinite;
        }
        
        @keyframes blink {
          0%, 50% { opacity: 1; }
          51%, 100% { opacity: 0; }
        }
        
        .character-card {
          transition: all 0.3s ease;
        }
        
        .character-card:hover {
          transform: translateY(-5px);
          box-shadow: 0 10px 25px rgba(0, 0, 0, 0.3);
        }
      `}</style>
    </div>
  );
};

export default StoryScreen;
