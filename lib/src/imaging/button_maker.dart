import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../core/ao_constants.dart';
import 'codecs.dart';

/// Integer rectangle in source-image pixels.
class IntRect {
  const IntRect(this.x, this.y, this.w, this.h);
  final int x, y, w, h;
}

/// Produces emote button icons and character-select icons.
///
/// Entry points:
///  * [renderAuto] — fully automatic (used by the auto-organiser): decode the
///    first frame, frame it ([CropFraming.head] = the character's face by
///    default, or [CropFraming.full] = a square around the whole sprite), and
///    scale to size. Matches the injected `ButtonRenderer` typedef.
///  * [renderFramed] — the same, but from an already-decoded frame (lets the UI
///    reuse its decode cache for snappy previews).
///  * [renderComposite] — the advanced studio path: explicit crop rectangle
///    plus optional background / foreground / mask / "selected" overlays.
class ButtonMaker {
  const ButtonMaker._();

  /// Matches the `ButtonRenderer` typedef expected by the organiser. Defaults to
  /// **head/face** framing, the natural look for AO emote buttons and icons.
  ///
  /// [zoom] tunes the head crop: `1.0` is the default framing, `>1` zooms in
  /// (tighter on the face), `<1` zooms out (more head-and-shoulders). Ignored
  /// for [CropFraming.full]. [offsetX]/[offsetY] nudge the crop square (in
  /// fractions of its side: -0.5..0.5) so you can re-centre the face. Optional
  /// [background] sits behind the sprite and [foreground] is composited **on
  /// top** (e.g. a KFO-style border/frame) — both fit to [size].
  static Future<Uint8List?> renderAuto(
    Uint8List sourceBytes,
    String ext,
    int size, [
    CropFraming framing = CropFraming.head,
    double zoom = 1.0,
  ]) async =>
      renderAutoOverlaid(sourceBytes, ext, size,
          framing: framing, zoom: zoom);

  /// [renderAuto] with the full set of named knobs (offsets + overlays). Kept
  /// separate so the bare [renderAuto] still matches the plain `ButtonRenderer`
  /// tear-off, while callers that capture overlays use this.
  static Future<Uint8List?> renderAutoOverlaid(
    Uint8List sourceBytes,
    String ext,
    int size, {
    CropFraming framing = CropFraming.head,
    double zoom = 1.0,
    double offsetX = 0,
    double offsetY = 0,
    img.Image? background,
    img.Image? foreground,
  }) async {
    final img.Image? frame = Codecs.decodeFirstFrame(sourceBytes, ext: ext);
    if (frame == null) return null;
    return renderFramed(frame, size,
        framing: framing,
        zoom: zoom,
        offsetX: offsetX,
        offsetY: offsetY,
        background: background,
        foreground: foreground);
  }

