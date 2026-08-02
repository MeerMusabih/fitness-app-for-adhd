import 'dart:math' as math;

import '../core/models.dart';

/// Core RPG math, targets, titles, achievements, missions & bosses.
class RpgEngine {
  RpgEngine._();

  // ---------------- XP / Levels ----------------
  static int xpForLevel(int level) => 100 + (level - 1) * 35;

  static int levelForXp(int total) {
    var level = 1;
    var rem = total;
    while (rem >= xpForLevel(level)) {
      rem -= xpForLevel(level);
      level++;
    }
    return level;
  }

  static int xpIntoLevel(int total) {
    final l = levelForXp(total);
    var used = 0;
    for (var i = 1; i < l; i++) {
      used += xpForLevel(i);
    }
    return total - used;
  }

  static double levelProgress(int total) {
    final l = levelForXp(total);
    final into = xpIntoLevel(total);
    return (into / xpForLevel(l)).clamp(0.0, 1.0);
  }

  // ---------------- Targets ----------------
  static double bmr(PlayerProfile p) {
    final base = 10 * p.startWeightKg + 6.25 * p.heightCm - 5 * p.age;
    return p.gender == 'male' ? base + 5 : base - 161;
  }

  /// Adaptive calorie target using current weight.
  static double calorieTarget(PlayerProfile p, double currentWeight) {
    final bmr = 10 * currentWeight + 6.25 * p.heightCm - 5 * p.age + (p.gender == 'male' ? 5 : -161);
    final tdee = bmr * 1.375; // light activity (home workouts, beginner)
    return math.max(1800, tdee - 550);
  }

  static double proteinTarget(double currentWeight) =>
      (currentWeight * 1.6).clamp(130.0, 220.0);

  static int waterTargetMl(double currentWeight) => (currentWeight * 35).round();

  static double bmi(double weightKg, double heightCm) =>
      weightKg / math.pow(heightCm / 100, 2);

  /// Estimated body fat % (US Navy): male only approximations.
  static double bodyFatPct(PlayerProfile p, double weightKg, double waistCm) {
    if (p.gender == 'male') {
      final logBmi = math.log(bmi(weightKg, p.heightCm));
      return (86.010 * logBmi - 70.041).clamp(5.0, 60.0);
    }
    return 0;
  }

  /// Predicted goal date assuming ~0.45 kg/week (≈500 kcal deficit).
  static DateTime predictedGoalDate(PlayerProfile p, double currentWeight) {
    final remaining = math.max(0, currentWeight - p.goalWeightKg);
    final weeks = remaining / 0.45;
    return DateTime.now().add(Duration(days: (weeks * 7).round()));
  }

  static double transformationPct(PlayerProfile p, double currentWeight) {
    final total = math.max(0.1, p.startWeightKg - p.goalWeightKg);
    final lost = math.max(0, p.startWeightKg - currentWeight);
    return ((lost / total) * 100).clamp(0.0, 100.0);
  }

  // ---------------- Titles ----------------
  static String titleFor(int level, Set<String> unlockedAchievementIds) {
    if (level >= 100) return 'Legend';
    if (unlockedAchievementIds.contains('reforged')) return 'Reforged';
    if (level >= 50) return 'Iron Will';
    if (level >= 25) return 'Warrior of Reforge';
    if (level >= 10) return 'Disciplined';
    if (level >= 5) return 'Determined';
    return 'The Beginner';
  }

  static const List<String> ranks = [
    'Bronze Novice', 'Silver Recruit', 'Gold Trainee', 'Platinum Athlete',
    'Diamond Warrior', 'Master', 'Grandmaster', 'Legend of Reforge',
  ];

  static String rankFor(int level) {
    final i = (level ~/ 15).clamp(0, ranks.length - 1);
    return ranks[i];
  }

