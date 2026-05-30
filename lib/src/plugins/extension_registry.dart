import '../animation/anim_engine.dart';
import '../animation/easing.dart';
import '../imaging/color_ops.dart';
import '../presets/presets.dart';
import 'pack.dart';

/// The single place the rest of the app asks "what presets / palettes / recipes
/// are available?". It merges the built-in [PresetLibrary] with every installed
/// [PinselPack], and exposes the code-level extension hooks for native
/// plugins. Listen to [revision] to refresh UI when packs change.
class ExtensionRegistry {
  ExtensionRegistry._();

  static final ExtensionRegistry instance = ExtensionRegistry._();

  final List<PinselPack> _packs = <PinselPack>[];

  /// Bumped whenever the available content changes (install/remove pack, or a
  /// native plugin registers a code op). UI can watch this to rebuild.
  int revision = 0;

  List<PinselPack> get packs => List<PinselPack>.unmodifiable(_packs);

  // ---- merged content (built-in + packs) ----

  List<OpPipeline> get colorPresets => <OpPipeline>[
        ...PresetLibrary.colorPresets,
        for (final PinselPack p in _packs) ...p.colorPresets,
      ];

  List<NamedPalette> get palettes => <NamedPalette>[
        ...PresetLibrary.palettes,
        for (final PinselPack p in _packs) ...p.palettes,
      ];

  List<NamedGradient> get gradients => <NamedGradient>[
        ...PresetLibrary.gradients,
        for (final PinselPack p in _packs) ...p.gradients,
      ];

  List<AnimPreset> get animPresets => <AnimPreset>[
        ...PresetLibrary.animPresets,
        for (final PinselPack p in _packs) ...p.animPresets,
      ];

  List<EmoteNameSet> get emoteNameSets => <EmoteNameSet>[
        ...PresetLibrary.emoteNameSets,
        for (final PinselPack p in _packs) ...p.emoteNameSets,
      ];

  // ---- pack management (works on every platform, including web) ----

  void installPack(PinselPack pack) {
    _packs.removeWhere((PinselPack p) => p.name == pack.name);
    _packs.add(pack);
    revision++;
  }

  PinselPack installPackJson(String json) {
    final PinselPack pack = PinselPack.fromJsonString(json);
    installPack(pack);
    return pack;
  }

  void removePack(String name) {
    _packs.removeWhere((PinselPack p) => p.name == name);
    revision++;
  }

  // ---- native code-plugin hooks ----

  /// Register a new colour op (id must be unique). Native plugins only.
  void registerColorOp(String id, OpApply fn) {
    ImageOps.register(id, fn);
    revision++;
  }

  /// Register a new animation recipe. Native plugins only.
  void registerRecipe(String id, RecipeFn fn) {
    AnimEngine.register(id, fn);
    revision++;
  }

  /// Register a new easing curve. Native plugins only.
  void registerEasing(String id, double Function(double) fn) {
    Easing.register(id, fn);
    revision++;
  }

  /// Counts for the "Plugins" screen.
  int get installedItemCount =>
      _packs.fold(0, (int sum, PinselPack p) => sum + p.itemCount);
}
