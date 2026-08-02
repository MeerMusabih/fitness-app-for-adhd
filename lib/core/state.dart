import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../core/coach.dart';
import '../core/models.dart';
import '../core/notification.dart';
import '../core/repo.dart';
import '../core/rpg.dart';
import '../core/widget_bridge.dart';

/// One-shot game events for dopamine feedback (XP bursts, confetti, sound).
enum GameEventType { xp, levelUp, achievement, confetti, boss, milestone, celebration, water, meal, workout }

class GameEvent {
  final GameEventType type;
  final String message;
  final int? xp;
  final Color? color;
  const GameEvent(this.type, this.message, {this.xp, this.color});
}

/// Central game controller: all mutations, XP, streaks, quests, achievements.
class GameController extends ChangeNotifier {
  GameState _s;
  bool loaded = false;
  final GameRepo _repo = GameRepo();
  final AiCoach coach = AiCoach();
  final _events = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get events => _events.stream;
  Future<void>? _saveInFlight;

  GameController(GameState state) : _s = state;

  GameState get state => _s;

  Future<void> init() async {
    final loadedState = await _repo.load();
    if (loadedState != null) {
      _s = loadedState;
    }
    loaded = true;
    notifyListeners();
    _pushWidgetData();
    await _scheduleReminders();
  }

  // ---------------- Derived getters ----------------
  PlayerProfile get profile => _s.profile;
  double get currentWeight =>
      _s.weightHistory.isEmpty ? profile.startWeightKg : _s.weightHistory.last.kg;
  int get level => RpgEngine.levelForXp(_s.totalXp);
  int get xpIntoLevel => RpgEngine.xpIntoLevel(_s.totalXp);
  int get xpToNext => RpgEngine.xpForLevel(level);
  double get levelProgress => RpgEngine.levelProgress(_s.totalXp);
  double get calorieGoal => RpgEngine.calorieTarget(profile, currentWeight);
  double get proteinGoal => RpgEngine.proteinTarget(currentWeight);
  int get waterGoalMl => RpgEngine.waterTargetMl(currentWeight);
  String get title => RpgEngine.titleFor(level, unlockedIds);
  String get rank => RpgEngine.rankFor(level);
  double get transformationPct => RpgEngine.transformationPct(profile, currentWeight);
  Set<String> get unlockedIds =>
      _s.achievements.where((a) => a.unlocked).map((a) => a.id).toSet();
  List<Achievement> get achievements => _s.achievements;
  List<Skill> get skills => _s.skills;

  DateTime get today => dateOnly(DateTime.now());

  DailyLog todayLog() {
    final key = stripDay(DateTime.now());
    return _s.dailyLogs[key] ?? DailyLog(date: DateTime.now());
  }

  DailyLog _ensureToday() {
    final key = stripDay(DateTime.now());
    return _s.dailyLogs.putIfAbsent(key, () => DailyLog(date: DateTime.now()));
  }

  List<Quest> get todayQuests {
    final missions = RpgEngine.generateDailyMissions(
      day: today,
      calorieGoal: calorieGoal,
      proteinGoal: proteinGoal,
      waterGoalMl: waterGoalMl,
      stepsGoal: 8000,
    );
    final log = todayLog();
    return missions.map((q) {
      final p = questProgress(q, log);
      return q.copyWith(
        progress: p,
        status: _s.claimedQuests.contains(q.id) ? QuestStatus.claimed : QuestStatus.active,
      );
    }).toList();
  }

  List<Quest> get weeklyQuests {
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final missions = RpgEngine.generateWeeklyQuests(weekStart, today);
    final weekLogs = _logsInRange(weekStart, weekStart.add(const Duration(days: 6)));
    return missions.map((q) {
      final p = weeklyProgress(q, weekLogs);
      return q.copyWith(
        progress: p,
        status: _s.claimedQuests.contains(q.id) ? QuestStatus.claimed : QuestStatus.active,
      );
    }).toList();
  }

  Boss get currentBoss {
    final boss = RpgEngine.bossForWeek(today);
    return boss;
  }

  double get bossProgress {
    final wq = weeklyQuests;
    if (wq.isEmpty) return 0;
    var sum = 0.0;
    for (final q in wq) {
      sum += (q.progress / q.target).clamp(0.0, 1.0);
    }
    return (sum / wq.length).clamp(0.0, 1.0);
  }

  double get dailyScore => RpgEngine.dailyScore(todayQuests, todayLog());

