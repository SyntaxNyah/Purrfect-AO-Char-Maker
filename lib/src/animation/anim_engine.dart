import 'dart:math' as math;

import 'package:image/image.dart' as img;

import '../imaging/button_maker.dart' show IntRect;
import '../imaging/color_ops.dart';
import 'anim_clip.dart';
import 'easing.dart';

/// Per-frame transform + colour state for one layer.
class FrameSpec {
  double dx = 0;
  double dy = 0;
  double scale = 1; // uniform scale
  double scaleX = 1; // extra horizontal scale (for squash & stretch)
  double scaleY = 1; // extra vertical scale
  double angle = 0; // degrees
  double opacity = 1;
  final List<ColorOp> colorOps = <ColorOp>[];

  void add(FrameSpec other) {
    dx += other.dx;
    dy += other.dy;
    scale *= other.scale;
    scaleX *= other.scaleX;
    scaleY *= other.scaleY;
    angle += other.angle;
    opacity *= other.opacity;
    colorOps.addAll(other.colorOps);
  }
}

/// A configured, serializable animation effect. Stack several to combine them
/// ("move + glow + rainbow"). Attach a [region] to animate only part of the
/// sprite (e.g. wave a hand).
class AnimRecipe {
  AnimRecipe(
    this.type, {
    Map<String, double>? p,
    Map<String, String>? colors,
    this.region,
    this.ease = 'linear',
  })  : p = p ?? <String, double>{},
        colors = colors ?? <String, String>{};

  final String type;
  final Map<String, double> p;
  final Map<String, String> colors;

  /// Easing curve name (see [Easing]) reshaping this recipe's phase.
  String ease;

  /// If non-null, this recipe animates only this sub-rectangle as a layer on
  /// top of the otherwise-static sprite.
  IntRect? region;

  double n(String k, [double f = 0]) => p[k] ?? f;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        if (p.isNotEmpty) 'p': p,
        if (colors.isNotEmpty) 'colors': colors,
        if (region != null)
          'region': <int>[region!.x, region!.y, region!.w, region!.h],
        if (ease != 'linear') 'ease': ease,
      };

  static AnimRecipe fromJson(Map<String, dynamic> j) {
    final List<dynamic>? r = j['region'] as List<dynamic>?;
    return AnimRecipe(
      j['type'] as String,
      ease: j['ease'] as String? ?? 'linear',
      p: (j['p'] as Map?)?.map((Object? k, Object? v) =>
          MapEntry<String, double>(k.toString(), (v as num).toDouble())),
      colors: (j['colors'] as Map?)?.map((Object? k, Object? v) =>
          MapEntry<String, String>(k.toString(), v.toString())),
      region: r == null
          ? null
          : IntRect(r[0] as int, r[1] as int, r[2] as int, r[3] as int),
    );
  }
}

/// Computes a [FrameSpec] for a recipe at animation phase `t` (0..1).
typedef RecipeFn = FrameSpec Function(double t, AnimRecipe r);

/// The animation generator. Renders standard multi-frame sprites (APNG/GIF) so
/// the output is 100% AO-compatible — the engine never speaks a custom format.
class AnimEngine {
  AnimEngine._();

  static final Map<String, RecipeFn> _registry = <String, RecipeFn>{
    'none': (double t, AnimRecipe r) => FrameSpec(),
    'sway': _sway,
    'bob': _bob,
    'bounce': _bounce,
    'float': _float,
    'breathe': _breathe,
    'shake': _shake,
    'spin': _spin,
    'tilt': _tilt,
    'wiggle': _wiggle,
    'zoomPulse': _zoomPulse,
    'jump': _jump,
    'glow': _glow,
    'flash': _flash,
    'pulse': _pulse,
    'rainbow': _rainbow,
    'tintPulse': _tintPulse,
    'fadeIn': _fadeIn,
    'fadeOut': _fadeOut,
    'throb': _throb,
    'nod': _nod,
    'headShake': _headShake,
    'swing': _swing,
    'drift': _drift,
    'orbit': _orbit,
    'heartbeat': _heartbeat,
    'strobe': _strobe,
    'flicker': _flicker,
    'neon': _neon,
    'hologram': _hologram,
    'glitch': _glitch,
    'colorCycle': _colorCycle,
    'wave': _wave,
    'pendulum': _pendulum,
    'vibrate': _vibrate,
    'pop': _pop,
    'wobble': _wobble,
    'slideIn': _slideIn,
    'slideOut': _slideOut,
    'squashStretch': _squashStretch,
    'twitch': _twitch,
    'breatheGlow': _breatheGlow,
  };

