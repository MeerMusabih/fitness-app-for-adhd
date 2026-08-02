import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/models.dart';
import '../core/state.dart';
import 'widgets.dart';

class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(gameProvider);
    final daily = c.todayQuests;
    final weekly = c.weeklyQuests;
    final boss = c.currentBoss;
    final achievements = c.achievements;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Text('Missions', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Complete quests → earn XP → defeat the weekly boss.',
              style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
          const SizedBox(height: 8),

          // ---------- Daily missions ----------
          SectionHeader(title: 'Today\'s Quests', subtitle: '${daily.where((q) => q.isComplete).length}/${daily.length} done'),
          ...daily.map((q) => _QuestCard(c: c, quest: q)),
          const SizedBox(height: 8),

          // ---------- Weekly quests ----------
          SectionHeader(title: 'Weekly Quests', subtitle: 'Damage the boss'),
          ...weekly.map((q) => _QuestCard(c: c, quest: q)),
          const SizedBox(height: 8),

          // ---------- Boss ----------
          GlassCard(
            borderColor: AppColors.red.withOpacity(0.4),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(boss.icon, style: const TextStyle(fontSize: 34)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Boss: ${boss.name}',
                            style: const TextStyle(color: AppColors.red, fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('Defeated by weekly quest progress',
                            style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                      ]),
                    ),
                    if (c.bossProgress >= 1.0)
                      const Text('🏆', style: TextStyle(fontSize: 24)),
                  ],
                ),
                const SizedBox(height: 10),
                GradientBar(progress: c.bossProgress, height: 12, color: c.bossProgress >= 1.0 ? AppColors.gold : AppColors.red),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${(c.bossProgress * 100).round()}% damage dealt',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text('Reward: +${boss.xpReward} XP · 🪙${boss.coinReward}',
                        style: const TextStyle(color: AppColors.gold, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ---------- Achievements ----------
          SectionHeader(title: 'Achievements', subtitle: '${achievements.where((a) => a.unlocked).length}/${achievements.length} unlocked'),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82,
            children: achievements.map((a) => _AchievementTile(a: a)).toList(),
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends ConsumerWidget {
  final GameController c;
  final Quest quest;
  const _QuestCard({required this.c, required this.quest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complete = quest.isComplete;
    final claimed = quest.status == QuestStatus.claimed;
    final pct = (quest.progress / quest.target).clamp(0.0, 1.0);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 18,
      borderColor: complete ? AppColors.green.withOpacity(0.4) : null,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: complete ? AppColors.green.withOpacity(0.2) : AppColors.glassBg,
              shape: BoxShape.circle,
              border: Border.all(color: complete ? AppColors.green : AppColors.glassStroke),
            ),
            child: Center(child: Text(quest.icon, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(quest.title,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  Text('+${quest.xp} XP',
                      style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 3),
                Text(quest.subtitle, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                const SizedBox(height: 6),
                GradientBar(
                    progress: complete ? 1 : pct,
                    height: 6,
                    color: complete ? AppColors.green : AppColors.blue),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (claimed)
            const Text('✅', style: TextStyle(fontSize: 20))
          else if (complete)
            GestureDetector(
              onTap: () => c.claimQuest(quest),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.35), blurRadius: 12)],
                ),
                child: const Text('CLAIM', style: TextStyle(color: Color(0xFF1A1204), fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            )
          else
            Text('${quest.progress.round()}/${quest.target.round()}',
                style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement a;
  const _AchievementTile({required this.a});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(8),
      radius: 16,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(a.icon, style: TextStyle(fontSize: 26, color: a.unlocked ? null : Colors.grey)),
          const SizedBox(height: 6),
          Text(a.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: a.unlocked ? AppColors.textPrimary : AppColors.textDim,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
