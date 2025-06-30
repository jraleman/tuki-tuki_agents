import { StoryScene, Character, TukiStyle } from '../types/GameTypes';

// Venezuelan characters representing different barrios and Tuki styles
export const characters: Character[] = [
  {
    id: 'maria_caracas',
    name: 'María La Caraqueña',
    description: 'The rhythm queen from Petare',
    avatar: '/characters/maria.png',
    hometown: 'Petare, Caracas',
    favoriteStyle: 'Tuki Clasico',
    backstory: `Born in the hills of Petare, María learned to dance before she could walk. 
    Her grandmother taught her the traditional steps of Venezuelan folk dance, but María 
    fell in love with the urban beats of Tuki that echoed through the barrio streets. 
    She's known for her lightning-fast footwork and her ability to stay on beat even 
    with the most complex Tuki rhythms.`
  },
  {
    id: 'carlos_maracaibo',
    name: 'Carlos El Zuliano',
    description: 'The oil city rhythm master',
    avatar: '/characters/carlos.png',
    hometown: 'Maracaibo, Zulia',
    favoriteStyle: 'Tuki Rapido',
    backstory: `From the hot streets of Maracaibo, Carlos brings the energy of Lake Maracaibo 
    to every beat. Working in the oil fields by day, he spends his nights perfecting his 
    Tuki moves. His style is fast and aggressive, reflecting the industrial heartbeat of 
    his hometown. They say he can dance to 180 BPM without breaking a sweat.`
  },
  {
    id: 'lucia_valencia',
    name: 'Lucía La Valenciana',
    description: 'The orange grove dancer',
    avatar: '/characters/lucia.png',
    hometown: 'Valencia, Carabobo',
    favoriteStyle: 'Tuki Suave',
    backstory: `Growing up in the orange groves of Valencia, Lucía developed a smoother, 
    more melodic approach to Tuki. Her movements flow like the Carabobo River, mixing 
    traditional Venezuelan dance with modern urban rhythms. She's the master of the 
    'Tuki Suave' style, proving that power doesn't always mean speed.`
  },
  {
    id: 'rodriguez_barquisimeto',
    name: 'Rodríguez El Llanero',
    description: 'The twilight city legend',
    avatar: '/characters/rodriguez.png',
    hometown: 'Barquisimeto, Lara',
    favoriteStyle: 'Tuki Fusion',
    backstory: `Known as the musical capital of Venezuela, Barquisimeto shaped Rodríguez 
    into a versatile dancer who blends Tuki with joropo, salsa, and even reggaeton. 
    His 'Tuki Fusion' style represents the cultural melting pot of his city. Legend says 
    he once danced for 12 hours straight during the city's twilight festival.`
  }
];

// Different Tuki styles that influence gameplay
export const tukiStyles: TukiStyle[] = [
  {
    name: 'Tuki Clasico',
    description: 'The original Tuki style from the barrios',
    characteristics: [
      'Steady 4/4 beat',
      'Emphasis on bass and percussion',
      'Traditional Venezuelan instruments mixed with urban beats',
      'Moderate speed with complex patterns'
    ],
    bpmRange: [120, 140],
    difficulty: 'beginner'
  },
  {
    name: 'Tuki Rapido',
    description: 'Fast-paced Tuki for experienced dancers',
    characteristics: [
      'High BPM with rapid-fire beats',
      'Industrial and electronic influences',
      'Challenging arrow patterns',
      'Tests stamina and precision'
    ],
    bpmRange: [160, 200],
    difficulty: 'heavy'
  },
  {
    name: 'Tuki Suave',
    description: 'Smooth and melodic Tuki style',
    characteristics: [
      'Flowing rhythms with melodic elements',
      'Incorporates traditional Venezuelan folk',
      'Longer hold notes and smooth transitions',
      'Focus on rhythm over speed'
    ],
    bpmRange: [100, 130],
    difficulty: 'standard'
  },
  {
    name: 'Tuki Fusion',
    description: 'Modern fusion incorporating multiple genres',
    characteristics: [
      'Blends Tuki with joropo, salsa, and reggaeton',
      'Unpredictable tempo changes',
      'Complex polyrhythms',
      'Master level challenge'
    ],
    bpmRange: [140, 180],
    difficulty: 'challenge'
  }
];

