extends Control

## A skippable, scrolling native briefing preserves the prototype's story browser.

signal start_requested(difficulty: int, mode: int)
signal setup_requested
signal settings_requested

const Data = preload("res://games/tuki-tuki_agents/data/tuki_data.gd")
var _panel: PanelContainer
var _song_label: Label
var _notice: Label
var _difficulty: OptionButton
var _mode: OptionButton
var _section: OptionButton
var _page_title: Label
var _page_text: Label
var _page_number: Label
var _previous: Button
var _next: Button
var _start: Button
var _pages: Array[Dictionary] = []
var _page := 0
var _margin: MarginContainer
var _scroll: ScrollContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.03, 0.08, 0.94)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = PanelContainer.new()
	add_child(_panel)
	_margin = MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		_margin.add_theme_constant_override("margin_" + edge, 24)
	_panel.add_child(_margin)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_margin.add_child(_scroll)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 14)
	_scroll.add_child(layout)
	var title := _label("TUKI TUKI / THE STREETS CALL", 34)
	title.add_theme_color_override("font_color", Color("f6ce46"))
	layout.add_child(title)
	_song_label = _label("", 23)
	layout.add_child(_song_label)
	_mode = OptionButton.new()
	_mode.add_item("Solo Story", 0)
	_mode.add_item("Solo Practice", 1)
	_mode.custom_minimum_size.y = 54
	layout.add_child(_mode)
	_difficulty = OptionButton.new()
	_difficulty.custom_minimum_size.y = 54
	_difficulty.tooltip_text = "Choose one of this song's supported charts."
	layout.add_child(_difficulty)
	_notice = _label("", 19)
	layout.add_child(_notice)
	_section = OptionButton.new()
	for section in ["Story", "Culture & styles", "Meet the champions"]:
		_section.add_item(section)
	_section.custom_minimum_size.y = 52
	_section.item_selected.connect(_change_section)
	layout.add_child(_section)
	_page_title = _label("", 25)
	layout.add_child(_page_title)
	_page_text = _label("", 22)
	layout.add_child(_page_text)
	var navigation := HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 12)
	layout.add_child(navigation)
	_previous = _button("Previous", navigation)
	_previous.pressed.connect(_turn_page.bind(-1))
	_page_number = _label("", 19)
	_page_number.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	navigation.add_child(_page_number)
	_next = _button("Next", navigation)
	_next.pressed.connect(_turn_page.bind(1))
	_start = _button("Dance / Skip story", layout)
	_start.pressed.connect(_on_start)
	var setup := _button("Change song or champion", layout)
	setup.pressed.connect(func() -> void: setup_requested.emit())
	var settings := _button("Settings", layout)
	settings.pressed.connect(func() -> void: settings_requested.emit())
	get_viewport().size_changed.connect(_resize)
	_resize()


## Unsupported preferences are named explicitly before the player confirms a chart.
func configure(song: Dictionary, preferred: int, mode: int, multiplayer: bool) -> void:
	_song_label.text = "%s\n%s / %s / %d BPM\n%s" % [
		song["title"], song["artist"], song["genre"], song["bpm"], song["description"],
	]
	_mode.visible = not multiplayer
	_mode.select(mode)
	_difficulty.clear()
	for index in song["difficulties"].size():
		var difficulty := int(song["difficulties"][index])
		_difficulty.add_item("%s / level %d" % [
			Data.DIFFICULTIES[difficulty], int(song["levels"][index]),
		], difficulty)
	var selected := _difficulty.get_item_index(preferred)
	_notice.text = (
		"Your preferred chart is unavailable for this song. Confirm a supported difficulty below."
		if selected < 0 else "Timing: Perfect 22 ms / Great 64 ms / Good 106 ms."
	)
	_difficulty.select(maxi(selected, 0))
	_start.text = "Start local battle" if multiplayer else "Dance / Skip story"
	_section.select(0 if mode == 0 else 1)
	_change_section(_section.selected)
	show()
	_focus_initial_control.call_deferred()


func _focus_initial_control() -> void:
	(_mode if _mode.visible else _difficulty).grab_focus()
	_scroll.scroll_vertical = 0


func _keep_focus_visible() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and _scroll.is_ancestor_of(focused):
		_scroll.ensure_control_visible(focused)


func _change_section(section: int) -> void:
	_pages.clear()
	_page = 0
	if section == 0:
		for chapter in Data.STORY:
			for line: Array in chapter["dialogue"]:
				_pages.append({
					"title": "%s / %s" % [chapter["title"], line[0]],
					"text": line[1],
				})
	elif section == 1:
		for style in Data.STYLES:
			_pages.append({
				"title": "%s / %s" % [style["title"], style["range"]], "text": style["text"],
			})
		_pages.append({"title": "The championship legend", "text": Data.LORE})
	else:
		for character in Data.CHARACTERS:
			_pages.append({
				"title": "%s / %s" % [character["title"], character["hometown"]],
				"text": "%s\n\n%s" % [character["style"], character["backstory"]],
			})
	_show_page()


func _turn_page(direction: int) -> void:
	_page = clampi(_page + direction, 0, _pages.size() - 1)
	_show_page()


func _show_page() -> void:
	_page_title.text = str(_pages[_page]["title"])
	_page_text.text = str(_pages[_page]["text"])
	_page_number.text = "%d / %d" % [_page + 1, _pages.size()]
	_previous.disabled = _page == 0
	_next.disabled = _page == _pages.size() - 1


func _on_start() -> void:
	start_requested.emit(_difficulty.get_selected_id(), _mode.get_selected_id())


func _resize() -> void:
	var available := get_viewport_rect().size
	var pixels := available.x / maxf(1.0, get_window().size.x)
	for control: Control in _panel.find_children("*", "Control", true, false):
		if control is Label:
			var base := int(control.get_meta("base_font_size", 22))
			control.add_theme_font_size_override("font_size", roundi(base * pixels))
		elif control is BaseButton:
			control.add_theme_font_size_override("font_size", roundi(20 * pixels))
			control.custom_minimum_size.y = 50 * pixels
	for edge in ["left", "right", "top", "bottom"]:
		_margin.add_theme_constant_override("margin_" + edge, roundi(20 * pixels))
	_panel.size = Vector2(minf(920 * pixels, available.x - 32 * pixels),
		maxf(160, available.y - 64 * pixels))
	_panel.position = (available - _panel.size) * 0.5
	_keep_focus_visible.call_deferred()


static func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.set_meta("base_font_size", font_size)
	return label


static func _button(text: String, parent: Node) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 54
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(button)
	return button
