import '../animation/anim_engine.dart';
import '../imaging/color_ops.dart';

/// A named colour palette (for swatches, gradient-map building, palette swaps).
class NamedPalette {
  const NamedPalette(this.name, this.category, this.colors);
  final String name;
  final String category;
  final List<int> colors; // ARGB
}

/// A named multi-stop gradient (for the gradient-map op).
class NamedGradient {
  const NamedGradient(this.name, this.stops);
  final String name;
  final List<int> stops; // ARGB, evenly spaced
}

/// A ready-to-apply animation: a stack of recipes plus frame/fps defaults.
class AnimPreset {
  const AnimPreset(this.name, this.category, this.recipes,
      {this.frames = 12, this.fps = 12});
  final String name;
  final String category;
  final List<AnimRecipe> recipes;
  final int frames;
  final int fps;
}

/// A set of common emote names to scaffold a character quickly.
class EmoteNameSet {
  const EmoteNameSet(this.name, this.names);
  final String name;
  final List<String> names;
}

/// The built-in preset library. Combined with plugin packs (see plugins/), this
/// is the "hundreds of presets" surface. Most are generated so the catalogue is
/// genuinely large and uniform; the rest are hand-curated favourites.
class PresetLibrary {
  PresetLibrary._();

  // ---- Colour pipelines -----------------------------------------------------

  static final List<OpPipeline> colorPresets = <OpPipeline>[
    ..._curatedColorPresets(),
    ..._hueWheelPresets(),
    ..._recolorPresets(),
    ..._tonePresets(),
    ..._duotonePresets(),
  ];

