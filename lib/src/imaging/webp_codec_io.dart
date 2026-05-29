import 'dart:ffi' as ffi;
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:image/image.dart' as img;

import 'webp_codec.dart';

// ---- libwebp C signatures ----
// size_t WebPEncodeRGBA(const uint8_t*, int w, int h, int stride, float q, uint8_t** out);
typedef _EncRgbaC = ffi.IntPtr Function(ffi.Pointer<ffi.Uint8>, ffi.Int32,
    ffi.Int32, ffi.Int32, ffi.Float, ffi.Pointer<ffi.Pointer<ffi.Uint8>>);
typedef _EncRgbaD = int Function(ffi.Pointer<ffi.Uint8>, int, int, int, double,
    ffi.Pointer<ffi.Pointer<ffi.Uint8>>);
// size_t WebPEncodeLosslessRGBA(const uint8_t*, int w, int h, int stride, uint8_t** out);
typedef _EncLosslessC = ffi.IntPtr Function(ffi.Pointer<ffi.Uint8>, ffi.Int32,
    ffi.Int32, ffi.Int32, ffi.Pointer<ffi.Pointer<ffi.Uint8>>);
typedef _EncLosslessD = int Function(
    ffi.Pointer<ffi.Uint8>, int, int, int, ffi.Pointer<ffi.Pointer<ffi.Uint8>>);
// void WebPFree(void*);
typedef _FreeC = ffi.Void Function(ffi.Pointer<ffi.Void>);
typedef _FreeD = void Function(ffi.Pointer<ffi.Void>);

// ---- libwebp(mux) animation encoder signatures (all structs passed as void*
// buffers; we only poke the well-known leading fields, which are ABI-stable) ----
typedef _I32VoidI32C = ffi.Int32 Function(ffi.Pointer<ffi.Void>, ffi.Int32);
typedef _I32VoidI32D = int Function(ffi.Pointer<ffi.Void>, int);
typedef _AnimNewC = ffi.Pointer<ffi.Void> Function(
    ffi.Int32, ffi.Int32, ffi.Pointer<ffi.Void>, ffi.Int32);
typedef _AnimNewD = ffi.Pointer<ffi.Void> Function(
    int, int, ffi.Pointer<ffi.Void>, int);
typedef _AnimAddC = ffi.Int32 Function(
    ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>, ffi.Int32, ffi.Pointer<ffi.Void>);
typedef _AnimAddD = int Function(
    ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>, int, ffi.Pointer<ffi.Void>);
typedef _AnimAssembleC = ffi.Int32 Function(
    ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>);
typedef _AnimAssembleD = int Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>);
typedef _VoidPtrC = ffi.Void Function(ffi.Pointer<ffi.Void>);
typedef _VoidPtrD = void Function(ffi.Pointer<ffi.Void>);
typedef _PicImportC = ffi.Int32 Function(
    ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Uint8>, ffi.Int32);
typedef _PicImportD = int Function(
    ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Uint8>, int);
typedef _ConfigInitC = ffi.Int32 Function(
    ffi.Pointer<ffi.Void>, ffi.Int32, ffi.Float, ffi.Int32);
typedef _ConfigInitD = int Function(ffi.Pointer<ffi.Void>, int, double, int);

/// Native WebP encoder backed by libwebp via dart:ffi.
///
/// It dynamically loads a libwebp shared library if one is available (bundled
/// next to the app, or installed system-wide). When no library is found it
/// degrades gracefully and reports the situation, so the app still runs and
/// callers fall back to APNG/PNG.
///
/// Installing libwebp:
///  * Windows: place `libwebp.dll` beside the executable.
///  * Linux:   `apt install libwebp7` / `dnf install libwebp` (or bundle .so).
///  * macOS:   `brew install webp`.
///  * Android: bundle `libwebp.so` per-ABI (jniLibs).
///  * iOS:     statically link libwebp into the runner.
/// See docs/PLUGINS.md for details.
class NativeWebpEncoder implements WebpEncoder {
  NativeWebpEncoder() {
    _tryLoad();
  }

  ffi.DynamicLibrary? _lib;
  _EncRgbaD? _encRgba;
  _EncLosslessD? _encLossless;
  _FreeD? _free;

  @override
  bool get supportsLossy => _encRgba != null && _free != null;

  @override
  bool get supportsLossless => _encLossless != null && _free != null;

  void _tryLoad() {
    for (final String name in _candidateLibs()) {
      try {
        final ffi.DynamicLibrary lib = name == '<process>'
            ? ffi.DynamicLibrary.process()
            : ffi.DynamicLibrary.open(name);
        _encRgba = lib.lookupFunction<_EncRgbaC, _EncRgbaD>('WebPEncodeRGBA');
        _encLossless =
            lib.lookupFunction<_EncLosslessC, _EncLosslessD>('WebPEncodeLosslessRGBA');
        _free = lib.lookupFunction<_FreeC, _FreeD>('WebPFree');
        _lib = lib;
        return;
      } catch (_) {
        // Try the next candidate.
      }
    }
  }

