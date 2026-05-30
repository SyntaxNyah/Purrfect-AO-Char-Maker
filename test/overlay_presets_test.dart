import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pinsel/src/imaging/overlay_presets.dart';

void main() {
  test('presets exist, are categorised, and cover the themed sets', () {
    expect(OverlayPresets.borders, isNotEmpty);
    expect(OverlayPresets.backgrounds, isNotEmpty);
    expect(OverlayPresets.borders.every((OverlayPreset p) => p.kind == OverlayKind.border),
        isTrue);
    expect(
        OverlayPresets.backgrounds
            .every((OverlayPreset p) => p.kind == OverlayKind.background),
        isTrue);

    final Set<String> cats = <String>{
      for (final OverlayPreset p in OverlayPresets.borders) p.category,
      for (final OverlayPreset p in OverlayPresets.backgrounds) p.category,
    };
    expect(cats, containsAll(<String>['Umineko', 'Danganronpa', 'Kawaii', 'Colours']));
  });

  test('every OverlayStyle builds via a spec (covers the builder)', () {
    for (final OverlayStyle style in OverlayStyle.values) {
      expect(stylesForKind(style.kind), contains(style),
          reason: '$style should be listed for its kind');
      final OverlaySpec spec = OverlaySpec(style: style);
      for (final int size in <int>[16, 64]) {
        final img.Image im = spec.build(size);
        expect(im.width, size, reason: '$style width @ $size');
        expect(im.height, size, reason: '$style height @ $size');
        expect(im.numChannels, 4, reason: '$style channels');
      }
    }
  });

  test('every preset builds a size×size RGBA image at any size', () {
    final List<OverlayPreset> all = <OverlayPreset>[
      ...OverlayPresets.borders,
      ...OverlayPresets.backgrounds,
    ];
    for (final int size in <int>[16, 48, 128]) {
      for (final OverlayPreset p in all) {
        final img.Image im = p.build(size);
        expect(im.width, size, reason: '${p.name} (${p.kind}) width @ $size');
        expect(im.height, size, reason: '${p.name} (${p.kind}) height @ $size');
        expect(im.numChannels, 4, reason: '${p.name} (${p.kind}) channels');
      }
    }
  });
}