  static List<OpPipeline> _curatedColorPresets() => <OpPipeline>[
        OpPipeline('Grayscale', <ColorOp>[ColorOp('grayscale')], category: 'Classic'),
        OpPipeline('Invert', <ColorOp>[ColorOp('invert')], category: 'Classic'),
        OpPipeline('Sepia', <ColorOp>[ColorOp('sepia')], category: 'Classic'),
        OpPipeline('Noir', <ColorOp>[
          ColorOp('grayscale'),
          ColorOp('contrast', nums: <String, double>{'amount': 1.35}),
        ], category: 'Classic'),
        OpPipeline('High Contrast', <ColorOp>[
          ColorOp('contrast', nums: <String, double>{'amount': 1.5}),
        ], category: 'Classic'),
        OpPipeline('Faded', <ColorOp>[
          ColorOp('contrast', nums: <String, double>{'amount': 0.8}),
          ColorOp('brightness', nums: <String, double>{'amount': 1.1}),
        ], category: 'Classic'),
        OpPipeline('Vaporwave', <ColorOp>[
          ColorOp('gradientMap', nums: <String, double>{
            'pos0': 0, 'pos1': 0.5, 'pos2': 1, 'strength': 0.85,
          }, strs: <String, String>{
            'stop0': '#FF2B0F54', 'stop1': '#FFFF4D9D', 'stop2': '#FF4DE2FF',
          }),
        ], category: 'Aesthetic'),
        OpPipeline('Synthwave Glow', <ColorOp>[
          ColorOp('saturation', nums: <String, double>{'amount': 1.3}),
          ColorOp('tint', nums: <String, double>{'amount': 0.2},
              strs: <String, String>{'color': '#FFFF2D95'}),
        ], category: 'Aesthetic'),
        OpPipeline('Golden', <ColorOp>[
          ColorOp('colorize', nums: <String, double>{'hue': 45, 'saturation': 0.85, 'strength': 0.9}),
        ], category: 'Aesthetic'),
        OpPipeline('Frostbite', <ColorOp>[
          ColorOp('colorize', nums: <String, double>{'hue': 200, 'saturation': 0.6, 'strength': 0.8}),
          ColorOp('brightness', nums: <String, double>{'amount': 1.05}),
        ], category: 'Aesthetic'),
        OpPipeline('Toxic', <ColorOp>[
          ColorOp('colorize', nums: <String, double>{'hue': 95, 'saturation': 1.0, 'strength': 0.9}),
        ], category: 'Aesthetic'),
        OpPipeline('Posterize 4', <ColorOp>[
          ColorOp('posterize', nums: <String, double>{'levels': 4}),
        ], category: 'Stylize'),
        OpPipeline('Comic Ink', <ColorOp>[
          ColorOp('posterize', nums: <String, double>{'levels': 5}),
          ColorOp('contrast', nums: <String, double>{'amount': 1.2}),
        ], category: 'Stylize'),
        OpPipeline('Silhouette', <ColorOp>[
          ColorOp('solidColor', strs: <String, String>{'color': '#FF000000'}),
        ], category: 'Stylize'),
        OpPipeline('Ghost', <ColorOp>[
          ColorOp('solidColor', strs: <String, String>{'color': '#FFFFFFFF'}),
          ColorOp('opacity', nums: <String, double>{'amount': 0.6}),
        ], category: 'Stylize'),
        OpPipeline('CRT', <ColorOp>[
          ColorOp('scanlines', nums: <String, double>{'gap': 2, 'amount': 0.35}),
          ColorOp('chromaShift', nums: <String, double>{'offset': 2}),
          ColorOp('vignette', nums: <String, double>{'amount': 0.5, 'feather': 0.6}),
        ], category: 'Stylize'),
        OpPipeline('Film Grain', <ColorOp>[
          ColorOp('noise', nums: <String, double>{'amount': 22, 'mono': 1}),
        ], category: 'Stylize'),
        OpPipeline('Vignette', <ColorOp>[
          ColorOp('vignette', nums: <String, double>{'amount': 0.6, 'feather': 0.5}),
        ], category: 'Stylize'),
        OpPipeline('Pixelate', <ColorOp>[
          ColorOp('pixelate', nums: <String, double>{'size': 6}),
        ], category: 'Stylize'),
        OpPipeline('Teal & Orange', <ColorOp>[
          ColorOp('splitTone', nums: <String, double>{'amount': 0.45},
              strs: <String, String>{'shadow': '#FF0E3A4A', 'highlight': '#FFF7A24B'}),
        ], category: 'Aesthetic'),
        OpPipeline('Glitchy', <ColorOp>[
          ColorOp('chromaShift', nums: <String, double>{'offset': 4}),
          ColorOp('noise', nums: <String, double>{'amount': 14, 'mono': 0}),
        ], category: 'Stylize'),
        OpPipeline('Outline', <ColorOp>[
          ColorOp('outline', nums: <String, double>{'size': 2},
              strs: <String, String>{'color': '#FF000000'}),
        ], category: 'Effects'),
        OpPipeline('White Outline', <ColorOp>[
          ColorOp('outline', nums: <String, double>{'size': 3},
              strs: <String, String>{'color': '#FFFFFFFF'}),
        ], category: 'Effects'),
        OpPipeline('Outer Glow', <ColorOp>[
          ColorOp('glow', nums: <String, double>{'radius': 6, 'strength': 1.0},
              strs: <String, String>{'color': '#FF8AD0FF'}),
        ], category: 'Effects'),
        OpPipeline('Drop Shadow', <ColorOp>[
          ColorOp('dropShadow', nums: <String, double>{'dx': 4, 'dy': 4, 'opacity': 0.5},
              strs: <String, String>{'color': '#FF000000'}),
        ], category: 'Effects'),
        OpPipeline('Sharpen', <ColorOp>[
          ColorOp('sharpen', nums: <String, double>{'amount': 1.0}),
        ], category: 'Effects'),
        OpPipeline('Soft Blur', <ColorOp>[
          ColorOp('blur', nums: <String, double>{'radius': 2}),
        ], category: 'Effects'),
        OpPipeline('Solarize', <ColorOp>[
          ColorOp('solarize', nums: <String, double>{'threshold': 128}),
        ], category: 'Stylize'),
        OpPipeline('Dither', <ColorOp>[
          ColorOp('dither', nums: <String, double>{'levels': 3}),
        ], category: 'Stylize'),
        OpPipeline('Cross Process', <ColorOp>[
          ColorOp('crossProcess', nums: <String, double>{'strength': 0.9}),
        ], category: 'Aesthetic'),
        OpPipeline('Bleach Bypass', <ColorOp>[
          ColorOp('bleachBypass', nums: <String, double>{'strength': 0.85}),
        ], category: 'Aesthetic'),
        OpPipeline('Sunbeam Wash', <ColorOp>[
          ColorOp('gradientTint', nums: <String, double>{'angle': 60, 'strength': 0.4},
              strs: <String, String>{'color0': '#FFFFE9A8', 'color1': '#FF5A78C8'}),
        ], category: 'Aesthetic'),
      ];

