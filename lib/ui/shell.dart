import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../core/constants.dart';
import '../core/dopamine.dart';
import '../core/state.dart';
import '../core/widget_bridge.dart';
import 'character.dart';
import 'coach.dart';
import 'dashboard.dart';
import 'food_log.dart';
import 'missions.dart';
import 'progress.dart';
import 'widgets.dart';
import 'workouts.dart';

/// Main navigation shell + global dopamine event overlays.
class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});

  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
  int _tab = 0;
  final List<GameEvent> _queue = [];
  StreamSubscription<GameEvent>? _sub;
  StreamSubscription<Uri?>? _widgetClickedSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initWidgetBridge());
    _sub = ref.read(gameProvider).events.listen(_onEvent);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _widgetClickedSub?.cancel();
    super.dispose();
  }

  Future<void> _initWidgetBridge() async {
    final controller = ref.read(gameProvider);
    try {
      WidgetBridge.registerInteractivity((action) async {
        if (!action.startsWith('reforge://action/')) return;
        await _handleAction(action.replaceFirst('reforge://action/', ''));
      });
      _widgetClickedSub = HomeWidget.widgetClicked.listen(
        (uri) {
          final a = uri?.toString() ?? '';
          if (a.startsWith('reforge://action/')) {
            _handleAction(a.replaceFirst('reforge://action/', ''));
          }
        },
        onError: (_) {},
      );
      // Handle launch-from-widget while app was closed.
      final action = await WidgetBridge.launchedAction();
      if (action != null && action.contains('reforge://action/')) {
        await controller.init();
        _handleAction(action.replaceFirst('reforge://action/', ''));
      }
    } catch (_) {}
  }

  Future<void> _handleAction(String action) async {
    final c = ref.read(gameProvider);
    if (!mounted) return;
    switch (action) {
      case 'water':
        c.addWater();
      case 'meal':
        setState(() => _tab = 1);
      case 'workout':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WorkoutScreen()));
      case 'walk':
        c.addSteps(1000);
      case 'coach':
        setState(() => _tab = 3);
      case 'open':
        break;
    }
  }

  void _onEvent(GameEvent e) {
    Dopamine.instance.play(e);
    if (!mounted) return;
    setState(() {
      if (_queue.length > 3) _queue.removeAt(0);
      _queue.add(e);
    });
    Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _queue.remove(e));
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardScreen(),
      const FoodLogScreen(),
      const MissionsScreen(),
      const CoachScreen(),
      const ProgressScreen(),
      const CharacterScreen(),
    ];

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            IndexedStack(index: _tab, children: screens),
            for (final e in _queue)
              if (e.type == GameEventType.xp ||
                  e.type == GameEventType.water ||
                  e.type == GameEventType.confetti)
                FloatingBurst(
                  key: ObjectKey(e),
                  text: e.message,
                  color: e.type == GameEventType.water ? AppColors.blue : AppColors.gold,
                ),
            for (final e in _queue)
              if (e.type == GameEventType.levelUp ||
                  e.type == GameEventType.achievement ||
                  e.type == GameEventType.boss ||
                  e.type == GameEventType.milestone)
                ConfettiOverlay(
                  key: ObjectKey(e),
                  color: e.type == GameEventType.boss ? AppColors.gold : AppColors.blue,
                ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.restaurant_rounded), label: 'Food'),
            BottomNavigationBarItem(icon: Icon(Icons.flag_rounded), label: 'Quests'),
            BottomNavigationBarItem(icon: Icon(Icons.smart_toy_rounded), label: 'Coach'),
            BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: 'Stats'),
            BottomNavigationBarItem(icon: Icon(Icons.face_rounded), label: 'Hero'),
          ],
        ),
      ),
    );
  }
}
