# Tuki Tuki

A native **Godot 4.7** DDR-style rhythm game celebrating Venezuelan Tuki culture.
This repository is a game module for **godot-base**, not a separate Godot
project. The React/Three.js prototype and its Vite/npm artifacts have been
removed.

## Run

Keep this repository at `godot-base\games\tuki-tuki_agents` and open the
parent `godot-base\project.godot`. From this directory:

```powershell
godot --path ..\.. -- --game=tuki_tuki
```

If Godot is not on PATH, set `$godot` to its executable:

```powershell
$godot = 'C:\Tools\Godot\Godot.exe'
Start-Process -FilePath $godot -ArgumentList @(
  '--path', '..\..', '--', '--game=tuki_tuki'
) -NoNewWindow -Wait -PassThru
```

The shared studio/menu flow offers solo or two local humans, a song, and a
champion per player. The native song briefing then offers supported difficulties,
**Story** or **Practice**, skippable dialogue, culture/style pages, and all four
champion biographies. Both local players receive the same deterministic chart.
Songs end at their declared length, then use the shared results, detailed
statistics, share card, and replay screens.

Standalone launches now follow the studio sting with a **skippable 3D rhythm
demonstration**, including on-screen text and original synthesized audio.
Collection launches retain the shared studio intro. Shared setup previews every
champion with the same original rig used in play.

**Store** sells three outfits and three pairs of shoes alongside two free
defaults. P1/P2 have independent outfit and shoe slots; one purchase can equip
both players. A completed song pays `round(best human score × 0.002) + 5`
**Beat Tokens**, capped at 180, once per completed run. Unfinished songs and the intro
pay nothing. Equipment updates live, including from pause, without changing
notes, timing, score or playback position. The shared `Store` owns all saves.

**Gallery** freely displays the four fictional champions, actual arrow meshes,
and championship venue with shared orbit/zoom controls. It records no progress;
champions wear P1's current cosmetics. Completion, a 25-note combo, 90% weighted
accuracy and a completed two-human battle earn shared achievements. All songs,
champions and gallery entries remain available without progression gates.

## Controls and settings

| Action | Player 1 | Player 2 |
| --- | --- | --- |
| Left / Down / Up / Right | A / S / W / D | Arrow keys |
| Pause | Esc or Space | Shared |
| Settings | F1 | Shared |

Mouse and independent touch contacts can also press the on-screen arrow pads.
Keys are rebindable through the framework's **Settings > Controls** tab.
Gamepad gameplay is not implemented; shared menu navigation still works.

**Settings > Game** persists preferred difficulty, solo mode, scroll speed
(0.5x-3x), audio offset (-200 to +200 ms), hit sounds, and background effects.
Chart, scroll and offset changes apply next song; sounds/background effects apply
live. A positive offset places the target moment later than the audible beat.
Reduced motion parks decorative animation while retaining essential arrow
movement; intense-effects settings suppress bursts and target flashes.
Pausing or opening Settings freezes the song and its clock.

## Set list

| Song | BPM | Length | Charts |
| --- | --- | --- | --- |
| Ritmo del Barrio | 130 | 3:00 | Beginner / Standard / Heavy |
| Poder Marabino | 180 | 2:30 | Standard / Heavy / Challenge |
| Flujo Valenciano | 110 | 3:20 | Beginner / Standard / Heavy |
| Leyenda de Fusión | 160 | 4:00 | Heavy / Challenge |
| Primer Paso | 100 | 1:00 | Beginner |

The original prototype referenced music and images that were never bundled.
This port preserves its synthesized-beat approach with finite, original
kick/hat/clap/melodic tracks generated in-engine. Champions, track credits, and
the championship legend are fictional; these are not recordings by the named
artists. No network downloads are required.

Judgements use the compensated audible playback clock: **Perfect <=22 ms**,
**Great <=64 ms**, **Good <=106 ms**, otherwise Miss. Base scores preserve the
running prototype's **100 / 80 / 50 / 0**, multiplied by
`1 + min(new_combo / 10, 2)` and rounded down. Wrong presses and overdue notes
break combo. Weighted accuracy includes wrong presses. Scroll speed changes
only presentation, never timing windows or tempo.

## Structure

| Path | Responsibility |
| --- | --- |
| `game.gd` | Auto-discovered `GameManifest`, theme, credits, songs, champions |
| `gameplay.tscn`, `gameplay.gd` | Inherited `GameShell` scene and native gameplay |
| `tuki_tuki_options.gd` | Constants-only tunables and rebindable actions |
| `data\tuki_data.gd` | Five songs, four champions, story, styles, lore |
| `rhythm\` | Seeded charts and node-free judgement/scoring |
| `audio\` | Finite synthesized PCM and pause-safe audible clock |
| `world\` | Shared original champion/venue meshes and pooled arrows/effects |
| `ui\` | Scrolling briefing and actual-model setup/store/gallery adapters |
| `intro.gd`, `intro.tscn` | Skippable, unscored, audio-clock-driven 3D opening |
| `assets\` | Game-owned logo |
| `assets\video\`, `tools\` | Native solo/local walkthroughs and real-input recording driver |
| `tests\` | Logic, audio, actual scene, and rendered layout checks |

Keep framework features in godot-base and game rules/assets here. There are no
dependencies on another game folder and no module-local autoloads.
The historical folder name stays unchanged; the catalog/export ID is `tuki_tuki`.

## Validate

Run from `godot-base` after importing the project. Integration endings exercise
real shared stats/save flow, so use a disposable `APPDATA`/user-data profile:

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://games/tuki-tuki_agents/tests/rhythm_test.gd -- --game=tuki_tuki
godot --headless --path . --script res://games/tuki-tuki_agents/tests/audio_test.gd -- --game=tuki_tuki
godot --headless --path . --script res://games/tuki-tuki_agents/tests/gameplay_test.gd -- --game=tuki_tuki
godot --path . --script res://games/tuki-tuki_agents/tests/stage_view_test.gd -- --game=tuki_tuki
```

Re-record both bundled Instructions walkthroughs from `godot-base` using the
shared Movie Maker/ffmpeg tool:

```powershell
pwsh tools\record_tutorials.ps1 -Godot godot -Games tuki_tuki
```

The last suite requires a graphics window; it checks real pixels, target framing,
feature models, intro layout, and physical touch sizes at landscape, portrait,
and ultrawide resolutions.
On Windows GUI-subsystem binaries, use `Start-Process -Wait -PassThru` and check
`.ExitCode`, as above. The parent README lists the shared framework suites, which
run with `--game=all`.
The gameplay suite also accepts `--expect-release` after `--` when run by
Godot with `--main-pack <export.pck>` and this test's absolute `--script` path. That
additionally checks the shipped catalog, feature branding, isolated saves,
walkthrough media, and exclusion of tools/tests.

The parent project includes **Windows - Tuki Tuki (standalone)** and
**Web - Tuki Tuki (standalone)** export presets with the `tuki_tuki` feature.
They isolate this game's save directory and omit other games and tests.
Web uses the non-threaded Compatibility template. Mobile hardware, audio-device
latency calibration, and human gameplay feel still require device/play testing.