  // ---------------- Achievements ----------------
  static List<Achievement> defaultAchievements() => [
        Achievement(id: 'first_workout', title: 'First Blood', description: 'Complete your first workout', icon: '💪', xp: 50),
        Achievement(id: 'streak_7', title: '7-Day Streak', description: 'Log activity 7 days in a row', icon: '🔥', xp: 100),
        Achievement(id: 'streak_30', title: 'Iron Month', description: 'Keep a 30-day streak alive', icon: '⚡', xp: 400),
        Achievement(id: 'lost_5kg', title: '5kg Down', description: 'Lose your first 5 kilograms', icon: '🏅', xp: 200),
        Achievement(id: 'lost_10kg', title: '10kg Down', description: 'Lose 10 kilograms', icon: '🥇', xp: 500),
        Achievement(id: 'walked_100km', title: 'Century Walker', description: 'Walk a total of 100 km', icon: '🚶', xp: 250),
        Achievement(id: 'pushups_100', title: 'Push-up Machine', description: 'Complete 100 total push-ups', icon: '🙌', xp: 150),
        Achievement(id: 'logged_meals_50', title: 'Meal Tracker', description: 'Log 50 meals', icon: '🍽️', xp: 150),
        Achievement(id: 'protein_30d', title: 'Protein Pro', description: 'Hit protein goal 30 days', icon: '🍗', xp: 300),
        Achievement(id: 'water_100d', title: 'Hydration Hero', description: 'Drink water goal 100 days', icon: '💧', xp: 400),
        Achievement(id: 'no_soda_50d', title: 'Soda-Free', description: '50 days without sugary drinks', icon: '🚫', xp: 250),
        Achievement(id: 'level_50', title: 'Halfway Legend', description: 'Reach level 50', icon: '🌟', xp: 1000),
        Achievement(id: 'level_100', title: 'Level 100', description: 'Reach the max level', icon: '👑', xp: 5000),
        Achievement(id: 'weight_logged_30', title: 'Scale Watcher', description: 'Log weight 30 times', icon: '⚖️', xp: 150),
        Achievement(id: 'reforged', title: 'Reforged', description: 'Reach 95% of your transformation', icon: '👑', xp: 500),
      ];

  // ---------------- Skills tree ----------------
  static List<Skill> defaultSkills() => [
        Skill(id: 'nutrition', name: 'Nutrition', icon: '🍎', description: 'Better choices, more protein, stable calories', maxLevel: 5),
        Skill(id: 'strength', name: 'Strength', icon: '🏋️', description: 'Push-ups, squats and bodyweight power', maxLevel: 5),
        Skill(id: 'endurance', name: 'Endurance', icon: '🏃', description: 'Walking, running and stamina', maxLevel: 5),
        Skill(id: 'mind', name: 'Mind', icon: '🧠', description: 'Sleep, meditation, habit control', maxLevel: 5),
        Skill(id: 'consistency', name: 'Consistency', icon: '📅', description: 'Streaks, daily logging, reliability', maxLevel: 5),
      ];

