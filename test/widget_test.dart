// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:budgex/providers/security_provider.dart';
import 'package:budgex/screens/security_lock_screen.dart';
import 'package:budgex/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


import 'package:provider/provider.dart';


void main() {
  test('project smoke test', () {
    expect(1 + 1, 2);
  });

  testWidgets('security lock screen survives keyboard inset', (tester) async {
    final view = tester.view;
    view.devicePixelRatio = 1;
    view.physicalSize = const Size(390, 520);
    view.viewInsets = const FakeViewPadding(bottom: 300);

    addTearDown(view.resetDevicePixelRatio);
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetViewInsets);

    await _pumpSecurityLockScreen(tester);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Show PIN'), findsOneWidget);
  });

  testWidgets('security lock PIN visibility button toggles obscure text', (
    tester,
  ) async {
    await _pumpSecurityLockScreen(tester);
    await tester.pump();

    expect(find.byTooltip('Show PIN'), findsOneWidget);
    expect(
      find.widgetWithIcon(IconButton, Icons.visibility_off_rounded),
      findsOneWidget,
    );

    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.visibility_off_rounded),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Hide PIN'), findsOneWidget);
    expect(
      find.widgetWithIcon(IconButton, Icons.visibility_rounded),
      findsOneWidget,
    );
  });
}

Future<void> _pumpSecurityLockScreen(WidgetTester tester) {
  return tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => SecurityProvider(),
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const SecurityLockScreen(),
      ),
    ),
  );
}
