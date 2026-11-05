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
const OUTFIT_SLOTS := ["tuki_tuki_p1_outfit", "tuki_tuki_p2_outfit"]
const SHOE_SLOTS := ["tuki_tuki_p1_shoes", "tuki_tuki_p2_shoes"]
const FIRST_SONG := "tuki_tuki_first_song"
const FLOW_COMBO := "tuki_tuki_combo_25"
const PRECISION := "tuki_tuki_precision_90"
const LOCAL_BATTLE := "tuki_tuki_local_battle"
const ACHIEVEMENTS := {
	FIRST_SONG: {
		"title": "Primer paso", "description": "Finish any song.", "badge": "STEP",
	},
	FLOW_COMBO: {
		"title": "Barrio flow", "description": "Finish a song with a best combo of at least 25.",
		"badge": "x25",
	},
	PRECISION: {
		"title": "On the beat", "description": "Finish a song with at least 90% weighted accuracy.",
		"badge": "90%",
	},
	LOCAL_BATTLE: {
		"title": "Two barrios, one beat",
		"description": "Finish a local battle with both humans hitting notes.", "badge": "P1+P2",
	},
}
const DEFAULT_OUTFIT := {
	"id": "tuki_tuki_outfit_champion", "title": "Champion colors",
	"kind": "outfit", "heading": "Outfits", "price": 0, "default": true,
	"description": "Your champion's original shirt and three-color stripes.",
	"color": Color("ff6b6b"), "champion_color": true, "jacket": false, "badge": "TEE",
}
const DEFAULT_SHOES := {
	"id": "tuki_tuki_shoes_street", "title": "Street trainers",
	"kind": "shoes", "heading": "Shoes", "price": 0, "default": true,
	"description": "The original light trainers. Every shoe has identical rhythm rules.",
	"color": Color("d8dfe8"), "trim": Color("263447"), "shoe_style": 0, "badge": "STEP",
}
const STORE_ITEMS: Array[Dictionary] = [
	DEFAULT_OUTFIT,
	{
		"id": "tuki_tuki_outfit_barrio", "title": "Barrio jacket",
		"kind": "outfit", "heading": "Outfits", "price": 40,
		"description": "A red street jacket with short sleeves and championship stripes.",
		"color": Color("e55668"), "jacket": true, "badge": "RED",
	},
	{
		"id": "tuki_tuki_outfit_lake", "title": "Lake jacket",
		"kind": "outfit", "heading": "Outfits", "price": 80,
		"description": "A teal jacket inspired by the fictional Maracaibo champion.",
		"color": Color("4ecdc4"), "jacket": true, "badge": "LAKE",
	},
	{
		"id": "tuki_tuki_outfit_fusion", "title": "Fusion jacket",
		"kind": "outfit", "heading": "Outfits", "price": 120,
		"description": "A violet concert jacket. Style changes, timing does not.",
		"color": Color("b997ef"), "jacket": true, "badge": "MIX",
	},
	DEFAULT_SHOES,
	{
		"id": "tuki_tuki_shoes_sunrise", "title": "Sunrise high-tops",
		"kind": "shoes", "heading": "Shoes", "price": 40,
		"description": "Gold high-tops with a red toe stripe and light soles.",
		"color": Color("f6ce46"), "trim": Color("e55668"), "shoe_style": 1, "badge": "SUN",
	},
	{
		"id": "tuki_tuki_shoes_skyline", "title": "Skyline trainers",
		"kind": "shoes", "heading": "Shoes", "price": 70,
		"description": "Blue trainers with teal stripes. A purely visual upgrade.",
		"color": Color("67baff"), "trim": Color("60d9c4"), "shoe_style": 2, "badge": "SKY",
	},
	{
		"id": "tuki_tuki_shoes_midnight", "title": "Midnight boots",
		"kind": "shoes", "heading": "Shoes", "price": 110,
		"description": "Violet ankle boots with gold toe stripes and light soles.",
		"color": Color("72569c"), "trim": Color("f6ce46"), "shoe_style": 3, "badge": "NITE",
	},
]
const STORE_SLOTS: Array[Dictionary] = [
	{
		"id": OUTFIT_SLOTS[0], "title": "P1 outfit", "kind": "outfit",
		"default": DEFAULT_OUTFIT["id"],
	},
	{
		"id": OUTFIT_SLOTS[1], "title": "P2 outfit", "kind": "outfit",
		"default": DEFAULT_OUTFIT["id"],
	},
	{
		"id": SHOE_SLOTS[0], "title": "P1 shoes", "kind": "shoes",
		"default": DEFAULT_SHOES["id"],
	},
	{
		"id": SHOE_SLOTS[1], "title": "P2 shoes", "kind": "shoes",
		"default": DEFAULT_SHOES["id"],
	},
]
const STORE_CURRENCY := {
	"name": "Beat Token", "plural": "Beat Tokens", "points_per_score": 0.002,
	"round_bonus": 5, "win_bonus": 0, "max_per_round": 180,
}
const GALLERY_EXHIBITS: Array[Dictionary] = [
	{
		"id": "maria_caracas", "title": "María La Caraqueña", "kind": "champion",
		"heading": "Champions", "description": "The fictional rhythm queen from Petare, Caracas.",
		"facts": ["Tuki Clásico", "Actual gameplay rig; wears P1's equipped cosmetics"],
	},
	{
		"id": "carlos_maracaibo", "title": "Carlos El Zuliano", "kind": "champion",
		"heading": "Champions", "description": "The fictional rhythm master from Maracaibo, Zulia.",
		"facts": ["Tuki Rápido", "Actual gameplay rig; wears P1's equipped cosmetics"],
	},
	{
		"id": "lucia_valencia", "title": "Lucía La Valenciana", "kind": "champion",
		"heading": "Champions", "description": "The fictional orange-grove dancer from Valencia.",
		"facts": ["Tuki Suave", "Actual gameplay rig; wears P1's equipped cosmetics"],
	},
	{
		"id": "rodriguez_barquisimeto", "title": "Rodríguez El Llanero", "kind": "champion",
		"heading": "Champions", "description": "The fictional fusion legend from Barquisimeto.",
		"facts": ["Tuki Fusion", "Actual gameplay rig; wears P1's equipped cosmetics"],
	},
	{
		"id": "arrow_targets", "title": "Four directions", "kind": "arrows",
		"heading": "The stage", "description": "The extruded arrows used for notes and front targets.",
		"facts": ["Left / down / up / right", "Original mesh; presentation never judges a hit"],
	},
	{
		"id": "championship_stage", "title": "The championship stage", "kind": "venue",
		"heading": "The stage", "description": "The original dance floor, skyline and title from play.",
		"facts": ["Compatibility-renderer geometry", "Free to inspect; no progress or audio recorded"],
	},
]
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
