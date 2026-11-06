// lib/screens/search_screen.dart
// Full SIKLAB-styled search — matches the dark theme exactly.
// Uses a custom full-screen widget instead of SearchDelegate
// so we have 100% control over every pixel.
//
// Navigation fix: ShellNavigator is NOT reachable from inside a new pushed
// route because it lives in a different subtree.  The caller must capture
// the shell's setIndex callback BEFORE calling showSiklabSearch and pass it
// in.  The page stores it and calls it after pop().
//
// Tab indices (matches your bottom nav bar):
//   0 → Home       (Module items)
//   1 → Modules
//   2 → Practice   (Topic items)
//   3 → Analytics  (Achievement / Stat items)
//   4 → Profile

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/secure_text_field.dart';

// ── Searchable item model ─────────────────────────────────────

class _Item {
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final Color color;
  const _Item(this.title, this.subtitle, this.category, this.icon, this.color);
}

final _all = <_Item>[
  // ── Modules ──────────────────────────────────────────────
  const _Item('Java', 'Object-oriented syntax and logic foundations.', 'Module',
      Icons.coffee_outlined, SiklabColors.orange),
  const _Item('Python', 'Readable problem solving and scripting workflow.',
      'Module', Icons.code, SiklabColors.cyan),
  const _Item('C#', 'Strongly typed coding with .NET style patterns.', 'Module',
      Icons.terminal, SiklabColors.purple),
  const _Item('JavaScript', 'Web-focused language fundamentals and async flow.',
      'Module', Icons.javascript_outlined, SiklabColors.success),
  const _Item('SQL', 'Database querying, joins, and data retrieval.', 'Module',
      Icons.storage_outlined, SiklabColors.cyan),
  // ── Topics ───────────────────────────────────────────────
  const _Item(
      'Data Structures',
      'Trees, graphs, heaps — master advanced structures.',
      'Topic',
      Icons.account_tree_outlined,
      SiklabColors.cyan),
  const _Item('Algorithms', 'Sorting, searching, dynamic programming and more.',
      'Topic', Icons.bolt, SiklabColors.purple),
  const _Item(
      'Systems Design',
      'Scalable architectures, databases, distributed systems.',
      'Topic',
      Icons.device_hub,
      SiklabColors.orange),
  const _Item('Big-O Notation', 'Time and space complexity analysis.', 'Topic',
      Icons.show_chart, SiklabColors.success),
  const _Item('Recursion', 'Solve problems by breaking them into sub-problems.',
      'Topic', Icons.refresh, SiklabColors.cyan),
  // ── Achievements ─────────────────────────────────────────
  const _Item(
      'Loop Master',
      'Complete all loop challenges without a single error.',
      'Achievement',
      Icons.all_inclusive,
      SiklabColors.purple),
  const _Item(
      'Fast Solver',
      'Solve 10 problems under the time limit consecutively.',
      'Achievement',
      Icons.bolt,
      SiklabColors.cyan),
  const _Item('Debug Pro', 'Fix 50 broken code snippets across all modules.',
      'Achievement', Icons.bug_report_outlined, SiklabColors.orange),
  const _Item('Streak King', 'Maintain a 14-day consecutive login streak.',
      'Achievement', Icons.military_tech, SiklabColors.success),
  const _Item('Deep Thinker', 'Solve 5 hard-difficulty problems in a row.',
      'Achievement', Icons.psychology, SiklabColors.purple),
  const _Item('Speed Run', 'Complete a full module in under 10 minutes.',
      'Achievement', Icons.speed, SiklabColors.cyan),
  // ── Stats ────────────────────────────────────────────────
  const _Item(
      'Logic Cycles',
      'Total number of problems attempted across all modules.',
      'Stat',
      Icons.loop,
      SiklabColors.cyan),
  const _Item('Current Streak', 'Consecutive days of active practice.', 'Stat',
      Icons.local_fire_department_outlined, SiklabColors.orange),
  const _Item('XP Points', 'Experience points earned by completing challenges.',
      'Stat', Icons.star_outline, SiklabColors.success),
];

// ── Tab-index mapping ─────────────────────────────────────────
//
// Capture shell.setIndex (or equivalent) in the caller and pass it here.
// This avoids the InheritedWidget-not-found problem that occurs when the
// search page is pushed as a separate route on top of the shell.
//
// Example caller usage:
//
//   final shell = context.dependOnInheritedWidgetOfExactType<ShellNavigator>();
//   if (shell != null) {
//     showSiklabSearch(context, onNavigate: shell.setIndex);
//   }

int _tabIndexFor(_Item item) {
  switch (item.category) {
    case 'Module':
      return 0; // Home  — modules are listed on the home screen
    case 'Topic':
      return 2; // Practice
    case 'Achievement':
    case 'Stat':
      return 3; // Analytics
    default:
      return 0;
  }
}

// ── Public entry point ────────────────────────────────────────
//
// [onNavigate] receives the target tab index after the search page is popped.
// Pass `shell.setIndex` (or equivalent) from the calling widget.

void showSiklabSearch(
  BuildContext context, {
  required void Function(int tabIndex) onNavigate,
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => _SearchPage(onNavigate: onNavigate),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 200),
    ),
  );
}