  static List<String> get recipeTypes => _registry.keys.toList()..sort();

  /// Plugin hook: register a new code recipe.
  static void register(String id, RecipeFn fn) => _registry[id] = fn;

  static FrameSpec _spec(double t, AnimRecipe r) {
    final double et = Easing.apply(r.ease, t);
    return (_registry[r.type] ?? _registry['none']!)(et, r);
  }

  /// Render [base] into a clip by stacking [recipes].
  ///
  /// [frames] frames are produced over one loop; [fps] sets the playback rate.
  static AnimClip render(
    img.Image base,
    List<AnimRecipe> recipes, {
    int frames = 12,
    int fps = 12,
    bool loop = true,
  }) {
    final img.Image src = base.numChannels == 4 ? base : base.convert(numChannels: 4);
    final int delayCentis = math.max(1, (100 / fps).round());

    final List<AnimRecipe> global =
        recipes.where((AnimRecipe r) => r.region == null).toList();
    final List<AnimRecipe> regional =
        recipes.where((AnimRecipe r) => r.region != null).toList();

    final List<AnimFrame> out = <AnimFrame>[];
    for (int i = 0; i < frames; i++) {
      final double t = frames <= 1 ? 0 : i / frames; // 0..1 (exclusive end => clean loop)

      // Whole-sprite layer.
      final FrameSpec g = FrameSpec();
      for (final AnimRecipe r in global) {
        g.add(_spec(t, r));
      }
      img.Image canvas = _renderLayer(
        src,
        g,
        canvasW: src.width,
        canvasH: src.height,
        anchorX: src.width / 2,
        anchorY: src.height / 2,
      );

      // Region layers on top.
      for (final AnimRecipe r in regional) {
        final IntRect reg = r.region!;
        final img.Image piece =
            img.copyCrop(src, x: reg.x, y: reg.y, width: reg.w, height: reg.h);
        final FrameSpec spec = _spec(t, r);
        final img.Image layer = _renderLayer(
          piece,
          spec,
          canvasW: src.width,
          canvasH: src.height,
          anchorX: reg.x + reg.w / 2,
          anchorY: reg.y + reg.h / 2,
        );
        canvas = img.compositeImage(canvas, layer, dstX: 0, dstY: 0);
      }

      out.add(AnimFrame(canvas, delayCentis: delayCentis));
    }
    return AnimClip(out);
  }

  /// Render directly from a per-phase [FrameSpec] function (used by the manual
  /// keyframe [Timeline]). Whole-sprite only.
  static AnimClip renderSpec(
    img.Image base,
    FrameSpec Function(double t) specAt, {
    int frames = 16,
    int fps = 12,
  }) {
    final img.Image src =
        base.numChannels == 4 ? base : base.convert(numChannels: 4);
    final int delayCentis = math.max(1, (100 / fps).round());
    final List<AnimFrame> out = <AnimFrame>[];
    for (int i = 0; i < frames; i++) {
      final double t = frames <= 1 ? 0 : i / frames;
      final img.Image canvas = _renderLayer(
        src,
        specAt(t),
        canvasW: src.width,
        canvasH: src.height,
        anchorX: src.width / 2,
        anchorY: src.height / 2,
      );
      out.add(AnimFrame(canvas, delayCentis: delayCentis));
    }
    return AnimClip(out);
  }

