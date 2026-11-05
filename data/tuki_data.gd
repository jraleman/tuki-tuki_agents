extends RefCounted

## The prototype's fictional set list, champions and Venezuelan story content.

const DIFFICULTIES := ["Beginner", "Standard", "Heavy", "Challenge"]
const SONGS: Array[Dictionary] = [
	{
		"id": "barrio_rhythm", "title": "Ritmo del Barrio",
		"artist": "Los Campeones del Tuki", "genre": "Tuki Clásico",
		"bpm": 130, "duration": 180.0, "seed": 130,
		"difficulties": [0, 1, 2], "levels": [3, 6, 9],
		"description": "Feel the heartbeat of Petare, where Tuki was born in the hills of Caracas.",
		"setting": "Urban hills, colorful houses, community spirit",
	},
	{
		"id": "maracaibo_power", "title": "Poder Marabino",
		"artist": "Carlos y Los Petroleros", "genre": "Tuki Rápido",
		"bpm": 180, "duration": 150.0, "seed": 180,
		"difficulties": [1, 2, 3], "levels": [7, 12, 15],
		"description": "Industrial strength Tuki from the oil capital of Venezuela.",
		"setting": "Oil refineries, industrial landscapes, worker solidarity",
	},
	{
		"id": "valencia_flow", "title": "Flujo Valenciano",
		"artist": "Lucía y Las Naranjas", "genre": "Tuki Suave",
		"bpm": 110, "duration": 200.0, "seed": 110,
		"difficulties": [0, 1, 2], "levels": [2, 5, 8],
		"description": "Smooth and melodic Tuki inspired by the orange groves of Carabobo.",
		"setting": "Orange groves, rivers, pastoral landscapes",
	},
	{
		"id": "fusion_legend", "title": "Leyenda de Fusión",
		"artist": "Rodríguez El Maestro", "genre": "Tuki Fusion",
		"bpm": 160, "duration": 240.0, "seed": 160,
		"difficulties": [2, 3], "levels": [11, 18],
		"description": "Master-level fusion blending traditional and modern Venezuelan music.",
		"setting": "Concert halls, musical instruments, cultural fusion",
	},
	{
		"id": "tutorial_basic", "title": "Primer Paso",
		"artist": "Escuela de Tuki", "genre": "Tutorial",
		"bpm": 100, "duration": 60.0, "seed": 100,
		"difficulties": [0], "levels": [1],
		"description": "Learn left, down, up and right with a repeating beginner pattern.",
		"setting": "Venezuelan flag colors and a clear practice stage",
	},
]

const CHARACTERS: Array[Dictionary] = [
	{
		"id": "maria_caracas", "title": "María La Caraqueña",
		"description": "The rhythm queen from Petare. Petare, Caracas / Tuki Clásico.",
		"hometown": "Petare, Caracas", "style": "Tuki Clásico", "color": "ff6b6b",
		"backstory": (
			"Born in the hills of Petare, María learned to dance before she could walk. "
			+ "Her grandmother taught her the traditional steps of Venezuelan folk dance, "
			+ "but María fell in love with the urban beats of Tuki that echoed through "
			+ "the barrio streets. She's known for her lightning-fast footwork and her "
			+ "ability to stay on beat even with the most complex Tuki rhythms."
		),
	},
	{
		"id": "carlos_maracaibo", "title": "Carlos El Zuliano",
		"description": "The oil city rhythm master. Maracaibo, Zulia / Tuki Rápido.",
		"hometown": "Maracaibo, Zulia", "style": "Tuki Rápido", "color": "4ecdc4",
		"backstory": (
			"From the hot streets of Maracaibo, Carlos brings the energy of Lake "
			+ "Maracaibo to every beat. Working in the oil fields by day, he spends "
			+ "his nights perfecting his Tuki moves. His style is fast and aggressive, "
			+ "reflecting the industrial heartbeat of his hometown. They say he can "
			+ "dance to 180 BPM without breaking a sweat."
		),
	},
	{
		"id": "lucia_valencia", "title": "Lucía La Valenciana",
		"description": "The orange grove dancer. Valencia, Carabobo / Tuki Suave.",
		"hometown": "Valencia, Carabobo", "style": "Tuki Suave", "color": "f4ad56",
		"backstory": (
			"Growing up in the orange groves of Valencia, Lucía developed a smoother, "
			+ "more melodic approach to Tuki. Her movements flow like the Carabobo "
			+ "River, mixing traditional Venezuelan dance with modern urban rhythms. "
			+ "She's the master of the Tuki Suave style, proving that power doesn't "
			+ "always mean speed."
		),
	},
	{
		"id": "rodriguez_barquisimeto", "title": "Rodríguez El Llanero",
		"description": "The twilight city legend. Barquisimeto, Lara / Tuki Fusion.",
		"hometown": "Barquisimeto, Lara", "style": "Tuki Fusion", "color": "b997ef",
		"backstory": (
			"Known as the musical capital of Venezuela, Barquisimeto shaped Rodríguez "
			+ "into a versatile dancer who blends Tuki with joropo, salsa, and even "
			+ "reggaeton. His Tuki Fusion style represents the cultural melting pot "
			+ "of his city. Legend says he once danced for 12 hours straight during "
			+ "the city's twilight festival."
		),
	},
]