  List<WeightEntry> get weightHistory => _s.weightHistory;
  List<MealLog> get mealLogs => _s.mealLogs;
  List<ChatMessage> get chatHistory => _s.chatHistory;
  List<FutureYouMilestone> get milestones => _s.milestones;
  AppSettings get settings => _s.settings;
  List<String> get recentFoodIds => _s.recentFoodIds;
  Set<String> get favoriteFoodIds => _s.favoriteFoodIds;

  double get streakDays {
    final active = _s.dailyLogs.values
        .where((d) => d.loggedInToday || d.waterMl > 0 || d.caloriesConsumed > 0 || d.steps > 0)
        .map((d) => d.date)
        .toList();
    return RpgEngine.currentStreak(active).toDouble();
  }

  int get mealCount => _s.mealLogs.length;
  double get totalDistanceKm => _s.totalDistanceKm;
  double get totalPushups => _s.totalPushups;
  int get weightLogCount => _s.weightLogCount;

  // ---------------- Quest progress ----------------
  List<DailyLog> _logsInRange(DateTime start, DateTime end) {
    final s = dateOnly(start), e = dateOnly(end);
    return _s.dailyLogs.values
        .where((d) => !d.date.isBefore(s) && !d.date.isAfter(e))
        .toList();
  }

  double questProgress(Quest q, DailyLog log) {
    switch (q.missionId) {
      case 'water':
        return log.waterMl.toDouble();
      case 'steps':
        return log.steps.toDouble();
      case 'protein':
        return log.proteinConsumed;
      case 'calories':
        if (log.caloriesConsumed <= 0) return 0;
        return log.caloriesConsumed <= q.target ? q.target : 0;
      case 'workout':
        return log.workoutDone ? 1 : 0;
      case 'no_sugar':
        return log.sugaryDrink ? 0 : 1;
      case 'sleep':
        return log.sleepHours >= 5.5 ? 1 : 0;
      case 'stretch':
        return log.stretchDone ? 1 : 0;
      case 'meditate':
        return log.meditateDone ? 1 : 0;
      case 'photo':
        return log.photoTaken ? 1 : 0;
      case 'read':
        return log.readDone ? 1 : 0;
      case 'veggies':
        return log.vegetables ? 1 : 0;
      default:
        return 0;
    }
  }

  double weeklyProgress(Quest q, List<DailyLog> weekLogs) {
    switch (q.missionId) {
      case 'workouts':
        return weekLogs.where((d) => d.workoutDone).length.toDouble();
      case 'calories':
        return weekLogs
            .where((d) => d.caloriesConsumed > 0 && d.caloriesConsumed <= calorieGoal)
            .length
            .toDouble();
      case 'protein':
        return weekLogs.where((d) => d.proteinConsumed >= proteinGoal).length.toDouble();
      case 'steps':
        return weekLogs.fold(0.0, (s, d) => s + d.steps);
      case 'no_sugar':
        return weekLogs.where((d) => !d.sugaryDrink).length.toDouble();
      default:
        return 0;
    }
  }

  // ---------------- Mutations ----------------
  void _commit() {
    notifyListeners();
    _save();
    _pushWidgetData();
  }

  Future<void> _save() {
    final s = _saveInFlight ??= _repo.save(_s).whenComplete(() => _saveInFlight = null);
    return s;
  }

  void _emit(GameEvent e) => _events.add(e);

  Future<void> _scheduleReminders() async {
    try {
      await NotificationService.instance.configure(_s.settings);
    } catch (_) {}
  }

  // XP with level-up detection.
  void addXp(int amount, {String reason = 'Action'}) {
    if (amount <= 0) return;
    final before = level;
    _s.totalXp += amount;
    final after = level;
    _emit(GameEvent(GameEventType.xp, '+$amount XP • $reason', xp: amount));
    if (after > before) {
      _emit(GameEvent(GameEventType.levelUp, 'LEVEL UP! You are now Level $after!', xp: 100));
      addCoins(after * 10, silent: true);
    }
    checkAchievements();
    _commit();
  }

  void addCoins(int amount, {bool silent = false}) {
    _s.coins += amount;
    if (!silent) _emit(GameEvent(GameEventType.confetti, '+$amount coins!'));
    _commit();
  }

  void spendCoins(int amount) {
    _s.coins = math.max(0, _s.coins - amount);
    _commit();
  }

  // ---------------- Water ----------------
  void addWater({int ml = 250, bool reward = true}) {
    final log = _ensureToday();
    log.waterMl += ml;
    log.loggedInToday = true;
    if (reward) {
      addXp(5, reason: 'Hydration +${ml}ml');
      _emit(GameEvent(GameEventType.water, '+$ml ml water', xp: 5));
    }
    _commit();
  }

