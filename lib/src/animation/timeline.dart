import 'package:image/image.dart' as img;

import '../imaging/color_ops.dart';
import 'anim_clip.dart';
import 'anim_engine.dart';
import 'easing.dart';

/// One manually-placed keyframe. [time] is 0..1 along the loop. Each transform
/// channel has a sensible neutral default, and [ease] controls the curve used
/// for the segment that *starts* at this keyframe.
class Keyframe {
  Keyframe({
    required this.time,
    this.dx = 0,
    this.dy = 0,
    this.scale = 1,
    this.angle = 0,
    this.opacity = 1,
    this.hue = 0,
    this.ease = 'linear',
  });

  double time;
  double dx;
  double dy;
  double scale;
  double angle;
  double opacity;
  double hue; // degrees of hue shift
  String ease;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'time': time,
        'dx': dx,
        'dy': dy,
        'scale': scale,
        'angle': angle,
        'opacity': opacity,
        'hue': hue,
        'ease': ease,
      };

  static Keyframe fromJson(Map<String, dynamic> j) => Keyframe(
        time: (j['time'] as num).toDouble(),
        dx: (j['dx'] as num? ?? 0).toDouble(),
        dy: (j['dy'] as num? ?? 0).toDouble(),
        scale: (j['scale'] as num? ?? 1).toDouble(),
        angle: (j['angle'] as num? ?? 0).toDouble(),
        opacity: (j['opacity'] as num? ?? 1).toDouble(),
        hue: (j['hue'] as num? ?? 0).toDouble(),
        ease: j['ease'] as String? ?? 'linear',
      );
}

/// A fully hand-authored animation: a sorted list of [Keyframe]s that the engine
/// interpolates. This is the "advanced mode" sitting alongside one-click
/// recipes — together they cover everyone from "just make it move" to
/// frame-perfect control.
class Timeline {
  Timeline(this.keyframes);

  final List<Keyframe> keyframes;

  void sort() => keyframes.sort((Keyframe a, Keyframe b) => a.time.compareTo(b.time));

  Map<String, dynamic> toJson() => <String, dynamic>{
        'keyframes': keyframes.map((Keyframe k) => k.toJson()).toList(),
      };

  static Timeline fromJson(Map<String, dynamic> j) => Timeline(
        ((j['keyframes'] as List?) ?? <dynamic>[])
            .map((dynamic e) => Keyframe.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  /// Build the interpolated [FrameSpec] at phase [t] (0..1).
  FrameSpec specAt(double t) {
    final FrameSpec s = FrameSpec();
    if (keyframes.isEmpty) return s;
    if (keyframes.length == 1) return _apply(s, keyframes.first);

    final List<Keyframe> ks = keyframes.toList()
      ..sort((Keyframe a, Keyframe b) => a.time.compareTo(b.time));

    if (t <= ks.first.time) return _apply(s, ks.first);
    if (t >= ks.last.time) return _apply(s, ks.last);

    for (int i = 0; i < ks.length - 1; i++) {
      final Keyframe a = ks[i], b = ks[i + 1];
      if (t >= a.time && t <= b.time) {
        final double span = (b.time - a.time).abs();
        final double raw = span < 1e-6 ? 0 : (t - a.time) / span;
        final double f = Easing.apply(a.ease, raw);
        s.dx = _lerp(a.dx, b.dx, f);
        s.dy = _lerp(a.dy, b.dy, f);
        s.scale = _lerp(a.scale, b.scale, f);
        s.angle = _lerp(a.angle, b.angle, f);
        s.opacity = _lerp(a.opacity, b.opacity, f);
        final double hue = _lerp(a.hue, b.hue, f);
        if (hue.abs() > 0.001) {
          s.colorOps.add(ColorOp('hueShift', nums: <String, double>{'degrees': hue}));
        }
        return s;
      }
    }
    return _apply(s, ks.last);
  }

  /// Render the timeline onto [base].
  AnimClip render(img.Image base, {int frames = 16, int fps = 12}) =>
      AnimEngine.renderSpec(base, specAt, frames: frames, fps: fps);

  FrameSpec _apply(FrameSpec s, Keyframe k) {
    s.dx = k.dx;
    s.dy = k.dy;
    s.scale = k.scale;
    s.angle = k.angle;
    s.opacity = k.opacity;
    if (k.hue.abs() > 0.001) {
      s.colorOps.add(ColorOp('hueShift', nums: <String, double>{'degrees': k.hue}));
    }
    return s;
  }

  static double _lerp(double a, double b, double f) => a + (b - a) * f;
}