const STYLES: Array[Dictionary] = [
	{
		"title": "Tuki Clásico", "range": "120-140 BPM",
		"text": "The original barrio sound: a steady 4/4 beat, bass and percussion, "
			+ "traditional instruments mixed with urban beats, and moderate-speed patterns.",
	},
	{
		"title": "Tuki Rápido", "range": "160-200 BPM",
		"text": "Fast-paced Tuki with rapid-fire beats and industrial/electronic influences. "
			+ "Challenging patterns test stamina and precision.",
	},
	{
		"title": "Tuki Suave", "range": "100-130 BPM",
		"text": "Flowing rhythms with melodic elements and Venezuelan folk influences. "
			+ "The emphasis is on rhythm, smooth movement and transitions rather than speed.",
	},
	{
		"title": "Tuki Fusion", "range": "140-180 BPM",
		"text": "A fictional championship style blending Tuki with joropo, salsa and "
			+ "reggaeton, with complex rhythms and master-level patterns.",
	},
]

const STORY: Array[Dictionary] = [
	{
		"title": "The Legend of Tuki Tuki",
		"description": "Welcome to Venezuela, where rhythm runs through the streets.",
		"dialogue": [
			["Narrator", "In the vibrant barrios of Venezuela, where concrete meets "
				+ "creativity and struggle breeds strength, a new sound emerged..."],
			["Narrator", "TUKI - born from the streets, forged by the people, a rhythm "
				+ "that captures the heartbeat of a nation. Fast, fierce, and "
				+ "unapologetically Venezuelan."],
			["Narrator", "But legend speaks of an ancient rhythm game played by the "
				+ "ancestral spirits of the land - Tuki Tuki - where dancers could "
				+ "channel the very essence of Venezuelan soul through their feet."],
			["Narrator", "Today, four champions from across Venezuela have gathered "
				+ "to compete in the ultimate Tuki battle. Each brings their unique "
				+ "style, their barrio's pride, and their passion for the rhythm."],
		],
	},
	{
		"title": "The Culture of Tuki",
		"description": "Learn about Venezuelan Tuki music and culture.",
		"dialogue": [
			["Cultural Guide", "Tuki emerged in the late 1990s in the barrios of "
				+ "Caracas, born from the creativity of young Venezuelans who mixed "
				+ "electronic beats with their cultural identity."],
			["Cultural Guide", "Tuki is characterized by rapid-fire electronic beats, "
				+ "often reaching 180+ BPM, creating an intense, almost hypnotic rhythm "
				+ "that demands both physical and mental stamina."],
			["Cultural Guide", "The dance style is aggressive and competitive, with "
				+ "dancers facing off in battles where creativity, speed, and endurance "
				+ "determine the winner. It's expression, rebellion, and community bonding."],
			["Cultural Guide", "In this championship's fictional tour, each barrio "
				+ "brings a variation - from Maracaibo's industrial sounds to "
				+ "Valencia's melodic influences. Experience them in Tuki Tuki!"],
		],
	},
	{
		"title": "Choose Your Champion",
		"description": "Select your dancer and represent your barrio.",
		"dialogue": [
			["Announcer", "Welcome to the grand Tuki Tuki championship! Four legendary "
				+ "dancers await your choice. Each brings a unique style and the pride "
				+ "of their homeland."],
			["Announcer", "Will you choose lightning-fast María from Petare? The "
				+ "industrial power of Carlos from Maracaibo? The smooth flow of Lucía "
				+ "from Valencia? Or Rodríguez's fusion mastery from Barquisimeto?"],
			["Announcer", "In multiplayer, two can dance together! Each player follows "
				+ "the same chart on their own lanes. Show your Venezuelan rhythm!"],
		],
	},
	{
		"title": "The Streets Call",
		"description": "Your first Tuki battle begins.",
		"dialogue": [
			["María La Caraqueña", "¡Epa! ¿Tú crees que puedes seguir el ritmo de "
				+ "Petare? These hills have taught me rhythms you've never heard!"],
			["Carlos El Zuliano", "Desde Maracaibo vengo yo, with the power of the "
				+ "oil fields in my feet. Let's see if you can handle industrial-strength Tuki!"],
			["Narrator", "The battle begins! Feel the pulse of Venezuela through your "
				+ "fingertips. Hit the arrows in perfect sync with the Tuki beat. "
				+ "¡Dale que vamos!"],
		],
	},
]

const LORE := (
	"Tuki Tuki: The Venezuelan Rhythm Revolution\n\n"
	+ "In the sprawling barrios of Venezuela, where music flows through concrete "
	+ "veins and rhythm pulses in every heartbeat, a legendary competition emerges "
	+ "every generation: the Tuki Tuki championship.\n\n"
	+ "Born from the underground scene of the late '90s, this is a cultural "
	+ "celebration and a test of endurance, creativity and Venezuelan soul. Four "
	+ "regions, four champions, one ultimate rhythm king or queen. The legend says "
	+ "that mastering all four styles reveals the Golden Rhythm, a mythical beat "
	+ "uniting Venezuelan music from joropo to Tuki, from the Andes to the Caribbean.\n\n"
	+ "From the hills of Petare to Maracaibo, Valencia's orange groves and "
	+ "Barquisimeto's concert halls, every stage brings its own flavor. Tuki "
	+ "represents urban identity, resilience, creativity and community.\n\n"
	+ "The championship, champions and track credits are fictional game lore. "
	+ "Audio is synthesized in-engine, not recordings by the named fictional artists."
)


## Return a defensive copy so session and view code cannot rewrite the set list.
static func song(id: String) -> Dictionary:
	for entry in SONGS:
		if str(entry["id"]) == id:
			return entry.duplicate(true)
	push_error("Tuki Tuki: unknown song '%s'." % id)
	return {}


## Setup, gameplay and the gallery share the same fictional champion data.
static func character(id: String) -> Dictionary:
	for entry in CHARACTERS:
		if str(entry["id"]) == id:
			return entry.duplicate(true)
	push_error("Tuki Tuki: unknown champion '%s'." % id)
	return {}
