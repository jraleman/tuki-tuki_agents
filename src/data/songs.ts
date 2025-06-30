import { Song, BeatMapArrow, ArrowDirection, Player } from '../types/GameTypes';

// Sample Tuki songs with Venezuelan themes
export const sampleSongs: Song[] = [
  {
    id: 'barrio_rhythm',
    title: 'Ritmo del Barrio',
    artist: 'Los Campeones del Tuki',
    genre: 'Tuki Clásico',
    bpm: 130,
    duration: 180, // 3 minutes
    audioFile: '/music/barrio_rhythm.mp3',
    backgroundImage: '/backgrounds/petare_hills.jpg',
    difficulties: {
      beginner: {
        difficulty: 'beginner',
        level: 3,
        totalNotes: 180,
        arrows: generateArrowPattern('beginner', 130, 180)
      },
      standard: {
        difficulty: 'standard',
        level: 6,
        totalNotes: 280,
        arrows: generateArrowPattern('standard', 130, 180)
      },
      heavy: {
        difficulty: 'heavy',
        level: 9,
        totalNotes: 420,
        arrows: generateArrowPattern('heavy', 130, 180)
      }
    }
  },
  {
    id: 'maracaibo_power',
    title: 'Poder Marabino',
    artist: 'Carlos y Los Petroleros',
    genre: 'Tuki Rápido',
    bpm: 180,
    duration: 150,
    audioFile: '/music/maracaibo_power.mp3',
    backgroundImage: '/backgrounds/maracaibo_oil.jpg',
    difficulties: {
      standard: {
        difficulty: 'standard',
        level: 7,
        totalNotes: 350,
        arrows: generateArrowPattern('standard', 180, 150)
      },
      heavy: {
        difficulty: 'heavy',
        level: 12,
        totalNotes: 520,
        arrows: generateArrowPattern('heavy', 180, 150)
      },
      challenge: {
        difficulty: 'challenge',
        level: 15,
        totalNotes: 680,
        arrows: generateArrowPattern('challenge', 180, 150)
      }
    }
  },
  {
    id: 'valencia_flow',
    title: 'Flujo Valenciano',
    artist: 'Lucía y Las Naranjas',
    genre: 'Tuki Suave',
    bpm: 110,
    duration: 200,
    audioFile: '/music/valencia_flow.mp3',
    backgroundImage: '/backgrounds/valencia_oranges.jpg',
    difficulties: {
      beginner: {
        difficulty: 'beginner',
        level: 2,
        totalNotes: 150,
        arrows: generateArrowPattern('beginner', 110, 200)
      },
      standard: {
        difficulty: 'standard',
        level: 5,
        totalNotes: 240,
        arrows: generateArrowPattern('standard', 110, 200)
      },
      heavy: {
        difficulty: 'heavy',
        level: 8,
        totalNotes: 360,
        arrows: generateArrowPattern('heavy', 110, 200)
      }
    }
  },
  {
    id: 'fusion_legend',
    title: 'Leyenda de Fusión',
    artist: 'Rodríguez El Maestro',
    genre: 'Tuki Fusion',
    bpm: 160,
    duration: 240,
    audioFile: '/music/fusion_legend.mp3',
    backgroundImage: '/backgrounds/barquisimeto_sunset.jpg',
    difficulties: {
      heavy: {
        difficulty: 'heavy',
        level: 11,
        totalNotes: 480,
        arrows: generateArrowPattern('heavy', 160, 240)
      },
      challenge: {
        difficulty: 'challenge',
        level: 18,
        totalNotes: 720,
        arrows: generateArrowPattern('challenge', 160, 240)
      }
    }
  },
  {
    id: 'tutorial_basic',
    title: 'Primer Paso',
    artist: 'Escuela de Tuki',
    genre: 'Tutorial',
    bpm: 100,
    duration: 60,
    audioFile: '/music/tutorial_basic.mp3',
    backgroundImage: '/backgrounds/venezuelan_flag.jpg',
    difficulties: {
      beginner: {
        difficulty: 'beginner',
        level: 1,
        totalNotes: 60,
        arrows: generateTutorialPattern()
      }
    }
  }
];

