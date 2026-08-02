import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/models.dart';
import '../core/state.dart';
import 'widgets.dart';

/// Character evolution stage for a given transformation progress %.
class CharacterStage {
  final String name;
  final String icon;
  final Color color;
  final int minProgress;
  const CharacterStage(this.name, this.icon, this.color, this.minProgress);

  static final List<CharacterStage> stages = [
    const CharacterStage('The Awakening', '🫃', AppColors.textSecondary, 0),
    const CharacterStage('The Apprentice', '🧍', AppColors.blue, 12),
    const CharacterStage('The Runner', '🏃', AppColors.teal, 28),
    const CharacterStage('The Warrior', '🧗', AppColors.purple, 45),
    const CharacterStage('The Athlete', '🏋️', AppColors.green, 62),
    const CharacterStage('The Champion', '🦸', AppColors.gold, 80),
    const CharacterStage('Reforged', '👑', AppColors.goldBright, 95),
  ];

  static CharacterStage forProgress(double pct) {
    CharacterStage current = stages.first;
    for (final s in stages) {
      if (pct >= s.minProgress) current = s;
    }
    return current;
  }
}

class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(gameProvider);
    final stage = CharacterStage.forProgress(c.transformationPct);
    final theme = _themeColor(c.settings.avatarTheme);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Evolution')),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---------- Current character ----------
            GlassCard(
              glow: c.transformationPct >= 80,
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [theme, theme.withOpacity(0.4)]),
                      border: Border.all(color: AppColors.gold, width: 2.5),
                      boxShadow: [BoxShadow(color: theme.withOpacity(0.5), blurRadius: 30)],
                    ),
                    child: Center(child: Text(stage.icon, style: const TextStyle(fontSize: 54))),
                  ),
                  PositionedText(pet: c.settings.petIcon),
                  const SizedBox(height: 10),
                  Text(stage.name,
                      style: const TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('Evolution ${c.transformationPct.round()}% · ${c.title}',
                      style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                  const SizedBox(height: 12),
                  GradientBar(progress: c.transformationPct / 100, height: 8, color: AppColors.green),
                  const SizedBox(height: 6),
                  Text('${c.currentWeight}kg → ${c.profile.goalWeightKg}kg (goal)',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ---------- Evolution path ----------
            const SectionHeader(title: 'Evolution Path'),
            for (final s in CharacterStage.stages)
              _StageRow(stage: s, current: stage.minProgress == s.minProgress, unlocked: c.transformationPct >= s.minProgress),
            const SizedBox(height: 8),

            // ---------- Customize ----------
            const SectionHeader(title: 'Customize'),
            GlassCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Avatar theme', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Row(children: [
                  for (final t in const ['blue', 'gold', 'green', 'purple'])
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => c.setSettings(c.settings.copyWith(avatarTheme: t)),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _themeColor(t),
                            border: Border.all(color: c.settings.avatarTheme == t ? AppColors.textPrimary : Colors.transparent, width: 2),
                          ),
                        ),
                      ),
                    ),
                ]),
                const SizedBox(height: 14),
                const Text('Companion pet', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  for (final pet in const ['🐕', '🐈', '🐢', '🦜', '🐉', '🦉', '🐺'])
                    GestureDetector(
                      onTap: () => c.setSettings(c.settings.copyWith(petIcon: pet)),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: c.settings.petIcon == pet ? AppColors.blue.withOpacity(0.25) : AppColors.glassBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.settings.petIcon == pet ? AppColors.blue : AppColors.glassStroke),
                        ),
                        child: Text(pet, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                ]),
              ]),
            ),
            const SizedBox(height: 8),

            // ---------- Skills ----------
            const SectionHeader(title: 'Skill Tree', subtitle: 'Level up skills with coins'),
            for (final s in c.skills) _SkillRow(c: c, skill: s),
            const SizedBox(height: 8),

            // ---------- Future You ----------
            const SectionHeader(title: 'Future You', subtitle: 'A message from your future self every 5 kg'),
            for (final m in c.milestones) _MilestoneCard(m: m, current: c.currentWeight),
            const SizedBox(height: 8),

            // ---------- Timeline ----------
            const SectionHeader(title: 'Timeline'),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TimelineRow(label: 'Day 1', value: '${c.profile.startWeightKg} kg', reached: true),
                  for (final m in c.milestones)
                    _TimelineRow(
                      label: m.targetWeight.round() == c.profile.goalWeightKg.round() ? 'GOAL' : '${m.targetWeight.round()} kg',
                      value: m.reached ? '${m.targetWeight.round()} kg ✓' : '${m.targetWeight.round()} kg',
                      reached: m.reached,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _themeColor(String theme) {
    switch (theme) {
      case 'gold':
        return AppColors.gold;
      case 'green':
        return AppColors.green;
      case 'purple':
        return AppColors.purple;
      default:
        return AppColors.blue;
    }
  }
}

