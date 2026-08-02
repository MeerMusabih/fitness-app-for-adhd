import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/state.dart';
import 'widgets.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  static const _exercises = [
    Exercise('Push-ups (knee)', '3 × 8', 'Hands shoulder-width, body straight, chest to floor. Build to full push-ups over 2 weeks.', '💪', AppColors.red),
    Exercise('Squats', '3 × 12', 'Feet shoulder-width, sit back like a chair, thighs parallel to floor.', '🦵', AppColors.blue),
    Exercise('Lunges', '3 × 8 / leg', 'Step forward, drop back knee to floor, push back up.', '🚶', AppColors.green),
    Exercise('Plank', '3 × 25s', 'Forearms down, body in a straight line, squeeze your core.', '⏱️', AppColors.purple),
    Exercise('Jumping Jacks', '3 × 30', 'Full-body cardio to raise your heart rate.', '🤸', AppColors.orange),
    Exercise('Burpees (modified)', '3 × 5', 'Step back to plank, step forward, stand, jump. Go slow at first.', '🔥', AppColors.pink),
    Exercise('High Knees', '3 × 30s', 'Run in place, knees to waist height, fast cadence.', '🏃', AppColors.teal),
    Exercise('Stretch & Cool Down', '1 × 3 min', 'Stretch hamstrings, chest, shoulders. Hold each 20s.', '🧘', AppColors.gold),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(gameProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Workout')),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassCard(
              glow: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Home Workout · No Equipment', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('Beginner · ~15 minutes · Full body · ${c.todayLog().workoutDone ? 'Completed today ✓' : 'Not done today'}',
                      style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WorkoutSessionScreen()),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('START WORKOUT  (+80 XP)'),
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: 'Exercise Library', subtitle: 'Tap an exercise for details'),
            for (final e in _exercises) _ExerciseTile(exercise: e),
          ],
        ),
      ),
    );
  }
}

class Exercise {
  final String name;
  final String sets;
  final String howTo;
  final String icon;
  final Color color;
  const Exercise(this.name, this.sets, this.howTo, this.icon, this.color);
}

class _ExerciseTile extends StatefulWidget {
  final Exercise exercise;
  const _ExerciseTile({required this.exercise});

  @override
  State<_ExerciseTile> createState() => _ExerciseTileState();
}

class _ExerciseTileState extends State<_ExerciseTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.exercise;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 18,
      onTap: () => setState(() => _open = !_open),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: e.color.withOpacity(0.15), shape: BoxShape.circle),
                child: Center(child: Text(e.icon, style: const TextStyle(fontSize: 19))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(e.sets, style: TextStyle(color: e.color, fontSize: 12)),
                ]),
              ),
              Icon(_open ? Icons.expand_less : Icons.expand_more, color: AppColors.textDim),
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(e.howTo, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive timed workout session with rest timers.
class WorkoutSessionScreen extends ConsumerStatefulWidget {
  const WorkoutSessionScreen({super.key});

  @override
  ConsumerState<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  late final List<_SessionStep> _steps;
  int _index = 0;
  int _secondsLeft = 0;
  Timer? _timer;
  bool _running = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _steps = [
      _SessionStep('Warm-up', 'March in place', '🔥', AppColors.orange, 180),
      _SessionStep('Squats', '3 × 12', '🦵', AppColors.blue, 90),
      _SessionStep('Rest', 'Breathe', '😮‍💨', AppColors.textDim, 45),
      _SessionStep('Knee Push-ups', '3 × 8', '💪', AppColors.red, 90),
      _SessionStep('Rest', 'Breathe', '😮‍💨', AppColors.textDim, 45),
      _SessionStep('Lunges', '3 × 8 per leg', '🚶', AppColors.green, 90),
      _SessionStep('Rest', 'Breathe', '😮‍💨', AppColors.textDim, 45),
      _SessionStep('Plank', '3 × 25s', '⏱️', AppColors.purple, 75),
      _SessionStep('Rest', 'Breathe', '😮‍💨', AppColors.textDim, 45),
      _SessionStep('Jumping Jacks', '3 × 30', '🤸', AppColors.orange, 90),
      _SessionStep('Rest', 'Breathe', '😮‍💨', AppColors.textDim, 45),
      _SessionStep('Stretch', 'Cool down', '🧘', AppColors.gold, 180),
    ];
    _secondsLeft = _steps.first.seconds;
    _startTimer();
  }

  void _startTimer() {
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          _next();
        }
      });
    });
  }

  void _next() {
    if (_index + 1 >= _steps.length) {
      _timer?.cancel();
      _finished = true;
      _complete();
      return;
    }
    _index++;
    _secondsLeft = _steps[_index].seconds;
  }

  void _complete() {
    final c = ref.read(gameProvider);
    c.completeWorkout(minutes: 15, pushups: 10, squats: 12);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      return Scaffold(
        backgroundColor: AppColors.bgStart,
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const ConfettiOverlay(),
            const Text('🏆', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 12),
            const Text('Workout Complete!', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('+80 XP  ·  +80 XP to Strength skill', style: TextStyle(color: AppColors.gold)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to Home'),
            ),
          ]),
        ),
      );
    }

    final step = _steps[_index];
    final total = _steps.length;
    final overallPct = _index / total + (_secondsLeft / step.seconds) / total;

    return Scaffold(
      appBar: AppBar(
        title: Text('Workout ${_index + 1}/$total'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            _timer?.cancel();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              GradientBar(progress: overallPct, height: 8, color: AppColors.green),
              const SizedBox(height: 28),
              Expanded(
                child: GlassCard(
                  glow: true,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(step.icon, style: const TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      Text(step.name,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(step.detail, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                      const SizedBox(height: 26),
                      Text('$_secondsLeft',
                          style: TextStyle(color: step.color, fontSize: 72, fontWeight: FontWeight.w900)),
                      const Text('seconds', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(_running ? 'Keep going, warrior! Future You is counting reps.' : '',
                  style: const TextStyle(color: AppColors.gold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionStep {
  final String name;
  final String detail;
  final String icon;
  final Color color;
  final int seconds;
  const _SessionStep(this.name, this.detail, this.icon, this.color, this.seconds);
}
