extends RefCounted

## Catalog registration; the shared framework needs no game-specific branches.

const Options = preload("res://games/tuki-tuki_agents/tuki_tuki_options.gd")
const Data = preload("res://games/tuki-tuki_agents/data/tuki_data.gd")


## Declare the game as data so collection and standalone menus share one route.
static func manifest() -> GameManifest:
	var game := GameManifest.new()
	game.id = Options.GAME_ID
	game.title = "Tuki Tuki"
	game.tagline = "The Venezuelan Rhythm Revolution."
	game.gameplay_scene_path = Options.ROOT + "gameplay.tscn"
	game.menu_order = 16
	game.control_style = GameManifest.CONTROL_STYLE_CUSTOM_KEYS
	game.supports_cpu_opponent = false
	game.uses_shell_round_rules = false
	game.characters = Data.CHARACTERS.duplicate(true)
	for song in Data.SONGS:
		game.levels.append({
			"id": song["id"], "title": song["title"],
			"description": "%s / %d BPM / %s" % [
				song["genre"], song["bpm"], song["description"],
			],
		})
	game.tunables = Options.TUNABLES
	game.control_bindings = Options.CONTROL_BINDINGS
	game.tutorial_video_path = Options.ROOT + "assets/video/tutorial.ogv"
	game.tutorial_poster_path = Options.ROOT + "assets/video/tutorial_poster.webp"
	game.local_tutorial_video_path = Options.ROOT + "assets/video/tutorial_local.ogv"
	game.local_tutorial_poster_path = Options.ROOT + "assets/video/tutorial_local_poster.webp"
	game.stats_url = "https://deskcansaw.com"
	game.copy = {
		"level_label": "Song", "character_label": "Champion",
		"single_player_description": "Follow a fictional Venezuelan championship or practice a song.",
		"multiplayer_description": "Two local dancers play the same chart on independent lanes.",
		"player_one_control_description": "Match left, down, up and right at the front targets.",
		"player_two_control_description": "Play your own four lanes alongside Player 1.",
		"solo_confirm_title": "Choose your champion and song",
		"solo_confirm_description": "Choose Story or Practice and a supported chart in the song briefing.",
		"versus_confirm_title": "Bring two dancers",
		"versus_confirm_description": "Choose a shared song; both players get the same chart.",
		"instructions_headline": "Feel the beat. Hit the arrows.",
		"instructions_rules": "Perfect 22 ms / Great 64 ms / Good 106 ms. Esc or Space pauses.",
		"instructions_solo_summary": (
			"Watch arrows travel toward the four front targets. Press the matching "
			+ "direction on the beat. Hits grow your combo; missed notes and wrong "
			+ "presses break it. The song, not a lives pool, ends the round. "
			+ "The briefing includes Story, Culture, champion biographies and Practice. "
			+ "All music is synthesized; no external song downloads are required."
		),
		"instructions_versus_summary": (
			"Both humans play the same song and chart at once. Each has independent "
			+ "arrows, timing, combo and score. Highest score wins."
		),
		"instructions_player_one_controls": "Left / down / up / right; on-screen pads also work.",
		"instructions_player_two_controls": "Your own left / down / up / right.",
	}
	var theme := GameTheme.new()
	theme.logo_texture_path = Options.ROOT + "assets/game-icon.svg"
	theme.accent = Color("f6ce46")
	theme.logo_color = Color("f6ce46")
	theme.plaque_color = Color("183255")
	theme.light = Color("f5f0d9")
	theme.background_top = Color("182c51")
	theme.background_bottom = Color("100f24")
	game.theme = theme
	game.credits = [
		{"heading": "Tuki Tuki", "lines": ["A Venezuelan rhythm-game celebration"]},
		{"heading": "Music & Art", "lines": [
			"Original in-engine synthesized rhythms and procedural 3D models",
			"Track credits and champions are fictional championship characters.",
		]},
	]
	return game