  /// Frame an already-decoded [frame] into a [size]×[size] PNG icon. See
  /// [renderAutoOverlaid] for [framing]/[zoom]/[offsetX]/[offsetY]/overlays.
  static Uint8List renderFramed(
    img.Image frame,
    int size, {
    CropFraming framing = CropFraming.head,
    double zoom = 1.0,
    double offsetX = 0,
    double offsetY = 0,
    img.Image? background,
    img.Image? foreground,
  }) {
    final img.Image rgba = _ensureRgba(frame);
    IntRect square = framing == CropFraming.head
        ? headSquare(rgba, zoom: zoom)
        : _centerSquare(autoTrimBounds(rgba), rgba.width, rgba.height);
    if (offsetX != 0 || offsetY != 0) {
      final int sx = (square.x + offsetX * square.w)
          .round()
          .clamp(0, math.max(0, rgba.width - square.w));
      final int sy = (square.y + offsetY * square.h)
          .round()
          .clamp(0, math.max(0, rgba.height - square.h));
      square = IntRect(sx, sy, square.w, square.h);
    }
    final img.Image cropped = img.copyCrop(rgba,
        x: square.x, y: square.y, width: square.w, height: square.h);
    final img.Image scaled = img.copyResize(cropped,
        width: size, height: size, interpolation: img.Interpolation.cubic);

    if (background == null && foreground == null) return Codecs.encodePng(scaled);
    final img.Image canvas = img.Image(width: size, height: size, numChannels: 4);
    if (background != null) {
      img.compositeImage(canvas, _fit(background, size), dstX: 0, dstY: 0);
    }
    img.compositeImage(canvas, scaled, dstX: 0, dstY: 0);
    if (foreground != null) {
      img.compositeImage(canvas, _fit(foreground, size), dstX: 0, dstY: 0);
    }
    return Codecs.encodePng(canvas);
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

  /// A square framing the character's **head/face**, derived from the alpha
  /// silhouette (no ML, no model files — works offline on every platform).
  ///
  /// Method: find the content box, measure the head's width across the top band,
  /// then walk down until the silhouette widens into the shoulders — that's the
  /// chin/neck line. Frame a padded square on the head, centred on its
  /// horizontal middle with a little headroom. Falls back to a top-centred
  /// square when the silhouette is ambiguous (e.g. a non-character image).
  ///
  /// [zoom] > 1 tightens the crop (more face), < 1 loosens it (more shoulders).
  static IntRect headSquare(img.Image image, {double zoom = 1.0}) {
    final int imgW = image.width, imgH = image.height;
    final IntRect c = autoTrimBounds(image);
    if (c.w < 6 || c.h < 6) return _centerSquare(c, imgW, imgH);

    final int x0 = c.x, x1 = c.x + c.w, y0 = c.y, y1 = c.y + c.h;
    // Per-row opaque extents within the content box.
    final List<int> lefts = <int>[];
    final List<int> rights = <int>[];
    for (int y = y0; y < y1; y++) {
      int lx = -1, rx = -1;
      for (int x = x0; x < x1; x++) {
        if (image.getPixel(x, y).a >= 1) {
          if (lx < 0) lx = x;
          rx = x;
        }
      }
      lefts.add(lx);
      rights.add(rx);
    }

    // Head width = the widest opaque run in the top band (~top 30% of content),
    // and the head's horizontal centre comes from that same widest row.
    final int band = math.max(3, (c.h * 0.30).round());
    int headW = 1, headCx = c.x + c.w ~/ 2;
    for (int i = 0; i < band && i < lefts.length; i++) {
      if (lefts[i] < 0) continue;
      final int w = rights[i] - lefts[i] + 1;
      if (w > headW) {
        headW = w;
        headCx = (lefts[i] + rights[i]) ~/ 2;
      }
    }

    // Shoulder line: the first row past a minimum head height where the
    // silhouette widens well beyond the head (≈1.5×). No clear widening (a bust
    // / portrait sprite) just uses the whole content height.
    final int minRows = math.max(4, (c.h * 0.12).round());
    int shoulder = y1;
    for (int i = minRows; i < lefts.length; i++) {
      if (lefts[i] < 0) continue;
      final int w = rights[i] - lefts[i] + 1;
      if (w > headW * 1.5) {
        shoulder = y0 + i;
        break;
      }
    }
    final int headH = (shoulder - y0).clamp(1, c.h);

    // Square side encompassing the head with a little margin; zoom tightens it.
    final double z = zoom <= 0 ? 1.0 : zoom;
    int side = (math.max(headW, headH) * 1.25 / z).round();
    side = side.clamp(8, math.min(imgW, imgH));

    // Centre horizontally on the head; give ~35% of the slack as headroom above
    // the crown so the face sits centred rather than the chin.
    final int extra = side - headH;
    int sx = headCx - side ~/ 2;
    int sy = y0 - (extra * 0.35).round();
    sx = sx.clamp(0, math.max(0, imgW - side));
    sy = sy.clamp(0, math.max(0, imgH - side));
    return IntRect(sx, sy, side, side);
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
