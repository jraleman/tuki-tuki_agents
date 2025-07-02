import { create } from 'zustand';
import { GameState, PlayerConfig, Song, Arrow, HitData, HitResult, GameSettings } from '../types/GameTypes';

// Default player configurations
const defaultPlayer1: PlayerConfig = {
  id: 'player1',
  name: 'Player 1',
  keys: {
    left: 'a',
    down: 's',
    up: 'w',
    right: 'd'
  },
  color: '#FF6B6B',
  position: 'left'
};

const defaultPlayer2: PlayerConfig = {
  id: 'player2',
  name: 'Player 2',
  keys: {
    left: 'ArrowLeft',
    down: 'ArrowDown',
    up: 'ArrowUp',
    right: 'ArrowRight'
  },
  color: '#4ECDC4',
  position: 'right'
};

// Default game settings
const defaultSettings: GameSettings = {
  scrollSpeed: 1.0,
  audioOffset: 0,
  soundEffects: true,
  backgroundEffects: true,
  player1Keys: defaultPlayer1.keys,
  player2Keys: defaultPlayer2.keys
};

interface GameStore {
  // Game state
  gameState: GameState;
  players: [PlayerConfig, PlayerConfig];
  arrows: Arrow[];
  settings: GameSettings;
  
  // UI state
  currentScene: string;
  showStory: boolean;
  showSettings: boolean;
  isMultiplayer: boolean;
  
  // Audio state
  audioContext: AudioContext | null;
  currentAudio: HTMLAudioElement | null;
  
  // Hit tracking for character animations
  lastHit: { [key: string]: { direction: string; time: number } };
  
  // Actions
  setGameState: (state: Partial<GameState>) => void;
  setCurrentScene: (scene: string) => void;
  setMultiplayer: (enabled: boolean) => void;
  setPlayer: (playerIndex: 0 | 1, config: Partial<PlayerConfig>) => void;
  setSettings: (settings: Partial<GameSettings>) => void;
  
  // Game actions
  startGame: (song: Song, isMultiplayer: boolean) => void;
  pauseGame: () => void;
  resumeGame: () => void;
  stopGame: () => void;
  
  // Arrow management
  addArrow: (arrow: Arrow) => void;
  updateArrows: (deltaTime: number) => void;
  removeArrow: (arrowId: string) => void;
  generateArrows: (song: Song, isMultiplayer: boolean) => void;
  
  // Hit detection and scoring
  registerHit: (player: 'player1' | 'player2', direction: string, time: number) => HitResult;
  updateScore: (hitData: HitData) => void;
  
  // Audio management
  initAudio: () => void;
  playAudio: (audioFile: string) => void;
  stopAudio: () => void;
  
  // Story mode
  toggleStory: () => void;
  toggleSettings: () => void;
  
  // Debug functions
  testStartGame: () => void;
}

