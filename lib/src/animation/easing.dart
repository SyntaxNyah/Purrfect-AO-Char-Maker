import 'dart:math' as math;

/// Easing curves used to shape animation phase `t` (0..1 in, 0..1 out).
///
/// Every recipe can pick an easing so the same motion can feel mechanical
/// (`linear`), snappy (`easeOutBack`), springy (`elastic`), etc. This is the
/// difference between "it moves" and "it feels alive".
class Easing {
  Easing._();

  static final Map<String, double Function(double)> _curves =
      <String, double Function(double)>{
    'linear': (double t) => t,
    'easeInSine': (double t) => 1 - math.cos((t * math.pi) / 2),
    'easeOutSine': (double t) => math.sin((t * math.pi) / 2),
    'easeInOutSine': (double t) => -(math.cos(math.pi * t) - 1) / 2,
    'easeInQuad': (double t) => t * t,
    'easeOutQuad': (double t) => 1 - (1 - t) * (1 - t),
    'easeInOutQuad': (double t) =>
        t < 0.5 ? 2 * t * t : 1 - math.pow(-2 * t + 2, 2) / 2,
    'easeInCubic': (double t) => t * t * t,
    'easeOutCubic': (double t) => 1 - math.pow(1 - t, 3).toDouble(),
    'easeInOutCubic': (double t) => t < 0.5
        ? 4 * t * t * t
        : 1 - math.pow(-2 * t + 2, 3) / 2,
    'easeInExpo': (double t) => t == 0 ? 0 : math.pow(2, 10 * t - 10).toDouble(),
    'easeOutExpo': (double t) => t == 1 ? 1 : 1 - math.pow(2, -10 * t).toDouble(),
    'easeInOutExpo': (double t) {
      if (t == 0 || t == 1) return t;
      return t < 0.5
          ? math.pow(2, 20 * t - 10).toDouble() / 2
          : (2 - math.pow(2, -20 * t + 10).toDouble()) / 2;
    },
    'easeInQuint': (double t) => t * t * t * t * t,
    'easeOutQuint': (double t) => 1 - math.pow(1 - t, 5).toDouble(),
    'easeInOutQuint': (double t) => t < 0.5
        ? 16 * t * t * t * t * t
        : 1 - math.pow(-2 * t + 2, 5).toDouble() / 2,
    'easeInCirc': (double t) => 1 - math.sqrt(1 - math.pow(t, 2)).toDouble(),
    'easeOutCirc': (double t) => math.sqrt(1 - math.pow(t - 1, 2)).toDouble(),
    'easeInOutBack': (double t) {
      const double c1 = 1.70158;
      const double c2 = c1 * 1.525;
      return t < 0.5
          ? (math.pow(2 * t, 2) * ((c2 + 1) * 2 * t - c2)).toDouble() / 2
          : (math.pow(2 * t - 2, 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2)
                  .toDouble() /
              2;
    },
    'easeInBack': (double t) {
      const double c1 = 1.70158;
      const double c3 = c1 + 1;
      return c3 * t * t * t - c1 * t * t;
    },
    'easeOutBack': (double t) {
      const double c1 = 1.70158;
      const double c3 = c1 + 1;
      return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2);
    },
    'easeOutBounce': _outBounce,
    'easeInBounce': (double t) => 1 - _outBounce(1 - t),
    'elastic': (double t) {
      if (t == 0 || t == 1) return t;
      const double c4 = (2 * math.pi) / 3;
      return math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1;
    },
  };

  static List<String> get names => _curves.keys.toList();

  /// Apply an easing curve by name (unknown name -> linear).
  static double apply(String name, double t) {
    final double c = t.clamp(0.0, 1.0);
    return (_curves[name] ?? _curves['linear']!)(c);
  }

  /// Register a custom easing (plugin hook).
  static void register(String name, double Function(double) fn) =>
      _curves[name] = fn;

  static double _outBounce(double t) {
    const double n1 = 7.5625;
    const double d1 = 2.75;
    if (t < 1 / d1) {
      return n1 * t * t;
    } else if (t < 2 / d1) {
      final double u = t - 1.5 / d1;
      return n1 * u * u + 0.75;
    } else if (t < 2.5 / d1) {
      final double u = t - 2.25 / d1;
      return n1 * u * u + 0.9375;
    } else {
      final double u = t - 2.625 / d1;
      return n1 * u * u + 0.984375;
    }
  }
}
