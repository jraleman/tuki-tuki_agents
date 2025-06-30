# Copilot Instructions for DDR Game Development

## Project Overview
You are helping to build a Dance Dance Revolution (DDR) style rhythm game called "Tuki-Tuki" using React and ThreeJS. This is a web-based rhythm game where players step on arrow keys in time with music.

## Tech Stack
- **Frontend Framework**: React 18+ with TypeScript
- **3D Graphics**: ThreeJS (Three.js) with React Three Fiber (@react-three/fiber)
- **Audio**: Web Audio API or Howler.js for precise audio timing
- **Styling**: CSS Modules or Styled Components for component styling
- **State Management**: React Context API or Zustand for game state
- **Build Tool**: Vite for development and building
- **Input Handling**: Keyboard events for arrow key detection

## Core Game Components

### 1. Game Engine Architecture
- **GameEngine**: Core game loop with requestAnimationFrame
- **AudioManager**: Handles music playback and timing synchronization
- **ScoreManager**: Tracks player performance and combo system
- **InputManager**: Handles keyboard input with precise timing
- **BeatMapLoader**: Loads and parses song charts/beatmaps

### 2. 3D Scene Components (ThreeJS)
- **GameStage**: Main 3D scene container
- **ArrowLane**: 3D lanes where arrows travel (4 lanes: left, down, up, right)
- **FallingArrows**: 3D arrow objects that move towards the player
- **HitZone**: Target area where players must hit arrows
- **ParticleEffects**: Visual feedback for successful hits
- **Background**: Animated 3D background elements

### 3. UI Components (React)
- **GameScreen**: Main gameplay interface
- **ScoreDisplay**: Shows current score, combo, and accuracy
- **SongSelector**: Menu for choosing songs
- **SettingsPanel**: Game configuration (speed, difficulty, key bindings)
- **ResultsScreen**: Post-game statistics and scoring

## Key Features to Implement

### Core Gameplay
- **Arrow Patterns**: Different arrow combinations based on difficulty
- **Timing System**: Perfect/Great/Good/Miss hit detection with timing windows
- **Combo System**: Consecutive hits increase score multiplier
- **Difficulty Levels**: Beginner, Standard, Heavy, Challenge
- **Speed Modifiers**: Adjustable arrow scroll speed

### Audio Integration
- **Beat Detection**: Sync arrow timing with music beats
- **Audio Offset**: User-adjustable audio synchronization
- **Sound Effects**: Hit sounds, miss sounds, menu sounds
- **Music Formats**: Support for MP3, OGG, WAV files

### Visual Features
- **3D Arrow Models**: Colorful 3D arrows with materials and lighting
- **Lane Highlighting**: Visual feedback when arrows are in hit zone
- **Particle Systems**: Explosions, trails, and hit effects
- **Dynamic Lighting**: Responsive to music and gameplay
- **Smooth Animations**: Interpolated movement and transitions

## File Structure Guidelines

```
src/
├── components/
│   ├── game/
│   │   ├── GameEngine.tsx
│   │   ├── GameScreen.tsx
│   │   ├── ScoreDisplay.tsx
│   │   └── InputHandler.tsx
│   ├── three/
│   │   ├── GameStage.tsx
│   │   ├── ArrowLane.tsx
│   │   ├── FallingArrow.tsx
│   │   └── ParticleEffects.tsx
│   └── ui/
│       ├── SongSelector.tsx
│       ├── SettingsPanel.tsx
│       └── ResultsScreen.tsx
├── hooks/
│   ├── useGameEngine.ts
│   ├── useAudioManager.ts
│   └── useKeyboardInput.ts
├── managers/
│   ├── AudioManager.ts
│   ├── ScoreManager.ts
│   └── BeatMapLoader.ts
├── types/
│   ├── GameTypes.ts
│   ├── BeatMap.ts
│   └── Score.ts
├── assets/
│   ├── songs/
│   ├── models/
│   └── textures/
└── utils/
    ├── timing.ts
    ├── math.ts
    └── audio.ts
```

## Development Guidelines

### Performance Optimization
- Use `useMemo` and `useCallback` for expensive computations
- Implement object pooling for arrows to reduce garbage collection
- Optimize ThreeJS renders with `useFrame` from React Three Fiber
- Use `React.memo` for components that don't need frequent re-renders
- Implement frustum culling for off-screen arrows