// Arrow pattern generator
function generateArrowPattern(difficulty: string, bpm: number, duration: number): BeatMapArrow[] {
  const patterns: BeatMapArrow[] = [];
  const beatInterval = (60 / bpm) * 1000; // milliseconds per beat
  const totalBeats = (duration / 60) * bpm;
  
  // Difficulty-based pattern density
  const densityMap: { [key: string]: number } = {
    'beginner': 0.3,
    'standard': 0.5,
    'heavy': 0.7,
    'challenge': 0.9
  };
  
  const density = densityMap[difficulty] || 0.5;
  const directions: ArrowDirection[] = ['left', 'down', 'up', 'right'];
  const players: Player[] = ['player1', 'player2'];
  
  for (let beat = 0; beat < totalBeats; beat++) {
    if (Math.random() < density) {
      // Add arrows for multiplayer
      players.forEach(player => {
        if (Math.random() < 0.7) { // 70% chance for each player
          patterns.push({
            time: beat * beatInterval,
            direction: directions[Math.floor(Math.random() * directions.length)],
            player: player
          });
        }
      });
    }
    
    // Add more complex patterns for higher difficulties
    if (difficulty === 'heavy' || difficulty === 'challenge') {
      // Add sync patterns
      if (beat % 4 === 0 && Math.random() < 0.4) {
        const syncDirection = directions[Math.floor(Math.random() * directions.length)];
        players.forEach(player => {
          patterns.push({
            time: beat * beatInterval,
            direction: syncDirection,
            player: player
          });
        });
      }
    }
    
    if (difficulty === 'challenge') {
      // Add rapid patterns
      if (Math.random() < 0.3) {
        const rapidDirection = directions[Math.floor(Math.random() * directions.length)];
        patterns.push({
          time: beat * beatInterval + beatInterval * 0.25,
          direction: rapidDirection,
          player: players[Math.floor(Math.random() * players.length)]
        });
      }
    }
  }
  
  return patterns.sort((a, b) => a.time - b.time);
}

// Special tutorial pattern
function generateTutorialPattern(): BeatMapArrow[] {
  const patterns: BeatMapArrow[] = [];
  const directions: ArrowDirection[] = ['left', 'down', 'up', 'right'];
  const players: Player[] = ['player1', 'player2'];
  
  // Simple alternating pattern for tutorial
  for (let i = 0; i < 60; i++) {
    patterns.push({
      time: i * 1000, // Every second
      direction: directions[i % 4],
      player: players[i % 2]
    });
  }
  
  return patterns;
}

// Venezuelan cultural song themes
export const songThemes = {
  'barrio_rhythm': {
    description: 'Feel the heartbeat of Petare, where Tuki was born in the hills of Caracas.',
    culturalNotes: 'Represents the original Tuki sound that emerged from Venezuelan barrios.',
    visualTheme: 'Urban hills, colorful houses, community spirit'
  },
  'maracaibo_power': {
    description: 'Industrial strength Tuki from the oil capital of Venezuela.',
    culturalNotes: 'Reflects the working-class energy of Maracaibo oil workers.',
    visualTheme: 'Oil refineries, industrial landscapes, worker solidarity'
  },
  'valencia_flow': {
    description: 'Smooth and melodic Tuki inspired by the orange groves of Carabobo.',
    culturalNotes: 'Represents the agricultural heart of Venezuela with gentler rhythms.',
    visualTheme: 'Orange groves, rivers, pastoral landscapes'
  },
  'fusion_legend': {
    description: 'Master-level Tuki fusion blending traditional and modern Venezuelan music.',
    culturalNotes: 'Celebrates Barquisimeto as the musical capital of Venezuela.',
    visualTheme: 'Concert halls, musical instruments, cultural fusion'
  }
};

export default sampleSongs;
