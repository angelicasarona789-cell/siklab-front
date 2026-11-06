import 'package:flutter/material.dart';

class ShellNavigator extends InheritedWidget {
  final void Function(int index) setIndex;
  final VoidCallback onBack;

  const ShellNavigator({
    super.key,
    required this.setIndex,
    required this.onBack,
    required super.child,
  });

  static void goHome(BuildContext context) => goTab(context, 0);

  static void goModules(BuildContext context) => goTab(context, 1);

  static void goPractice(BuildContext context) => goTab(context, 2);

  static void goTab(BuildContext context, int index) {
    final shell = context.dependOnInheritedWidgetOfExactType<ShellNavigator>();
    if (shell != null) {
      shell.setIndex(index);
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  static void back(BuildContext context) {
    final shell = context.getInheritedWidgetOfExactType<ShellNavigator>();
    if (shell != null) {
      shell.onBack();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  bool updateShouldNotify(ShellNavigator old) => false;
}
