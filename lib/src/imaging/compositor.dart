import 'package:image/image.dart' as img;

import 'button_maker.dart' show IntRect;
import 'color_ops.dart';
import 'region_edit.dart';

/// One stacked layer in a composite (back-to-front order).
class Layer {
  Layer(
    this.image, {
    this.x = 0,
    this.y = 0,
    this.scale = 1,
    this.angle = 0,
    this.opacity = 1,
    this.visible = true,
    this.name = 'layer',
  });

  img.Image image;
  int x; // top-left placement on the canvas
  int y;
  double scale;
  double angle; // degrees
  double opacity; // 0..1
  bool visible;
  String name;
}

/// Result of cutting a region out of a sprite.
class CutResult {
  CutResult(this.image, this.offsetX, this.offsetY);

  /// The snipped pixels (transparent elsewhere), trimmed to their bounds.
  final img.Image image;

  /// Where the trimmed image sat in the source (so you can paste it back in
  /// place, or know its original position).
  final int offsetX;
  final int offsetY;
}

/// Snip parts of different sprites and stack them together — e.g. put one
/// character's head on another's body ("frankensprite").
///
/// Flow:
///   1. [cut] a region (rectangle, ellipse, or any [SelectionMask]) out of the
///      source sprite.
///   2. [flatten] a list of [Layer]s (the body as the bottom layer, the cut head
///      as a layer on top) with per-layer position / scale / rotation / opacity.
class Compositor {
  const Compositor._();

  /// Cut the masked pixels out of [src]. Returns the snipped piece (alpha taken
  /// from the mask) trimmed to its bounding box, plus its source offset.
  static CutResult cut(img.Image src, SelectionMask mask, {bool trim = true}) {
    final img.Image rgba = src.numChannels == 4 ? src.clone() : src.convert(numChannels: 4);
    int minX = rgba.width, minY = rgba.height, maxX = -1, maxY = -1;
    for (int y = 0; y < rgba.height; y++) {
      for (int x = 0; x < rgba.width; x++) {
        final int w = mask.get(x, y);
        final img.Pixel p = rgba.getPixel(x, y);
        final int a = (p.a.toInt() * w) ~/ 255;
        rgba.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), a);
        if (a > 0) {
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }
    if (!trim || maxX < 0) return CutResult(rgba, 0, 0);
    final img.Image cropped = img.copyCrop(rgba,
        x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);
    return CutResult(cropped, minX, minY);
  }

  /// Convenience: cut a rectangle.
  static CutResult cutRect(img.Image src, IntRect r) =>
      cut(src, RegionEditor.rectangle(src.width, src.height, r));

  /// Convenience: cut an ellipse (good for heads).
  static CutResult cutEllipse(img.Image src, IntRect r) =>
      cut(src, RegionEditor.ellipse(src.width, src.height, r));

  /// Paste [piece] onto a copy of [base] with a transform. [x],[y] are the
  /// top-left of the (transformed) piece.
  static img.Image place(
    img.Image base,
    img.Image piece, {
    int x = 0,
    int y = 0,
    double scale = 1,
    double angle = 0,
    double opacity = 1,
  }) {
    final img.Image canvas = base.numChannels == 4 ? base.clone() : base.convert(numChannels: 4);
    img.compositeImage(canvas, _transform(piece, scale, angle, opacity), dstX: x, dstY: y);
    return canvas;
  }

  /// Flatten ordered layers onto a fresh [width]×[height] transparent canvas.
  static img.Image flatten(int width, int height, List<Layer> layers) {
    final img.Image canvas = img.Image(width: width, height: height, numChannels: 4);
    for (final Layer layer in layers) {
      if (!layer.visible) continue;
      img.compositeImage(
        canvas,
        _transform(layer.image, layer.scale, layer.angle, layer.opacity),
        dstX: layer.x,
        dstY: layer.y,
      );
    }
    return canvas;
  }

  static img.Image _transform(img.Image src, double scale, double angle, double opacity) {
    img.Image work = src.numChannels == 4 ? src.clone() : src.convert(numChannels: 4);
    if (scale != 1.0 && scale > 0) {
      work = img.copyResize(work,
          width: (work.width * scale).round().clamp(1, 1 << 16),
          height: (work.height * scale).round().clamp(1, 1 << 16),
          interpolation: img.Interpolation.cubic);
    }
    if (angle.abs() > 0.001) {
      work = img.copyRotate(work, angle: angle, interpolation: img.Interpolation.cubic);
    }
    if (opacity < 1.0) {
      ImageOps.apply(work, ColorOp('opacity', nums: <String, double>{'amount': opacity}));
    }
    return work;
  }
}
