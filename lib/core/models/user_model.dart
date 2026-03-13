/// User model — persisted in Firestore at users/{uid}
class UserModel {
  final String uid;
  final String username;
  final String avatarUrl;
  final int coins;
  final int totalXp;
  final Map<String, int> highScores;
  final List<String> unlockedSkins;
  final int loginStreak;
  final DateTime lastLogin;

  UserModel({
    required this.uid,
    required this.username,
    this.avatarUrl = '',
    this.coins = 0,
    this.totalXp = 0,
    this.highScores = const {},
    this.unlockedSkins = const [],
    this.loginStreak = 0,
    DateTime? lastLogin,
  }) : lastLogin = lastLogin ?? DateTime.now();

  /// Demo user for pre-Firebase development
  factory UserModel.demo() {
    return UserModel(
      uid: 'demo_user',
      username: 'Player_1',
      avatarUrl: '',
      coins: 1250,
      totalXp: 4800,
      highScores: {
        'beat_crash': 12400,
        'snack_stackers': 850,
        'micro_heist': 15,
        'glow_merge': 2048,
        'flick_royale': 9,
      },
      unlockedSkins: ['default', 'neon_purple'],
      loginStreak: 5,
      lastLogin: DateTime.now(),
    );
  }

  UserModel copyWith({
    String? uid,
    String? username,
    String? avatarUrl,
    int? coins,
    int? totalXp,
    Map<String, int>? highScores,
    List<String>? unlockedSkins,
    int? loginStreak,
    DateTime? lastLogin,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coins: coins ?? this.coins,
      totalXp: totalXp ?? this.totalXp,
      highScores: highScores ?? this.highScores,
      unlockedSkins: unlockedSkins ?? this.unlockedSkins,
      loginStreak: loginStreak ?? this.loginStreak,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'username': username,
        'avatarUrl': avatarUrl,
        'coins': coins,
        'totalXp': totalXp,
        'highScores': highScores,
        'unlockedSkins': unlockedSkins,
        'loginStreak': loginStreak,
        'lastLogin': lastLogin.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String? ?? '',
      coins: json['coins'] as int? ?? 0,
      totalXp: json['totalXp'] as int? ?? 0,
      highScores: Map<String, int>.from(json['highScores'] ?? {}),
      unlockedSkins: List<String>.from(json['unlockedSkins'] ?? []),
      loginStreak: json['loginStreak'] as int? ?? 0,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : DateTime.now(),
    );
  }
}
