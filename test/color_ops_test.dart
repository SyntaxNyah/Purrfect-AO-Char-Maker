import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:purrfect/src/imaging/color_ops.dart';

img.Image _solid(int r, int g, int b, int a) {
  final img.Image im = img.Image(width: 2, height: 2, numChannels: 4);
  for (int y = 0; y < 2; y++) {
    for (int x = 0; x < 2; x++) {
      im.setPixelRgba(x, y, r, g, b, a);
    }
  }
  return im;
}

void main() {
  test('invert flips RGB', () {
    final img.Image im = _solid(255, 0, 0, 255);
    ImageOps.apply(im, ColorOp('invert'));
    final img.Pixel p = im.getPixel(0, 0);
    expect(p.r, 0);
    expect(p.g, 255);
    expect(p.b, 255);
  });

  test('hueShift 120° turns red into green', () {
    final img.Image im = _solid(255, 0, 0, 255);
    ImageOps.apply(im, ColorOp('hueShift', nums: <String, double>{'degrees': 120}));
    final img.Pixel p = im.getPixel(0, 0);
    expect(p.g, greaterThan(200));
    expect(p.r, lessThan(60));
    expect(p.b, lessThan(60));
  });

  test('fully transparent pixels are never recoloured', () {
    final img.Image im = _solid(255, 0, 0, 0);
    ImageOps.apply(im, ColorOp('invert'));
    final img.Pixel p = im.getPixel(0, 0);
    expect(p.r, 255); // unchanged because alpha == 0
  });

  test('colorize preserves brightness ordering', () {
    final img.Image im = img.Image(width: 2, height: 1, numChannels: 4)
      ..setPixelRgba(0, 0, 30, 30, 30, 255)
      ..setPixelRgba(1, 0, 220, 220, 220, 255);
    ImageOps.apply(im, ColorOp('colorize', nums: <String, double>{'hue': 300, 'saturation': 0.8}));
    final int lDark = im.getPixel(0, 0).r.toInt() + im.getPixel(0, 0).g.toInt();
    final int lLight = im.getPixel(1, 0).r.toInt() + im.getPixel(1, 0).g.toInt();
    expect(lLight, greaterThan(lDark));
  });

  test('ColorOp JSON round-trips', () {
    final ColorOp op = ColorOp('tint',
        nums: <String, double>{'amount': 0.5}, strs: <String, String>{'color': '#FF112233'});
    final ColorOp back = ColorOp.fromJson(op.toJson());
    expect(back.type, 'tint');
    expect(back.n('amount'), 0.5);
    expect(back.s('color'), '#FF112233');
  });

  test('hex colour parsing handles #rgb/argb forms', () {
    expect(parseHexColor('#FFFFFF'), 0xFFFFFFFF);
    expect(parseHexColor('00FF00'), 0xFF00FF00);
    expect(parseHexColor('#8000FF00'), 0x8000FF00);
    expect(parseHexColor('nope'), isNull);
  });
}