  /// Render one layer ([src]) transformed by [spec] onto a transparent canvas of
  /// [canvasW] x [canvasH], so its center lands at (anchor + dx, anchor + dy).
  static img.Image _renderLayer(
    img.Image src,
    FrameSpec spec, {
    required int canvasW,
    required int canvasH,
    required double anchorX,
    required double anchorY,
  }) {
    img.Image work = src.clone();
    if (spec.colorOps.isNotEmpty) ImageOps.applyAll(work, spec.colorOps);
    if (spec.opacity < 1.0) {
      ImageOps.apply(work, ColorOp('opacity', nums: <String, double>{'amount': spec.opacity}));
    }
    final double sx = spec.scale * spec.scaleX;
    final double sy = spec.scale * spec.scaleY;
    if ((sx != 1.0 || sy != 1.0) && sx > 0 && sy > 0) {
      work = img.copyResize(work,
          width: math.max(1, (work.width * sx).round()),
          height: math.max(1, (work.height * sy).round()),
          interpolation: img.Interpolation.cubic);
    }
    if (spec.angle.abs() > 0.001) {
      work = img.copyRotate(work, angle: spec.angle, interpolation: img.Interpolation.cubic);
    }

    final img.Image canvas = img.Image(width: canvasW, height: canvasH, numChannels: 4);
    final int dstX = (anchorX + spec.dx - work.width / 2).round();
    final int dstY = (anchorY + spec.dy - work.height / 2).round();
    return img.compositeImage(canvas, work, dstX: dstX, dstY: dstY);
  }

  // ---------------------------------------------------------------------------
  // Built-in recipes. `intensity` and `cycles` are the common knobs; all are
  // smooth and loop seamlessly (phase t is exclusive of 1.0).
  // ---------------------------------------------------------------------------

  static double _tau(double t, double cycles) => 2 * math.pi * t * cycles;

  static FrameSpec _sway(double t, AnimRecipe r) => FrameSpec()
    ..angle = r.n('intensity', 6) * math.sin(_tau(t, r.n('cycles', 1)));

  static FrameSpec _bob(double t, AnimRecipe r) => FrameSpec()
    ..dy = r.n('intensity', 6) * math.sin(_tau(t, r.n('cycles', 1)));

  static FrameSpec _bounce(double t, AnimRecipe r) => FrameSpec()
    ..dy = -r.n('intensity', 12) * math.sin(_tau(t, r.n('cycles', 1))).abs();

  static FrameSpec _float(double t, AnimRecipe r) => FrameSpec()
    ..dy = r.n('intensity', 4) * math.sin(_tau(t, r.n('cycles', 1)))
    ..dx = r.n('drift', 2) * math.cos(_tau(t, r.n('cycles', 1)));

  static FrameSpec _breathe(double t, AnimRecipe r) => FrameSpec()
    ..scale = 1 + r.n('intensity', 3) / 100.0 * (0.5 + 0.5 * math.sin(_tau(t, r.n('cycles', 1))));

  static FrameSpec _shake(double t, AnimRecipe r) {
    final double i = r.n('intensity', 4);
    final double c = r.n('cycles', 6);
    return FrameSpec()
      ..dx = i * math.sin(_tau(t, c))
      ..dy = i * 0.6 * math.sin(_tau(t, c * 1.7) + 1.3);
  }

  static FrameSpec _spin(double t, AnimRecipe r) =>
      FrameSpec()..angle = 360.0 * r.n('cycles', 1) * t;

  static FrameSpec _tilt(double t, AnimRecipe r) => FrameSpec()
    ..angle = r.n('intensity', 10) * math.sin(_tau(t, r.n('cycles', 1)));

  static FrameSpec _wiggle(double t, AnimRecipe r) => FrameSpec()
    ..angle = r.n('intensity', 5) * math.sin(_tau(t, r.n('cycles', 3)));

  static FrameSpec _zoomPulse(double t, AnimRecipe r) => FrameSpec()
    ..scale = 1 + r.n('intensity', 8) / 100.0 * (0.5 + 0.5 * math.sin(_tau(t, r.n('cycles', 1))));

  static FrameSpec _jump(double t, AnimRecipe r) {
    // Parabolic hop within the loop.
    final double h = r.n('intensity', 20);
    final double x = (t * 2 - 1); // -1..1
    return FrameSpec()..dy = -h * (1 - x * x);
  }

  static FrameSpec _glow(double t, AnimRecipe r) {
    final double amt = (0.5 + 0.5 * math.sin(_tau(t, r.n('cycles', 1)))) * r.n('intensity', 0.6);
    return FrameSpec()
      ..colorOps.add(ColorOp('tint',
          nums: <String, double>{'amount': amt},
          strs: <String, String>{'color': r.colors['color'] ?? '#FFFFE08A'}))
      ..colorOps.add(ColorOp('brightness', nums: <String, double>{'amount': 1 + 0.3 * amt}));
  }