// Story mode scenes
export const storyScenes: StoryScene[] = [
  {
    id: 'opening',
    title: 'The Legend of Tuki Tuki',
    description: 'Welcome to Venezuela, where rhythm runs through the streets',
    backgroundImage: '/backgrounds/venezuela_street.jpg',
    backgroundMusic: '/music/intro_ambient.mp3',
    dialogue: [
      {
        character: 'Narrator',
        text: `In the vibrant barrios of Venezuela, where concrete meets creativity 
        and struggle breeds strength, a new sound emerged...`,
        avatar: '/ui/narrator_icon.png'
      },
      {
        character: 'Narrator',
        text: `TUKI - born from the streets, forged by the people, a rhythm that 
        captures the heartbeat of a nation. Fast, fierce, and unapologetically Venezuelan.`,
        avatar: '/ui/narrator_icon.png'
      },
      {
        character: 'Narrator',
        text: `But legend speaks of an ancient rhythm game played by the ancestral 
        spirits of the land - "Tuki Tuki" - where dancers could channel the very 
        essence of Venezuelan soul through their feet.`,
        avatar: '/ui/narrator_icon.png'
      },
      {
        character: 'Narrator',
        text: `Today, four champions from across Venezuela have gathered to compete 
        in the ultimate Tuki battle. Each brings their unique style, their barrio's 
        pride, and their passion for the rhythm that defines them.`,
        avatar: '/ui/narrator_icon.png'
      }
    ],
    nextScene: 'character_selection',
    choices: [
      {
        text: 'Begin the Journey',
        nextScene: 'character_selection'
      },
      {
        text: 'Learn About Tuki Culture',
        nextScene: 'culture_info'
      }
    ]
  },
  {
    id: 'culture_info',
    title: 'The Culture of Tuki',
    description: 'Learn about Venezuelan Tuki music and culture',
    backgroundImage: '/backgrounds/barrio_sunset.jpg',
    backgroundMusic: '/music/cultural_theme.mp3',
    dialogue: [
      {
        character: 'Cultural Guide',
        text: `Tuki emerged in the late 1990s in the barrios of Caracas, born from 
        the creativity of young Venezuelans who mixed electronic beats with their 
        cultural identity.`,
        avatar: '/characters/guide.png'
      },
      {
        character: 'Cultural Guide',
        text: `Unlike other genres, Tuki is characterized by its rapid-fire electronic 
        beats, often reaching 180+ BPM, creating an intense, almost hypnotic rhythm 
        that demands both physical and mental stamina.`,
        avatar: '/characters/guide.png'
      },
      {
        character: 'Cultural Guide',
        text: `The dance style is aggressive and competitive, with dancers facing off 
        in "battles" where creativity, speed, and endurance determine the winner. 
        It's a form of expression, rebellion, and community bonding.`,
        avatar: '/characters/guide.png'
      },
      {
        character: 'Cultural Guide',
        text: `Each barrio developed its own variation - from the industrial sounds 
        of Maracaibo to the melodic influences of Valencia. Today, you'll experience 
        all these styles in Tuki Tuki!`,
        avatar: '/characters/guide.png'
      }
    ],
    nextScene: 'character_selection',
    choices: [
      {
        text: 'Ready to Dance!',
        nextScene: 'character_selection'
      }
    ]
  },
  {
    id: 'character_selection',
    title: 'Choose Your Champion',
    description: 'Select your dancer and represent your barrio',
    backgroundImage: '/backgrounds/competition_stage.jpg',
    backgroundMusic: '/music/selection_theme.mp3',
    dialogue: [
      {
        character: 'Announcer',
        text: `Welcome to the grand Tuki Tuki championship! Four legendary dancers 
        await your choice. Each brings their unique style and the pride of their homeland.`,
        avatar: '/ui/announcer_icon.png'
      },
      {
        character: 'Announcer',
        text: `Will you choose the lightning-fast María from Petare? The industrial 
        power of Carlos from Maracaibo? The smooth flow of Lucía from Valencia? 
        Or the fusion mastery of Rodríguez from Barquisimeto?`,
        avatar: '/ui/announcer_icon.png'
      },
      {
        character: 'Announcer',
        text: `Remember - in multiplayer mode, two can dance together! One using WASD, 
        the other using arrow keys. Show the world what Venezuelan rhythm really means!`,
        avatar: '/ui/announcer_icon.png'
      }
    ],
    nextScene: 'first_battle',
    choices: [
      {
        text: 'Single Player Story',
        nextScene: 'story_mode'
      },
      {
        text: 'Multiplayer Battle',
        nextScene: 'multiplayer_setup'
      },
      {
        text: 'Practice Mode',
        nextScene: 'practice_mode'
      }
    ]
  },
  {
    id: 'first_battle',
    title: 'The Streets Call',
    description: 'Your first Tuki battle begins',
    backgroundImage: '/backgrounds/street_battle.jpg',
    backgroundMusic: '/music/pre_battle.mp3',
    dialogue: [
      {
        character: 'María La Caraqueña',
        text: `¡Epa! ¿Tú crees que puedes seguir el ritmo de Petare? 
        These hills have taught me rhythms you've never heard!`,
        avatar: '/characters/maria.png',
        emotion: 'confident'
      },
      {
        character: 'Carlos El Zuliano',
        text: `Desde Maracaibo vengo yo, with the power of the oil fields in my feet. 
        Let's see if you can handle industrial-strength Tuki!`,
        avatar: '/characters/carlos.png',
        emotion: 'determined'
      },
      {
        character: 'Narrator',
        text: `The battle begins! Feel the pulse of Venezuela through your fingertips. 
        Hit the arrows in perfect sync with the Tuki beat. ¡Dale que vamos!`,
        avatar: '/ui/narrator_icon.png'
      }
    ],
    nextScene: 'game_start'
  }
];

