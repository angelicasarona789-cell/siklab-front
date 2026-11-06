import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklab/navigation/shell_navigator.dart';
import 'package:siklab/theme/app_theme.dart';
import 'package:siklab/widgets/shared_widgets.dart';

void main() {
  testWidgets('back button invokes the shell tab history action',
      (tester) async {
    var wentBack = false;
    final themeNotifier = ThemeNotifier();
    addTearDown(themeNotifier.dispose);

    await tester.pumpWidget(
      SiklabThemeScope(
        notifier: themeNotifier,
        child: MaterialApp(
          home: ShellNavigator(
            setIndex: (_) {},
            onBack: () => wentBack = true,
            child: const Scaffold(
              body: Center(child: SiklabBackButton()),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Back'));
    expect(wentBack, isTrue);
  });

  testWidgets('demo accounts are available in the hamburger menu',
      (tester) async {
    final themeNotifier = ThemeNotifier();
    addTearDown(themeNotifier.dispose);

    await tester.pumpWidget(
      SiklabThemeScope(
        notifier: themeNotifier,
        child: const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topRight,
              child: SiklabHamburgerMenu(),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Demo accounts'));
    await tester.pumpAndSettle();

    expect(find.text('Mars'), findsOneWidget);
    expect(find.text('Edcel'), findsOneWidget);
    expect(find.text('Miguel'), findsOneWidget);
    expect(find.text('Jelord'), findsOneWidget);
    expect(find.text('Mcking'), findsOneWidget);
    expect(
      find.text(
          'Each account has completed Java, Python, C#, JavaScript, and SQL.'),
      findsOneWidget,
    );
  });
}