  /// 24 evenly-spaced hue rotations.
  static List<OpPipeline> _hueWheelPresets() => <OpPipeline>[
        for (int deg = 15; deg < 360; deg += 15)
          OpPipeline('Hue +$deg°',
              <ColorOp>[ColorOp('hueShift', nums: <String, double>{'degrees': deg.toDouble()})],
              category: 'Hue Wheel'),
      ];

  /// "Make it <colour>" recolours that preserve shading (the OC-maker staple).
  static List<OpPipeline> _recolorPresets() {
    const Map<String, double> hues = <String, double>{
      'Red': 0, 'Crimson': 350, 'Orange': 30, 'Amber': 45, 'Yellow': 55,
      'Lime': 90, 'Green': 120, 'Emerald': 150, 'Teal': 175, 'Cyan': 190,
      'Sky': 205, 'Blue': 220, 'Indigo': 250, 'Violet': 275, 'Purple': 290,
      'Magenta': 310, 'Pink': 330, 'Rose': 340,
    };
    return <OpPipeline>[
      for (final MapEntry<String, double> e in hues.entries)
        OpPipeline('Make it ${e.key}', <ColorOp>[
          ColorOp('colorize',
              nums: <String, double>{'hue': e.value, 'saturation': 0.8, 'strength': 0.95}),
        ], category: 'Recolour'),
    ];
  }

  static List<OpPipeline> _tonePresets() => <OpPipeline>[
        for (final double m in <double>[0.6, 0.8, 1.2, 1.4, 1.6])
          OpPipeline('Brightness ${(m * 100).round()}%',
              <ColorOp>[ColorOp('brightness', nums: <String, double>{'amount': m})],
              category: 'Tone'),
        for (final double m in <double>[0.6, 0.8, 1.2, 1.4])
          OpPipeline('Saturation ${(m * 100).round()}%',
              <ColorOp>[ColorOp('saturation', nums: <String, double>{'amount': m})],
              category: 'Tone'),
        for (final double s in <double>[-1, -0.5, 0.5, 1])
          OpPipeline('Warmth ${s > 0 ? '+' : ''}${(s * 100).round()}',
              <ColorOp>[ColorOp('temperature', nums: <String, double>{'amount': s})],
              category: 'Tone'),
      ];

  static List<OpPipeline> _duotonePresets() {
    const List<List<String>> pairs = <List<String>>[
      <String>['#FF1B1B3A', '#FFFF715B', 'Sunset'],
      <String>['#FF0D1B2A', '#FF77B6EA', 'Ocean'],
      <String>['#FF1A1A1A', '#FFE63946', 'Crimson Noir'],
      <String>['#FF2D132C', '#FFEE4540', 'Berry'],
      <String>['#FF003049', '#FFFCBF49', 'Gold Rush'],
      <String>['#FF1B4332', '#FF95D5B2', 'Forest'],
    ];
    return <OpPipeline>[
      for (final List<String> p in pairs)
        OpPipeline('Duotone ${p[2]}', <ColorOp>[
          ColorOp('duotone', strs: <String, String>{'shadow': p[0], 'highlight': p[1]}),
        ], category: 'Duotone'),
    ];
  }

  // ---- Palettes -------------------------------------------------------------