  List<String> _candidateLibs() {
    if (Platform.isWindows) {
      return <String>['libwebp.dll', 'webp.dll'];
    }
    if (Platform.isMacOS) {
      return <String>[
        'libwebp.dylib',
        '/opt/homebrew/lib/libwebp.dylib',
        '/usr/local/lib/libwebp.dylib',
        '<process>',
      ];
    }
    if (Platform.isIOS) {
      return <String>['<process>'];
    }
    // Linux / Android
    return <String>['libwebp.so', 'libwebp.so.7', 'libwebp.so.6'];
  }

  @override
  Future<WebpResult> encode(img.Image image,
      {bool lossless = false, int quality = 90}) async {
    if (_lib == null || _free == null) {
      return WebpResult.fail(
        'libwebp not found. Bundle/install it (see docs/PLUGINS.md) for native '
        'WebP, or use the web build where WebP works out of the box.',
      );
    }
    if (lossless && _encLossless == null) {
      return WebpResult.fail('libwebp present but lossless export unavailable.');
    }
    if (!lossless && _encRgba == null) {
      return WebpResult.fail('libwebp present but lossy export unavailable.');
    }

    final img.Image frame =
        image.frames.isNotEmpty ? image.frames.first : image;
    final img.Image rgbaImg =
        frame.numChannels == 4 ? frame : frame.convert(numChannels: 4);
    final Uint8List rgba = rgbaImg.getBytes(order: img.ChannelOrder.rgba);
    final int w = rgbaImg.width;
    final int h = rgbaImg.height;
    final int stride = w * 4;

    final ffi.Pointer<ffi.Uint8> inPtr = malloc<ffi.Uint8>(rgba.length);
    final ffi.Pointer<ffi.Pointer<ffi.Uint8>> outPtrPtr =
        malloc<ffi.Pointer<ffi.Uint8>>();
    try {
      inPtr.asTypedList(rgba.length).setAll(0, rgba);
      final int size = lossless
          ? _encLossless!(inPtr, w, h, stride, outPtrPtr)
          : _encRgba!(inPtr, w, h, stride, quality.clamp(0, 100).toDouble(),
              outPtrPtr);
      if (size == 0) {
        return WebpResult.fail('libwebp returned an empty buffer.');
      }
      final ffi.Pointer<ffi.Uint8> outPtr = outPtrPtr.value;
      final Uint8List bytes = Uint8List.fromList(outPtr.asTypedList(size));
      _free!(outPtr.cast<ffi.Void>());
      return WebpResult.ok(bytes);
    } catch (e) {
      return WebpResult.fail('Native WebP encode failed: $e');
    } finally {
      malloc.free(inPtr);
      malloc.free(outPtrPtr);
    }
  }

  // WEBP ABI versions for libwebp 1.x (used by the *Internal init functions).
  static const int _kEncoderAbi = 0x020f;
  static const int _kMuxAbi = 0x0108;

