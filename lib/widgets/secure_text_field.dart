// secure_text_field.dart
//
// Drop-in replacements that block ALL clipboard interaction — copy, cut,
// AND paste — no matter where the text came from (inside this field,
// another field in the app, or another app/window entirely).
//
// Blocked through every entry point Flutter exposes:
//   • The long-press / right-click selection toolbar (Copy/Cut/Paste
//     buttons are stripped out; only "Select all" remains, purely for
//     navigation — it does not by itself copy anything)
//   • Keyboard shortcuts: Ctrl+C / Cmd+C, Ctrl+X / Cmd+X, Ctrl+V / Cmd+V
//   • Programmatic copy/cut/paste intents dispatched by Flutter's text
//     editing system
//
// Two widgets are provided:
//   • SecureTextField   — replacement for TextField / TextFormField
//   • SecureSelectableText — replacement for SelectableText (read-only
//     code/text that users could otherwise select-and-copy)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared shortcut/action map that swallows copy, cut, and paste key
/// combinations before Flutter's default text-editing shortcuts fire.
Map<ShortcutActivator, Intent> _blockedClipboardShortcuts() => {
      const SingleActivator(LogicalKeyboardKey.keyC, control: true):
          const _BlockedClipboardIntent(),
      const SingleActivator(LogicalKeyboardKey.keyC, meta: true):
          const _BlockedClipboardIntent(),
      const SingleActivator(LogicalKeyboardKey.keyX, control: true):
          const _BlockedClipboardIntent(),
      const SingleActivator(LogicalKeyboardKey.keyX, meta: true):
          const _BlockedClipboardIntent(),
      const SingleActivator(LogicalKeyboardKey.keyV, control: true):
          const _BlockedClipboardIntent(),
      const SingleActivator(LogicalKeyboardKey.keyV, meta: true):
          const _BlockedClipboardIntent(),
    };

Map<Type, Action<Intent>> _blockedClipboardActions(BuildContext context,
        {required bool showFeedback}) =>
    {
      _BlockedClipboardIntent: CallbackAction<_BlockedClipboardIntent>(
        onInvoke: (intent) {
          if (showFeedback) _feedback(context);
          return null;
        },
      ),
      CopySelectionTextIntent: CallbackAction<CopySelectionTextIntent>(
        onInvoke: (intent) {
          if (showFeedback) _feedback(context);
          return null;
        },
      ),
      PasteTextIntent: CallbackAction<PasteTextIntent>(
        onInvoke: (intent) {
          if (showFeedback) _feedback(context);
          return null;
        },
      ),
    };

void _feedback(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Copy and paste are disabled in this app.'),
      duration: Duration(seconds: 2),
    ),
  );
}

/// Blocks clipboard keyboard shortcuts throughout the application.
class ClipboardGuard extends StatelessWidget {
  final Widget child;

  const ClipboardGuard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _blockedClipboardShortcuts(),
      child: Actions(
        actions: _blockedClipboardActions(context, showFeedback: false),
        child: child,
      ),
    );
  }
}

/// Selection toolbar with Copy/Cut/Paste removed, keeping only
/// non-clipboard actions (e.g. Select all).
Widget _strippedToolbar(
    BuildContext context, EditableTextState editableTextState) {
  final buttonItems = editableTextState.contextMenuButtonItems
      .where((item) =>
          item.type != ContextMenuButtonType.copy &&
          item.type != ContextMenuButtonType.cut &&
          item.type != ContextMenuButtonType.paste)
      .toList();
  if (buttonItems.isEmpty) return const SizedBox.shrink();
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: editableTextState.contextMenuAnchors,
    buttonItems: buttonItems,
  );
}

/// Drop-in replacement for TextField / TextFormField with copy, cut, and
/// paste all disabled.
class SecureTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextStyle? style;
  final InputDecoration? decoration;
  final bool obscureText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool showSnackBarOnBlock;
  final Color? cursorColor;

  const SecureTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.maxLines = 1,
    this.keyboardType,
    this.style,
    this.decoration,
    this.obscureText = false,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.showSnackBarOnBlock = true,
    this.cursorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _blockedClipboardShortcuts(),
      child: Actions(
        actions: _blockedClipboardActions(context,
            showFeedback: showSnackBarOnBlock),
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: style,
          decoration: decoration,
          obscureText: obscureText,
          enabled: enabled,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          validator: validator,
          cursorColor: cursorColor,
          contextMenuBuilder: _strippedToolbar,
        ),
      ),
    );
  }
}

/// Drop-in replacement for SelectableText with copy and cut disabled
/// (paste doesn't apply to read-only text).
class SecureSelectableText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const SecureSelectableText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _blockedClipboardShortcuts(),
      child: Actions(
        actions: _blockedClipboardActions(context, showFeedback: true),
        child: SelectableText(
          text,
          style: style,
          contextMenuBuilder: _strippedToolbar,
        ),
      ),
    );
  }
}

class _BlockedClipboardIntent extends Intent {
  const _BlockedClipboardIntent();
}
