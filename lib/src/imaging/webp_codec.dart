import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'webp_codec_io.dart'
    if (dart.library.html) 'webp_codec_web.dart' as impl;

/// Result of a WebP encode attempt.
class WebpResult {
  WebpResult.ok(this.bytes)
      : ok = true,
        reason = null;
  WebpResult.fail(this.reason)
      : ok = false,
        bytes = null;

  final bool ok;
  final Uint8List? bytes;
  final String? reason;
}

/// Encodes images to WebP (lossy and/or lossless).
///
/// * **Web**: uses the browser's built-in WebP encoder (Canvas) — lossy is
///   universally supported; lossless depends on the browser.
/// * **Native (desktop/mobile)**: pure-Dart WebP *encoding* is not yet
///   available, so the default encoder reports it is unsupported. This is a
///   documented plugin extension point — drop in a libwebp-backed encoder via
///   [WebpEncoder.override] and the rest of the app uses it automatically.
abstract class WebpEncoder {
  bool get supportsLossy;
  bool get supportsLossless;

  /// Encode [image] (first frame) to a still WebP. [quality] is 0..100 and
  /// ignored when [lossless] is true.
  Future<WebpResult> encode(img.Image image,
      {bool lossless = false, int quality = 90});

  /// Encode an **animated** WebP from [frames] with per-frame durations in
  /// milliseconds ([frameDurationsMs]). Native builds use libwebp's animation
  /// encoder (libwebpmux); the browser encoder can't do animated WebP, so the
  /// web build reports unsupported (export APNG/GIF instead — APNG is ideal for
  /// 2D visual-novel sprites anyway).
  Future<WebpResult> encodeAnimation(
    List<img.Image> frames,
    List<int> frameDurationsMs, {
    bool lossless = false,
    int quality = 90,
  });

  /// The active encoder. Replace this to inject a native libwebp encoder.
  static WebpEncoder instance = impl.makeWebpEncoder();

  /// Plugin hook: install a custom encoder (e.g. an FFI libwebp binding).
  static void override(WebpEncoder encoder) => instance = encoder;
}
