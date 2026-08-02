import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/notification.dart';
import '../core/state.dart';
import 'widgets.dart';

/// App settings: widget personality, notifications, dopamine feedback.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _personalities = {
    'warrior': ('💂', 'Warrior', 'Tough love, ranks and battle calls'),
    'coach': ('🎽', 'Coach', 'Encouraging, data-driven nudges'),
    'minimal': ('⚪', 'Minimal', 'Quiet, clean, no frills'),
    'anime': ('⚔️', 'Anime', 'Over-the-top hero moments'),
    'scifi': ('🛰️', 'Sci-Fi', 'Reforge as a starship mission'),
    'retro': ('🕹️', 'Retro', '8-bit arcade vibes'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(gameProvider);
    final s = c.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---------- Widget personality ----------
            const SectionHeader(title: 'Home Screen Widget'),
            GlassCard(
              child: Column(
                children: [
                  for (final e in _personalities.entries)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Text(e.value.$1, style: const TextStyle(fontSize: 22)),
                      title: Text(e.key == s.widgetPersonality ? '${e.value.$2} ✓' : e.value.$2,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(e.value.$3, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                      trailing: Radio<String>(
                        value: e.key,
                        groupValue: s.widgetPersonality,
                        activeColor: AppColors.gold,
                        onChanged: (_) => c.setSettings(s.copyWith(widgetPersonality: e.key)),
                      ),
                      onTap: () => c.setSettings(s.copyWith(widgetPersonality: e.key)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ---------- Dopamine ----------
            const SectionHeader(title: 'Dopamine Feedback'),
            GlassCard(
              child: Column(
                children: [
                  SwitchListTile(
                    value: s.dopamineMode,
                    title: const Text('Dopamine mode', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                    subtitle: const Text('Reward sounds & effects on actions', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
                    activeThumbColor: AppColors.gold,
                    onChanged: (v) => c.setSettings(s.copyWith(dopamineMode: v)),
                  ),
                  SwitchListTile(
                    value: s.sounds,
                    title: const Text('Sound effects', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                    activeThumbColor: AppColors.blue,
                    onChanged: (v) => c.setSettings(s.copyWith(sounds: v)),
                  ),
                  SwitchListTile(
                    value: s.haptics,
                    title: const Text('Haptic vibration', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                    activeThumbColor: AppColors.green,
                    onChanged: (v) => c.setSettings(s.copyWith(haptics: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ---------- Notifications ----------
            const SectionHeader(title: 'Reminders'),
            GlassCard(
              child: Column(
                children: [
                  SwitchListTile(
                    value: s.notificationsEnabled,
                    title: const Text('Enable reminders', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                    subtitle: const Text('Water, workouts, streaks & weekly review', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
                    activeThumbColor: AppColors.gold,
                    onChanged: (v) => c.setSettings(s.copyWith(notificationsEnabled: v)),
                  ),
                  if (s.notificationsEnabled) ...[
                    _TimeTile(label: 'Water reminder', icon: '💧', hour: s.waterReminderHour, minute: s.waterReminderMinute,
                        onPick: (t) => c.setSettings(s.copyWith(waterReminderHour: t.hour, waterReminderMinute: t.minute))),
                    _TimeTile(label: 'Workout reminder', icon: '💪', hour: s.workoutReminderHour, minute: s.workoutReminderMinute,
                        onPick: (t) => c.setSettings(s.copyWith(workoutReminderHour: t.hour, workoutReminderMinute: t.minute))),
                    _TimeTile(label: 'Sleep reminder', icon: '🌙', hour: s.sleepReminderHour, minute: s.sleepReminderMinute,
                        onPick: (t) => c.setSettings(s.copyWith(sleepReminderHour: t.hour, sleepReminderMinute: t.minute))),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ---------- Danger zone ----------
            const SectionHeader(title: 'Data'),
            GlassCard(
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.restart_alt_rounded, color: AppColors.red, size: 22),
                    title: const Text('Reset all progress', style: TextStyle(color: AppColors.red, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Deletes the saved game (keeps nothing)', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
                    onTap: () => _confirmReset(context, c),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Center(child: Text('Reforge v0.1 · made for Future You', style: TextStyle(color: AppColors.textDim, fontSize: 11))),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, GameController c) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Reset the game?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('All XP, coins, streaks and logs will be wiped.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textDim))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              c.resetGame();
              NotificationService.instance.cancelAll();
            },
            child: const Text('Reset', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final String icon;
  final int hour;
  final int minute;
  final ValueChanged<DateTime> onPick;
  const _TimeTile({required this.label, required this.icon, required this.hour, required this.minute, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Text(icon, style: const TextStyle(fontSize: 18)),
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      trailing: Text('$hh:$mm', style: const TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w700)),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
          builder: (ctx, child) => Theme(data: ThemeData.dark(), child: child!),
        );
        if (picked != null) {
          onPick(DateTime(0, 1, 1, picked.hour, picked.minute));
        }
      },
    );
  }
}
