/// Catalogues of the customisable surface of an AO2 theme — every widget the
/// client positions, every colour and font key it reads, and the image assets
/// users most often replace. Used by the Theme Maker to offer one-tap "add"
/// pickers so you can customise *anything* without memorising key names. None of
/// these are required — themes can contain any key/file, and the editor lets you
/// add arbitrary names too. Grounded in the real AO2 client (the
/// `set_size_and_pos` widget list, `get_color`/`get_design_element` reads) and
/// real themes.
library;

/// A known image asset slot.
class ThemeImageSlot {
  const ThemeImageSlot(this.fileName, this.category, this.hint);
  final String fileName;
  final String category;
  final String hint;
}

/// A known positioned widget (`name = x, y, w, h`) with a sensible default size.
class ThemeWidgetDef {
  const ThemeWidgetDef(this.name, this.category, this.hint,
      {this.w = 100, this.h = 30});
  final String name;
  final String category;
  final String hint;
  final int w;
  final int h;
}

/// The full courtroom widget catalogue (drawn from the client's `set_size_and_pos`
/// calls + design.ini), grouped by [ThemeWidgetDef.category]. Add any of these in
/// the Layout tab; the Arrange tab lets you drag them into place.
const List<ThemeWidgetDef> kCourtroomWidgets = <ThemeWidgetDef>[
  // Core viewport + chat.
  ThemeWidgetDef('courtroom', 'Core', 'The whole window (sets theme size)', w: 1280, h: 720),
  ThemeWidgetDef('viewport', 'Core', 'The scene/character viewport', w: 1280, h: 480),
  ThemeWidgetDef('ao2_chatbox', 'Core', 'The IC chat box', w: 1280, h: 100),
  ThemeWidgetDef('showname', 'Core', 'Speaker name label', w: 240, h: 26),
  ThemeWidgetDef('message', 'Core', 'IC message text', w: 1200, h: 60),
  ThemeWidgetDef('chat_arrow', 'Core', 'Next-message arrow', w: 24, h: 24),

  // IC log + entry.
  ThemeWidgetDef('ic_chatlog', 'IC', 'IC chat log', w: 300, h: 320),
  ThemeWidgetDef('ao2_ic_chat_name', 'IC', 'IC name entry', w: 120, h: 22),
  ThemeWidgetDef('ao2_ic_chat_message', 'IC', 'IC message entry', w: 440, h: 22),

  // OOC.
  ThemeWidgetDef('ms_chatlog', 'OOC', 'Master-server (OOC) log', w: 213, h: 287),
  ThemeWidgetDef('server_chatlog', 'OOC', 'Server (OOC) log', w: 213, h: 287),
  ThemeWidgetDef('ooc_chat_message', 'OOC', 'OOC message entry', w: 295, h: 20),
  ThemeWidgetDef('ooc_chat_name', 'OOC', 'OOC name entry', w: 107, h: 20),
  ThemeWidgetDef('ooc_toggle', 'OOC', 'Server/master toggle', w: 134, h: 21),
  ThemeWidgetDef('casing_button', 'OOC', 'Casing announce', w: 56, h: 21),

  // Music + area.
  ThemeWidgetDef('music_list', 'Music/Area', 'Music list', w: 295, h: 308),
  ThemeWidgetDef('area_list', 'Music/Area', 'Area list', w: 295, h: 308),
  ThemeWidgetDef('music_search', 'Music/Area', 'Music search box', w: 296, h: 21),
  ThemeWidgetDef('music_display', 'Music/Area', 'Now-playing display', w: 275, h: 26),
  ThemeWidgetDef('music_name', 'Music/Area', 'Scrolling track name', w: 266, h: 26),
  ThemeWidgetDef('switch_area_music', 'Music/Area', 'Area/Music switch', w: 32, h: 32),
  ThemeWidgetDef('area_password', 'Music/Area', 'Area password box', w: 224, h: 23),

  // Pairing.
  ThemeWidgetDef('pair_button', 'Pairing', 'Pairing toggle', w: 50, h: 50),
  ThemeWidgetDef('pair_list', 'Pairing', 'Pairing char list', w: 213, h: 290),
  ThemeWidgetDef('pair_offset_spinbox', 'Pairing', 'Horizontal offset', w: 70, h: 22),
  ThemeWidgetDef('pair_vert_offset_spinbox', 'Pairing', 'Vertical offset', w: 70, h: 22),
  ThemeWidgetDef('pair_order_dropdown', 'Pairing', 'Front/back order', w: 70, h: 22),

  // Mute.
  ThemeWidgetDef('mute_button', 'Mute', 'Mute toggle', w: 50, h: 50),
  ThemeWidgetDef('mute_list', 'Mute', 'Muted-char list', w: 213, h: 290),

  // Emote selector.
  ThemeWidgetDef('emotes', 'Emotes', 'Emote button grid', w: 350, h: 240),
  ThemeWidgetDef('emote_left', 'Emotes', 'Previous emote page', w: 30, h: 30),
  ThemeWidgetDef('emote_right', 'Emotes', 'Next emote page', w: 30, h: 30),

  // Dropdowns + text colour + position.
  ThemeWidgetDef('iniswap_dropdown', 'Dropdowns', 'Iniswap select', w: 60, h: 20),
  ThemeWidgetDef('iniswap_remove', 'Dropdowns', 'Remove iniswap', w: 20, h: 20),
  ThemeWidgetDef('emote_dropdown', 'Dropdowns', 'Emote select', w: 105, h: 20),
  ThemeWidgetDef('sfx_dropdown', 'Dropdowns', 'SFX select', w: 76, h: 20),
  ThemeWidgetDef('sfx_remove', 'Dropdowns', 'Remove SFX', w: 20, h: 20),
  ThemeWidgetDef('effects_dropdown', 'Dropdowns', 'Effect select', w: 92, h: 20),
  ThemeWidgetDef('text_color', 'Dropdowns', 'Text-colour select', w: 69, h: 20),
  ThemeWidgetDef('pos_dropdown', 'Dropdowns', 'Position select', w: 40, h: 20),
  ThemeWidgetDef('pos_remove', 'Dropdowns', 'Reset position', w: 20, h: 20),

  // Interjections.
  ThemeWidgetDef('hold_it', 'Interjections', 'Hold It button', w: 130, h: 40),
  ThemeWidgetDef('objection', 'Interjections', 'Objection button', w: 130, h: 40),
  ThemeWidgetDef('take_that', 'Interjections', 'Take That button', w: 130, h: 40),
  ThemeWidgetDef('custom_objection', 'Interjections', 'Custom shout button', w: 130, h: 40),

  // Judge controls + verdict.
  ThemeWidgetDef('witness_testimony', 'Judge', 'Witness Testimony', w: 40, h: 40),
  ThemeWidgetDef('cross_examination', 'Judge', 'Cross Examination', w: 40, h: 40),
  ThemeWidgetDef('not_guilty', 'Judge', 'Not Guilty verdict', w: 40, h: 40),
  ThemeWidgetDef('guilty', 'Judge', 'Guilty verdict', w: 40, h: 40),
  ThemeWidgetDef('defense_plus', 'Judge', 'Defense +', w: 20, h: 20),
  ThemeWidgetDef('defense_minus', 'Judge', 'Defense −', w: 20, h: 20),
  ThemeWidgetDef('prosecution_plus', 'Judge', 'Prosecution +', w: 20, h: 20),
  ThemeWidgetDef('prosecution_minus', 'Judge', 'Prosecution −', w: 20, h: 20),

  // Penalty bars.
  ThemeWidgetDef('defense_bar', 'Penalty', 'Defense health bar', w: 92, h: 15),
  ThemeWidgetDef('prosecution_bar', 'Penalty', 'Prosecution health bar', w: 92, h: 15),

  // Misc buttons.
  ThemeWidgetDef('change_character', 'Misc', 'Change character', w: 150, h: 30),
  ThemeWidgetDef('reload_theme', 'Misc', 'Reload theme', w: 150, h: 30),
  ThemeWidgetDef('call_mod', 'Misc', 'Call mod', w: 150, h: 30),
  ThemeWidgetDef('settings', 'Misc', 'Settings', w: 70, h: 70),
  ThemeWidgetDef('realization', 'Misc', 'Realization flash', w: 50, h: 50),
  ThemeWidgetDef('screenshake', 'Misc', 'Screenshake', w: 50, h: 50),

  // Checkboxes.
  ThemeWidgetDef('flip', 'Checkboxes', 'Flip sprite', w: 36, h: 21),
  ThemeWidgetDef('additive', 'Checkboxes', 'Additive text', w: 60, h: 21),
  ThemeWidgetDef('showname_enable', 'Checkboxes', 'Show name', w: 78, h: 21),
  ThemeWidgetDef('pre', 'Checkboxes', 'Play preanim', w: 59, h: 21),
  ThemeWidgetDef('pre_no_interrupt', 'Checkboxes', 'Don\'t interrupt', w: 80, h: 21),
  ThemeWidgetDef('slide_enable', 'Checkboxes', 'Slide transitions', w: 60, h: 21),
  ThemeWidgetDef('immediate', 'Checkboxes', 'Immediate text', w: 70, h: 21),
  ThemeWidgetDef('casing', 'Checkboxes', 'Casing', w: 53, h: 21),
  ThemeWidgetDef('guard', 'Checkboxes', 'Guard', w: 61, h: 21),

  // Sound sliders.
  ThemeWidgetDef('music_label', 'Sound', 'Music label', w: 40, h: 20),
  ThemeWidgetDef('sfx_label', 'Sound', 'SFX label', w: 40, h: 20),
  ThemeWidgetDef('blip_label', 'Sound', 'Blip label', w: 40, h: 20),
  ThemeWidgetDef('music_slider', 'Sound', 'Music volume', w: 143, h: 12),
  ThemeWidgetDef('sfx_slider', 'Sound', 'SFX volume', w: 143, h: 12),
  ThemeWidgetDef('blip_slider', 'Sound', 'Blip volume', w: 143, h: 12),

  // Evidence.
  ThemeWidgetDef('evidence_button', 'Evidence', 'Open evidence', w: 203, h: 28),
  ThemeWidgetDef('evidence_background', 'Evidence', 'Evidence panel', w: 512, h: 384),
  ThemeWidgetDef('evidence_name', 'Evidence', 'Evidence name', w: 304, h: 39),
  ThemeWidgetDef('evidence_buttons', 'Evidence', 'Evidence grid', w: 430, h: 80),
  ThemeWidgetDef('evidence_description', 'Evidence', 'Description', w: 315, h: 125),
  ThemeWidgetDef('evidence_left', 'Evidence', 'Prev page', w: 20, h: 20),
  ThemeWidgetDef('evidence_right', 'Evidence', 'Next page', w: 20, h: 20),
  ThemeWidgetDef('evidence_present', 'Evidence', 'Present', w: 79, h: 16),
  ThemeWidgetDef('left_evidence_icon', 'Evidence', 'Left shown evidence', w: 100, h: 100),
  ThemeWidgetDef('right_evidence_icon', 'Evidence', 'Right shown evidence', w: 100, h: 100),

  // Character select.
  ThemeWidgetDef('char_select', 'Char select', 'Char-select screen', w: 1280, h: 720),
  ThemeWidgetDef('char_buttons', 'Char select', 'Character grid', w: 700, h: 600),
  ThemeWidgetDef('char_select_left', 'Char select', 'Prev page', w: 25, h: 25),
  ThemeWidgetDef('char_select_right', 'Char select', 'Next page', w: 25, h: 25),
  ThemeWidgetDef('char_search', 'Char select', 'Search', w: 120, h: 22),
  ThemeWidgetDef('back_to_lobby', 'Char select', 'Back to lobby', w: 91, h: 23),
  ThemeWidgetDef('spectator', 'Char select', 'Spectate', w: 80, h: 23),

  // Timers (clock_0 universal, 1/3 def, 2/4 pro).
  ThemeWidgetDef('clock_0', 'Timers', 'Universal timer', w: 71, h: 17),
  ThemeWidgetDef('clock_1', 'Timers', 'Defense timer', w: 71, h: 17),
  ThemeWidgetDef('clock_2', 'Timers', 'Prosecution timer', w: 71, h: 17),
  ThemeWidgetDef('clock_3', 'Timers', 'Defense timer 2', w: 71, h: 17),
  ThemeWidgetDef('clock_4', 'Timers', 'Prosecution timer 2', w: 71, h: 17),
];