class PositionedText extends StatelessWidget {
  final String pet;
  const PositionedText({required this.pet});
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(46, 0),
      child: Text(pet, style: const TextStyle(fontSize: 22)),
    );
  }
}

class _StageRow extends StatelessWidget {
  final CharacterStage stage;
  final bool current;
  final bool unlocked;
  const _StageRow({required this.stage, required this.current, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      radius: 16,
      borderColor: current ? stage.color.withOpacity(0.7) : null,
      child: Row(
        children: [
          Text(stage.icon, style: TextStyle(fontSize: 22, color: unlocked ? null : Colors.grey.shade600)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(stage.name,
                style: TextStyle(
                    color: unlocked ? AppColors.textPrimary : AppColors.textDim,
                    fontWeight: current ? FontWeight.w800 : FontWeight.w500)),
          ),
          if (current)
            const Text('YOU', style: TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.w800))
          else if (unlocked)
            const Text('✓', style: TextStyle(color: AppColors.green, fontSize: 15))
          else
            Text('${stage.minProgress}%', style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SkillRow extends ConsumerWidget {
  final GameController c;
  final Skill skill;
  const _SkillRow({required this.c, required this.skill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxed = skill.level >= skill.maxLevel;
    final cost = skill.level * 100;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 16,
      child: Row(
        children: [
          Text(skill.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(skill.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(children: [
                for (var i = 1; i <= skill.maxLevel; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.diamond_rounded,
                        size: 14,
                        color: i <= skill.level ? AppColors.blue : AppColors.textDim.withOpacity(0.4)),
                  ),
              ]),
            ]),
          ),
          if (maxed)
            const Text('MAX', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w800))
          else
            GestureDetector(
              onTap: c.state.coins >= cost ? () => c.upgradeSkill(skill.id) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: c.state.coins >= cost ? AppColors.blue : AppColors.glassBg,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text('🪙$cost',
                    style: TextStyle(
                        color: c.state.coins >= cost ? Colors.white : AppColors.textDim,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatefulWidget {
  final FutureYouMilestone m;
  final double current;
  const _MilestoneCard({required this.m, required this.current});

  @override
  State<_MilestoneCard> createState() => _MilestoneCardState();
}

class _MilestoneCardState extends State<_MilestoneCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final reached = widget.m.reached;
    final isNext = !reached && widget.current > widget.m.targetWeight;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 16,
      onTap: () => setState(() => _open = !_open),
      borderColor: reached ? AppColors.gold.withOpacity(0.6) : null,
      child: Column(
        children: [
          Row(
            children: [
              Text(reached ? '🎉' : '🔒', style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Reach ${widget.m.targetWeight.round()} kg',
                      style: TextStyle(
                          color: reached ? AppColors.gold : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  Text(reached
                      ? 'Future You is here ✓'
                      : isNext
                          ? 'Next milestone · ${(widget.current - widget.m.targetWeight).toStringAsFixed(1)} kg to go'
                          : 'Future You waits for you here',
                      style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
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
              child: Text(widget.m.message,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final String value;
  final bool reached;
  const _TimelineRow({required this.label, required this.value, required this.reached});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: reached ? AppColors.green : AppColors.textDim),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Text(value,
              style: TextStyle(
                  color: reached ? AppColors.textPrimary : AppColors.textDim,
                  fontWeight: reached ? FontWeight.w700 : FontWeight.w400)),
        ],
      ),
    );
  }
}
