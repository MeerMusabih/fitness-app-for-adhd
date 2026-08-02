import 'package:flutter/foundation.dart';

/// ---------- Profile & body ----------

class PlayerProfile {
  String name;
  int age;
  double heightCm;
  double startWeightKg;
  double goalWeightKg;
  String gender; // 'male' | 'female'
  String country;
  String level; // 'beginner'
  bool worksOutAtHome;
  double startWaistCm;
  double startChestCm;

  PlayerProfile({
    this.name = 'Champion',
    this.age = 20,
    this.heightCm = 178,
    this.startWeightKg = 110,
    this.goalWeightKg = 85,
    this.gender = 'male',
    this.country = 'Pakistan',
    this.level = 'beginner',
    this.worksOutAtHome = true,
    this.startWaistCm = 104,
    this.startChestCm = 112,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'heightCm': heightCm,
        'startWeightKg': startWeightKg,
        'goalWeightKg': goalWeightKg,
        'gender': gender,
        'country': country,
        'level': level,
        'worksOutAtHome': worksOutAtHome,
        'startWaistCm': startWaistCm,
        'startChestCm': startChestCm,
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> j) => PlayerProfile(
        name: j['name'] ?? 'Champion',
        age: (j['age'] ?? 20) as int,
        heightCm: (j['heightCm'] ?? 178).toDouble(),
        startWeightKg: (j['startWeightKg'] ?? 110).toDouble(),
        goalWeightKg: (j['goalWeightKg'] ?? 85).toDouble(),
        gender: j['gender'] ?? 'male',
        country: j['country'] ?? 'Pakistan',
        level: j['level'] ?? 'beginner',
        worksOutAtHome: j['worksOutAtHome'] ?? true,
        startWaistCm: (j['startWaistCm'] ?? 104).toDouble(),
        startChestCm: (j['startChestCm'] ?? 112).toDouble(),
      );

  PlayerProfile copyWith({
    String? name,
    int? age,
    double? heightCm,
    double? startWeightKg,
    double? goalWeightKg,
    String? gender,
    String? country,
    String? level,
    bool? worksOutAtHome,
    double? startWaistCm,
    double? startChestCm,
  }) =>
      PlayerProfile(
        name: name ?? this.name,
        age: age ?? this.age,
        heightCm: heightCm ?? this.heightCm,
        startWeightKg: startWeightKg ?? this.startWeightKg,
        goalWeightKg: goalWeightKg ?? this.goalWeightKg,
        gender: gender ?? this.gender,
        country: country ?? this.country,
        level: level ?? this.level,
        worksOutAtHome: worksOutAtHome ?? this.worksOutAtHome,
        startWaistCm: startWaistCm ?? this.startWaistCm,
        startChestCm: startChestCm ?? this.startChestCm,
      );
}

class WeightEntry {
  final DateTime date;
  final double kg;
  final double? waistCm;
  final double? chestCm;
  WeightEntry({required this.date, required this.kg, this.waistCm, this.chestCm});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'kg': kg,
        'waist': waistCm,
        'chest': chestCm,
      };

  factory WeightEntry.fromJson(Map<String, dynamic> j) => WeightEntry(
        date: DateTime.parse(j['date']),
        kg: (j['kg'] as num).toDouble(),
        waistCm: j['waist'] == null ? null : (j['waist'] as num).toDouble(),
        chestCm: j['chest'] == null ? null : (j['chest'] as num).toDouble(),
      );
}

/// ---------- Food & nutrition ----------

@immutable
class FoodItem {
  final String id;
  final String name;
  final double calories; // per 100 g (or per unit if unitItem)
  final double protein; // per 100 g
  final double carbs; // per 100 g
  final double fat; // per 100 g
  final String category; // 'pakistani' | 'fastfood' | 'street' | 'homemade' | 'usda'
  final List<String> aliases;
  final bool unitItem; // serving is "1 unit" rather than grams
  final double? unitWeightG; // weight of one unit

  const FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.category = 'pakistani',
    this.aliases = const [],
    this.unitItem = false,
    this.unitWeightG,
  });

  double get kjs => calories * 4.184;
}

