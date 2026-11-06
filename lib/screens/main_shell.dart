import 'package:flutter/material.dart';
import '../widgets/shared_widgets.dart';
import '../navigation/shell_navigator.dart';
import 'home_screen.dart';
import 'modules_screen.dart';
import 'practice_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';

// ─── Main shell ───────────────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final Set<int> _initializedTabs = {0};
  final List<int> _tabHistory = [];
  final GlobalKey<PracticeScreenState> _practiceKey =
      GlobalKey<PracticeScreenState>();

  Widget _screen(int index) {
    if (!_initializedTabs.contains(index)) {
      return SizedBox.shrink(key: ValueKey('uninitialized-tab-$index'));
    }
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const ModulesScreen();
      case 2:
        return PracticeScreen(key: _practiceKey);
      case 3:
        return const AnalyticsScreen();
      case 4:
        return const ProfileScreen();
      default:
        throw RangeError.index(index, const [0, 1, 2, 3, 4], 'index');
    }
  }

  void _selectTab(int index) {
    if (index == _index) {
      if (index == 2) {
        _practiceKey.currentState?.refreshUnlockStatus();
      }
      return;
    }
    _tabHistory.add(_index);
    _initializedTabs.add(index);
    if (index == 2) {
      _practiceKey.currentState?.refreshUnlockStatus();
    }
    setState(() => _index = index);
  }

  void _goBack() {
    final previousIndex = _tabHistory.isEmpty ? 0 : _tabHistory.removeLast();
    if (previousIndex == 2) {
      _practiceKey.currentState?.refreshUnlockStatus();
    }
    if (previousIndex != _index) {
      setState(() => _index = previousIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShellNavigator(
      setIndex: _selectTab,
      onBack: _goBack,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          sizing: StackFit.expand,
          children: List<Widget>.generate(5, _screen),
        ),
        bottomNavigationBar: SiklabBottomNav(
          currentIndex: _index,
          onTap: _selectTab,
        ),
      ),
    );
  }
}