  static FrameSpec _flash(double t, AnimRecipe r) {
    final double spike = math.pow(0.5 + 0.5 * math.sin(_tau(t, r.n('cycles', 1))), 6).toDouble();
    return FrameSpec()
      ..colorOps.add(ColorOp('brightness', nums: <String, double>{'amount': 1 + r.n('intensity', 1.2) * spike}));
  }

  static FrameSpec _pulse(double t, AnimRecipe r) => FrameSpec()
    ..opacity = (1 - r.n('intensity', 0.5) * (0.5 + 0.5 * math.sin(_tau(t, r.n('cycles', 1)))))
        .clamp(0.0, 1.0);

  static FrameSpec _rainbow(double t, AnimRecipe r) => FrameSpec()
    ..colorOps.add(ColorOp('hueShift',
        nums: <String, double>{'degrees': 360.0 * r.n('cycles', 1) * t}));

  static FrameSpec _tintPulse(double t, AnimRecipe r) {
    final double amt = (0.5 + 0.5 * math.sin(_tau(t, r.n('cycles', 1)))) * r.n('intensity', 0.5);
    return FrameSpec()
      ..colorOps.add(ColorOp('tint',
          nums: <String, double>{'amount': amt},
          strs: <String, String>{'color': r.colors['color'] ?? '#FFFF5577'}));
  }

  static FrameSpec _fadeIn(double t, AnimRecipe r) => FrameSpec()..opacity = t;
  static FrameSpec _fadeOut(double t, AnimRecipe r) => FrameSpec()..opacity = 1 - t;

  static FrameSpec _throb(double t, AnimRecipe r) {
    final FrameSpec s = _zoomPulse(t, r);
    s.add(_glow(t, r));
    return s;
  }

  static FrameSpec _nod(double t, AnimRecipe r) => FrameSpec()
    ..dy = r.n('intensity', 5) * math.sin(_tau(t, r.n('cycles', 1)))
    ..angle = r.n('intensity', 5) * 0.4 * math.sin(_tau(t, r.n('cycles', 1)));

  static FrameSpec _headShake(double t, AnimRecipe r) => FrameSpec()
    ..dx = r.n('intensity', 6) * math.sin(_tau(t, r.n('cycles', 2)))
    ..angle = r.n('intensity', 6) * 0.3 * math.sin(_tau(t, r.n('cycles', 2)));

  static FrameSpec _swing(double t, AnimRecipe r) => FrameSpec()
    ..angle = r.n('intensity', 12) * math.sin(_tau(t, r.n('cycles', 1)))
    ..dx = r.n('intensity', 12) * 0.5 * math.sin(_tau(t, r.n('cycles', 1)));

  static FrameSpec _drift(double t, AnimRecipe r) => FrameSpec()
    ..dx = r.n('intensity', 8) * math.sin(_tau(t, r.n('cycles', 1)))
    ..dy = r.n('intensity', 8) * 0.3 * math.cos(_tau(t, r.n('cycles', 1)));

  static FrameSpec _orbit(double t, AnimRecipe r) {
    final double rad = r.n('intensity', 8);
    return FrameSpec()
      ..dx = rad * math.cos(_tau(t, r.n('cycles', 1)))
      ..dy = rad * math.sin(_tau(t, r.n('cycles', 1)));
  }

  static FrameSpec _heartbeat(double t, AnimRecipe r) {
    // Two quick bumps per cycle.
    final double base = math.sin(_tau(t, r.n('cycles', 1)));
    final double bump = math.max(0, base).toDouble() +
        0.6 * math.max(0, math.sin(_tau(t, r.n('cycles', 1)) - 0.9)).toDouble();
    return FrameSpec()..scale = 1 + r.n('intensity', 6) / 100.0 * bump;
  }

  static FrameSpec _strobe(double t, AnimRecipe r) {
    final int step = (t * r.n('cycles', 6) * 2).floor();
    return FrameSpec()..opacity = step.isEven ? 1.0 : (1 - r.n('intensity', 1)).clamp(0.0, 1.0);
  }

