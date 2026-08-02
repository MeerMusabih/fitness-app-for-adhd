import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/constants.dart';
import '../core/rpg.dart';
import '../core/state.dart';
import 'widgets.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(gameProvider);
    final weights = c.weightHistory;
    final logs = c.state.dailyLogs.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    final recent7 = logs.length > 7 ? logs.sublist(logs.length - 7) : logs;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Text('Progress', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Your transformation, quantified. Log weight weekly to unlock insights.',
              style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
          const SizedBox(height: 8),

          // ---------- Log weight ----------
          GlassCard(
            onTap: () => _logWeightDialog(context, c),
            child: Row(
              children: [
                const Text('⚖️', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Log today\'s weight', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                    Text('Last: ${weights.isEmpty ? c.currentWeight : weights.last.kg} kg',
                        style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                  ]),
                ),
                const Icon(Icons.add_circle_rounded, color: AppColors.gold),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ---------- Weight chart ----------
          if (weights.length >= 2) ...[
            const SectionHeader(title: 'Weight Trend'),
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 200,
                child: _LineChart(
                  points: weights.map((w) => (w.date, w.kg)).toList(),
                  lineColor: AppColors.green,
                  minY: (c.profile.goalWeightKg - 2).clamp(40.0, 200.0),
                  maxY: (c.profile.startWeightKg + 2).clamp(40.0, 250.0),
                ),
              ),
            ),
          ],

          // ---------- Weekly stats chart ----------
          if (logs.isNotEmpty) ...[
            const SectionHeader(title: 'Calories · 7 days'),
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 170,
                child: _BarChart(
                  points: recent7.map((d) => (d.date, d.caloriesConsumed)).toList(),
                  goal: c.calorieGoal,
                  color: AppColors.orange,
                ),
              ),
            ),
            const SectionHeader(title: 'Protein · 7 days'),
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 170,
                child: _BarChart(
                  points: recent7.map((d) => (d.date, d.proteinConsumed)).toList(),
                  goal: c.proteinGoal,
                  color: AppColors.green,
                ),
              ),
            ),
          ],

          // ---------- Key metrics ----------
          const SectionHeader(title: 'Body Metrics'),
          Row(children: [
            Expanded(child: StatChip(icon: '📏', label: 'BMI', value: RpgEngine.bmi(c.currentWeight, c.profile.heightCm).toStringAsFixed(1))),
            const SizedBox(width: 8),
            Expanded(child: StatChip(icon: '🧬', label: 'Est. Body Fat', value: '${RpgEngine.bodyFatPct(c.profile, c.currentWeight, _latestWaist(c)).toStringAsFixed(0)}%')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: StatChip(icon: '📅', label: 'Predicted Goal', value: DateFormat('MMM d').format(RpgEngine.predictedGoalDate(c.profile, c.currentWeight)))),
            const SizedBox(width: 8),
            Expanded(child: StatChip(icon: '📉', label: 'Lost So Far', value: '${(c.profile.startWeightKg - c.currentWeight).toStringAsFixed(1)} kg')),
          ]),
          const SizedBox(height: 8),

          // ---------- AI insight ----------
          const SectionHeader(title: 'AI Insights'),
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('This week\'s forecast', style: TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                _insight(c),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  double _latestWaist(GameController c) {
    for (final w in c.weightHistory.reversed) {
      if (w.waistCm != null) return w.waistCm!;
    }
    return c.profile.startWaistCm;
  }

  String _insight(GameController c) {
    final logs = c.state.dailyLogs.values.where((d) => d.loggedInToday || d.caloriesConsumed > 0).toList();
    final avgProtein = logs.isEmpty ? 0.0 : logs.map((d) => d.proteinConsumed).reduce((a, b) => a + b) / logs.length;
    final avgCalories = logs.isEmpty ? 0.0 : logs.map((d) => d.caloriesConsumed).reduce((a, b) => a + b) / logs.length;
    final weekWorkouts = logs.where((d) => d.workoutDone).length;
    final predicted30d = c.currentWeight - ((c.calorieGoal > 0 && avgCalories < c.calorieGoal + 100 && avgCalories > 0) ? 2.0 : 0.8);

    final parts = <String>[];
    parts.add('At your current pace, your weight in 30 days is projected near ${predicted30d.toStringAsFixed(1)} kg.');
    if (avgProtein < c.proteinGoal) {
      parts.add('⚠️ Protein is your biggest lever: you averaged ${avgProtein.round()}g vs a ${c.proteinGoal.round()}g goal.');
    } else {
      parts.add('✅ Protein is on track — you averaged ${avgProtein.round()}g.');
    }
    if (avgCalories > 0 && avgCalories < c.calorieGoal) {
      parts.add('✅ Calories are inside your budget on average.');
    } else if (avgCalories >= c.calorieGoal) {
      parts.add('⚠️ Calories run hot (avg ${avgCalories.round()} kcal). Trim one chai/sweet treat.');
    }
    if (weekWorkouts >= 3) {
      parts.add('💪 ${weekWorkouts} workouts this week — that\'s real boss damage.');
    } else {
      parts.add('🏋️ Try for 3+ workouts next week to speed up the timeline.');
    }
    return parts.join('\n\n');
  }

  void _logWeightDialog(BuildContext context, GameController c) {
    final controller = TextEditingController(text: c.currentWeight.toStringAsFixed(1));
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚖️ Log Weight', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 20),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(suffixText: 'kg'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final v = double.tryParse(controller.text);
                if (v != null && v > 30) {
                  c.logWeight(v);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save (+15 XP)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  final List<(DateTime, double)> points;
  final Color lineColor;
  final double minY;
  final double maxY;
  const _LineChart({required this.points, required this.lineColor, required this.minY, required this.maxY});

  @override
  Widget build(BuildContext context) {
    final spots = points.indexed.map((e) => FlSpot(e.$1.toDouble(), e.$2.$2)).toList();
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${points[i].$1.day}', style: const TextStyle(color: AppColors.textDim, fontSize: 9)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3, color: lineColor, strokeWidth: 2, strokeColor: AppColors.bgStart),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [lineColor.withOpacity(0.25), lineColor.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 500),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<(DateTime, double)> points;
  final double goal;
  final Color color;
  const _BarChart({required this.points, required this.goal, required this.color});

  @override
  Widget build(BuildContext context) {
    final maxV = points.fold(goal, (m, e) => e.$2 > m ? e.$2 : m) * 1.15;
    return BarChart(
      BarChartData(
        maxY: maxV,
        gridData: FlGridData(show: false),
        alignment: BarChartAlignment.spaceAround,
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${points[i].$1.day}', style: const TextStyle(color: AppColors.textDim, fontSize: 9)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].$2,
                  color: color,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: goal,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ],
            ),
        ],
      ),
      duration: const Duration(milliseconds: 500),
    );
  }
}
