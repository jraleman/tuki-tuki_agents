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
  startGame: (song, isMultiplayer) => set((prev) => ({
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
  })),
  
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
          arrow.position[2] + (settings.scrollSpeed * deltaTime * 0.01)
        ] as [number, number, number]
      }))
      .filter(arrow => arrow.position[2] < 10 && !arrow.hit && !arrow.missed);
    
    return { arrows: updatedArrows };
  }),
  
  removeArrow: (arrowId) => set((prev) => ({
    arrows: prev.arrows.filter(arrow => arrow.id !== arrowId)
  })),
  
  // Hit detection and scoring
  registerHit: (player, direction, _time) => {
    const { arrows } = get();
    const playerArrows = arrows.filter(arrow => 
      arrow.player === player && 
      arrow.direction === direction as any && 
      !arrow.hit && 
      !arrow.missed &&
      Math.abs(arrow.position[2]) < 2 // Hit zone
    );
    
    if (playerArrows.length === 0) return 'MISS';
    
    // Find closest arrow
    const closestArrow = playerArrows.reduce((closest, current) => 
      Math.abs(current.position[2]) < Math.abs(closest.position[2]) ? current : closest
    );
    
    const timeDiff = Math.abs(closestArrow.position[2]);
    let result: HitResult = 'MISS';
    
    if (timeDiff <= 0.3) result = 'PERFECT';
    else if (timeDiff <= 0.6) result = 'GREAT';
    else if (timeDiff <= 1.0) result = 'GOOD';
    else result = 'MISS';
    
    // Mark arrow as hit
    set((prev) => ({
      arrows: prev.arrows.map(arrow => 
        arrow.id === closestArrow.id ? { ...arrow, hit: true } : arrow
      )
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
  toggleSettings: () => set((prev) => ({ showSettings: !prev.showSettings }))
}));