// ── Full-screen search page ────────────────────────────────────

class _SearchPage extends StatefulWidget {
  /// Called with the correct tab index once the user taps a result.
  final void Function(int tabIndex) onNavigate;
  const _SearchPage({required this.onNavigate});

  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  String _q = '';
  String _activeFilter = 'All';

  static const _filters = ['All', 'Module', 'Topic', 'Achievement', 'Stat'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    _ctrl.addListener(() => setState(() => _q = _ctrl.text));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<_Item> get _filtered {
    final base = _activeFilter == 'All'
        ? _all
        : _all.where((i) => i.category == _activeFilter).toList();
    if (_q.trim().isEmpty) return base;
    final q = _q.toLowerCase();
    return base
        .where((i) =>
            i.title.toLowerCase().contains(q) ||
            i.subtitle.toLowerCase().contains(q) ||
            i.category.toLowerCase().contains(q))
        .toList();
  }

  /// Pop the search route, then switch to the correct shell tab.
  void _handleTap(_Item item) {
    final targetIndex = _tabIndexFor(item);
    // Pop first so the shell is fully restored before we call setIndex.
    Navigator.of(context).pop();
    // Use addPostFrameCallback so the shell has rebuilt after the pop.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onNavigate(targetIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = context.clBg;
    final bgCard = context.clBgCard;
    final bgElev = context.clBgElevated;
    final border = context.clBorder;

    // Group filtered results by category, preserving insertion order.
    final Map<String, List<_Item>> groups = {};
    for (final item in _filtered) {
      groups.putIfAbsent(item.category, () => []).add(item);
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search bar ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: SiklabColors.cyan.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: SiklabColors.cyan.withValues(alpha: 0.06),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: context.clTextSecondary,
                      constraints:
                          const BoxConstraints.tightFor(width: 40, height: 40),
                      padding: EdgeInsets.zero,
                    ),
                    const Icon(Icons.search,
                        color: SiklabColors.cyan, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SecureTextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        style: GoogleFonts.sourceCodePro(
                          color: const Color(0xFFE8E8F0),
                          fontSize: 14,
                        ),
                        cursorColor: SiklabColors.cyan,
                        decoration: InputDecoration(
                          hintText: 'Search modules, topics, achievements…',
                          hintStyle: GoogleFonts.sourceCodePro(
                            color: const Color(0xFF3A4F63),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_q.isNotEmpty)
                      GestureDetector(
                        onTap: () => _ctrl.clear(),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.close,
                              color: Color(0xFF6B6B80), size: 18),
                        ),
                      ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: bgElev,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: border),
                        ),
                        child: Text('ESC',
                            style: GoogleFonts.sourceCodePro(
                              color: const Color(0xFF6B6B80),
                              fontSize: 10,
                              letterSpacing: 1,
                            )),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Category filter chips ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final selected = _activeFilter == filter;
                    return GestureDetector(
                      onTap: () => setState(() => _activeFilter = filter),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected
                              ? SiklabColors.cyan.withValues(alpha: 0.12)
                              : bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? SiklabColors.cyan.withValues(alpha: 0.5)
                                : border,
                          ),
                        ),
                        child: Text(
                          filter.toUpperCase(),
                          style: GoogleFonts.sourceCodePro(
                            color: selected
                                ? SiklabColors.cyan
                                : const Color(0xFF6B6B80),
                            fontSize: 9,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Results ───────────────────────────────────────
            Expanded(
              child: _filtered.isEmpty
                  ? _EmptyState(query: _q)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        for (final entry in groups.entries) ...[
                          // Category header
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 4),
                            child: Row(children: [
                              Container(width: 16, height: 1, color: border),
                              const SizedBox(width: 8),
                              Text(entry.key.toUpperCase(),
                                  style: GoogleFonts.sourceCodePro(
                                      color: const Color(0xFF6B6B80),
                                      fontSize: 9,
                                      letterSpacing: 1.8)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Container(height: 1, color: border)),
                            ]),
                          ),
                          // Items
                          for (final item in entry.value)
                            _ItemTile(
                              item: item,
                              bgCard: bgCard,
                              border: border,
                              onTap: () => _handleTap(item),
                            ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single result tile ────────────────────────────────────────

class _ItemTile extends StatelessWidget {
  final _Item item;
  final Color bgCard, border;
  final VoidCallback onTap;
  const _ItemTile(
      {required this.item,
      required this.bgCard,
      required this.border,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: item.color.withValues(alpha: 0.22)),
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFFE8E8F0),
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFF6B8099), fontSize: 12)),
              ],
            ),
          ),
          if (item.category == 'Module' || item.category == 'Topic')
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(Icons.arrow_forward_ios, color: item.color, size: 11),
            ),
        ]),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: context.clBgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.clBorder),
            ),
            child: const Icon(Icons.search_off,
                color: SiklabColors.textMuted, size: 28),
          ),
          const SizedBox(height: 14),
          Text('No results for "$query"',
              style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFF6B6B80), fontSize: 14)),
          const SizedBox(height: 6),
          Text('Try a different keyword',
              style: GoogleFonts.sourceCodePro(
                  color: const Color(0xFF3A4F63),
                  fontSize: 11,
                  letterSpacing: 1)),
        ],
      ),
    );
  }
}