/// Known design-ini colour keys.
const List<String> kThemeColorKeys = <String>[
  'ooc_default_color',
  'ooc_server_color',
  'found_song_color',
  'missing_song_color',
  'area_free_color',
  'area_lfp_color',
  'area_casing_color',
  'area_recess_color',
  'area_rp_color',
  'area_gaming_color',
  'area_locked_color',
];

/// Known font widget keys (each gets size/font/colour/bold/sharp).
const List<String> kFontWidgets = <String>[
  'showname',
  'message',
  'ic_chatlog',
  'ms_chatlog',
  'server_chatlog',
  'music_list',
  'music_name',
  'area_list',
  'evidence_name',
  'evidence_image_name',
  'evidence_description',
  'clock_0',
  'clock_1',
  'clock_2',
  'clock_3',
  'clock_4',
];

/// Known non-xywh design scalars (alignment, spacing, flags…). Value formats in
/// the hint. Editable in the Theme Maker's Style → Design options.
const List<({String key, String hint})> kThemeScalars = <({String key, String hint})>[
  (key: 'showname_align', hint: 'left / center / right'),
  (key: 'showname_extra_width', hint: 'extra px past the name'),
  (key: 'music_list_animated', hint: '1 = animated music list'),
  (key: 'music_list_indent', hint: 'indent px'),
  (key: 'chatbox_always_show', hint: '1 = always show chatbox'),
  (key: 'emote_button_spacing', hint: 'x, y px between emote buttons'),
  (key: 'char_button_spacing', hint: 'x, y px between char buttons'),
  (key: 'evidence_button_spacing', hint: 'x, y px between evidence'),
  (key: 'evidence_button_size', hint: 'w, h px'),
  (key: 'effects_icon_size', hint: 'w, h px'),
];

