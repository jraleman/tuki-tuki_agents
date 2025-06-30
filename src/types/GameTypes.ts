// Game state and core types
export interface GameState {
  isPlaying: boolean;
  isPaused: boolean;
  currentTime: number;
  score: { player1: number; player2: number };
  combo: { player1: number; player2: number };
  accuracy: { player1: number; player2: number };
  currentSong?: Song;
  difficulty: Difficulty;
  gameMode: 'story' | 'multiplayer' | 'practice';
}

// Player types
export type Player = 'player1' | 'player2';

export interface PlayerConfig {
  id: Player;
  name: string;
  keys: {
    left: string;
    down: string;
    up: string;
    right: string;
  };
  color: string;
  position: 'left' | 'right';
}

// Arrow and gameplay types
export type ArrowDirection = 'left' | 'down' | 'up' | 'right';

export interface Arrow {
  id: string;
  direction: ArrowDirection;
  time: number; // When the arrow should be hit (in milliseconds)
  lane: number; // 0-3 for each direction
  player: Player;
  position: [number, number, number]; // 3D position
  speed: number;
  hit: boolean;
  missed: boolean;
}

export type HitResult = 'PERFECT' | 'GREAT' | 'GOOD' | 'MISS';

export interface HitData {
  result: HitResult;
  timeDiff: number;
  arrow: Arrow;
  player: Player;
}

// Song and beatmap types
export interface Song {
  id: string;
  title: string;
  artist: string;
  genre: string;
  bpm: number;
  duration: number; // in seconds
  audioFile: string;
  backgroundImage?: string;
  difficulties: {
    beginner?: BeatMap;
    standard?: BeatMap;
    heavy?: BeatMap;
    challenge?: BeatMap;
  };
}

export interface BeatMap {
  difficulty: Difficulty;
  level: number;
  totalNotes: number;
  arrows: BeatMapArrow[];
}

export interface BeatMapArrow {
  time: number; // Time in milliseconds when arrow should be hit
  direction: ArrowDirection;
  player: Player;
}

export type Difficulty = 'beginner' | 'standard' | 'heavy' | 'challenge';

// Scoring system
export interface ScoreData {
  perfect: number;
  great: number;
  good: number;
  miss: number;
  maxCombo: number;
  totalScore: number;
  accuracy: number;
}

// Game settings
export interface GameSettings {
  scrollSpeed: number;
  audioOffset: number;
  soundEffects: boolean;
  backgroundEffects: boolean;
  player1Keys: PlayerConfig['keys'];
  player2Keys: PlayerConfig['keys'];
}

// Story mode types
export interface StoryScene {
  id: string;
  title: string;
  description: string;
  dialogue: DialogueLine[];
  backgroundImage: string;
  backgroundMusic?: string;
  nextScene?: string;
  choices?: StoryChoice[];
}

export interface DialogueLine {
  character: string;
  text: string;
  avatar?: string;
  emotion?: string;
}

export interface StoryChoice {
  text: string;
  nextScene: string;
  requirement?: {
    type: 'score' | 'accuracy' | 'combo';
    value: number;
  };
}

// Venezuelan Tuki culture and backstory types
export interface Character {
  id: string;
  name: string;
  description: string;
  avatar: string;
  hometown: string;
  favoriteStyle: string;
  backstory: string;
}

export interface TukiStyle {
  name: string;
  description: string;
  characteristics: string[];
  bpmRange: [number, number];
  difficulty: Difficulty;
}
