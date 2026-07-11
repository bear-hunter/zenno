import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/database/database_exceptions.dart';
import 'package:zenno/core/database/tables/settings_tables.dart';
import 'package:zenno/features/library/application/library_providers.dart';
import 'package:zenno/features/library/presentation/pages/library_page.dart';

void main() {
  testWidgets('explains when another web tab owns the database', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySortProvider.overrideWithValue(LibrarySort.recent),
          canvasListProvider.overrideWith(
            (ref) => Stream<List<Canvase>>.error(
              StateError(databaseAlreadyOpenMessage),
            ),
          ),
          canvasFolderListProvider.overrideWith(
            (ref) => Stream<List<CanvasFolder>>.value(const []),
          ),
        ],
        child: const MaterialApp(home: LibraryPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Zenno is open in another tab'), findsOneWidget);
    expect(
      find.text('Close the other tab, then reload this page.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsNothing);
  });
}
