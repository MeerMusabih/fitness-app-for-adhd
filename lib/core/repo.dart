import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/models.dart';
import '../core/rpg.dart';

/// Full serializable game state (single JSON blob in SharedPreferences).
class GameState {
  PlayerProfile profile;
  int totalXp;
  int coins;
  List<Achievement> achievements;
  List<Skill> skills;
  List<WeightEntry> weightHistory;
  Map<String, DailyLog> dailyLogs; // key = 'yyyy-MM-dd'
  List<MealLog> mealLogs;
  List<ChatMessage> chatHistory;
  List<FutureYouMilestone> milestones;
  Set<String> claimedQuests;
  Set<String> defeatedBosses;
  Set<String> favoriteFoodIds;
  List<String> recentFoodIds;
  AppSettings settings;
  DateTime createdAt;
  double totalPushups;
  double totalDistanceKm;
  int weightLogCount;

  GameState({
    PlayerProfile? profile,
    this.totalXp = 0,
    this.coins = 0,
    List<Achievement>? achievements,
    List<Skill>? skills,
    List<WeightEntry>? weightHistory,
    Map<String, DailyLog>? dailyLogs,
    List<MealLog>? mealLogs,
    List<ChatMessage>? chatHistory,
    List<FutureYouMilestone>? milestones,
    Set<String>? claimedQuests,
    Set<String>? defeatedBosses,
    Set<String>? favoriteFoodIds,
    List<String>? recentFoodIds,
    AppSettings? settings,
    DateTime? createdAt,
    this.totalPushups = 0,
    this.totalDistanceKm = 0,
    this.weightLogCount = 0,
  })  : profile = profile ?? PlayerProfile(),
        achievements = achievements ?? RpgEngine.defaultAchievements(),
        skills = skills ?? RpgEngine.defaultSkills(),
        weightHistory = weightHistory ?? [],
        dailyLogs = dailyLogs ?? {},
        mealLogs = mealLogs ?? [],
        chatHistory = chatHistory ?? [],
        milestones = milestones ?? _defaultMilestones(profile ?? PlayerProfile()),
        claimedQuests = claimedQuests ?? {},
        defeatedBosses = defeatedBosses ?? {},
        favoriteFoodIds = favoriteFoodIds ?? {},
        recentFoodIds = recentFoodIds ?? [],
        settings = settings ?? const AppSettings(),
        createdAt = createdAt ?? DateTime.now();

  static List<FutureYouMilestone> _defaultMilestones(PlayerProfile p) {
    final out = <FutureYouMilestone>[];
    var target = (p.startWeightKg - 5).round();
    while (target >= p.goalWeightKg) {
      out.add(FutureYouMilestone(
        targetWeight: target.toDouble(),
        startWeight: p.startWeightKg,
        message: 'Hey ${p.name}. I\'m you, at ${target}kg. I know the road felt long — '
            'but look what you already built. Every glass of water, every walk, every '
            'meal you logged brought you here. Keep going. The version at ${(target - 5).clamp(p.goalWeightKg, 9999)}kg is even stronger.',
      ));
      target -= 5;
    }
    return out;
  }

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'totalXp': totalXp,
        'coins': coins,
        'achievements': achievements.map((a) => a.toJson()).toList(),
        'skills': skills.map((s) => s.toJson()).toList(),
        'weightHistory': weightHistory.map((w) => w.toJson()).toList(),
        'dailyLogs': dailyLogs.map((k, v) => MapEntry(k, v.toJson())),
        'mealLogs': mealLogs.map((m) => m.toJson()).toList(),
        'chatHistory': chatHistory.map((c) => c.toJson()).toList(),
        'milestones': milestones.map((m) => m.toJson()).toList(),
        'claimedQuests': claimedQuests.toList(),
        'defeatedBosses': defeatedBosses.toList(),
        'favoriteFoodIds': favoriteFoodIds.toList(),
        'recentFoodIds': recentFoodIds,
        'settings': settings.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'totalPushups': totalPushups,
        'totalDistanceKm': totalDistanceKm,
        'weightLogCount': weightLogCount,
      };

  factory GameState.fromJson(Map<String, dynamic> j) => GameState(
        profile: PlayerProfile.fromJson(j['profile'] as Map<String, dynamic>),
        totalXp: (j['totalXp'] ?? 0) as int,
        coins: (j['coins'] ?? 0) as int,
        achievements: (j['achievements'] as List)
            .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
            .toList(),
        skills: (j['skills'] as List)
            .map((e) => Skill.fromJson(e as Map<String, dynamic>))
            .toList(),
        weightHistory: (j['weightHistory'] as List)
            .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        dailyLogs: (j['dailyLogs'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, DailyLog.fromJson(v as Map<String, dynamic>))),
        mealLogs: (j['mealLogs'] as List)
            .map((e) => MealLog.fromJson(e as Map<String, dynamic>))
            .toList(),
        chatHistory: (j['chatHistory'] as List)
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
        milestones: (j['milestones'] as List)
            .map((e) => FutureYouMilestone.fromJson(e as Map<String, dynamic>))
            .toList(),
        claimedQuests: (j['claimedQuests'] as List).cast<String>().toSet(),
        defeatedBosses: (j['defeatedBosses'] as List).cast<String>().toSet(),
        favoriteFoodIds: (j['favoriteFoodIds'] as List).cast<String>().toSet(),
        recentFoodIds: (j['recentFoodIds'] as List).cast<String>(),
        settings: AppSettings.fromJson(j['settings'] as Map<String, dynamic>),
        createdAt: DateTime.parse(j['createdAt']),
        totalPushups: (j['totalPushups'] ?? 0).toDouble(),
        totalDistanceKm: (j['totalDistanceKm'] ?? 0).toDouble(),
        weightLogCount: (j['weightLogCount'] ?? 0) as int,
      );
}

/// Lightweight JSON store backed by SharedPreferences.
class GameRepo {
  static const _key = 'reforge_game_state_v1';

  Future<GameState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return GameState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(GameState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