  static const List<NamedPalette> palettes = <NamedPalette>[
    NamedPalette('Game Boy', 'Retro', <int>[
      0xFF0F380F, 0xFF306230, 0xFF8BAC0F, 0xFF9BBC0F,
    ]),
    NamedPalette('PICO-8', 'Retro', <int>[
      0xFF000000, 0xFF1D2B53, 0xFF7E2553, 0xFF008751, 0xFFAB5236, 0xFF5F574F,
      0xFFC2C3C7, 0xFFFFF1E8, 0xFFFF004D, 0xFFFFA300, 0xFFFFEC27, 0xFF00E436,
      0xFF29ADFF, 0xFF83769C, 0xFFFF77A8, 0xFFFFCCAA,
    ]),
    NamedPalette('NES', 'Retro', <int>[
      0xFF7C7C7C, 0xFF0000FC, 0xFF0000BC, 0xFF4428BC, 0xFF940084, 0xFFA80020,
      0xFFA81000, 0xFF881400, 0xFF503000, 0xFF007800, 0xFF006800, 0xFF005800,
    ]),
    NamedPalette('Pastel Dream', 'Soft', <int>[
      0xFFFFADAD, 0xFFFFD6A5, 0xFFFDFFB6, 0xFFCAFFBF, 0xFF9BF6FF, 0xFFA0C4FF,
      0xFFBDB2FF, 0xFFFFC6FF,
    ]),
    NamedPalette('Sunset', 'Warm', <int>[
      0xFF355070, 0xFF6D597A, 0xFFB56576, 0xFFE56B6F, 0xFFEAAC8B,
    ]),
    NamedPalette('Forest', 'Cool', <int>[
      0xFF081C15, 0xFF1B4332, 0xFF2D6A4F, 0xFF40916C, 0xFF74C69D, 0xFFB7E4C7,
    ]),
    NamedPalette('Grayscale 8', 'Neutral', <int>[
      0xFF000000, 0xFF242424, 0xFF484848, 0xFF6C6C6C, 0xFF909090, 0xFFB4B4B4,
      0xFFD8D8D8, 0xFFFFFFFF,
    ]),
    NamedPalette('Skin Tones', 'Character', <int>[
      0xFFFFE0BD, 0xFFFFCD94, 0xFFEAC086, 0xFFC68642, 0xFF8D5524, 0xFF5C3A21,
    ]),
    NamedPalette('Hair Colors', 'Character', <int>[
      0xFF1C1C1C, 0xFF3B2417, 0xFF6A4E42, 0xFFB08D57, 0xFFE6C200, 0xFFC0392B,
      0xFF2980B9, 0xFFE91E63, 0xFFECF0F1,
    ]),
    NamedPalette('Neon', 'Vivid', <int>[
      0xFFFF073A, 0xFFFF7F00, 0xFFFFFF00, 0xFF00FF00, 0xFF00FFFF, 0xFF0080FF,
      0xFFB400FF, 0xFFFF00FF,
    ]),
  ];

  // ---- Gradients ------------------------------------------------------------

  static const List<NamedGradient> gradients = <NamedGradient>[
    NamedGradient('Fire', <int>[0xFF000000, 0xFF7A1F00, 0xFFFF5A00, 0xFFFFD000, 0xFFFFFFC0]),
    NamedGradient('Ice', <int>[0xFF001B3A, 0xFF0066AA, 0xFF66CCFF, 0xFFE8FBFF]),
    NamedGradient('Toxic', <int>[0xFF071A00, 0xFF2E7D00, 0xFF8FE000, 0xFFE8FFB0]),
    NamedGradient('Royal', <int>[0xFF1A0033, 0xFF6A00B8, 0xFFB44DFF, 0xFFF0D0FF]),
    NamedGradient('Sunset', <int>[0xFF22223B, 0xFF9A348E, 0xFFEE6C4D, 0xFFFFD166]),
    NamedGradient('Ocean', <int>[0xFF001219, 0xFF005F73, 0xFF0A9396, 0xFF94D2BD]),
    NamedGradient('Mono', <int>[0xFF000000, 0xFFFFFFFF]),
    NamedGradient('Sepia', <int>[0xFF2B1B0E, 0xFF8A6A45, 0xFFE8D5B0]),
    NamedGradient('Rainbow', <int>[
      0xFFFF0000, 0xFFFFA500, 0xFFFFFF00, 0xFF00FF00, 0xFF00FFFF, 0xFF0000FF, 0xFFFF00FF,
    ]),
    NamedGradient('Candy', <int>[0xFFFF61A6, 0xFFFFB36B, 0xFFFFF06B, 0xFF6BFFB3]),
  ];

  /// Build a gradient-map op from a [NamedGradient].
  static ColorOp gradientMapOp(NamedGradient g, {double strength = 1}) {
    final Map<String, String> strs = <String, String>{};
    final Map<String, double> nums = <String, double>{'strength': strength};
    for (int i = 0; i < g.stops.length; i++) {
      strs['stop$i'] = formatHexColor(g.stops[i]);
      nums['pos$i'] = g.stops.length == 1 ? 0 : i / (g.stops.length - 1);
    }
    return ColorOp('gradientMap', nums: nums, strs: strs);
  }

