import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pinsel/src/core/ao_constants.dart';
import 'package:pinsel/src/imaging/button_maker.dart';
import 'package:pinsel/src/imaging/codecs.dart';

/// A crude standing-figure silhouette: a narrow head at the top over a wide
/// body, on a 100×200 transparent canvas.
img.Image _figure() {
  final img.Image im = img.Image(width: 100, height: 200, numChannels: 4);
  void fill(int x0, int y0, int x1, int y1) {
    for (int y = y0; y < y1; y++) {
      for (int x = x0; x < x1; x++) {
        im.setPixelRgba(x, y, 220, 180, 150, 255);
      }
    }
  }

  fill(42, 12, 58, 50); // head (width 16, centred on x≈50)
  fill(46, 50, 54, 62); // neck
  fill(20, 62, 80, 190); // shoulders + body (width 60)
  return im;
}

void main() {
  group('CropFraming', () {
    test('fromId round-trips and defaults to head', () {
      expect(CropFraming.fromId('head'), CropFraming.head);
      expect(CropFraming.fromId('full'), CropFraming.full);
      expect(CropFraming.fromId('nonsense'), CropFraming.defaultValue);
      expect(CropFraming.defaultValue, CropFraming.head);
    });
  });

  group('ButtonMaker.headSquare', () {
    test('frames the head near the top, not the whole body', () {
      final IntRect r = ButtonMaker.headSquare(_figure());
      expect(r.w, r.h, reason: 'must be square');
      expect(r.w, lessThan(120), reason: 'should not span the whole 200px body');
      // Horizontal centre lands on the figure (≈x50).
      final double cx = r.x + r.w / 2;
      expect(cx, greaterThan(30));
      expect(cx, lessThan(70));
      // Vertically anchored to the upper part of the canvas (the face).
      expect(r.y, lessThan(80));
      // Always inside the image.
      expect(r.x, greaterThanOrEqualTo(0));
      expect(r.y, greaterThanOrEqualTo(0));
      expect(r.x + r.w, lessThanOrEqualTo(100));
      expect(r.y + r.h, lessThanOrEqualTo(200));
    });

    test('zoom > 1 tightens (smaller) and < 1 loosens (larger)', () {
      final int tight = ButtonMaker.headSquare(_figure(), zoom: 1.5).w;
      final int normal = ButtonMaker.headSquare(_figure(), zoom: 1.0).w;
      final int loose = ButtonMaker.headSquare(_figure(), zoom: 0.7).w;
      expect(tight, lessThan(normal));
      expect(loose, greaterThan(normal));
    });
  });

  group('ButtonMaker.renderFramed', () {
    test('outputs a size×size PNG', () {
      final Uint8List png = ButtonMaker.renderFramed(_figure(), 48);
      final img.Image? out = Codecs.decode(png, ext: 'png');
      expect(out, isNotNull);
      expect(out!.width, 48);
      expect(out.height, 48);
    });

    test('a fully-opaque foreground overlay is composited on top', () {
      final img.Image border = img.Image(width: 10, height: 10, numChannels: 4);
      for (int y = 0; y < 10; y++) {
        for (int x = 0; x < 10; x++) {
          border.setPixelRgba(x, y, 255, 0, 0, 255); // solid red
        }
      }
      final Uint8List png =
          ButtonMaker.renderFramed(_figure(), 16, foreground: border);
      final img.Image out = Codecs.decode(png, ext: 'png')!;
      final img.Pixel p = out.getPixel(8, 8);
      expect(p.r.toInt(), 255);
      expect(p.g.toInt(), 0);
      expect(p.b.toInt(), 0);
    });

    test('offset shifts the crop (different pixels than no offset)', () {
      final Uint8List a = ButtonMaker.renderFramed(_figure(), 32, offsetY: 0);
      final Uint8List b = ButtonMaker.renderFramed(_figure(), 32, offsetY: 0.4);
      expect(a, isNot(equals(b)));
    });
  });
}