  // ---------------- Steps ----------------
  void addSteps(int steps) {
    if (steps <= 0) return;
    final log = _ensureToday();
    log.steps += steps;
    log.loggedInToday = true;
    _s.totalDistanceKm += steps / 1300.0;
    checkAchievements();
    _commit();
  }

  // ---------------- Food ----------------
  void logFoods(List<LoggedFood> foods, {String method = 'text', bool reward = true}) {
    if (foods.isEmpty) return;
    final log = _ensureToday();
    final meal = MealLog(
      time: DateTime.now(),
      foods: foods,
      method: method,
      calories: foods.fold(0.0, (s, f) => s + f.calories),
      protein: foods.fold(0.0, (s, f) => s + f.protein),
      carbs: foods.fold(0.0, (s, f) => s + f.carbs),
      fat: foods.fold(0.0, (s, f) => s + f.fat),
    );
    log.caloriesConsumed += meal.calories;
    log.proteinConsumed += meal.protein;
    log.loggedInToday = true;
    _s.mealLogs.add(meal);
    for (final f in foods) {
      _s.recentFoodIds.remove(f.foodId);
      _s.recentFoodIds.insert(0, f.foodId);
    }
    _s.recentFoodIds = _s.recentFoodIds.take(20).toList();
    final sugary = foods.any((f) => const {'cola', 'sugary_drink', 'cold_drink'}.contains(f.foodId));
    if (sugary) log.sugaryDrink = true;
    if (reward) addXp(10, reason: 'Meal logged');
    checkAchievements();
    _commit();
  }

  void toggleFavorite(String foodId) {
    if (!_s.favoriteFoodIds.remove(foodId)) {
      _s.favoriteFoodIds.add(foodId);
    }
    _commit();
  }

  // ---------------- Sleep / misc ----------------
  void setSleep(double hours) {
    final log = _ensureToday();
    log.sleepHours = hours;
    log.loggedInToday = true;
    if (hours >= 5.5) addXp(20, reason: 'Sleep tracked');
    _commit();
  }

  void completeWorkout({int minutes = 20, int pushups = 0, int squats = 0}) {
    final log = _ensureToday();
    final wasDone = log.workoutDone;
    log.workoutDone = true;
    log.workoutMinutes += minutes;
    log.loggedInToday = true;
    _s.totalPushups += pushups;
    if (!wasDone) {
      addXp(80, reason: 'Workout complete');
      _emit(GameEvent(GameEventType.workout, 'Workout done! +80 XP'));
    }
    checkAchievements();
    _commit();
  }

  void setExtraMission(String missionId) {
    final log = _ensureToday();
    log.loggedInToday = true;
    switch (missionId) {
      case 'stretch':
        log.stretchDone = true;
      case 'meditate':
        log.meditateDone = true;
      case 'read':
        log.readDone = true;
      case 'photo':
        log.photoTaken = true;
      case 'veggies':
        log.vegetables = true;
    }
    addXp(10, reason: 'Extra mission');
    _commit();
  }

  void markSugaryDrink() {
    _ensureToday().sugaryDrink = true;
    _ensureToday().loggedInToday = true;
    _commit();
  }

  void setCheckIn({int? mood, int? energy, int? stress}) {
    final log = _ensureToday();
    if (mood != null) log.mood = mood;
    if (energy != null) log.energy = energy;
    if (stress != null) log.stress = stress;
    log.loggedInToday = true;
    _commit();
  }

  // ---------------- Weight ----------------
  void logWeight(double kg, {double? waistCm, double? chestCm}) {
    final prevWeight = currentWeight;
    _s.weightHistory.add(WeightEntry(
      date: DateTime.now(),
      kg: kg,
      waistCm: waistCm,
      chestCm: chestCm,
    ));
    _s.weightLogCount++;
    addXp(15, reason: 'Weigh-in logged');

    if (kg < prevWeight) {
      _emit(GameEvent(GameEventType.confetti, 'Trending down! ${(prevWeight - kg).toStringAsFixed(1)} kg lighter', xp: 25));
    }

    // Future You milestones every 5kg
    for (var i = 0; i < _s.milestones.length; i++) {
      final m = _s.milestones[i];
      if (!m.reached && kg <= m.targetWeight) {
        _s.milestones[i] = m.copyWith(reached: true, reachedAt: DateTime.now());
        _emit(GameEvent(GameEventType.milestone,
            '🎉 Future You milestone: ${m.targetWeight.round()} kg reached!\n\n${m.message}',
            xp: 200));
        addCoins(100, silent: true);
      }
    }
    checkAchievements();
    _commit();
  }