/// Curated image-asset slots, grouped by category. Built (not const) so the
/// penalty-bar series can be generated.
List<ThemeImageSlot> get kThemeImageSlots {
  final List<ThemeImageSlot> out = <ThemeImageSlot>[
    // Shout bubbles (animated).
    const ThemeImageSlot('holdit_bubble.webp', 'Shouts', '“HOLD IT!” animation'),
    const ThemeImageSlot('objection_bubble.webp', 'Shouts', '“OBJECTION!” animation'),
    const ThemeImageSlot('takethat_bubble.webp', 'Shouts', '“TAKE THAT!” animation'),
    const ThemeImageSlot('custom.gif', 'Shouts', 'Custom shout animation'),
    const ThemeImageSlot('witnesstestimony_bubble.webp', 'Shouts', 'Witness Testimony banner'),
    const ThemeImageSlot('crossexamination_bubble.webp', 'Shouts', 'Cross Examination banner'),
    const ThemeImageSlot('guilty_bubble.webp', 'Shouts', 'Guilty verdict'),
    const ThemeImageSlot('notguilty_bubble.webp', 'Shouts', 'Not Guilty verdict'),

    // Buttons.
    const ThemeImageSlot('holdit.png', 'Buttons', 'Hold It button'),
    const ThemeImageSlot('objection.png', 'Buttons', 'Objection button'),
    const ThemeImageSlot('takethat.png', 'Buttons', 'Take That button'),
    const ThemeImageSlot('custom.png', 'Buttons', 'Custom shout button'),
    const ThemeImageSlot('witnesstestimony.png', 'Buttons', 'Witness Testimony'),
    const ThemeImageSlot('crossexamination.png', 'Buttons', 'Cross Examination'),
    const ThemeImageSlot('guilty.png', 'Buttons', 'Guilty button'),
    const ThemeImageSlot('notguilty.png', 'Buttons', 'Not Guilty button'),
    const ThemeImageSlot('change_character.png', 'Buttons', 'Change character'),
    const ThemeImageSlot('reload_theme.png', 'Buttons', 'Reload theme'),
    const ThemeImageSlot('call_mod.png', 'Buttons', 'Call mod'),
    const ThemeImageSlot('settings.png', 'Buttons', 'Settings cog'),
    const ThemeImageSlot('pair_button.png', 'Buttons', 'Pairing toggle'),
    const ThemeImageSlot('mute.png', 'Buttons', 'Mute toggle'),
    const ThemeImageSlot('evidence_button.png', 'Buttons', 'Evidence toggle'),
    const ThemeImageSlot('switch_area_music.png', 'Buttons', 'Area/Music switch'),
    const ThemeImageSlot('defminus.png', 'Buttons', 'Defense −'),
    const ThemeImageSlot('defplus.png', 'Buttons', 'Defense +'),
    const ThemeImageSlot('arrow_left.png', 'Buttons', 'Emote page left'),
    const ThemeImageSlot('arrow_right.png', 'Buttons', 'Emote page right'),

    // Chat.
    const ThemeImageSlot('chatbox.png', 'Chat', 'IC chat box frame'),
    const ThemeImageSlot('chat_arrow.webp', 'Chat', 'Next-message arrow'),
    const ThemeImageSlot('chatblank.png', 'Chat', 'Blank chat box'),
    const ThemeImageSlot('chatmed.png', 'Chat', 'Medium chat box'),
    const ThemeImageSlot('chatbig.png', 'Chat', 'Large chat box'),

    // Backgrounds.
    const ThemeImageSlot('charselect_background.png', 'Backgrounds', 'Character select'),
    const ThemeImageSlot('loadingbackground.png', 'Backgrounds', 'Loading screen'),
    const ThemeImageSlot('lobbybackground.png', 'Backgrounds', 'Server lobby'),

    // Character select.
    const ThemeImageSlot('char_selector.png', 'Char select', 'Selected highlight'),
    const ThemeImageSlot('char_taken.png', 'Char select', 'Taken overlay'),
    const ThemeImageSlot('char_passworded.png', 'Char select', 'Passworded overlay'),

    // Evidence.
    const ThemeImageSlot('evidence_background.png', 'Evidence', 'Evidence panel'),
    const ThemeImageSlot('evidence_selector.png', 'Evidence', 'Selected highlight'),
    const ThemeImageSlot('evidence_overlay.png', 'Evidence', 'Evidence overlay'),

    // Selectors.
    const ThemeImageSlot('emote_selected.png', 'Selectors', 'Selected emote'),
    const ThemeImageSlot('evidence_selected.png', 'Selectors', 'Selected evidence'),
  ];
  // Penalty bars: defensebar0..10 and prosecutionbar0..10.
  for (int i = 0; i <= 10; i++) {
    out.add(ThemeImageSlot('defensebar$i.png', 'Penalty bars', 'Defense bar @ $i'));
  }
  for (int i = 0; i <= 10; i++) {
    out.add(ThemeImageSlot('prosecutionbar$i.png', 'Penalty bars', 'Prosecution bar @ $i'));
  }
  return out;
}

/// Distinct image categories in catalogue order.
List<String> get kThemeImageCategories {
  final List<String> out = <String>[];
  for (final ThemeImageSlot s in kThemeImageSlots) {
    if (!out.contains(s.category)) out.add(s.category);
  }
  return out;
}
