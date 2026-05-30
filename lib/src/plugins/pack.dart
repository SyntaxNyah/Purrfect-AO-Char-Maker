import 'dart:convert';

import '../animation/anim_engine.dart';
import '../imaging/color_ops.dart';
import '../presets/presets.dart';

/// A drop-in content pack: pure JSON that composes the app's built-in ops and
/// recipes into new presets, palettes, gradients, animations and name sets.
///
/// Because packs contain *data only* (no code), they load identically on
/// desktop, mobile and the web — paste a URL, pick a file, or bundle them. This
/// is the safe, cross-platform half of the plugin system; native code plugins
/// (new ops/recipes/easings) register through [ImageOps.register],
/// [AnimEngine.register] and the easing registry.
class PinselPack {
  PinselPack({
    required this.name,
    this.author = 'unknown',
    this.version = '1.0.0',
    this.description = '',
    List<OpPipeline>? colorPresets,
    List<NamedPalette>? palettes,
    List<NamedGradient>? gradients,
    List<AnimPreset>? animPresets,
    List<EmoteNameSet>? emoteNameSets,
  })  : colorPresets = colorPresets ?? <OpPipeline>[],
        palettes = palettes ?? <NamedPalette>[],
        gradients = gradients ?? <NamedGradient>[],
        animPresets = animPresets ?? <AnimPreset>[],
        emoteNameSets = emoteNameSets ?? <EmoteNameSet>[];

  final String name;
  final String author;
  final String version;
  final String description;
  final List<OpPipeline> colorPresets;
  final List<NamedPalette> palettes;
  final List<NamedGradient> gradients;
  final List<AnimPreset> animPresets;
  final List<EmoteNameSet> emoteNameSets;

  int get itemCount =>
      colorPresets.length +
      palettes.length +
      gradients.length +
      animPresets.length +
      emoteNameSets.length;

  static PinselPack fromJsonString(String s) =>
      fromJson(jsonDecode(s) as Map<String, dynamic>);

  static PinselPack fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) =>
        ((j[key] as List?) ?? <dynamic>[])
            .map((dynamic e) => f((e as Map).cast<String, dynamic>()))
            .toList();

    return PinselPack(
      name: j['name'] as String? ?? 'Unnamed Pack',
      author: j['author'] as String? ?? 'unknown',
      version: j['version'] as String? ?? '1.0.0',
      description: j['description'] as String? ?? '',
      colorPresets: list<OpPipeline>('colorPresets', OpPipeline.fromJson),
      palettes: list<NamedPalette>('palettes', _paletteFromJson),
      gradients: list<NamedGradient>('gradients', _gradientFromJson),
      animPresets: list<AnimPreset>('animPresets', _animPresetFromJson),
      emoteNameSets: list<EmoteNameSet>('emoteNameSets', _nameSetFromJson),
    );
  }

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'author': author,
        'version': version,
        'description': description,
        'colorPresets': colorPresets.map((OpPipeline p) => p.toJson()).toList(),
        'palettes': palettes.map(_paletteToJson).toList(),
        'gradients': gradients.map(_gradientToJson).toList(),
        'animPresets': animPresets.map(_animPresetToJson).toList(),
        'emoteNameSets': emoteNameSets.map(_nameSetToJson).toList(),
      };

  // ---- element (de)serialisers ----

  static NamedPalette _paletteFromJson(Map<String, dynamic> j) => NamedPalette(
        j['name'] as String? ?? 'Palette',
        j['category'] as String? ?? 'Custom',
        ((j['colors'] as List?) ?? <dynamic>[])
            .map((dynamic c) => parseHexColor(c.toString()) ?? 0xFFFFFFFF)
            .toList(),
      );

  static Map<String, dynamic> _paletteToJson(NamedPalette p) => <String, dynamic>{
        'name': p.name,
        'category': p.category,
        'colors': p.colors.map(formatHexColor).toList(),
      };

  static NamedGradient _gradientFromJson(Map<String, dynamic> j) => NamedGradient(
        j['name'] as String? ?? 'Gradient',
        ((j['stops'] as List?) ?? <dynamic>[])
            .map((dynamic c) => parseHexColor(c.toString()) ?? 0xFFFFFFFF)
            .toList(),
      );

  static Map<String, dynamic> _gradientToJson(NamedGradient g) => <String, dynamic>{
        'name': g.name,
        'stops': g.stops.map(formatHexColor).toList(),
      };

  static AnimPreset _animPresetFromJson(Map<String, dynamic> j) => AnimPreset(
        j['name'] as String? ?? 'Animation',
        j['category'] as String? ?? 'Custom',
        ((j['recipes'] as List?) ?? <dynamic>[])
            .map((dynamic e) => AnimRecipe.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        frames: (j['frames'] as num?)?.toInt() ?? 12,
        fps: (j['fps'] as num?)?.toInt() ?? 12,
      );

  static Map<String, dynamic> _animPresetToJson(AnimPreset a) => <String, dynamic>{
        'name': a.name,
        'category': a.category,
        'frames': a.frames,
        'fps': a.fps,
        'recipes': a.recipes.map((AnimRecipe r) => r.toJson()).toList(),
      };

  static EmoteNameSet _nameSetFromJson(Map<String, dynamic> j) => EmoteNameSet(
        j['name'] as String? ?? 'Names',
        ((j['names'] as List?) ?? <dynamic>[]).map((dynamic e) => e.toString()).toList(),
      );

  static Map<String, dynamic> _nameSetToJson(EmoteNameSet n) => <String, dynamic>{
        'name': n.name,
        'names': n.names,
      };
}
