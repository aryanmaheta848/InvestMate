import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invest_mate/models/stock_model.dart';

class NewsModel {
  final String id;
  final String title;
  final String description;
  final String content;
  final String source;
  final String? author;
  final String url;
  final String? imageUrl;
  final DateTime publishedAt;
  final List<String> symbols; // Associated stock symbols
  final SentimentType sentiment;
  final double sentimentScore; // -1 to 1
  final List<String> tags;
  final int viewCount;
  final DateTime createdAt;

  NewsModel({
    required this.id,
    required this.title,
    required this.description,
    this.content = '',
    required this.source,
    this.author,
    required this.url,
    this.imageUrl,
    required this.publishedAt,
    this.symbols = const [],
    this.sentiment = SentimentType.neutral,
    this.sentimentScore = 0.0,
    this.tags = const [],
    this.viewCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory NewsModel.fromNewsAPI(Map<String, dynamic> data) {
    return NewsModel(
      id: data['url']?.hashCode.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      content: data['content'] ?? '',
      source: data['source']?['name'] ?? '',
      author: data['author'],
      url: data['url'] ?? '',
      imageUrl: data['urlToImage'],
      publishedAt: DateTime.tryParse(data['publishedAt'] ?? '') ?? DateTime.now(),
    );
  }

  factory NewsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    return NewsModel(
      id: doc.id,
      title: data?['title'] ?? '',
      description: data?['description'] ?? '',
      content: data?['content'] ?? '',
      source: data?['source'] ?? '',
      author: data?['author'],
      url: data?['url'] ?? '',
      imageUrl: data?['imageUrl'],
      publishedAt: (data?['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      symbols: List<String>.from(data?['symbols'] ?? []),
      sentiment: SentimentType.values.firstWhere(
        (sentiment) => sentiment.toString() == 'SentimentType.${data?['sentiment']}',
        orElse: () => SentimentType.neutral,
      ),
      sentimentScore: (data?['sentimentScore'] ?? 0.0).toDouble(),
      tags: List<String>.from(data?['tags'] ?? []),
      viewCount: (data?['viewCount'] ?? 0).toInt(),
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'source': source,
      'author': author,
      'url': url,
      'imageUrl': imageUrl,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'symbols': symbols,
      'sentiment': sentiment.toString().split('.').last,
      'sentimentScore': sentimentScore,
      'tags': tags,
      'viewCount': viewCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Getters
  bool get isBullish => sentiment == SentimentType.bullish;
  bool get isBearish => sentiment == SentimentType.bearish;
  bool get isNeutral => sentiment == SentimentType.neutral;
  
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasContent => content.isNotEmpty;
  
  String get formattedPublishedAt {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get sentimentText {
    switch (sentiment) {
      case SentimentType.bullish:
        return 'Positive';
      case SentimentType.bearish:
        return 'Negative';
      case SentimentType.neutral:
        return 'Neutral';
    }
  }

  String get shortDescription {
    if (description.length <= 100) return description;
    return '${description.substring(0, 100)}...';
  }

  bool isRelatedToStock(String symbol) {
    return symbols.contains(symbol);
  }

  NewsModel copyWith({
    String? id,
    String? title,
    String? description,
    String? content,
    String? source,
    String? author,
    String? url,
    String? imageUrl,
    DateTime? publishedAt,
    List<String>? symbols,
    SentimentType? sentiment,
    double? sentimentScore,
    List<String>? tags,
    int? viewCount,
    DateTime? createdAt,
  }) {
    return NewsModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      source: source ?? this.source,
      author: author ?? this.author,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      symbols: symbols ?? this.symbols,
      sentiment: sentiment ?? this.sentiment,
      sentimentScore: sentimentScore ?? this.sentimentScore,
      tags: tags ?? this.tags,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'NewsModel(id: $id, title: $title, source: $source, sentiment: $sentiment)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NewsModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class MarketNewsModel {
  final String title;
  final String description;
  final String source;
  final DateTime publishedAt;
  final String url;
  final String? imageUrl;
  final SentimentType sentiment;
  final double impact; // 0.0 to 1.0

  MarketNewsModel({
    required this.title,
    required this.description,
    required this.source,
    required this.publishedAt,
    required this.url,
    this.imageUrl,
    this.sentiment = SentimentType.neutral,
    this.impact = 0.5,
  });

  factory MarketNewsModel.fromNewsAPI(Map<String, dynamic> data) {
    return MarketNewsModel(
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      source: data['source']?['name'] ?? '',
      url: data['url'] ?? '',
      imageUrl: data['urlToImage'],
      publishedAt: DateTime.tryParse(data['publishedAt'] ?? '') ?? DateTime.now(),
    );
  }

  String get formattedPublishedAt {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get impactText {
    if (impact >= 0.8) return 'High';
    if (impact >= 0.6) return 'Medium';
    if (impact >= 0.4) return 'Low';
    return 'Minimal';
  }
}

class NewsFilter {
  final List<String> symbols;
  final List<SentimentType> sentiments;
  final List<String> sources;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;

  NewsFilter({
    this.symbols = const [],
    this.sentiments = const [],
    this.sources = const [],
    this.startDate,
    this.endDate,
    this.limit = 20,
  });

  NewsFilter copyWith({
    List<String>? symbols,
    List<SentimentType>? sentiments,
    List<String>? sources,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    return NewsFilter(
      symbols: symbols ?? this.symbols,
      sentiments: sentiments ?? this.sentiments,
      sources: sources ?? this.sources,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      limit: limit ?? this.limit,
    );
  }
}