  static FrameSpec _flicker(double t, AnimRecipe r) {
    final double noise = (math.sin(t * 97.13) * 43758.5453);
    final double f = (noise - noise.floorToDouble());
    return FrameSpec()..opacity = (1 - r.n('intensity', 0.3) * f).clamp(0.0, 1.0);
  }

  static FrameSpec _neon(double t, AnimRecipe r) {
    final FrameSpec s = _glow(t, r);
    s.colorOps.add(ColorOp('saturation', nums: <String, double>{'amount': 1.4}));
    return s;
  }

  static FrameSpec _hologram(double t, AnimRecipe r) {
    final FrameSpec s = FrameSpec()
      ..opacity = 0.7
      ..dx = r.n('intensity', 2) * math.sin(_tau(t, r.n('cycles', 8)));
    s.colorOps.add(ColorOp('tint',
        nums: <String, double>{'amount': 0.35},
        strs: <String, String>{'color': r.colors['color'] ?? '#FF66E0FF'}));
    return s;
  }

  static FrameSpec _glitch(double t, AnimRecipe r) {
    final int step = (t * r.n('cycles', 10)).floor();
    final double j = ((step * 2654435761) % 1000) / 1000.0 - 0.5;
    final FrameSpec s = FrameSpec()..dx = r.n('intensity', 6) * j * 2;
    if (step.isOdd) {
      s.colorOps.add(ColorOp('channelSwap', strs: <String, String>{'order': 'gbr'}));
    }
    return s;
  }

  static FrameSpec _colorCycle(double t, AnimRecipe r) => FrameSpec()
    ..colorOps.add(ColorOp('hueShift',
        nums: <String, double>{'degrees': 360.0 * r.n('cycles', 1) * t}));

  static FrameSpec _wave(double t, AnimRecipe r) {
    final double c = r.n('cycles', 2);
    return FrameSpec()
      ..dx = r.n('intensity', 5) * math.sin(_tau(t, c))
      ..angle = r.n('intensity', 5) * 0.5 * math.sin(_tau(t, c) + 0.6);
  }

  static FrameSpec _pendulum(double t, AnimRecipe r) =>
      FrameSpec()..angle = r.n('intensity', 16) * math.sin(_tau(t, r.n('cycles', 1)));

  static FrameSpec _vibrate(double t, AnimRecipe r) {
    final double i = r.n('intensity', 2);
    return FrameSpec()
      ..dx = i * math.sin(_tau(t, r.n('cycles', 20)))
      ..dy = i * math.cos(_tau(t, r.n('cycles', 23)));
  }

  static FrameSpec _pop(double t, AnimRecipe r) =>
      FrameSpec()..scale = 1 + r.n('intensity', 12) / 100.0 * math.sin(math.pi * t);

  static FrameSpec _wobble(double t, AnimRecipe r) {
    final double i = r.n('intensity', 8);
    return FrameSpec()
      ..angle = i * math.sin(_tau(t, r.n('cycles', 2)))
      ..scale = 1 + i / 200.0 * math.sin(_tau(t, r.n('cycles', 2) * 2));
  }

  static FrameSpec _slideIn(double t, AnimRecipe r) =>
      FrameSpec()..dx = -r.n('intensity', 40) * (1 - t);

  static FrameSpec _slideOut(double t, AnimRecipe r) =>
      FrameSpec()..dx = r.n('intensity', 40) * t;

  /// Volume-preserving squash & stretch (uses the non-uniform scale channels).
  static FrameSpec _squashStretch(double t, AnimRecipe r) {
    final double a = r.n('intensity', 12) / 100.0 * math.sin(_tau(t, r.n('cycles', 1)));
    return FrameSpec()
      ..scaleX = 1 - a
      ..scaleY = 1 + a;
  }

  static FrameSpec _twitch(double t, AnimRecipe r) {
    final double trigger = math.sin(_tau(t, r.n('cycles', 6)));
    final double i = r.n('intensity', 6);
    return FrameSpec()
      ..dx = trigger > 0.85 ? i : 0
      ..angle = trigger > 0.85 ? i * 0.5 : 0;
  }

  static FrameSpec _breatheGlow(double t, AnimRecipe r) {
    final FrameSpec s = _breathe(t, r);
    s.add(_glow(t, r));
    return s;
  }
}
