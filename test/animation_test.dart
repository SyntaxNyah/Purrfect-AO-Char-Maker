import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:purrfect/src/animation/anim_engine.dart';
import 'package:purrfect/src/animation/anim_clip.dart';
import 'package:purrfect/src/animation/easing.dart';
import 'package:purrfect/src/animation/timeline.dart';

img.Image _base() => img.Image(width: 8, height: 8, numChannels: 4)
  ..setPixelRgba(4, 4, 255, 128, 0, 255);

void main() {
  test('render produces the requested number of same-size frames', () {
    final AnimClip clip = AnimEngine.render(
      _base(),
      <AnimRecipe>[AnimRecipe('spin', p: <String, double>{'cycles': 1})],
      frames: 6,
      fps: 12,
    );
    expect(clip.frames.length, 6);
    for (final AnimFrame f in clip.frames) {
      expect(f.image.width, 8);
      expect(f.image.height, 8);
    }
  });

  test('stacked recipes combine without error', () {
    final AnimClip clip = AnimEngine.render(
      _base(),
      <AnimRecipe>[
        AnimRecipe('bounce', p: <String, double>{'intensity': 4}),
        AnimRecipe('glow', p: <String, double>{'intensity': 0.6}),
        AnimRecipe('rainbow', p: <String, double>{'cycles': 1}),
      ],
      frames: 4,
    );
    expect(clip.frames.length, 4);
  });

  test('recipe registry exposes the built-ins', () {
    expect(AnimEngine.recipeTypes, contains('glow'));
    expect(AnimEngine.recipeTypes, contains('spin'));
    expect(AnimEngine.recipeTypes, contains('heartbeat'));
  });

  test('AnimRecipe JSON round-trips including region and easing', () {
    final AnimRecipe r = AnimRecipe('sway',
        p: <String, double>{'intensity': 7}, ease: 'easeOutBack');
    final AnimRecipe back = AnimRecipe.fromJson(r.toJson());
    expect(back.type, 'sway');
    expect(back.n('intensity'), 7);
    expect(back.ease, 'easeOutBack');
  });

  test('easing curves are clamped and named', () {
    expect(Easing.apply('linear', 0.5), closeTo(0.5, 1e-9));
    expect(Easing.apply('easeOutQuad', 0), 0);
    expect(Easing.apply('easeOutQuad', 1), 1);
    expect(Easing.names, contains('elastic'));
  });

  test('timeline interpolates between keyframes', () {
    final Timeline tl = Timeline(<Keyframe>[
      Keyframe(time: 0, dx: 0),
      Keyframe(time: 1, dx: 10),
    ]);
    expect(tl.specAt(0).dx, closeTo(0, 1e-6));
    expect(tl.specAt(0.5).dx, closeTo(5, 1e-6));
    final AnimClip clip = tl.render(_base(), frames: 5);
    expect(clip.frames.length, 5);
  });
}