export const useGameStore = create<GameStore>((set, get) => ({
  // Initial state
  gameState: {
    isPlaying: false,
    isPaused: false,
    currentTime: 0,
    score: { player1: 0, player2: 0 },
    combo: { player1: 0, player2: 0 },
    accuracy: { player1: 100, player2: 100 },
    difficulty: 'standard',
    gameMode: 'story'
  },
  
  players: [defaultPlayer1, defaultPlayer2],
  arrows: [],
  settings: defaultSettings,
  
  currentScene: 'opening',
  showStory: true,
  showSettings: false,
  isMultiplayer: false,
  
  audioContext: null,
  currentAudio: null,
  lastHit: {},
  
  // Actions
  setGameState: (state) => set((prev) => ({
    gameState: { ...prev.gameState, ...state }
  })),
  
  setCurrentScene: (scene) => set({ currentScene: scene }),
  
  setMultiplayer: (enabled) => set({ isMultiplayer: enabled }),
  
  setPlayer: (playerIndex, config) => set((prev) => {
    const newPlayers = [...prev.players] as [PlayerConfig, PlayerConfig];
    newPlayers[playerIndex] = { ...newPlayers[playerIndex], ...config };
    return { players: newPlayers };
  }),
  
  setSettings: (newSettings) => set((prev) => ({
    settings: { ...prev.settings, ...newSettings }
  })),
  
  // Game actions
  startGame: (song, isMultiplayer) => {
    console.log('Starting game with song:', song.title);
    set((prev) => ({
      gameState: {
        ...prev.gameState,
        isPlaying: true,
        isPaused: false,
        currentTime: 0,
        currentSong: song,
        gameMode: isMultiplayer ? 'multiplayer' : 'story',
        score: { player1: 0, player2: 0 },
        combo: { player1: 0, player2: 0 },
        accuracy: { player1: 100, player2: 100 }
      },
      isMultiplayer,
      arrows: [],
      showStory: false
    }));
    
    // Start generating arrows
    console.log('Generating arrows...');
    get().generateArrows(song, isMultiplayer);
  },
  
  pauseGame: () => set((prev) => ({
    gameState: { ...prev.gameState, isPaused: true }
  })),
  
  resumeGame: () => set((prev) => ({
    gameState: { ...prev.gameState, isPaused: false }
  })),
  
  stopGame: () => set((prev) => ({
    gameState: {
      ...prev.gameState,
      isPlaying: false,
      isPaused: false,
      currentTime: 0
    },
    arrows: []
  })),
  
  // Arrow management
  addArrow: (arrow) => set((prev) => ({
    arrows: [...prev.arrows, arrow]
  })),
  
  updateArrows: (deltaTime) => set((prev) => {
    const { settings } = prev;
    const updatedArrows = prev.arrows
      .map(arrow => ({
        ...arrow,
        position: [
          arrow.position[0],
          arrow.position[1],
          // Arrows move from bottom (negative Z) to top (positive Z)
          arrow.position[2] + (settings.scrollSpeed * deltaTime * 0.01)
        ] as [number, number, number]
      }))
      // Remove arrows that have passed the hit zone (positive Z beyond hit zone)
      .filter(arrow => arrow.position[2] < 3 && !arrow.hit && !arrow.missed);
    
    return { arrows: updatedArrows };
  }),
  
  removeArrow: (arrowId) => set((prev) => ({
    arrows: prev.arrows.filter(arrow => arrow.id !== arrowId)
  })),
  
  generateArrows: (song, isMultiplayer) => {
    const directions: Array<'left' | 'down' | 'up' | 'right'> = ['left', 'down', 'up', 'right'];
    const players: Array<'player1' | 'player2'> = isMultiplayer ? ['player1', 'player2'] : ['player1'];
    
    // Generate a simple pattern for demonstration
    const generatePattern = () => {
      const pattern: Arrow[] = [];
      const duration = song.duration * 1000 || 30000; // Convert to milliseconds
      const beatInterval = (60 / (song.bpm || 120)) * 1000; // milliseconds per beat
      
      // Generate arrows every beat
      for (let time = 0; time < duration; time += beatInterval) {
        players.forEach(player => {
          // Generate random arrows with high probability for testing
          if (Math.random() > 0.2) { // 80% chance to generate an arrow
            const direction = directions[Math.floor(Math.random() * directions.length)];
            const arrow: Arrow = {
              id: `${player}-${time}-${direction}-${Math.random()}`,
              direction,
              time,
              lane: directions.indexOf(direction),
              player,
              position: [0, 0, -15], // Start further back for longer travel time
              speed: 1,
              hit: false,
              missed: false
            };
            pattern.push(arrow);
          }
        });
      }
      
      return pattern.sort((a, b) => a.time - b.time); // Sort by time
    };
    
    const allArrows = generatePattern();
    console.log(`Generated ${allArrows.length} arrows for song: ${song.title}`);
    
    // Start spawning arrows immediately and continuously
    let arrowIndex = 0;
    const spawnArrows = () => {
      const { gameState } = get();
      if (!gameState.isPlaying) return;
      
      const currentTime = gameState.currentTime;
      const lookAheadTime = 4000; // 4 seconds ahead
      
      // Add arrows that should spawn now
      while (arrowIndex < allArrows.length && allArrows[arrowIndex].time <= currentTime + lookAheadTime) {
        const arrow = { ...allArrows[arrowIndex] };
        get().addArrow(arrow);
        arrowIndex++;
      }
      
      if (gameState.isPlaying && arrowIndex < allArrows.length) {
        setTimeout(spawnArrows, 100); // Check every 100ms
      }
    };
    
    // Start spawning immediately
    setTimeout(spawnArrows, 100);
  },
  
  // Hit detection and scoring
  registerHit: (player, direction, _time) => {
    const { arrows } = get();
    const playerArrows = arrows.filter(arrow => 
      arrow.player === player && 
      arrow.direction === direction as any && 
      !arrow.hit && 
      !arrow.missed &&
      // Hit zone is at Z=2, arrows move from negative to positive Z
      arrow.position[2] >= 1 && arrow.position[2] <= 3
    );
    
    if (playerArrows.length === 0) return 'MISS';
    
    // Find closest arrow to the hit zone (Z=2)
    const hitZoneZ = 2;
    const closestArrow = playerArrows.reduce((closest, current) => 
      Math.abs(current.position[2] - hitZoneZ) < Math.abs(closest.position[2] - hitZoneZ) ? current : closest
    );
    
    const timeDiff = Math.abs(closestArrow.position[2] - hitZoneZ);
    let result: HitResult = 'MISS';
    
    if (timeDiff <= 0.3) result = 'PERFECT';
    else if (timeDiff <= 0.6) result = 'GREAT';
    else if (timeDiff <= 1.0) result = 'GOOD';
    else result = 'MISS';
    
    // Mark arrow as hit and track hit for character animation
    set((prev) => ({
      arrows: prev.arrows.map(arrow => 
        arrow.id === closestArrow.id ? { ...arrow, hit: true } : arrow
      ),
      lastHit: {
        ...prev.lastHit,
        [player]: {
          direction: direction,
          time: Date.now()
        }
      }
    }));
    
    // Update score
    const hitData: HitData = {
      result,
      timeDiff,
      arrow: closestArrow,
      player
    };
    
    get().updateScore(hitData);
    
    return result;
  },
  
  updateScore: (hitData) => set((prev) => {
    const { result, player } = hitData;
    const scoreValues = {
      'PERFECT': 100,
      'GREAT': 80,
      'GOOD': 50,
      'MISS': 0
    };
    
    const newCombo = result === 'MISS' ? 0 : prev.gameState.combo[player] + 1;
    const comboMultiplier = Math.min(newCombo / 10, 3);
    const points = scoreValues[result] * (1 + comboMultiplier);
    
    return {
      gameState: {
        ...prev.gameState,
        score: {
          ...prev.gameState.score,
          [player]: prev.gameState.score[player] + points
        },
        combo: {
          ...prev.gameState.combo,
          [player]: newCombo
        }
      }
    };
  }),
  
  // Audio management
  initAudio: () => {
    if (typeof window !== 'undefined' && !get().audioContext) {
      const context = new (window.AudioContext || (window as any).webkitAudioContext)();
      set({ audioContext: context });
    }
  },
  
  playAudio: (audioFile) => {
    const { currentAudio } = get();
    if (currentAudio) {
      currentAudio.pause();
      currentAudio.currentTime = 0;
    }
    
    const audio = new Audio(audioFile);
    audio.play().catch(console.error);
    set({ currentAudio: audio });
  },
  
  stopAudio: () => {
    const { currentAudio } = get();
    if (currentAudio) {
      currentAudio.pause();
      currentAudio.currentTime = 0;
      set({ currentAudio: null });
    }
  },
  
  // UI actions
  toggleStory: () => set((prev) => ({ showStory: !prev.showStory })),
  toggleSettings: () => set((prev) => ({ showSettings: !prev.showSettings })),
  
  // Debug functions
  testStartGame: () => {
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
    console.log('Test starting game...');
    get().startGame(testSong, false);
  }
}));

// Make store available globally for debugging
if (typeof window !== 'undefined') {
  (window as any).gameStore = useGameStore;
}