  @override
  Future<WebpResult> encodeAnimation(
    List<img.Image> frames,
    List<int> frameDurationsMs, {
    bool lossless = false,
    int quality = 90,
  }) async {
    if (_lib == null) {
      return WebpResult.fail('libwebp not found (see docs/PLUGINS.md).');
    }
    if (frames.isEmpty) return WebpResult.fail('No frames to encode.');

    final ffi.DynamicLibrary base = _lib!;
    final ffi.DynamicLibrary mux = _openMux() ?? base;

    final _I32VoidI32D optInit;
    final _AnimNewD animNew;
    final _AnimAddD animAdd;
    final _AnimAssembleD assemble;
    final _VoidPtrD animDelete;
    final _VoidPtrD dataClear;
    final _I32VoidI32D picInit;
    final _PicImportD picImport;
    final _VoidPtrD picFree;
    final _ConfigInitD configInit;
    try {
      optInit = mux.lookupFunction<_I32VoidI32C, _I32VoidI32D>('WebPAnimEncoderOptionsInitInternal');
      animNew = mux.lookupFunction<_AnimNewC, _AnimNewD>('WebPAnimEncoderNewInternal');
      animAdd = mux.lookupFunction<_AnimAddC, _AnimAddD>('WebPAnimEncoderAdd');
      assemble = mux.lookupFunction<_AnimAssembleC, _AnimAssembleD>('WebPAnimEncoderAssemble');
      animDelete = mux.lookupFunction<_VoidPtrC, _VoidPtrD>('WebPAnimEncoderDelete');
      dataClear = mux.lookupFunction<_VoidPtrC, _VoidPtrD>('WebPDataClear');
      picInit = base.lookupFunction<_I32VoidI32C, _I32VoidI32D>('WebPPictureInitInternal');
      picImport = base.lookupFunction<_PicImportC, _PicImportD>('WebPPictureImportRGBA');
      picFree = base.lookupFunction<_VoidPtrC, _VoidPtrD>('WebPPictureFree');
      configInit = base.lookupFunction<_ConfigInitC, _ConfigInitD>('WebPConfigInitInternal');
    } catch (e) {
      return WebpResult.fail(
          'Animated WebP needs libwebpmux + libwebp encoder symbols: $e');
    }

    final img.Image first = frames.first;
    final int w = first.width, h = first.height;

    final ffi.Pointer<ffi.Uint8> opts = calloc<ffi.Uint8>(256);
    final ffi.Pointer<ffi.Uint8> config = calloc<ffi.Uint8>(256);
    final ffi.Pointer<ffi.Uint8> pic = calloc<ffi.Uint8>(4096);
    final ffi.Pointer<ffi.Uint8> data = calloc<ffi.Uint8>(32);
    ffi.Pointer<ffi.Void> enc = ffi.nullptr;
    try {
      if (optInit(opts.cast<ffi.Void>(), _kMuxAbi) == 0) {
        return WebpResult.fail('Animated WebP: options init failed.');
      }
      enc = animNew(w, h, opts.cast<ffi.Void>(), _kMuxAbi);
      if (enc == ffi.nullptr) {
        return WebpResult.fail('Animated WebP: encoder allocation failed.');
      }
      if (configInit(config.cast<ffi.Void>(), 0,
              quality.clamp(0, 100).toDouble(), _kEncoderAbi) ==
          0) {
        return WebpResult.fail('Animated WebP: config init failed.');
      }
      config.cast<ffi.Int32>().value = lossless ? 1 : 0; // .lossless @ offset 0

      int timestamp = 0;
      for (int i = 0; i < frames.length; i++) {
        final img.Image f =
            frames[i].numChannels == 4 ? frames[i] : frames[i].convert(numChannels: 4);
        final Uint8List rgba = f.getBytes(order: img.ChannelOrder.rgba);
        final ffi.Pointer<ffi.Uint8> rgbaPtr = calloc<ffi.Uint8>(rgba.length);
        try {
          if (picInit(pic.cast<ffi.Void>(), _kEncoderAbi) == 0) {
            return WebpResult.fail('Animated WebP: picture init failed.');
          }
          pic.cast<ffi.Int32>().value = 1; // use_argb @ offset 0
          ffi.Pointer<ffi.Int32>.fromAddress(pic.address + 8).value = w; // width
          ffi.Pointer<ffi.Int32>.fromAddress(pic.address + 12).value = h; // height
          rgbaPtr.asTypedList(rgba.length).setAll(0, rgba);
          if (picImport(pic.cast<ffi.Void>(), rgbaPtr, w * 4) == 0) {
            picFree(pic.cast<ffi.Void>());
            return WebpResult.fail('Animated WebP: RGBA import failed.');
          }
          final int added = animAdd(enc, pic.cast<ffi.Void>(), timestamp, config.cast<ffi.Void>());
          picFree(pic.cast<ffi.Void>());
          if (added == 0) {
            return WebpResult.fail('Animated WebP: add frame $i failed.');
          }
        } finally {
          calloc.free(rgbaPtr);
        }
        timestamp += i < frameDurationsMs.length ? frameDurationsMs[i] : 100;
      }
      // Final NULL frame flushes the last duration.
      animAdd(enc, ffi.nullptr, timestamp, ffi.nullptr);
      if (assemble(enc, data.cast<ffi.Void>()) == 0) {
        return WebpResult.fail('Animated WebP: assemble failed.');
      }
      final ffi.Pointer<ffi.Uint8> outPtr = data.cast<ffi.Pointer<ffi.Uint8>>().value;
      final int size = ffi.Pointer<ffi.IntPtr>.fromAddress(data.address + 8).value;
      if (outPtr == ffi.nullptr || size <= 0) {
        return WebpResult.fail('Animated WebP: empty output.');
      }
      final Uint8List bytes = Uint8List.fromList(outPtr.asTypedList(size));
      dataClear(data.cast<ffi.Void>());
      return WebpResult.ok(bytes);
    } catch (e) {
      return WebpResult.fail('Animated WebP encode failed: $e');
    } finally {
      if (enc != ffi.nullptr) animDelete(enc);
      calloc.free(opts);
      calloc.free(config);
      calloc.free(pic);
      calloc.free(data);
    }
  }

  ffi.DynamicLibrary? _openMux() {
    final List<String> names = Platform.isWindows
        ? <String>['libwebpmux.dll', 'webpmux.dll']
        : Platform.isMacOS
            ? <String>[
                'libwebpmux.dylib',
                '/opt/homebrew/lib/libwebpmux.dylib',
                '/usr/local/lib/libwebpmux.dylib',
              ]
            : <String>['libwebpmux.so', 'libwebpmux.so.3'];
    for (final String n in names) {
      try {
        return ffi.DynamicLibrary.open(n);
      } catch (_) {}
    }
    return null;
  }
}

WebpEncoder makeWebpEncoder() => NativeWebpEncoder();
