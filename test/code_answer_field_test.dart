import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklab/widgets/code_answer_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Tab inserts indentation and Shift+Tab removes it',
      (tester) async {
    final controller = TextEditingController(text: 'print(1)');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CodeAnswerField(
            controller: controller,
            focusNode: focusNode,
            language: 'Python',
            maxLines: null,
          ),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(controller.text, 'print(1)    ');

    controller.value = const TextEditingValue(
      text: '    print(1)',
      selection: TextSelection.collapsed(offset: 4),
    );
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(controller.text, 'print(1)');
  });

  testWidgets('Ctrl+Space opens matching completions and inserts selection',
      (tester) async {
    final controller = TextEditingController(text: 'sout');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CodeAnswerField(
            controller: controller,
            focusNode: focusNode,
            language: 'Java',
            maxLines: null,
          ),
        ),
      ),
    );
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);
    focusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.text('sout'), findsNWidgets(2));
    await tester.tap(find.text('print'));
    await tester.pumpAndSettle();

    expect(controller.text, 'System.out.println();');
    expect(controller.selection.baseOffset, 'System.out.println('.length);
  });
}
