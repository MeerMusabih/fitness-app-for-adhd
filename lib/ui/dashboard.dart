import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/constants.dart';
import '../core/models.dart';
import '../core/rpg.dart';
import '../core/state.dart';
import 'character.dart';
import 'missions.dart';
import 'settings.dart';
import 'workouts.dart';
import 'widgets.dart';

/// Home / Dashboard: level, XP, weight, score, missions, boss, mood.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _moodDialog(BuildContext context, GameController c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final log = c.todayLog();
          Widget row(int current, ValueChanged<int> onSel, List<String> items) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(items.length, (i) {
                  final selected = current == i + 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () => onSel(i + 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? AppColors.blue.withOpacity(0.25) : Colors.transparent,
                          border: Border.all(color: selected ? AppColors.blue : AppColors.glassStroke, width: 1.6),
                        ),
                        child: Text(items[i], style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  );
                }),
              );
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Daily Check-In', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('How are you feeling, Champion?', style: TextStyle(color: AppColors.textDim, fontSize: 13)),
                const SizedBox(height: 18),
                const Text('Mood', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                row(log.mood, (v) { c.setCheckIn(mood: v); setSheet(() {}); }, const ['😞', '😕', '😐', '🙂', '😄']),
                const SizedBox(height: 16),
                const Text('Energy', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                row(log.energy, (v) { c.setCheckIn(energy: v); setSheet(() {}); }, const ['🪫', '😪', '😐', '⚡', '⚡⚡']),
                const SizedBox(height: 16),
                const Text('Stress', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                row(log.stress, (v) { c.setCheckIn(stress: v); setSheet(() {}); }, const ['😰', '😬', '😐', '😌', '🧘']),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(gameProvider);
    final log = c.todayLog();
    final remaining = (c.currentWeight - c.profile.goalWeightKg).clamp(0.0, 999.0);
    final predicted = RpgEngine.predictedGoalDate(c.profile, c.currentWeight);
    final dateFmt = DateFormat('MMM d, yyyy');
    final waterPct = (log.waterMl / c.waterGoalMl).clamp(0.0, 1.0);
    final proteinPct = (log.proteinConsumed / c.proteinGoal).clamp(0.0, 1.0);
    final calPct = (log.caloriesConsumed / c.calorieGoal).clamp(0.0, 1.0);
    final stepPct = (log.steps / 8000).clamp(0.0, 1.0);
    final missions = c.todayQuests;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ---------- Header ----------
          Row(
            children: [
              _Avatar(level: c.level),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${c.profile.name}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 19, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('${c.title}  ·  ${c.rank}',
                        style: const TextStyle(color: AppColors.gold, fontSize: 12)),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Text('🪙', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 3),
                      Text('${c.state.coins} coins',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ]),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
                icon: const Icon(Icons.settings_rounded, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ---------- XP Card ----------
          GlassCard(
            glow: c.levelProgress >= 0.9,
            child: Column(
              children: [
                Row(
                  children: [
                    Text('LEVEL ${c.level}',
                        style: const TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    const Spacer(),
                    Text('${c.xpIntoLevel}/${c.xpToNext} XP',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                GradientBar(progress: c.levelProgress, height: 12),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${(c.levelProgress * 100).round()}% to Level ${c.level + 1}',
                      style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ---------- Score + Transformation ----------
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  child: Column(
                    children: [
                      const Text('Today\'s Score', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 8),
                      ProgressRing(
                        progress: c.dailyScore / 100,
                        size: 108,
                        strokeWidth: 10,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedNumber(c.dailyScore, decimals: 0,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
                            const Text('/ 100', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GlassCard(
                  child: Column(
                    children: [
                      const Text('Transformation', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 8),
                      ProgressRing(
                        progress: c.transformationPct / 100,
                        size: 108,
                        strokeWidth: 10,
                        color: AppColors.green,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedNumber(c.transformationPct, decimals: 0,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
                            const Text('%', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ---------- Weight card ----------
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardTitle('Weight Journey', icon: '⚖️'),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('CURRENT', style: TextStyle(color: AppColors.textDim, fontSize: 10, letterSpacing: 1)),
                      Text('${c.currentWeight.toStringAsFixed(1)} kg',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 30, fontWeight: FontWeight.w800)),
                    ]),
                    const Spacer(),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text('GOAL', style: TextStyle(color: AppColors.textDim, fontSize: 10, letterSpacing: 1)),
                      Text('${c.profile.goalWeightKg.toStringAsFixed(0)} kg',
                          style: const TextStyle(color: AppColors.green, fontSize: 22, fontWeight: FontWeight.w700)),
                    ]),
                  ],
                ),
                const SizedBox(height: 8),
                GradientBar(progress: c.transformationPct / 100, height: 8, color: AppColors.green),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Pill(icon: '🔥', text: '${c.streakDays.round()} day streak', color: AppColors.orange),
                    const SizedBox(width: 8),
                    _Pill(icon: '🎯', text: '${remaining.toStringAsFixed(1)} kg to go', color: AppColors.blue),
                  ],
                ),
                const SizedBox(height: 8),
                Text('📅 Predicted goal date: ${dateFmt.format(predicted)}',
                    style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ---------- Quick actions ----------
          SectionHeader(title: 'Quick Actions', subtitle: 'Tap for instant XP'),
          Row(
            children: [
              Expanded(child: _QuickAction(icon: '💧', label: 'Water', color: AppColors.blue, onTap: () => c.addWater())),
              const SizedBox(width: 8),
              Expanded(child: _QuickAction(icon: '🚶', label: '+1000 steps', color: AppColors.green, onTap: () => c.addSteps(1000))),
              const SizedBox(width: 8),
              Expanded(child: _QuickAction(icon: '😊', label: 'Check-in', color: AppColors.purple, onTap: () => _moodDialog(context, c))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _QuickAction(icon: '💪', label: 'Workout', color: AppColors.red, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WorkoutScreen())))),
              const SizedBox(width: 8),
              Expanded(child: _QuickAction(icon: '🌙', label: 'Sleep', color: AppColors.teal, onTap: () => _sleepDialog(context, c))),
              const SizedBox(width: 8),
              Expanded(child: _QuickAction(icon: '📸', label: 'Photo', color: AppColors.gold, onTap: () => c.setExtraMission('photo'))),
            ],
          ),
          const SizedBox(height: 8),

          // ---------- Today's stats ----------
          SectionHeader(title: 'Today\'s Stats'),
          Row(
            children: [
              Expanded(child: StatChip(icon: '🔥', label: 'Calories', value: '${log.caloriesConsumed.round()}/${c.calorieGoal.round()}', color: AppColors.orange)),
              const SizedBox(width: 8),
              Expanded(child: StatChip(icon: '🍗', label: 'Protein', value: '${log.proteinConsumed.round()}/${c.proteinGoal.round()}g', color: AppColors.green)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: StatChip(icon: '💧', label: 'Water', value: '${log.waterMl}/${c.waterGoalMl}ml', color: AppColors.blue)),
              const SizedBox(width: 8),
              Expanded(child: StatChip(icon: '🏃', label: 'Steps', value: '${log.steps}/8000', color: AppColors.purple)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: StatChip(icon: '💪', label: 'Workout', value: log.workoutDone ? 'Done ✓' : 'Pending', color: log.workoutDone ? AppColors.green : AppColors.red)),
              const SizedBox(width: 8),
              Expanded(child: StatChip(icon: '🌙', label: 'Sleep', value: '${log.sleepHours.toStringAsFixed(1)}h', color: AppColors.teal)),
            ],
          ),
          const SizedBox(height: 4),

          // ---------- Progress bars mini ----------
          GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _MiniBar('Calories', calPct, AppColors.orange),
                _MiniBar('Protein', proteinPct, AppColors.green),
                _MiniBar('Water', waterPct, AppColors.blue),
                _MiniBar('Steps', stepPct, AppColors.purple),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ---------- Today's missions preview ----------
          SectionHeader(title: 'Today\'s Missions', subtitle: '${missions.where((q) => q.isComplete).length}/${missions.length} complete',
              trailing: TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MissionsScreen())),
                child: const Text('See all →', style: TextStyle(color: AppColors.blue)),
              )),
          ...missions.take(3).map((q) => _MissionTile(c: c, quest: q)),
          const SizedBox(height: 8),

          // ---------- Boss ----------
          _BossCard(c: c),
          const SizedBox(height: 8),

          // ---------- Character / Future You ----------
          _CharacterTeaser(c: c),
          const SizedBox(height: 8),

          // ---------- Reminder / mood ----------
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _Pill(icon: '😄', text: 'Mood ${log.mood}/5', color: AppColors.pink),
                  const SizedBox(width: 8),
                  _Pill(icon: '⚡', text: 'Energy ${log.energy}/5', color: AppColors.gold),
                ]),
                const SizedBox(height: 12),
                const Text('📌 Next up: drink a glass of water for +5 XP',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sleepDialog(BuildContext context, GameController c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌙 How much sleep did you get?', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [for (var h = 4; h <= 9; h++)
                ChoiceChip(
                  label: Text('$h h'),
                  selected: c.todayLog().sleepHours.round() == h,
                  onSelected: (_) { c.setSleep(h.toDouble()); Navigator.pop(ctx); },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final int level;
  const _Avatar({required this.level});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [AppColors.blue, AppColors.purple]),
        border: Border.all(color: AppColors.gold, width: 2),
        boxShadow: [BoxShadow(color: AppColors.blue.withOpacity(0.4), blurRadius: 16)],
      ),
      child: Center(
        child: Text('🦸', style: TextStyle(fontSize: 26)),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String icon;
  final String text;
  final Color color;
  const _Pill({required this.icon, required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text('$icon  $text', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      radius: 18,
      onTap: onTap,
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final String label;
  final double pct;
  final Color color;
  const _MiniBar(this.label, this.pct, this.color);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 66, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11))),
          Expanded(child: GradientBar(progress: pct, height: 6, color: color)),
        ],
      ),
    );
  }
}

class _MissionTile extends ConsumerWidget {
  final GameController c;
  final Quest quest;
  const _MissionTile({required this.c, required this.quest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complete = quest.isComplete;
    final claimed = quest.status == QuestStatus.claimed;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 18,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: complete ? AppColors.green.withOpacity(0.2) : AppColors.glassBg,
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(quest.icon, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quest.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${quest.progress.round()}/${quest.target.round()}  ·  +${quest.xp} XP',
                    style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (claimed)
            const Text('✓', style: TextStyle(color: AppColors.green, fontSize: 18, fontWeight: FontWeight.bold))
          else if (complete)
            _ClaimButton(quest: quest, c: c)
          else
            SizedBox(width: 44, height: 6, child: GradientBar(progress: quest.progress / quest.target)),
        ],
      ),
    );
  }
}

class _ClaimButton extends ConsumerWidget {
  final Quest quest;
  final GameController c;
  const _ClaimButton({required this.quest, required this.c});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => c.claimQuest(quest),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.35), blurRadius: 12)],
        ),
        child: const Text('CLAIM +XP', style: TextStyle(color: Color(0xFF1A1204), fontSize: 11, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _BossCard extends ConsumerWidget {
  final GameController c;
  const _BossCard({required this.c});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boss = c.currentBoss;
    final hp = (boss.maxHp * (1 - c.bossProgress)).round();
    final defeated = c.bossProgress >= 1.0;
    return GlassCard(
      borderColor: defeated ? AppColors.gold.withOpacity(0.7) : AppColors.red.withOpacity(0.4),
      glow: defeated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(boss.icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(defeated ? 'BOSS DEFEATED!' : 'Weekly Boss: ${boss.name}',
                        style: TextStyle(color: defeated ? AppColors.gold : AppColors.red, fontSize: 15, fontWeight: FontWeight.w800)),
                    Text(boss.description, style: const TextStyle(color: AppColors.textDim, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GradientBar(progress: c.bossProgress, height: 10, color: defeated ? AppColors.gold : AppColors.red),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(defeated ? 'Rewards claimed: +${boss.xpReward} XP 🏆' : 'HP remaining: $hp / ${boss.maxHp.round()}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              if (!defeated)
                const Text('Defeat it with weekly quests', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CharacterTeaser extends ConsumerWidget {
  final GameController c;
  const _CharacterTeaser({required this.c});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = CharacterStage.forProgress(c.transformationPct);
    return GlassCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CharacterScreen())),
      child: Row(
        children: [
          Text(stage.icon, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stage.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text('${c.transformationPct.round()}% of your evolution · tap to meet Future You',
                    style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textDim),
        ],
      ),
    );
  }
}
