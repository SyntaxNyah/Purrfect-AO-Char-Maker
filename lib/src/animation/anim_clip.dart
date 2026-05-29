import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../core/ao_constants.dart';
import '../imaging/codecs.dart';
import '../imaging/webp_codec.dart';

/// One frame of a generated animation.
class AnimFrame {
  AnimFrame(this.image, {this.delayCentis = AoTiming.defaultFrameDelayCentis});

  final img.Image image;

  /// Frame delay in centiseconds (1/100 s), matching AO/GIF semantics.
  int delayCentis;

  int get delayMs => delayCentis * 10;
}

/// A finished, encodable animation clip.
class AnimClip {
  AnimClip(this.frames);

  final List<AnimFrame> frames;

  bool get isAnimated => frames.length > 1;

  int get width => frames.isEmpty ? 0 : frames.first.image.width;
  int get height => frames.isEmpty ? 0 : frames.first.image.height;

  /// Assemble into a single multi-frame [img.Image] for encoding.
  img.Image toImage() {
    if (frames.isEmpty) {
      return img.Image(width: 1, height: 1, numChannels: 4);
    }
    final img.Image base = frames.first.image;
    base.frameDuration = frames.first.delayMs;
    // Reset any pre-existing frames, then append the rest.
    for (int i = 1; i < frames.length; i++) {
      final img.Image f = frames[i].image;
      f.frameDuration = frames[i].delayMs;
      base.addFrame(f);
    }
    return base;
  }

  /// Encode to APNG (default) or GIF.
  Uint8List encode({String ext = 'apng'}) =>
      Codecs.encodeForExtension(toImage(), ext);

  /// Encode as **animated WebP** when possible, falling back to APNG when the
  /// platform can't produce WebP (e.g. web build, or native without libwebpmux).
  /// Returns the bytes and the extension actually used.
  Future<({Uint8List bytes, String ext})> encodePreferWebp({
    bool lossless = false,
    int quality = 90,
  }) async {
    final WebpResult r = await WebpEncoder.instance.encodeAnimation(
      frames.map((AnimFrame f) => f.image).toList(),
      frames.map((AnimFrame f) => f.delayMs).toList(),
      lossless: lossless,
      quality: quality,
    );
    if (r.ok && r.bytes != null) {
      return (bytes: r.bytes!, ext: 'webp');
    }
    return (bytes: encode(ext: 'apng'), ext: 'apng');
  }
}
