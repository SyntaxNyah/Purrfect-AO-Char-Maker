import 'dart:math' as math;

import 'package:image/image.dart' as img;

import '../core/ao_constants.dart';
import '../imaging/button_maker.dart' show IntRect;
import 'anim_clip.dart';

/// Builds talking ("(b)") animations so users can add lip-sync without knowing
/// anything about animation.
///
/// Three modes, easiest first:
///  1. [twoState] — give it a mouth-closed and a mouth-open sprite. Done.
///  2. [fromVisemes] — give it several mouth shapes; it cycles them naturally.
///  3. [auto] — give it just one sprite and (optionally) where the mouth is;
///     it fakes a jaw-drop. Rough, but zero extra art required.
class LipSync {
  const LipSync._();

  /// Closed/open alternation. The resulting clip loops, which is exactly what AO
  /// wants for a talking sprite.
  static AnimClip twoState(
    img.Image closed,
    img.Image open, {
    int closedCentis = 7,
    int openCentis = 7,
  }) {
    return AnimClip(<AnimFrame>[
      AnimFrame(_rgba(closed), delayCentis: closedCentis),
      AnimFrame(_rgba(open), delayCentis: openCentis),
    ]);
  }

  /// Cycle through any number of mouth shapes (visemes). A natural talking mouth
  /// bounces between a few shapes; pass them in the order you want them played.
  static AnimClip fromVisemes(
    List<img.Image> visemes, {
    int perFrameCentis = 6,
    bool pingPong = true,
  }) {
    if (visemes.isEmpty) {
      throw ArgumentError('Need at least one viseme.');
    }
    final List<img.Image> seq = <img.Image>[...visemes];
    if (pingPong && visemes.length > 2) {
      seq.addAll(visemes.reversed.skip(1).take(visemes.length - 2));
    }
    return AnimClip(<AnimFrame>[
      for (final img.Image v in seq) AnimFrame(_rgba(v), delayCentis: perFrameCentis),
    ]);
  }

  /// Procedural fallback: fake a mouth opening on a single sprite by stretching
  /// the lower part of a mouth region downward (a "jaw drop"). If [mouth] is
  /// null, the lower-third center of the sprite is assumed.
  static AnimClip auto(
    img.Image base, {
    IntRect? mouth,
    double openAmount = 0.35,
    int frames = 4,
    int fps = 10,
  }) {
    final img.Image src = _rgba(base);
    final IntRect region = mouth ?? _defaultMouthRegion(src);
    final int delay = math.max(1, (100 / fps).round());
    final List<AnimFrame> out = <AnimFrame>[];
    for (int i = 0; i < frames; i++) {
      final double phase = frames <= 1 ? 0 : i / frames;
      final double open = (0.5 - 0.5 * math.cos(2 * math.pi * phase)) * openAmount;
      out.add(AnimFrame(_openMouth(src, region, open), delayCentis: delay));
    }
    return AnimClip(out);
  }

  // ---- helpers ----

  static img.Image _rgba(img.Image src) =>
      src.numChannels == 4 ? src.clone() : src.convert(numChannels: 4);

  static IntRect _defaultMouthRegion(img.Image src) {
    final int w = (src.width * 0.4).round();
    final int h = (src.height * 0.16).round();
    final int x = (src.width - w) ~/ 2;
    final int y = (src.height * 0.62).round();
    return IntRect(x, y, w, h);
  }

  /// Stretch the mouth region taller by [open] (fraction of its height) and
  /// composite it back, nudged down — a cheap but convincing open mouth.
  static img.Image _openMouth(img.Image src, IntRect r, double open) {
    final img.Image frame = src.clone();
    if (open <= 0.001) return frame;
    final img.Image piece =
        img.copyCrop(src, x: r.x, y: r.y, width: r.w, height: r.h);
    final int newH = math.max(r.h, (r.h * (1 + open)).round());
    final img.Image stretched = img.copyResize(piece,
        width: r.w, height: newH, interpolation: img.Interpolation.cubic);
    return img.compositeImage(frame, stretched, dstX: r.x, dstY: r.y);
  }
}
