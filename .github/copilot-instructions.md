# Tuki Tuki development

This is a native Godot 4.7 game module inside
`godot-base\games\tuki-tuki_agents`. Read the host repository's `AGENTS.md` and
`godot-base\README.md` for the framework contract. Do not reintroduce React,
Three.js, Vite, npm, or a second `project.godot`.

- `game.gd` supplies `GameManifest`; `gameplay.tscn` inherits the shared
  `game_shell.tscn` and `gameplay.gd` extends `GameShell`.
- Keep game rules, original assets, synthesized audio and tests in this folder.
  Do not depend on sibling games or add game-name branches to the framework.
- Declare settings/actions in the constants-only `tuki_tuki_options.gd`.
  Persist options through shared `Settings`, not game-local save machinery.
- Keep judgement in node-free `rhythm\rhythm_state.gd`. Visual scroll speed
  must not change hit windows, chart times, audio tempo or scoring.
- Use the compensated audible playback clock for arrows and input; preserve
  the musical position across pause/settings. Never use frame counts as time.
- Local players get independent note-resolution buffers over the same chart.
  Prevent key repeat and keep simultaneous lanes/contacts independent.
- Use `gl_compatibility`, pooled arrows/effects, responsive scrolling UI,
  live accessibility preferences, P1/P2 labels and semantic audio captions.
  Accessibility setter overrides must call `super(value)`.
- Songs and champions are fictional game content. Audio is synthesized;
  do not claim missing recordings or unimplemented campaign/hold-note features.
- Use typed GDScript, tabs, snake_case and concise documentation of non-obvious
  behavior. Load gameplay scenes at runtime in tests rather than importing
  `GameShell` before autoload initialization.

Run the four module suites listed in this README and the parent framework's
required suites. `stage_view_test.gd` needs a real window. Preserve `.gd.uid`
and import-setting sidecars, and do not commit generated engine/build caches.
