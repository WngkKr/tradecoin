class NewsModel {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String source;
  final String sourceUrl;
  final DateTime publishedAt;
  final String category;
  final List<String> tags;
  final MarketImpact marketImpact;
  final SentimentAnalysis sentimentAnalysis;
  final String? imageUrl;
  final int readCount;
  final bool isBreaking;

  const NewsModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.source,
    required this.sourceUrl,
    required this.publishedAt,
    required this.category,
    required this.tags,
    required this.marketImpact,
    required this.sentimentAnalysis,
    this.imageUrl,
    this.readCount = 0,
    this.isBreaking = false,
  });

  NewsModel copyWith({
    String? id,
    String? title,
    String? summary,
    String? content,
    String? source,
    String? sourceUrl,
    DateTime? publishedAt,
    String? category,
    List<String>? tags,
    MarketImpact? marketImpact,
    SentimentAnalysis? sentimentAnalysis,
    String? imageUrl,
    int? readCount,
    bool? isBreaking,
  }) {
    return NewsModel(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      source: source ?? this.source,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      marketImpact: marketImpact ?? this.marketImpact,
      sentimentAnalysis: sentimentAnalysis ?? this.sentimentAnalysis,
      imageUrl: imageUrl ?? this.imageUrl,
      readCount: readCount ?? this.readCount,
      isBreaking: isBreaking ?? this.isBreaking,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'content': content,
      'source': source,
      'sourceUrl': sourceUrl,
      'publishedAt': publishedAt.toIso8601String(),
      'category': category,
      'tags': tags,
      'marketImpact': marketImpact.toJson(),
      'sentimentAnalysis': sentimentAnalysis.toJson(),
      'imageUrl': imageUrl,
      'readCount': readCount,
      'isBreaking': isBreaking,
    };
  }

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      content: json['content'] ?? '',
      source: json['source'] ?? '',
      sourceUrl: json['sourceUrl'] ?? '',
      publishedAt: DateTime.parse(json['publishedAt']),
      category: json['category'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      marketImpact: MarketImpact.fromJson(json['marketImpact'] ?? {}),
      sentimentAnalysis: SentimentAnalysis.fromJson(json['sentimentAnalysis'] ?? {}),
      imageUrl: json['imageUrl'],
      readCount: json['readCount'] ?? 0,
      isBreaking: json['isBreaking'] ?? false,
    );
  }
}

class MarketImpact {
  final MarketImpactLevel level;
  final String description;
  final List<String> affectedCoins;
  final double priceImpactScore; // -1.0 to 1.0
  final String timeframe; // 'immediate', 'short-term', 'long-term'

  const MarketImpact({
    required this.level,
    required this.description,
    required this.affectedCoins,
    required this.priceImpactScore,
    required this.timeframe,
  });

  Map<String, dynamic> toJson() {
    return {
      'level': level.toString(),
      'description': description,
      'affectedCoins': affectedCoins,
      'priceImpactScore': priceImpactScore,
      'timeframe': timeframe,
    };
  }

  factory MarketImpact.fromJson(Map<String, dynamic> json) {
    return MarketImpact(
      level: MarketImpactLevel.values.firstWhere(
        (level) => level.toString() == json['level'],
        orElse: () => MarketImpactLevel.neutral,
      ),
      description: json['description'] ?? '',
      affectedCoins: List<String>.from(json['affectedCoins'] ?? []),
      priceImpactScore: (json['priceImpactScore'] ?? 0.0).toDouble(),
      timeframe: json['timeframe'] ?? 'short-term',
    );
  }
}

class SentimentAnalysis {
  final SentimentType sentiment;
  final double confidenceScore; // 0.0 to 1.0
  final String reasonsPositive;
  final String reasonsNegative;
  final Map<String, double> emotionScores; // fear, greed, uncertainty, etc.

  const SentimentAnalysis({
    required this.sentiment,
    required this.confidenceScore,
    required this.reasonsPositive,
    required this.reasonsNegative,
    required this.emotionScores,
  });

  Map<String, dynamic> toJson() {
    return {
      'sentiment': sentiment.toString(),
      'confidenceScore': confidenceScore,
      'reasonsPositive': reasonsPositive,
      'reasonsNegative': reasonsNegative,
      'emotionScores': emotionScores,
    };
  }

  factory SentimentAnalysis.fromJson(Map<String, dynamic> json) {
    return SentimentAnalysis(
      sentiment: SentimentType.values.firstWhere(
        (sentiment) => sentiment.toString() == json['sentiment'],
        orElse: () => SentimentType.neutral,
      ),
      confidenceScore: (json['confidenceScore'] ?? 0.0).toDouble(),
      reasonsPositive: json['reasonsPositive'] ?? '',
      reasonsNegative: json['reasonsNegative'] ?? '',
      emotionScores: Map<String, double>.from(json['emotionScores'] ?? {}),
    );
  }
}

enum MarketImpactLevel {
  veryNegative,
  negative,
  neutral,
  positive,
  veryPositive,
}

enum SentimentType {
  veryBearish,
  bearish,
  neutral,
  bullish,
  veryBullish,
}

class NewsCategory {
  static const String bitcoin = 'Bitcoin';
  static const String ethereum = 'Ethereum';
  static const String defi = 'DeFi';
  static const String nft = 'NFT';
  static const String metaverse = 'Metaverse';
  static const String regulation = 'Regulation';
  static const String adoption = 'Adoption';
  static const String technology = 'Technology';
  static const String mining = 'Mining';
  static const String trading = 'Trading';
  static const String altcoins = 'Altcoins';
  static const String market = 'Market';

  static const List<String> all = [
    bitcoin,
    ethereum,
    defi,
    nft,
    metaverse,
    regulation,
    adoption,
    technology,
    mining,
    trading,
    altcoins,
    market,
  ];
}

class NewsSource {
  static const String coindesk = 'CoinDesk';
  static const String cointelegraph = 'Cointelegraph';
  static const String coinreaders = 'CoinReaders';
  static const String decenter = 'Decenter';
  static const String tokenpost = 'TokenPost';
  static const String cryptonews = 'CryptoNews';
  static const String theblock = 'The Block';

  static const List<String> korean = [
    coinreaders,
    decenter,
    tokenpost,
  ];

  static const List<String> international = [
    coindesk,
    cointelegraph,
    cryptonews,
    theblock,
  ];
}