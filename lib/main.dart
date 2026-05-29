import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/app.dart';
import 'src/ui/app_state.dart';

void main() {
  runApp(
    ChangeNotifierProvider<AppState>(
      create: (_) => AppState(),
      child: const PurrfectApp(),
    ),
  );
}
