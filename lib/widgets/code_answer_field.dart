import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'secure_text_field.dart';

class CodeAnswerField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String language;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextStyle? style;
  final InputDecoration? decoration;
  final Color? cursorColor;
  final bool showSnackBarOnBlock;

  const CodeAnswerField({
    required this.controller,
    required this.language,
    this.focusNode,
    this.maxLines,
    this.keyboardType,
    this.style,
    this.decoration,
    this.cursorColor,
    this.showSnackBarOnBlock = true,
    super.key,
  });

  @override
  State<CodeAnswerField> createState() => _CodeAnswerFieldState();
}

class _CodeAnswerFieldState extends State<CodeAnswerField> {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _ownedFocusNode = FocusNode();
  OverlayEntry? _completionOverlay;
  List<_Completion> _filteredCompletions = [];
  int _selectedCompletion = 0;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refreshCompletions);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant CodeAnswerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refreshCompletions);
      widget.controller.addListener(_refreshCompletions);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChanged);
      _focusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refreshCompletions);
    _focusNode.removeListener(_handleFocusChanged);
    _removeCompletionOverlay();
    _ownedFocusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) _removeCompletionOverlay();
  }

  void _refreshCompletions() {
    if (_completionOverlay == null) return;
    _filteredCompletions = _matchingCompletions();
    _selectedCompletion = 0;
    if (_filteredCompletions.isEmpty) {
      _removeCompletionOverlay();
    } else {
      _completionOverlay?.markNeedsBuild();
    }
  }

  List<_Completion> _matchingCompletions() {
    final value = widget.controller.value;
    final cursor =
        value.selection.isValid ? value.selection.start : value.text.length;
    final beforeCursor =
        value.text.substring(0, cursor.clamp(0, value.text.length));
    final prefixMatch =
        RegExp(r'[A-Za-z_][A-Za-z0-9_]*$').firstMatch(beforeCursor);
    final prefix = prefixMatch?.group(0)?.toLowerCase() ?? '';
    final completions = _completionsFor(widget.language);
    if (prefix.isEmpty) return completions;
    return completions
        .where((item) => item.label.toLowerCase().startsWith(prefix))
        .toList(growable: false);
  }

  void _showCompletions() {
    _filteredCompletions = _matchingCompletions();
    if (_filteredCompletions.isEmpty) return;
    _selectedCompletion = 0;
    _completionOverlay ??= OverlayEntry(builder: _buildCompletionOverlay);
    Overlay.of(context).insert(_completionOverlay!);
  }

  Widget _buildCompletionOverlay(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 40).clamp(220.0, 360.0);
    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 8),
        child: Material(
          elevation: 12,
          color: const Color(0xFF17232D),
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemCount: _filteredCompletions.length,
              itemBuilder: (context, index) {
                final completion = _filteredCompletions[index];
                return Semantics(
                  button: true,
                  label:
                      'Insert ${completion.insertText}, ${completion.detail}',
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: InkWell(
                      onTapDown: (_) => _applyCompletion(completion),
                      child: Container(
                        color: index == _selectedCompletion
                            ? const Color(0xFF263A49)
                            : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                completion.label,
                                style: GoogleFonts.sourceCodePro(
                                  color: const Color(0xFFE8E8F0),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              completion.detail,
                              style: GoogleFonts.sourceCodePro(
                                color: const Color(0xFF9AA9B5),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _acceptSelectedCompletion() {
    if (_filteredCompletions.isEmpty) return;
    _applyCompletion(
      _filteredCompletions[_selectedCompletion.clamp(
        0,
        _filteredCompletions.length - 1,
      )],
    );
  }

  void _applyCompletion(_Completion completion) {
    final value = widget.controller.value;
    final selection = value.selection;
    final cursor =
        (selection.isValid ? selection.extentOffset : value.text.length)
            .clamp(0, value.text.length);
    final beforeCursor = value.text.substring(0, cursor);
    final prefixMatch =
        RegExp(r'[A-Za-z_][A-Za-z0-9_]*$').firstMatch(beforeCursor);
    final replaceStart = selection.isValid && !selection.isCollapsed
        ? selection.start
        : prefixMatch?.start ?? cursor;
    final replaceEnd =
        selection.isValid && !selection.isCollapsed ? selection.end : cursor;
    final text = value.text.replaceRange(
      replaceStart,
      replaceEnd,
      completion.insertText,
    );
    final newCursor = (replaceStart +
            (completion.cursorOffset ?? completion.insertText.length))
        .clamp(0, text.length);
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    _removeCompletionOverlay();
    _focusNode.requestFocus();
  }

  void _insertIndent() {
    if (_completionOverlay != null) {
      _acceptSelectedCompletion();
      return;
    }
    final value = widget.controller.value;
    final selection = value.selection;
    if (!selection.isValid) return;
    const indent = '    ';
    final selectedText = selection.textInside(value.text);
    final text = value.text.replaceRange(
      selection.start,
      selection.end,
      '$indent$selectedText',
    );
    widget.controller.value = TextEditingValue(
      text: text,
      selection: selection.isCollapsed
          ? TextSelection.collapsed(offset: selection.start + indent.length)
          : TextSelection(
              baseOffset: selection.start + indent.length,
              extentOffset: selection.end + indent.length,
            ),
    );
    _focusNode.requestFocus();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final isControl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (isControl && event.logicalKey == LogicalKeyboardKey.space) {
      _showCompletions();
    } else if (event.logicalKey == LogicalKeyboardKey.tab) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        _removeIndent();
      } else {
        _insertIndent();
      }
    } else if (_completionOverlay != null &&
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_filteredCompletions.isNotEmpty) {
        _selectedCompletion =
            (_selectedCompletion + 1) % _filteredCompletions.length;
        _completionOverlay?.markNeedsBuild();
      }
    } else if (_completionOverlay != null &&
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_filteredCompletions.isNotEmpty) {
        _selectedCompletion =
            (_selectedCompletion - 1) % _filteredCompletions.length;
        if (_selectedCompletion < 0) {
          _selectedCompletion = _filteredCompletions.length - 1;
        }
        _completionOverlay?.markNeedsBuild();
      }
    } else if (_completionOverlay != null &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _removeCompletionOverlay();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _removeIndent() {
    final value = widget.controller.value;
    final selection = value.selection;
    if (!selection.isValid) return;
    final lineStart = value.text.lastIndexOf('\n', selection.start - 1) + 1;
    final indentation = value.text.substring(lineStart, selection.start);
    final removeCount = indentation.startsWith('    ')
        ? 4
        : indentation.startsWith('  ')
            ? 2
            : indentation.startsWith(' ')
                ? 1
                : 0;
    if (removeCount == 0) return;
    final text = value.text.replaceRange(
      selection.start - removeCount,
      selection.start,
      '',
    );
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: selection.start - removeCount),
    );
    _focusNode.requestFocus();
  }

  void _removeCompletionOverlay() {
    _completionOverlay?.remove();
    _completionOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SecureTextField(
              controller: widget.controller,
              focusNode: _focusNode,
              maxLines: widget.maxLines,
              keyboardType: widget.keyboardType,
              style: widget.style,
              decoration: widget.decoration,
              showSnackBarOnBlock: widget.showSnackBarOnBlock,
              cursorColor: widget.cursorColor,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                'TAB: indent  •  CTRL+SPACE: suggestions  •  ESC: close',
                style: GoogleFonts.sourceCodePro(
                  color: Theme.of(context).hintColor,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_Completion> _completionsFor(String language) {
    switch (language.toLowerCase()) {
      case 'java':
        return const [
          _Completion('sout', 'System.out.println();', 'print', 19),
          _Completion(
              'main',
              'public static void main(String[] args) {\n    \n}',
              'method',
              45),
          _Completion('syso', 'System.out.println();', 'print', 19),
          _Completion(
              'for', 'for (int i = 0; i < ; i++) {\n    \n}', 'loop', 20),
          _Completion('if', 'if () {\n    \n}', 'condition', 4),
          _Completion('class', 'class  {\n    \n}', 'class', 6),
          _Completion('String', 'String ', 'type'),
          _Completion('int', 'int ', 'type'),
          _Completion('return', 'return ', 'keyword'),
          _Completion('new', 'new ', 'keyword'),
        ];
      case 'python':
        return const [
          _Completion('print', 'print()', 'output', 6),
          _Completion('def', 'def ():\n    ', 'function', 4),
          _Completion('for', 'for item in :\n    ', 'loop', 12),
          _Completion('if', 'if :\n    ', 'condition', 3),
          _Completion('while', 'while :\n    ', 'loop', 6),
          _Completion('class', 'class :\n    ', 'class', 6),
          _Completion('input', 'input()', 'input', 6),
          _Completion('range', 'range()', 'built-in', 6),
          _Completion('import', 'import ', 'keyword'),
          _Completion('return', 'return ', 'keyword'),
        ];
      case 'c#':
        return const [
          _Completion(
              'Console.WriteLine', 'Console.WriteLine();', 'output', 19),
          _Completion('Console.ReadLine', 'Console.ReadLine()', 'input', 17),
          _Completion(
              'for', 'for (int i = 0; i < ; i++) {\n    \n}', 'loop', 20),
          _Completion('if', 'if () {\n    \n}', 'condition', 4),
          _Completion('class', 'class  {\n    \n}', 'class', 6),
          _Completion('int', 'int ', 'type'),
          _Completion('string', 'string ', 'type'),
          _Completion('var', 'var ', 'type'),
          _Completion('return', 'return ', 'keyword'),
          _Completion('new', 'new ', 'keyword'),
        ];
      case 'javascript':
        return const [
          _Completion('console.log', 'console.log();', 'output', 12),
          _Completion('function', 'function () {\n    \n}', 'function', 9),
          _Completion('const', 'const  = ;', 'variable', 6),
          _Completion('let', 'let  = ;', 'variable', 4),
          _Completion(
              'for', 'for (let i = 0; i < ; i++) {\n    \n}', 'loop', 20),
          _Completion('if', 'if () {\n    \n}', 'condition', 4),
          _Completion('return', 'return ', 'keyword'),
          _Completion('class', 'class  {\n    \n}', 'class', 6),
          _Completion('Array', 'Array.from()', 'built-in', 12),
          _Completion('async', 'async ', 'keyword'),
        ];
      case 'sql':
        return const [
          _Completion('SELECT', 'SELECT ', 'query'),
          _Completion('FROM', 'FROM ', 'clause'),
          _Completion('WHERE', 'WHERE ', 'clause'),
          _Completion('JOIN', 'JOIN ', 'clause'),
          _Completion('GROUP BY', 'GROUP BY ', 'clause'),
          _Completion('ORDER BY', 'ORDER BY ', 'clause'),
          _Completion('INSERT INTO', 'INSERT INTO ', 'query'),
          _Completion('UPDATE', 'UPDATE ', 'query'),
          _Completion('DELETE FROM', 'DELETE FROM ', 'query'),
          _Completion('COUNT', 'COUNT()', 'function', 6),
        ];
      default:
        return const [];
    }
  }
}

class _Completion {
  final String label;
  final String insertText;
  final String detail;
  final int? cursorOffset;

  const _Completion(
    this.label,
    this.insertText,
    this.detail, [
    this.cursorOffset,
  ]);
}