  // ---------------- Quests ----------------
  bool claimQuest(Quest q) {
    if (q.progress < q.target) return false;
    if (_s.claimedQuests.contains(q.id)) return false;
    _s.claimedQuests.add(q.id);
    addXp(q.xp, reason: 'Quest: ${q.title}');
    addCoins(q.coins, silent: true);
    _emit(GameEvent(GameEventType.confetti, 'Quest complete: ${q.title}', xp: q.xp));

    // Weekly quest -> boss damage
    if (q.kind == QuestKind.weekly) {
      final before = bossProgress;
      _checkBossDefeated();
      if (bossProgress > before) {
        _emit(GameEvent(GameEventType.confetti, 'Boss damage! ${currentBoss.name} is weakened.'));
      }
    }
    _commit();
    return true;
  }

  void _checkBossDefeated() {
    if (bossProgress >= 1.0 && !_s.defeatedBosses.contains(currentBoss.id)) {
      _s.defeatedBosses.add(currentBoss.id);
      _emit(GameEvent(GameEventType.boss, '🏆 BOSS DEFEATED: ${currentBoss.name}!\n\nYou earned ${currentBoss.xpReward} XP and ${currentBoss.coinReward} coins.'));
      addXp(currentBoss.xpReward, reason: 'Boss defeated');
      addCoins(currentBoss.coinReward, silent: true);
    }
  }

  // ---------------- Skills ----------------
  bool upgradeSkill(String id) {
    final idx = _s.skills.indexWhere((s) => s.id == id);
    if (idx < 0) return false;
    final s = _s.skills[idx];
    if (s.level >= s.maxLevel) return false;
    final cost = s.level * 100;
    if (_s.coins < cost) return false;
    spendCoins(cost);
    _s.skills[idx] = s.copyWith(level: s.level + 1);
    _emit(GameEvent(GameEventType.levelUp, '${s.name} upgraded to level ${s.level + 1}!'));
    _commit();
    return true;
  }

  // ---------------- Settings ----------------
  void setSettings(AppSettings s) {
    _s = GameState(
      profile: _s.profile,
      totalXp: _s.totalXp,
      coins: _s.coins,
      achievements: _s.achievements,
      skills: _s.skills,
      weightHistory: _s.weightHistory,
      dailyLogs: _s.dailyLogs,
      mealLogs: _s.mealLogs,
      chatHistory: _s.chatHistory,
      milestones: _s.milestones,
      claimedQuests: _s.claimedQuests,
      defeatedBosses: _s.defeatedBosses,
      favoriteFoodIds: _s.favoriteFoodIds,
      recentFoodIds: _s.recentFoodIds,
      settings: s,
      createdAt: _s.createdAt,
      totalPushups: _s.totalPushups,
      totalDistanceKm: _s.totalDistanceKm,
      weightLogCount: _s.weightLogCount,
    );
    NotificationService.instance.configure(s);
    _commit();
  }

  /// Wipes progress but keeps the player profile.
  void resetGame() {
    _s = GameState(profile: profile);
    _repo.clear();
    notifyListeners();
    _pushWidgetData();
    _scheduleReminders();
  }

  void updateProfile(PlayerProfile p) {
    _s = GameState(
      profile: p,
      totalXp: _s.totalXp,
      coins: _s.coins,
      achievements: _s.achievements,
      skills: _s.skills,
      weightHistory: _s.weightHistory,
      dailyLogs: _s.dailyLogs,
      mealLogs: _s.mealLogs,
      chatHistory: _s.chatHistory,
      milestones: RpgEngine.transformMilestones(_s.milestones, p),
      claimedQuests: _s.claimedQuests,
      defeatedBosses: _s.defeatedBosses,
      favoriteFoodIds: _s.favoriteFoodIds,
      recentFoodIds: _s.recentFoodIds,
      settings: _s.settings,
      createdAt: _s.createdAt,
      totalPushups: _s.totalPushups,
      totalDistanceKm: _s.totalDistanceKm,
      weightLogCount: _s.weightLogCount,
    );
    _commit();
  }

