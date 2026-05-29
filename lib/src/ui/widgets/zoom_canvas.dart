import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'checker_image.dart';

/// A zoomable / pannable sprite viewport (sprites are for a chatroom, so quick
/// zoom matters). Wraps [CheckerImage] in an [InteractiveViewer].
class ZoomCanvas extends StatelessWidget {
  const ZoomCanvas({super.key, required this.bytes, this.minScale = 0.25, this.maxScale = 16});

  final Uint8List? bytes;
  final double minScale;
  final double maxScale;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: InteractiveViewer(
        minScale: minScale,
        maxScale: maxScale,
        boundaryMargin: const EdgeInsets.all(400),
        child: CheckerImage(bytes: bytes),
      ),
    );
  }
}