  // ---- Animation presets ----------------------------------------------------

  static final List<AnimPreset> animPresets = <AnimPreset>[
    AnimPreset('Idle Breathe', 'Idle',
        <AnimRecipe>[AnimRecipe('breathe', p: <String, double>{'intensity': 2.5})],
        frames: 16, fps: 12),
    AnimPreset('Gentle Float', 'Idle', <AnimRecipe>[
      AnimRecipe('float', p: <String, double>{'intensity': 4}, ease: 'easeInOutSine'),
    ], frames: 24, fps: 12),
    AnimPreset('Happy Bounce', 'Emotion', <AnimRecipe>[
      AnimRecipe('bounce', p: <String, double>{'intensity': 12}, ease: 'easeOutQuad'),
    ], frames: 14, fps: 16),
    AnimPreset('Angry Shake', 'Emotion',
        <AnimRecipe>[AnimRecipe('shake', p: <String, double>{'intensity': 5, 'cycles': 8})],
        frames: 12, fps: 24),
    AnimPreset('Sad Sway', 'Emotion',
        <AnimRecipe>[AnimRecipe('sway', p: <String, double>{'intensity': 4}, ease: 'easeInOutSine')],
        frames: 24, fps: 10),
    AnimPreset('Nod Yes', 'Gesture',
        <AnimRecipe>[AnimRecipe('nod', p: <String, double>{'intensity': 6, 'cycles': 2})],
        frames: 16, fps: 16),
    AnimPreset('Shake No', 'Gesture',
        <AnimRecipe>[AnimRecipe('headShake', p: <String, double>{'intensity': 7, 'cycles': 2})],
        frames: 16, fps: 16),
    AnimPreset('Spin', 'Flashy',
        <AnimRecipe>[AnimRecipe('spin', p: <String, double>{'cycles': 1})],
        frames: 18, fps: 18),
    AnimPreset('Magical', 'Flashy', <AnimRecipe>[
      AnimRecipe('float', p: <String, double>{'intensity': 3}),
      AnimRecipe('glow', p: <String, double>{'intensity': 0.6}, colors: <String, String>{'color': '#FFB8E0FF'}),
      AnimRecipe('rainbow', p: <String, double>{'cycles': 1}),
    ], frames: 24, fps: 14),
    AnimPreset('Heartbeat', 'Flashy',
        <AnimRecipe>[AnimRecipe('heartbeat', p: <String, double>{'intensity': 8})],
        frames: 18, fps: 18),
    AnimPreset('Neon Pulse', 'Flashy', <AnimRecipe>[
      AnimRecipe('neon', p: <String, double>{'intensity': 0.7}, colors: <String, String>{'color': '#FFFF2D95'}),
    ], frames: 16, fps: 14),
    AnimPreset('Hologram', 'Flashy',
        <AnimRecipe>[AnimRecipe('hologram', p: <String, double>{'intensity': 2})],
        frames: 20, fps: 16),
    AnimPreset('Glitch', 'Flashy',
        <AnimRecipe>[AnimRecipe('glitch', p: <String, double>{'intensity': 6, 'cycles': 10})],
        frames: 16, fps: 20),
    AnimPreset('Excited Throb', 'Emotion',
        <AnimRecipe>[AnimRecipe('throb', p: <String, double>{'intensity': 8})],
        frames: 16, fps: 16),
    AnimPreset('Fade In', 'Transition',
        <AnimRecipe>[AnimRecipe('fadeIn', ease: 'easeOutCubic')],
        frames: 12, fps: 24),
    AnimPreset('Jump', 'Gesture',
        <AnimRecipe>[AnimRecipe('jump', p: <String, double>{'intensity': 24}, ease: 'easeOutQuad')],
        frames: 16, fps: 18),
    AnimPreset('Pop In', 'Transition',
        <AnimRecipe>[AnimRecipe('pop', p: <String, double>{'intensity': 16}, ease: 'easeOutBack')],
        frames: 12, fps: 20),
    AnimPreset('Slide In', 'Transition',
        <AnimRecipe>[AnimRecipe('slideIn', p: <String, double>{'intensity': 50}, ease: 'easeOutCubic')],
        frames: 14, fps: 24),
    AnimPreset('Wobble', 'Emotion',
        <AnimRecipe>[AnimRecipe('wobble', p: <String, double>{'intensity': 9, 'cycles': 2})],
        frames: 20, fps: 16),
    AnimPreset('Squash Bounce', 'Emotion', <AnimRecipe>[
      AnimRecipe('bounce', p: <String, double>{'intensity': 10}, ease: 'easeOutQuad'),
      AnimRecipe('squashStretch', p: <String, double>{'intensity': 10}),
    ], frames: 16, fps: 18),
    AnimPreset('Vibrate', 'Emotion',
        <AnimRecipe>[AnimRecipe('vibrate', p: <String, double>{'intensity': 2, 'cycles': 20})],
        frames: 12, fps: 30),
    AnimPreset('Pendulum', 'Idle',
        <AnimRecipe>[AnimRecipe('pendulum', p: <String, double>{'intensity': 14}, ease: 'easeInOutSine')],
        frames: 24, fps: 12),
    AnimPreset('Breathe + Glow', 'Idle',
        <AnimRecipe>[AnimRecipe('breatheGlow', p: <String, double>{'intensity': 3})],
        frames: 24, fps: 12),
    AnimPreset('Spooky Aura', 'Flashy', <AnimRecipe>[
      AnimRecipe('ghostFloat', p: <String, double>{'intensity': 4}),
      AnimRecipe('auraGlow', p: <String, double>{'intensity': 7},
          colors: <String, String>{'color': '#FFB58CFF'}),
    ], frames: 24, fps: 14),
    AnimPreset('Outline Pulse', 'Flashy',
        <AnimRecipe>[AnimRecipe('outlinePulse', p: <String, double>{'intensity': 3},
            colors: <String, String>{'color': '#FFFFE066'})],
        frames: 18, fps: 14),
    AnimPreset('Shiver', 'Emotion',
        <AnimRecipe>[AnimRecipe('shiver', p: <String, double>{'intensity': 2, 'cycles': 24})],
        frames: 14, fps: 24),
    AnimPreset('Drop In', 'Transition',
        <AnimRecipe>[AnimRecipe('dropIn', p: <String, double>{'intensity': 44}, ease: 'easeInQuad')],
        frames: 16, fps: 20),
    AnimPreset('Peek In', 'Transition',
        <AnimRecipe>[AnimRecipe('peek', p: <String, double>{'intensity': 40})],
        frames: 24, fps: 16),
    AnimPreset('Gallop', 'Gesture',
        <AnimRecipe>[AnimRecipe('gallop', p: <String, double>{'intensity': 8, 'cycles': 2})],
        frames: 16, fps: 18),
    AnimPreset('Sparkle', 'Flashy',
        <AnimRecipe>[AnimRecipe('sparkle', p: <String, double>{'intensity': 0.9, 'cycles': 8})],
        frames: 16, fps: 16),
    AnimPreset('Spring In', 'Transition',
        <AnimRecipe>[AnimRecipe('springIn', p: <String, double>{'intensity': 30, 'cycles': 2})],
        frames: 18, fps: 18),
    AnimPreset('Rack Focus', 'Idle',
        <AnimRecipe>[AnimRecipe('focusPull', p: <String, double>{'intensity': 4})],
        frames: 20, fps: 12),
  ];

  // ---- Emote name sets ------------------------------------------------------

  static const List<EmoteNameSet> emoteNameSets = <EmoteNameSet>[
    EmoteNameSet('Ace Attorney Basics', <String>[
      'Normal', 'Confident', 'Thinking', 'Pointing', 'Damage', 'Sweating',
      'Cornered', 'Breakdown', 'Document', 'Desk Slam', 'Nodding', 'Headshake',
    ]),
    EmoteNameSet('Danganronpa Basics', <String>[
      'Neutral', 'Happy', 'Angry', 'Sad', 'Surprised', 'Smug', 'Nervous',
      'Despair', 'Hope', 'Thinking',
    ]),
    EmoteNameSet('Generic Expressions', <String>[
      'Normal', 'Smile', 'Laugh', 'Frown', 'Cry', 'Shock', 'Blush', 'Angry',
      'Bored', 'Wink', 'Scared', 'Sleepy',
    ]),
  ];

  /// Quick stats for the UI ("X presets available").
  static int get totalCount =>
      colorPresets.length +
      palettes.length +
      gradients.length +
      animPresets.length +
      emoteNameSets.length;
}