  // ---------------- Coach ----------------
  Future<CoachReply> coachSend(String message) async {
    _s.chatHistory.add(ChatMessage(role: 'user', text: message, time: DateTime.now()));
    _commit();
    final ctx = CoachContext(
      profile: profile,
      currentWeight: currentWeight,
      todayLog: todayLog(),
      calorieGoal: calorieGoal,
      proteinGoal: proteinGoal,
      waterGoalMl: waterGoalMl,
      todayQuests: todayQuests,
      weightHistory: _s.weightHistory,
      streak: streakDays.toInt(),
      history: _s.chatHistory,
    );
    final reply = await coach.reply(ctx, message);
    _s.chatHistory.add(ChatMessage(role: 'coach', text: reply.text, time: DateTime.now()));
    if (reply.foodsToLog.isNotEmpty) {
      logFoods(reply.foodsToLog, method: 'coach');
    }
    if (reply.celebration) _emit(GameEvent(GameEventType.celebration, 'Coach: great job!'));
    if (reply.encouragement) _emit(GameEvent(GameEventType.celebration, 'Coach: stay strong!'));
    _commit();
    return reply;
  }

  // ---------------- Achievements ----------------
  void checkAchievements() {
    final activeDays = _s.dailyLogs.values.map((d) => d.date).toList();
    final streak = RpgEngine.currentStreak(activeDays);
    final lostKg = profile.startWeightKg - currentWeight;
    final proteinDays = _s.dailyLogs.values.where((d) => d.proteinConsumed >= proteinGoal).length;
    final waterDays = _s.dailyLogs.values.where((d) => d.waterMl >= waterGoalMl).length;
    final noSodaDays = _s.dailyLogs.values.where((d) => !d.sugaryDrink && (d.loggedInToday || d.caloriesConsumed > 0)).length;

    for (var i = 0; i < _s.achievements.length; i++) {
      final a = _s.achievements[i];
      if (a.unlocked) continue;
      var met = false;
      switch (a.id) {
        case 'first_workout':
          met = _s.dailyLogs.values.any((d) => d.workoutDone);
        case 'streak_7':
          met = streak >= 7;
        case 'streak_30':
          met = streak >= 30;
        case 'lost_5kg':
          met = lostKg >= 5;
        case 'lost_10kg':
          met = lostKg >= 10;
        case 'walked_100km':
          met = _s.totalDistanceKm >= 100;
        case 'pushups_100':
          met = _s.totalPushups >= 100;
        case 'logged_meals_50':
          met = _s.mealLogs.length >= 50;
        case 'protein_30d':
          met = proteinDays >= 30;
        case 'water_100d':
          met = waterDays >= 100;
        case 'no_soda_50d':
          met = noSodaDays >= 50;
        case 'level_50':
          met = level >= 50;
        case 'level_100':
          met = level >= 100;
        case 'weight_logged_30':
          met = _s.weightLogCount >= 30;
      }
      if (met) {
        _s.achievements[i] = a.copyWith(unlocked: true, unlockedAt: DateTime.now());
        _emit(GameEvent(GameEventType.achievement, '🏆 Achievement unlocked: ${a.title}!\n\n${a.description}\n+${a.xp} XP', xp: a.xp));
        addXp(a.xp, reason: 'Achievement: ${a.title}');
      }
    }
  }

  // ---------------- Widget bridge ----------------
  void _pushWidgetData() {
    WidgetBridge.pushUpdate(
      level: level,
      xpInto: xpIntoLevel,
      xpNext: xpToNext,
      streak: streakDays.toInt(),
      currentWeight: currentWeight,
      goalWeight: profile.goalWeightKg,
      calories: todayLog().caloriesConsumed,
      calorieGoal: calorieGoal,
      protein: todayLog().proteinConsumed,
      proteinGoal: proteinGoal,
      water: todayLog().waterMl.toDouble(),
      waterGoal: waterGoalMl.toDouble(),
      steps: todayLog().steps.toDouble(),
      stepsGoal: 8000,
      workoutDone: todayLog().workoutDone,
      sleepHours: todayLog().sleepHours,
      completion: dailyScore / 100,
      title: title,
      rank: rank,
      boss: currentBoss.name,
      mood: todayLog().mood,
      energy: todayLog().energy,
    );
  }

  @override
  void dispose() {
    _events.close();
    super.dispose();
  }
}

/// Global singletons (lightweight DI without codegen).
class Di {
  Di._();
  static final GameController controller = GameController(GameState());
  static final GameRepo repo = GameRepo();
}

/// Riverpod access to the game controller.
final gameProvider = ChangeNotifierProvider<GameController>((ref) => Di.controller);