  // ---------------- Daily missions ----------------
  /// Generates today's missions. Core set + rotating extras by day-of-year.
  static List<Quest> generateDailyMissions({
    required DateTime day,
    required double calorieGoal,
    required double proteinGoal,
    required int waterGoalMl,
    required double stepsGoal,
  }) {
    final dayNum = day.difference(DateTime(day.year)).inDays;
    final core = <Quest>[
      Quest(
        id: 'd_water_$dayNum', kind: QuestKind.daily, missionId: 'water',
        title: 'Hydration Quest', subtitle: 'Drink ${waterGoalMl ~/ 1000}.${(waterGoalMl % 1000) ~/ 100}L water',
        icon: '💧', xp: 40, coins: 5, target: waterGoalMl.toDouble(), day: day,
      ),
      Quest(
        id: 'd_steps_$dayNum', kind: QuestKind.daily, missionId: 'steps',
        title: 'Walker Mission', subtitle: 'Reach ${stepsGoal.round()} steps',
        icon: '🏃', xp: 50, coins: 5, target: stepsGoal, day: day,
      ),
      Quest(
        id: 'd_protein_$dayNum', kind: QuestKind.daily, missionId: 'protein',
        title: 'Protein Target', subtitle: 'Eat ${proteinGoal.round()}g protein',
        icon: '🍗', xp: 50, coins: 5, target: proteinGoal, day: day,
      ),
      Quest(
        id: 'd_calories_$dayNum', kind: QuestKind.daily, missionId: 'calories',
        title: 'Fuel Within Limits', subtitle: 'Stay under ${calorieGoal.round()} kcal',
        icon: '🔥', xp: 40, coins: 5, target: calorieGoal, day: day,
      ),
      Quest(
        id: 'd_workout_$dayNum', kind: QuestKind.daily, missionId: 'workout',
        title: 'Workout Quest', subtitle: 'Complete today\'s workout',
        icon: '💪', xp: 80, coins: 10, target: 1, day: day,
      ),
    ];

    final extrasPool = [
      Quest(id: '', kind: QuestKind.daily, missionId: 'no_sugar', title: 'No Sugary Drinks', subtitle: 'Skip sodas all day', icon: '🥤', xp: 45, coins: 6, target: 1, day: DateTime(2000)),
      Quest(id: '', kind: QuestKind.daily, missionId: 'sleep', title: 'Sleep Before Midnight', subtitle: 'Be asleep by 12 AM', icon: '🌙', xp: 40, coins: 5, target: 1, day: DateTime(2000)),
      Quest(id: '', kind: QuestKind.daily, missionId: 'stretch', title: 'Stretch', subtitle: '5 minutes of stretching', icon: '🧘', xp: 25, coins: 3, target: 1, day: DateTime(2000)),
      Quest(id: '', kind: QuestKind.daily, missionId: 'meditate', title: 'Meditate', subtitle: '3 minutes of mindfulness', icon: '🕉️', xp: 25, coins: 3, target: 1, day: DateTime(2000)),
      Quest(id: '', kind: QuestKind.daily, missionId: 'photo', title: 'Progress Photo', subtitle: 'Snap a progress photo', icon: '📸', xp: 20, coins: 3, target: 1, day: DateTime(2000)),
      Quest(id: '', kind: QuestKind.daily, missionId: 'read', title: 'Read', subtitle: '15 minutes with a book', icon: '📖', xp: 20, coins: 3, target: 1, day: DateTime(2000)),
      Quest(id: '', kind: QuestKind.daily, missionId: 'veggies', title: 'Eat Veggies', subtitle: 'One serving of vegetables', icon: '🥦', xp: 20, coins: 3, target: 1, day: DateTime(2000)),
    ];

    final start = dayNum % extrasPool.length;
    for (var i = 0; i < 3; i++) {
      final src = extrasPool[(start + i) % extrasPool.length];
      core.add(Quest(
        id: 'd_${src.missionId}_$dayNum', kind: QuestKind.daily, missionId: src.missionId,
        title: src.title, subtitle: src.subtitle, icon: src.icon,
        xp: src.xp, coins: src.coins, target: src.target, day: day,
      ));
    }
    return core;
  }

  // ---------------- Weekly quests ----------------
  static List<Quest> generateWeeklyQuests(DateTime weekStart, DateTime day) {
    final num = weekStart.difference(DateTime(weekStart.year)).inDays ~/ 7;
    return [
      Quest(id: 'w_workouts_$num', kind: QuestKind.weekly, missionId: 'workouts',
        title: 'Weekly Workouts', subtitle: 'Complete 4 workouts', icon: '💪',
        xp: 200, coins: 30, target: 4, day: day),
      Quest(id: 'w_calories_$num', kind: QuestKind.weekly, missionId: 'calories',
        title: 'Calorie Discipline', subtitle: '4 days within calorie goal', icon: '🔥',
        xp: 150, coins: 20, target: 4, day: day),
      Quest(id: 'w_protein_$num', kind: QuestKind.weekly, missionId: 'protein',
        title: 'Protein Week', subtitle: '5 days hitting protein', icon: '🍗',
        xp: 150, coins: 20, target: 5, day: day),
      Quest(id: 'w_steps_$num', kind: QuestKind.weekly, missionId: 'steps',
        title: 'Steps Campaign', subtitle: 'Walk 45,000 steps total', icon: '🏃',
        xp: 150, coins: 20, target: 45000, day: day),
      Quest(id: 'w_sugar_$num', kind: QuestKind.weekly, missionId: 'no_sugar',
        title: 'Sugar Free Week', subtitle: '6 days with no sugary drinks', icon: '🥤',
        xp: 120, coins: 15, target: 6, day: day),
    ];
  }

