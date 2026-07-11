import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/config/theme/app_theme.dart';

void main() {
  test('custom system colors feed generated themes', () {
    final theme = AppTheme.darkWith(
      accentColor: const Color(0xFF1E9BFF),
      backgroundColor: const Color(0xFF172331),
    );

    expect(theme.colorScheme.primary, const Color(0xFF1E9BFF));
    expect(theme.scaffoldBackgroundColor, const Color(0xFF172331));
    expect(theme.colorScheme.surface, const Color(0xFF172331));
  });
}
