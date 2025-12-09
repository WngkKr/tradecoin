class TradeCoinUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserSubscription subscription;
  final UserProfile profile;
  final UserSettings? settings;
  final UserStats? stats;
  final bool isActive;
  final int version;

  const TradeCoinUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.updatedAt,
    required this.subscription,
    required this.profile,
    this.settings,
    this.stats,
    this.isActive = true,
    this.version = 1,
  });
  
  factory TradeCoinUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return TradeCoinUser(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      subscription: UserSubscription.fromMap(data['subscription'] ?? {}),
      profile: UserProfile.fromMap(data['profile'] ?? {}),
      settings: data['settings'] != null ? UserSettings.fromMap(data['settings']) : null,
      stats: data['stats'] != null ? UserStats.fromMap(data['stats']) : null,
      isActive: data['isActive'] ?? true,
      version: data['version'] ?? 1,
    );
  }

  factory TradeCoinUser.fromJson(Map<String, dynamic> json) {
    return TradeCoinUser(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      photoURL: json['photoURL'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      subscription: UserSubscription.fromMap(json['subscription'] ?? {}),
      profile: UserProfile.fromMap(json['profile'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'subscription': subscription.toMap(),
      'profile': profile.toMap(),
      'settings': settings?.toMap(),
      'stats': stats?.toMap(),
      'isActive': isActive,
      'version': version,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'subscription': subscription.toMap(),
      'profile': profile.toMap(),
    };
  }

  // Firebase용 toMap 메소드 (toFirestore와 동일)
  Map<String, dynamic> toMap() {
    return toFirestore();
  }

  // copyWith 메소드 추가
  TradeCoinUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserSubscription? subscription,
    UserProfile? profile,
    UserSettings? settings,
    UserStats? stats,
    bool? isActive,
    int? version,
  }) {
    return TradeCoinUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subscription: subscription ?? this.subscription,
      profile: profile ?? this.profile,
      settings: settings ?? this.settings,
      stats: stats ?? this.stats,
      isActive: isActive ?? this.isActive,
      version: version ?? this.version,
    );
  }
}

class UserSubscription {
  final String tier;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool autoRenew;
  
  const UserSubscription({
    required this.tier,
    required this.status,
    this.startDate,
    this.endDate,
    required this.autoRenew,
  });
  
  factory UserSubscription.fromMap(Map<String, dynamic> map) {
    return UserSubscription(
      tier: map['tier'] ?? 'free',
      status: map['status'] ?? 'active',
      startDate: map['startDate']?.toDate(),
      endDate: map['endDate']?.toDate(),
      autoRenew: map['autoRenew'] ?? false,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'tier': tier,
      'status': status,
      'startDate': startDate,
      'endDate': endDate,
      'autoRenew': autoRenew,
    };
  }
}

class UserProfile {
  final String experienceLevel;
  final String riskTolerance;
  final List<String> preferredCoins;
  final String? investmentGoal;
  final double? monthlyBudget;

  const UserProfile({
    required this.experienceLevel,
    required this.riskTolerance,
    required this.preferredCoins,
    this.investmentGoal,
    this.monthlyBudget,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      experienceLevel: map['experienceLevel'] ?? 'beginner',
      riskTolerance: map['riskTolerance'] ?? 'conservative',
      preferredCoins: List<String>.from(map['preferredCoins'] ?? []),
      investmentGoal: map['investmentGoal'],
      monthlyBudget: map['monthlyBudget']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'experienceLevel': experienceLevel,
      'riskTolerance': riskTolerance,
      'preferredCoins': preferredCoins,
      'investmentGoal': investmentGoal,
      'monthlyBudget': monthlyBudget,
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }
}

class UserSettings {
  final UserNotificationSettings notifications;
  final UserTradingSettings trading;

  const UserSettings({
    required this.notifications,
    required this.trading,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      notifications: UserNotificationSettings.fromMap(map['notifications'] ?? {}),
      trading: UserTradingSettings.fromMap(map['trading'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notifications': notifications.toMap(),
      'trading': trading.toMap(),
    };
  }
}

class UserNotificationSettings {
  final bool push;
  final bool email;
  final bool sms;
  final int signalThreshold;

  const UserNotificationSettings({
    required this.push,
    required this.email,
    required this.sms,
    required this.signalThreshold,
  });

  factory UserNotificationSettings.fromMap(Map<String, dynamic> map) {
    return UserNotificationSettings(
      push: map['push'] ?? true,
      email: map['email'] ?? true,
      sms: map['sms'] ?? false,
      signalThreshold: map['signalThreshold'] ?? 75,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'push': push,
      'email': email,
      'sms': sms,
      'signalThreshold': signalThreshold,
    };
  }
}

class UserTradingSettings {
  final bool autoTrading;
  final int maxPositions;
  final int maxLeverage;
  final double stopLoss;
  final double takeProfit;

  const UserTradingSettings({
    required this.autoTrading,
    required this.maxPositions,
    required this.maxLeverage,
    required this.stopLoss,
    required this.takeProfit,
  });

  factory UserTradingSettings.fromMap(Map<String, dynamic> map) {
    return UserTradingSettings(
      autoTrading: map['autoTrading'] ?? false,
      maxPositions: map['maxPositions'] ?? 2,
      maxLeverage: map['maxLeverage'] ?? 5,
      stopLoss: map['stopLoss']?.toDouble() ?? 3.0,
      takeProfit: map['takeProfit']?.toDouble() ?? 10.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'autoTrading': autoTrading,
      'maxPositions': maxPositions,
      'maxLeverage': maxLeverage,
      'stopLoss': stopLoss,
      'takeProfit': takeProfit,
    };
  }
}

class UserStats {
  final int signalsUsed;
  final int tradesExecuted;
  final double totalPnL;
  final double winRate;
  final DateTime? lastLogin;

  const UserStats({
    required this.signalsUsed,
    required this.tradesExecuted,
    required this.totalPnL,
    required this.winRate,
    this.lastLogin,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      signalsUsed: map['signalsUsed'] ?? 0,
      tradesExecuted: map['tradesExecuted'] ?? 0,
      totalPnL: map['totalPnL']?.toDouble() ?? 0.0,
      winRate: map['winRate']?.toDouble() ?? 0.0,
      lastLogin: map['lastLogin']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'signalsUsed': signalsUsed,
      'tradesExecuted': tradesExecuted,
      'totalPnL': totalPnL,
      'winRate': winRate,
      'lastLogin': lastLogin,
    };
  }
}