  // ---------------- Boss battles ----------------
  static const List<Map<String, String>> bossPool = [
    {'id': 'sugar_monster', 'name': 'Sugar Monster', 'icon': '👹',
     'desc': 'A towering blob of fizzy soda. It grows stronger with every sweet drink. Kill it by staying off sugary drinks.'},
    {'id': 'lazy_sunday', 'name': 'Lazy Sunday', 'icon': '🛋️',
     'desc': 'The couch calls your name. Defeat it by staying active and completing your workout.'},
    {'id': 'late_night', 'name': 'Late Night Snacker', 'icon': '🌙',
     'desc': 'A sneaky fiend that strikes after midnight. Beat it by eating 1-2g protein and sleeping early.'},
    {'id': 'fast_food', 'name': 'Fast Food Demon', 'icon': '😈',
     'desc': 'Summoned by every fried craving. Weaken it with home-cooked meals and clean protein.'},
    {'id': 'holiday_feast', 'name': 'Holiday Feast', 'icon': '🎉',
     'desc': 'An endless buffet. Defeat it by logging meals honestly and stopping at the right portions.'},
    {'id': 'plateau', 'name': 'The Plateau', 'icon': '🗿',
     'desc': 'The wall every warrior meets. Break through it by staying consistent when the scale stalls.'},
  ];

  static Boss bossForWeek(DateTime day) {
    final epoch = DateTime(2026, 1, 5); // a Monday
    final weeks = day.difference(epoch).inDays ~/ 7;
    final meta = bossPool[weeks.abs() % bossPool.length];
    final start = day.subtract(Duration(days: day.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return Boss(
      id: '${meta['id']}_$weeks', name: meta['name']!, icon: meta['icon']!,
      description: meta['desc']!, maxHp: 500, xpReward: 300, coinReward: 100,
      missions: const [], start: start, end: end,
    );
  }

  // ---------------- Daily score ----------------
  static double dailyScore(List<Quest> todayQuests, DailyLog log) {
    if (todayQuests.isEmpty) return 0;
    var score = 0.0;
    for (final q in todayQuests) {
      score += (q.progress / q.target).clamp(0.0, 1.0) * (100.0 / todayQuests.length);
    }
    if (log.mood >= 4) score += 3;
    if (log.energy >= 4) score += 2;
    if (log.mood <= 2) score -= 5;
    return score.clamp(0.0, 100.0);
  }

  // ---------------- Streaks ----------------
  /// Longest run of consecutive days where the condition predicate is true.
  static int currentStreak(List<DateTime> days) {
    if (days.isEmpty) return 0;
    final set = days.map(dateOnly).toSet();
    var streak = 0;
    var cursor = dateOnly(DateTime.now());
    if (!set.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (set.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int longestStreak(List<DateTime> days) {
    if (days.isEmpty) return 0;
    final set = days.map(dateOnly).toSet().toList()..sort();
    var best = 0, cur = 0;
    DateTime? prev;
    for (final d in set) {
      if (prev != null && d.difference(prev).inDays == 1) {
        cur++;
      } else {
        cur = 1;
      }
      best = math.max(best, cur);
      prev = d;
    }
    return best;
  }

  /// Rebuilds Future You milestones, preserving reached flags when the
  /// starting weight is unchanged.
  static List<FutureYouMilestone> transformMilestones(
      List<FutureYouMilestone> current, PlayerProfile newProfile) {
    if (current.isNotEmpty && current.first.startWeight == newProfile.startWeightKg) {
      return current;
    }
    final out = <FutureYouMilestone>[];
    var target = (newProfile.startWeightKg - 5).round();
    while (target >= newProfile.goalWeightKg) {
      out.add(FutureYouMilestone(
        targetWeight: target.toDouble(),
        startWeight: newProfile.startWeightKg,
        message: 'Hey ${newProfile.name}. I\'m you, at ${target}kg. Every glass of water, '
            'every walk, every logged meal brought you here. Keep going — the version at '
            '${math.max(newProfile.goalWeightKg, target - 5).round()}kg is even stronger.',
      ));
      target -= 5;
    }
    return out;
  }
}