### Timing Precision
- Use `performance.now()` for high-precision timing
- Implement audio lookahead for consistent timing
- Account for display refresh rate and audio latency
- Use Web Audio API for sample-accurate timing
- Implement calibration system for user-specific timing offsets

### Code Quality
- Use TypeScript for type safety
- Implement proper error handling for audio loading
- Use consistent naming conventions (camelCase for variables, PascalCase for components)
- Add comprehensive JSDoc comments for complex functions
- Follow React best practices (hooks, context, etc.)

### Testing Considerations
- Unit tests for game logic (scoring, timing, input handling)
- Integration tests for audio synchronization
- Performance tests for 3D rendering
- User acceptance tests for gameplay feel

## Key Algorithms to Implement

### 1. Hit Detection
```typescript
// Timing window constants (in milliseconds)
const PERFECT_WINDOW = 22;
const GREAT_WINDOW = 64;
const GOOD_WINDOW = 106;

function evaluateHit(arrowTime: number, hitTime: number): HitResult {
  const timeDiff = Math.abs(hitTime - arrowTime);
  if (timeDiff <= PERFECT_WINDOW) return 'PERFECT';
  if (timeDiff <= GREAT_WINDOW) return 'GREAT';
  if (timeDiff <= GOOD_WINDOW) return 'GOOD';
  return 'MISS';
}
```

### 2. Score Calculation
```typescript
function calculateScore(hitResult: HitResult, combo: number): number {
  const baseScore = {
    PERFECT: 100,
    GREAT: 80,
    GOOD: 60,
    MISS: 0
  };
  
  const comboMultiplier = Math.min(combo / 10, 3.0);
  return baseScore[hitResult] * (1 + comboMultiplier);
}
```

### 3. Arrow Movement
```typescript
function updateArrowPosition(arrow: Arrow, deltaTime: number, scrollSpeed: number): void {
  arrow.position.z += scrollSpeed * deltaTime;
  if (arrow.position.z > HIT_ZONE_POSITION + MISS_THRESHOLD) {
    arrow.missed = true;
  }
}
```

## Dependencies to Include

### Core Dependencies
```json
{
  "react": "^18.2.0",
  "react-dom": "^18.2.0",
  "three": "^0.150.0",
  "@react-three/fiber": "^8.10.0",
  "@react-three/drei": "^9.50.0",
  "howler": "^2.2.3",
  "zustand": "^4.3.0"
}
```

### Development Dependencies
```json
{
  "typescript": "^4.9.0",
  "@types/react": "^18.0.0",
  "@types/three": "^0.150.0",
  "vite": "^4.0.0",
  "@vitejs/plugin-react": "^3.0.0"
}
```

## Common Patterns and Best Practices

### 1. Game Loop Implementation
- Use `useFrame` from React Three Fiber for 3D updates
- Separate game logic from rendering
- Implement fixed timestep for consistent gameplay
- Handle pause/resume states properly

### 2. Audio Synchronization
- Load audio files as ArrayBuffers
- Use Web Audio API for precise timing
- Implement audio offset calibration
- Handle audio loading errors gracefully

### 3. Input Handling
- Use event listeners for keyboard input
- Implement key repeat prevention
- Support custom key bindings
- Handle multiple simultaneous inputs

### 4. Memory Management
- Pool arrow objects to reduce allocations
- Clean up audio contexts properly
- Remove event listeners on component unmount
- Dispose of ThreeJS objects when no longer needed

## Debugging and Development Tips

### Performance Monitoring
- Use React DevTools Profiler
- Monitor ThreeJS render calls
- Track audio latency and timing accuracy
- Implement FPS counter for performance monitoring

### Common Issues to Watch For
- Audio desynchronization over time
- Input lag on different devices
- Memory leaks from audio contexts
- ThreeJS performance bottlenecks
- Browser compatibility issues with Web Audio API

## Game Design Considerations

### Accessibility
- Colorblind-friendly arrow colors
- Adjustable visual contrast
- Keyboard navigation support
- Audio cues for visual elements

### User Experience
- Smooth difficulty progression
- Clear visual feedback for all actions
- Responsive menu navigation
- Comprehensive settings options
- Progress saving and statistics tracking

Remember to focus on creating a smooth, responsive gameplay experience with precise timing and engaging visual effects. The combination of React's component system and ThreeJS's 3D capabilities should create an immersive rhythm game experience.