@immutable
class LoggedFood {
  final String foodId;
  final String name;
  final double quantity; // grams or units
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  const LoggedFood({
    required this.foodId,
    required this.name,
    required this.quantity,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  Map<String, dynamic> toJson() => {
        'foodId': foodId,
        'name': name,
        'quantity': quantity,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };

  factory LoggedFood.fromJson(Map<String, dynamic> j) => LoggedFood(
        foodId: j['foodId'] ?? '',
        name: j['name'] ?? '',
        quantity: (j['quantity'] as num).toDouble(),
        calories: (j['calories'] as num).toDouble(),
        protein: (j['protein'] as num).toDouble(),
        carbs: (j['carbs'] as num).toDouble(),
        fat: (j['fat'] as num).toDouble(),
      );
}

@immutable
class MealLog {
  final DateTime time;
  final List<LoggedFood> foods;
  final String method; // voice | text | photo | barcode | recent | favorite | manual
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  const MealLog({
    required this.time,
    required this.foods,
    required this.method,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'foods': foods.map((f) => f.toJson()).toList(),
        'method': method,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };

  factory MealLog.fromJson(Map<String, dynamic> j) => MealLog(
        time: DateTime.parse(j['time']),
        foods: (j['foods'] as List)
            .map((e) => LoggedFood.fromJson(e as Map<String, dynamic>))
            .toList(),
        method: j['method'] ?? 'text',
        calories: (j['calories'] as num).toDouble(),
        protein: (j['protein'] as num).toDouble(),
        carbs: (j['carbs'] as num).toDouble(),
        fat: (j['fat'] as num).toDouble(),
      );
}

/// ---------- Daily tracking ----------

class DailyLog {
  final DateTime date;
  int waterMl;
  int steps;
  double sleepHours;
  int workoutMinutes;
  bool workoutDone;
  double caloriesConsumed;
  double proteinConsumed;
  int mood; // 1..5
  int energy; // 1..5
  int stress; // 1..5
  bool sugaryDrink;
  bool vegetables;
  bool stretchDone;
  bool meditateDone;
  bool readDone;
  bool photoTaken;
  bool loggedInToday;

  DailyLog({
    required this.date,
    this.waterMl = 0,
    this.steps = 0,
    this.sleepHours = 0,
    this.workoutMinutes = 0,
    this.workoutDone = false,
    this.caloriesConsumed = 0,
    this.proteinConsumed = 0,
    this.mood = 3,
    this.energy = 3,
    this.stress = 3,
    this.sugaryDrink = false,
    this.vegetables = false,
    this.stretchDone = false,
    this.meditateDone = false,
    this.readDone = false,
    this.photoTaken = false,
    this.loggedInToday = false,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'waterMl': waterMl,
        'steps': steps,
        'sleepHours': sleepHours,
        'workoutMinutes': workoutMinutes,
        'workoutDone': workoutDone,
        'caloriesConsumed': caloriesConsumed,
        'proteinConsumed': proteinConsumed,
        'mood': mood,
        'energy': energy,
        'stress': stress,
        'sugaryDrink': sugaryDrink,
        'vegetables': vegetables,
        'stretchDone': stretchDone,
        'meditateDone': meditateDone,
        'readDone': readDone,
        'photoTaken': photoTaken,
        'loggedInToday': loggedInToday,
      };

  factory DailyLog.fromJson(Map<String, dynamic> j) => DailyLog(
        date: DateTime.parse(j['date']),
        waterMl: (j['waterMl'] ?? 0) as int,
        steps: (j['steps'] ?? 0) as int,
        sleepHours: (j['sleepHours'] ?? 0).toDouble(),
        workoutMinutes: (j['workoutMinutes'] ?? 0) as int,
        workoutDone: j['workoutDone'] ?? false,
        caloriesConsumed: (j['caloriesConsumed'] ?? 0).toDouble(),
        proteinConsumed: (j['proteinConsumed'] ?? 0).toDouble(),
        mood: (j['mood'] ?? 3) as int,
        energy: (j['energy'] ?? 3) as int,
        stress: (j['stress'] ?? 3) as int,
        sugaryDrink: j['sugaryDrink'] ?? false,
        vegetables: j['vegetables'] ?? false,
        stretchDone: j['stretchDone'] ?? false,
        meditateDone: j['meditateDone'] ?? false,
        readDone: j['readDone'] ?? false,
        photoTaken: j['photoTaken'] ?? false,
        loggedInToday: j['loggedInToday'] ?? false,
      );
}

/// ---------- Quests & missions ----------

enum QuestStatus { active, done, claimed, failed }

enum QuestKind { daily, weekly, boss }

@immutable
class Quest {
  final String id;
  final QuestKind kind;
  final String missionId; // maps to MissionDef
  final String title;
  final String subtitle;
  final String icon;
  final int xp;
  final int coins;
  final double target; // progress numerator target
  final double progress; // current progress (already credited)
  final QuestStatus status;
  final DateTime day;

  const Quest({
    required this.id,
    required this.kind,
    required this.missionId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.xp,
    required this.coins,
    required this.target,
    this.progress = 0,
    this.status = QuestStatus.active,
    required this.day,
  });

  bool get isComplete => progress >= target;

  Quest copyWith({double? progress, QuestStatus? status, double? target}) => Quest(
        id: id,
        kind: kind,
        missionId: missionId,
        title: title,
        subtitle: subtitle,
        icon: icon,
        xp: xp,
        coins: coins,
        target: target ?? this.target,
        progress: progress ?? this.progress,
        status: status ?? this.status,
        day: day,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'missionId': missionId,
        'title': title,
        'subtitle': subtitle,
        'icon': icon,
        'xp': xp,
        'coins': coins,
        'target': target,
        'progress': progress,
        'status': status.name,
        'day': day.toIso8601String(),
      };

  factory Quest.fromJson(Map<String, dynamic> j) => Quest(
        id: j['id'],
        kind: QuestKind.values.byName(j['kind']),
        missionId: j['missionId'],
        title: j['title'],
        subtitle: j['subtitle'],
        icon: j['icon'],
        xp: (j['xp'] as num).toInt(),
        coins: (j['coins'] as num).toInt(),
        target: (j['target'] as num).toDouble(),
        progress: (j['progress'] as num?)?.toDouble() ?? 0,
        status: QuestStatus.values.byName(j['status'] ?? 'active'),
        day: DateTime.parse(j['day']),
      );
}

/// ---------- Bosses ----------

@immutable
class Boss {
  final String id;
  final String name;
  final String icon;
  final String description;
  final double maxHp;
  final int xpReward;
  final int coinReward;
  final List<String> missions; // missions that damage this boss
  final DateTime start;
  final DateTime end;

  const Boss({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.maxHp,
    required this.xpReward,
    required this.coinReward,
    required this.missions,
    required this.start,
    required this.end,
  });
}

/// ---------- Achievements ----------

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int xp;
  bool unlocked;
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.xp,
    this.unlocked = false,
    this.unlockedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'icon': icon,
        'xp': xp,
        'unlocked': unlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  factory Achievement.fromJson(Map<String, dynamic> j) => Achievement(
        id: j['id'],
        title: j['title'],
        description: j['description'],
        icon: j['icon'],
        xp: (j['xp'] as num).toInt(),
        unlocked: j['unlocked'] ?? false,
        unlockedAt: j['unlockedAt'] == null ? null : DateTime.parse(j['unlockedAt']),
      );

  Achievement copyWith({bool? unlocked, DateTime? unlockedAt}) => Achievement(
        id: id,
        title: title,
        description: description,
        icon: icon,
        xp: xp,
        unlocked: unlocked ?? this.unlocked,
        unlockedAt: unlockedAt ?? this.unlockedAt,
      );
}

/// ---------- Coins & skills ----------

class Skill {
  final String id;
  final String name;
  final String icon;
  final String description;
  int level;
  final int maxLevel;

  Skill({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    this.level = 1,
    this.maxLevel = 5,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'description': description,
        'level': level,
        'maxLevel': maxLevel,
      };

  factory Skill.fromJson(Map<String, dynamic> j) => Skill(
        id: j['id'],
        name: j['name'],
        icon: j['icon'],
        description: j['description'],
        level: (j['level'] as num?)?.toInt() ?? 1,
        maxLevel: (j['maxLevel'] as num?)?.toInt() ?? 5,
      );

  Skill copyWith({int? level}) => Skill(
        id: id,
        name: name,
        icon: icon,
        description: description,
        level: level ?? this.level,
        maxLevel: maxLevel,
      );
}

/// ---------- Future You milestones ----------

@immutable
class FutureYouMilestone {
  final double targetWeight;
  final double startWeight;
  final String message;
  final bool reached;
  final DateTime? reachedAt;

  const FutureYouMilestone({
    required this.targetWeight,
    required this.startWeight,
    required this.message,
    this.reached = false,
    this.reachedAt,
  });

  Map<String, dynamic> toJson() => {
        'targetWeight': targetWeight,
        'startWeight': startWeight,
        'message': message,
        'reached': reached,
        'reachedAt': reachedAt?.toIso8601String(),
      };

  factory FutureYouMilestone.fromJson(Map<String, dynamic> j) => FutureYouMilestone(
        targetWeight: (j['targetWeight'] as num).toDouble(),
        startWeight: (j['startWeight'] as num).toDouble(),
        message: j['message'],
        reached: j['reached'] ?? false,
        reachedAt: j['reachedAt'] == null ? null : DateTime.parse(j['reachedAt']),
      );

  FutureYouMilestone copyWith({bool? reached, DateTime? reachedAt}) => FutureYouMilestone(
        targetWeight: targetWeight,
        startWeight: startWeight,
        message: message,
        reached: reached ?? this.reached,
        reachedAt: reachedAt ?? this.reachedAt,
      );
}

/// ---------- Chat ----------

@immutable
class ChatMessage {
  final String role; // user | coach
  final String text;
  final DateTime time;
  const ChatMessage({required this.role, required this.text, required this.time});

  Map<String, dynamic> toJson() => {'role': role, 'text': text, 'time': time.toIso8601String()};
  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        role: j['role'],
        text: j['text'],
        time: DateTime.parse(j['time']),
      );
}

/// ---------- Settings ----------

@immutable
class AppSettings {
  final String widgetPersonality; // warrior | coach | minimal | anime | scifi | retro
  final bool dopamineMode;
  final bool haptics;
  final bool sounds;
  final bool notificationsEnabled;
  final int waterReminderHour;
  final int waterReminderMinute;
  final int workoutReminderHour;
  final int workoutReminderMinute;
  final int sleepReminderHour;
  final int sleepReminderMinute;
  final String avatarTheme; // blue | gold | green | purple
  final String petIcon;
  final String background; // night | gym | sunset | galaxy

  const AppSettings({
    this.widgetPersonality = 'warrior',
    this.dopamineMode = true,
    this.haptics = true,
    this.sounds = true,
    this.notificationsEnabled = true,
    this.waterReminderHour = 10,
    this.waterReminderMinute = 0,
    this.workoutReminderHour = 18,
    this.workoutReminderMinute = 0,
    this.sleepReminderHour = 22,
    this.sleepReminderMinute = 30,
    this.avatarTheme = 'blue',
    this.petIcon = '🐕',
    this.background = 'night',
  });

  AppSettings copyWith({
    String? widgetPersonality,
    bool? dopamineMode,
    bool? haptics,
    bool? sounds,
    bool? notificationsEnabled,
    int? waterReminderHour,
    int? waterReminderMinute,
    int? workoutReminderHour,
    int? workoutReminderMinute,
    int? sleepReminderHour,
    int? sleepReminderMinute,
    String? avatarTheme,
    String? petIcon,
    String? background,
  }) =>
      AppSettings(
        widgetPersonality: widgetPersonality ?? this.widgetPersonality,
        dopamineMode: dopamineMode ?? this.dopamineMode,
        haptics: haptics ?? this.haptics,
        sounds: sounds ?? this.sounds,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        waterReminderHour: waterReminderHour ?? this.waterReminderHour,
        waterReminderMinute: waterReminderMinute ?? this.waterReminderMinute,
        workoutReminderHour: workoutReminderHour ?? this.workoutReminderHour,
        workoutReminderMinute: workoutReminderMinute ?? this.workoutReminderMinute,
        sleepReminderHour: sleepReminderHour ?? this.sleepReminderHour,
        sleepReminderMinute: sleepReminderMinute ?? this.sleepReminderMinute,
        avatarTheme: avatarTheme ?? this.avatarTheme,
        petIcon: petIcon ?? this.petIcon,
        background: background ?? this.background,
      );

  Map<String, dynamic> toJson() => {
        'widgetPersonality': widgetPersonality,
        'dopamineMode': dopamineMode,
        'haptics': haptics,
        'sounds': sounds,
        'notificationsEnabled': notificationsEnabled,
        'waterReminderHour': waterReminderHour,
        'waterReminderMinute': waterReminderMinute,
        'workoutReminderHour': workoutReminderHour,
        'workoutReminderMinute': workoutReminderMinute,
        'sleepReminderHour': sleepReminderHour,
        'sleepReminderMinute': sleepReminderMinute,
        'avatarTheme': avatarTheme,
        'petIcon': petIcon,
        'background': background,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        widgetPersonality: j['widgetPersonality'] ?? 'warrior',
        dopamineMode: j['dopamineMode'] ?? true,
        haptics: j['haptics'] ?? true,
        sounds: j['sounds'] ?? true,
        notificationsEnabled: j['notificationsEnabled'] ?? true,
        waterReminderHour: (j['waterReminderHour'] ?? 10) as int,
        waterReminderMinute: (j['waterReminderMinute'] ?? 0) as int,
        workoutReminderHour: (j['workoutReminderHour'] ?? 18) as int,
        workoutReminderMinute: (j['workoutReminderMinute'] ?? 0) as int,
        sleepReminderHour: (j['sleepReminderHour'] ?? 22) as int,
        sleepReminderMinute: (j['sleepReminderMinute'] ?? 30) as int,
        avatarTheme: j['avatarTheme'] ?? 'blue',
        petIcon: j['petIcon'] ?? '🐕',
        background: j['background'] ?? 'night',
      );
}

/// ---------- Misc helpers ----------

String stripDay(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

double round2(double v) => (v * 100).roundToDouble() / 100;