// Game lore and world building
export const gameLore = {
  title: "Tuki Tuki: The Venezuelan Rhythm Revolution",
  
  backstory: `
    In the sprawling barrios of Venezuela, where music flows through concrete veins 
    and rhythm pulses in every heartbeat, a legendary competition emerges every 
    generation - the Tuki Tuki championship.
    
    Born from the underground Tuki scene of the late '90s, this isn't just a dance 
    battle - it's a cultural celebration, a test of endurance, creativity, and pure 
    Venezuelan soul. Four regions, four champions, one ultimate rhythm king or queen.
    
    The legend says that whoever masters all four Tuki styles and defeats the 
    champions of each barrio will unlock the "Golden Rhythm" - a mythical beat 
    that embodies the complete spirit of Venezuelan music, from joropo to Tuki, 
    from the Andes to the Caribbean coast.
  `,
  
  setting: `
    From the bustling hills of Petare in Caracas to the industrial heartland of 
    Maracaibo, from the orange groves of Valencia to the musical capital of 
    Barquisimeto - each location brings its unique flavor to the Tuki scene.
    
    The stages transform with each battle: urban rooftops with the city lights 
    flickering to the beat, oil refinery platforms where sparks fly with every 
    perfect hit, peaceful riverside venues where the rhythm flows like water, 
    and grand concert halls where tradition meets innovation.
  `,
  
  culturalSignificance: `
    Tuki represents more than music - it's Venezuelan urban identity, resilience, 
    and creativity in the face of adversity. This game celebrates that spirit, 
    bringing the authentic energy of Venezuelan barrios to players worldwide.
    
    Every beat tells a story of community, every arrow pattern reflects the 
    complex rhythms of Venezuelan life, and every perfect combo honors the 
    cultural heritage that makes Tuki uniquely, powerfully Venezuelan.
  `
};

export default {
  characters,
  tukiStyles,
  storyScenes,
  gameLore
};
