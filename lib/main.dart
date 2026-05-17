import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenno/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Zenno is a landscape-first tablet app; lock orientation before first frame.
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ProviderScope(child: ZennoApp()));
}
