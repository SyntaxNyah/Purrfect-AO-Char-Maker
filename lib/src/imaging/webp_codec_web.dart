import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'webp_codec.dart';

/// Browser-native WebP encoder. Uses an off-screen `<canvas>` and
/// `toDataURL('image/webp', quality)`, which every modern browser supports for
/// lossy output. "Lossless" requests are encoded at maximum quality (browsers
/// do not expose a true lossless flag through the canvas API).
class WebWebpEncoder implements WebpEncoder {
  const WebWebpEncoder();

  @override
  bool get supportsLossy => true;

  @override
  bool get supportsLossless => true; // best-effort: max-quality encode

  @override
  Future<WebpResult> encode(img.Image image,
      {bool lossless = false, int quality = 90}) async {
    try {
      final img.Image frame =
          image.frames.isNotEmpty ? image.frames.first : image;
      final int w = frame.width;
      final int h = frame.height;
      final Uint8List rgba = frame.getBytes(order: img.ChannelOrder.rgba);

      final html.CanvasElement canvas =
          html.CanvasElement(width: w, height: h);
      final html.CanvasRenderingContext2D ctx = canvas.context2D;
      final html.ImageData data =
          html.ImageData(Uint8ClampedList.fromList(rgba), w, h);
      ctx.putImageData(data, 0, 0);

      final double q = lossless ? 1.0 : (quality.clamp(0, 100) / 100.0);
      final String url = canvas.toDataUrl('image/webp', q);
      if (!url.startsWith('data:image/webp')) {
        return WebpResult.fail('This browser did not produce WebP output.');
      }
      final int comma = url.indexOf(',');
      final Uint8List bytes = base64.decode(url.substring(comma + 1));
      return WebpResult.ok(bytes);
    } catch (e) {
      return WebpResult.fail('Canvas WebP encode failed: $e');
    }
  }

  @override
  Future<WebpResult> encodeAnimation(
    List<img.Image> frames,
    List<int> frameDurationsMs, {
    bool lossless = false,
    int quality = 90,
  }) async =>
      WebpResult.fail(
        'Animated WebP is not supported by the browser encoder. Export APNG or '
        'GIF (APNG is ideal for 2D visual-novel sprites), or use a native build '
        'with libwebpmux.',
      );
}

WebpEncoder makeWebpEncoder() => const WebWebpEncoder();
