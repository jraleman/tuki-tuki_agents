extends RefCounted

## Constants-only declarations shared by the manifest, gameplay and tests.

const GAME_ID := "tuki_tuki"
const ROOT := "res://games/tuki-tuki_agents/"
const DIFFICULTY_KEY := "game/tuki_tuki_difficulty"
const MODE_KEY := "game/tuki_tuki_mode"
const SCROLL_KEY := "game/tuki_tuki_scroll_speed"
const OFFSET_KEY := "game/tuki_tuki_audio_offset"
const SFX_KEY := "game/tuki_tuki_sound_effects"
const BACKGROUND_KEY := "game/tuki_tuki_background_effects"
const SETTINGS_ACTION := &"tuki_tuki_settings"
const ACTIONS := [
	[&"tuki_tuki_p1_left", &"tuki_tuki_p1_down", &"tuki_tuki_p1_up", &"tuki_tuki_p1_right"],
	[&"tuki_tuki_p2_left", &"tuki_tuki_p2_down", &"tuki_tuki_p2_up", &"tuki_tuki_p2_right"],
]
const SYMBOLS := ["<", "v", "^", ">"]
const TUNABLES: Array[Dictionary] = [
	{
		"key": MODE_KEY, "type": GameManifest.OPTION_CHOICE, "default": 0,
		"title": "Solo mode", "heading": "Tuki Tuki",
		"description": "Story includes the championship dialogue; Practice goes straight to the set list.",
		"choices": [{"value": 0, "title": "Story"}, {"value": 1, "title": "Practice"}],
	},
	{
		"key": DIFFICULTY_KEY, "type": GameManifest.OPTION_CHOICE, "default": 1,
		"title": "Preferred difficulty",
		"description": "The pre-song briefing offers only charts supported by the selected song.",
		"choices": [
			{"value": 0, "title": "Beginner"}, {"value": 1, "title": "Standard"},
			{"value": 2, "title": "Heavy"}, {"value": 3, "title": "Challenge"},
		],
	},
	{
		"key": SCROLL_KEY, "default": 1.0, "min": 0.5, "max": 3.0, "step": 0.1,
		"title": "Arrow scroll speed", "format": GameManifest.FORMAT_PERCENT,
		"description": "Changes travel distance, not the song tempo or hit windows. Applies next song.",
	},
	{
		"key": OFFSET_KEY, "default": 0.0, "min": -200.0, "max": 200.0, "step": 10.0,
		"title": "Audio offset", "format": GameManifest.FORMAT_MILLISECONDS,
		"description": "Positive values move the target moment later than the audible beat. Applies next song.",
	},
	{
		"key": SFX_KEY, "type": GameManifest.OPTION_TOGGLE, "default": true,
		"title": "Hit sound effects", "description": "Plays a distinct cue for hits and misses.",
	},
	{
		"key": BACKGROUND_KEY, "type": GameManifest.OPTION_TOGGLE, "default": true,
		"title": "Background effects",
		"description": "Allows decorative dancing and stage pulses. Reduced motion always takes priority.",
	},
]
const CONTROL_BINDINGS: Array[Dictionary] = [
	{
		"key": "controls/tuki_tuki_p1_left", "default": KEY_A,
		"title": "Left", "action": ACTIONS[0][0], "player": 0,
	},
	{
		"key": "controls/tuki_tuki_p1_down", "default": KEY_S,
		"title": "Down", "action": ACTIONS[0][1], "player": 0,
	},
	{
		"key": "controls/tuki_tuki_p1_up", "default": KEY_W,
		"title": "Up", "action": ACTIONS[0][2], "player": 0,
	},
	{
		"key": "controls/tuki_tuki_p1_right", "default": KEY_D,
		"title": "Right", "action": ACTIONS[0][3], "player": 0,
	},
	{
		"key": "controls/tuki_tuki_p2_left", "default": KEY_LEFT,
		"title": "Left", "action": ACTIONS[1][0], "player": 1,
	},
	{
		"key": "controls/tuki_tuki_p2_down", "default": KEY_DOWN,
		"title": "Down", "action": ACTIONS[1][1], "player": 1,
	},
	{
		"key": "controls/tuki_tuki_p2_up", "default": KEY_UP,
		"title": "Up", "action": ACTIONS[1][2], "player": 1,
	},
	{
		"key": "controls/tuki_tuki_p2_right", "default": KEY_RIGHT,
		"title": "Right", "action": ACTIONS[1][3], "player": 1,
	},
	{
		"key": "controls/tuki_tuki_settings", "default": KEY_F1,
		"title": "Settings", "action": SETTINGS_ACTION, "player": -1,
	},
]
