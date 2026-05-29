import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../core/ao_constants.dart';
import 'codecs.dart';

/// Integer rectangle in source-image pixels.
class IntRect {
  const IntRect(this.x, this.y, this.w, this.h);
  final int x, y, w, h;
}

/// Produces emote button icons.
///
/// Two entry points:
///  * [renderAuto] — fully automatic (used by the auto-organiser): trims
///    transparent margins, crops to a centred square, scales to size. Great
///    default buttons with zero user input.
///  * [renderComposite] — the advanced studio path: explicit crop rectangle
///    plus optional background / foreground / mask / "selected" overlays.
class ButtonMaker {
  const ButtonMaker._();

  /// Matches the [ButtonRenderer] typedef expected by the organiser.
  static Future<Uint8List?> renderAuto(
      Uint8List sourceBytes, String ext, int size) async {
    final img.Image? frame = Codecs.decodeFirstFrame(sourceBytes, ext: ext);
    if (frame == null) return null;
    final img.Image rgba = _ensureRgba(frame);
    final IntRect trim = autoTrimBounds(rgba);
    final IntRect square = _centerSquare(trim, rgba.width, rgba.height);
    final img.Image cropped =
        img.copyCrop(rgba, x: square.x, y: square.y, width: square.w, height: square.h);
    final img.Image out = img.copyResize(cropped,
        width: size, height: size, interpolation: img.Interpolation.cubic);
    return Codecs.encodePng(out);
  }

  /// Full control button render for the studio screen.
  static Uint8List renderComposite({
    required img.Image sourceFrame,
    required IntRect crop,
    int size = CharFolder.recommendedButtonSize,
    img.Image? background,
    img.Image? foreground,
    img.Image? mask,
    img.Image? selectedOverlay,
    bool on = false,
  }) {
    final img.Image rgba = _ensureRgba(sourceFrame);
    img.Image cut = img.copyCrop(rgba,
        x: crop.x, y: crop.y, width: crop.w, height: crop.h);
    cut = img.copyResize(cut,
        width: size, height: size, interpolation: img.Interpolation.cubic);

    img.Image canvas = img.Image(width: size, height: size, numChannels: 4);
    if (background != null) {
      img.compositeImage(canvas, _fit(background, size),
          dstX: 0, dstY: 0);
    }
    img.compositeImage(canvas, cut, dstX: 0, dstY: 0);
    if (on && selectedOverlay != null) {
      img.compositeImage(canvas, _fit(selectedOverlay, size), dstX: 0, dstY: 0);
    }
    if (foreground != null) {
      img.compositeImage(canvas, _fit(foreground, size), dstX: 0, dstY: 0);
    }
    if (mask != null) {
      canvas = _applyMaskAlpha(canvas, _fit(mask, size));
    }
    return Codecs.encodePng(canvas);
  }

  // ---- helpers ----

  static img.Image _ensureRgba(img.Image src) {
    if (src.numChannels == 4) return src;
    return src.convert(numChannels: 4);
  }

  static img.Image _fit(img.Image src, int size) =>
      (src.width == size && src.height == size)
          ? _ensureRgba(src)
          : img.copyResize(_ensureRgba(src),
              width: size, height: size, interpolation: img.Interpolation.cubic);

  /// Bounding box of all pixels with alpha > 0. Falls back to the full image if
  /// everything is opaque or everything is transparent.
  static IntRect autoTrimBounds(img.Image image, {int alphaThreshold = 1}) {
    int minX = image.width, minY = image.height, maxX = -1, maxY = -1;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        if (image.getPixel(x, y).a >= alphaThreshold) {
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }
    if (maxX < 0) return IntRect(0, 0, image.width, image.height);
    return IntRect(minX, minY, maxX - minX + 1, maxY - minY + 1);
  }

  /// Largest centred square that fits the content box, clamped to the image.
  static IntRect _centerSquare(IntRect box, int imgW, int imgH) {
    final int side = box.w > box.h ? box.w : box.h;
    final int cx = box.x + box.w ~/ 2;
    final int cy = box.y + box.h ~/ 2;
    int x = cx - side ~/ 2;
    int y = cy - side ~/ 2;
    int s = side;
    if (s > imgW) s = imgW;
    if (s > imgH) s = imgH;
    if (x < 0) x = 0;
    if (y < 0) y = 0;
    if (x + s > imgW) x = imgW - s;
    if (y + s > imgH) y = imgH - s;
    return IntRect(x, y, s, s);
  }

  /// Multiply destination alpha by the mask's alpha (black/transparent mask =
  /// hidden). Matches AO's mask convention.
  static img.Image _applyMaskAlpha(img.Image dst, img.Image mask) {
    for (int y = 0; y < dst.height; y++) {
      for (int x = 0; x < dst.width; x++) {
        final img.Pixel d = dst.getPixel(x, y);
        final img.Pixel m = mask.getPixel(x, y);
        final int a = (d.a.toInt() * m.a.toInt()) ~/ 255;
        dst.setPixelRgba(x, y, d.r.toInt(), d.g.toInt(), d.b.toInt(), a);
      }
    }
    return dst;
  }
}
