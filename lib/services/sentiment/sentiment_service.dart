import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:invest_mate/models/stock_model.dart';

class SentimentResult {
  final SentimentType type;
  final double score; // -1.0 to 1.0
  final double confidence; // 0.0 to 1.0
  final Map<String, double>? breakdown;

  SentimentResult({
    required this.type,
    required this.score,
    required this.confidence,
    this.breakdown,
  });
}

class SentimentService {
  static final SentimentService _instance = SentimentService._internal();
  factory SentimentService() => _instance;
  SentimentService._internal();

  final Dio _dio = Dio();

  // For production, you might want to use a proper sentiment analysis API
  // like Google Cloud Natural Language API, AWS Comprehend, or Azure Text Analytics
  static const String sentimentApiUrl = 'YOUR_SENTIMENT_API_URL';
  static const String sentimentApiKey = 'YOUR_SENTIMENT_API_KEY';

  // Financial sentiment keywords for basic analysis
  static const Map<String, double> _bullishKeywords = {
    // Strong positive
    'surge': 0.8, 'soar': 0.8, 'rally': 0.8, 'boom': 0.8, 'breakthrough': 0.8,
    'record': 0.7, 'high': 0.7, 'gain': 0.7, 'profit': 0.7, 'growth': 0.7,
    'revenue': 0.6, 'earnings': 0.6, 'dividend': 0.6, 'expansion': 0.6,
    'bullish': 0.9, 'optimistic': 0.7, 'positive': 0.6, 'strong': 0.6,
    'upgrade': 0.7, 'outperform': 0.8, 'buy': 0.7, 'invest': 0.5,
    'milestone': 0.6, 'achievement': 0.6, 'success': 0.6, 'beat': 0.7,
    'exceed': 0.7, 'above': 0.5, 'higher': 0.5, 'up': 0.4, 'rise': 0.6,
    'increase': 0.5, 'improve': 0.6, 'strengthen': 0.6, 'recover': 0.6,
  };

  static const Map<String, double> _bearishKeywords = {
    // Strong negative
    'crash': -0.8, 'plunge': -0.8, 'collapse': -0.8, 'tumble': -0.8,
    'plummet': -0.8, 'decline': -0.6, 'fall': -0.6, 'drop': -0.6,
    'loss': -0.7, 'deficit': -0.7, 'debt': -0.6, 'bankruptcy': -0.9,
    'bearish': -0.9, 'pessimistic': -0.7, 'negative': -0.6, 'weak': -0.6,
    'downgrade': -0.7, 'underperform': -0.8, 'sell': -0.7, 'avoid': -0.6,
    'concern': -0.5, 'worry': -0.5, 'risk': -0.4, 'warning': -0.6,
    'alert': -0.5, 'caution': -0.4, 'below': -0.5, 'lower': -0.5,
    'down': -0.4, 'decrease': -0.5, 'reduce': -0.5, 'cut': -0.6,
    'slash': -0.7, 'layoff': -0.7, 'closure': -0.8, 'suspend': -0.6,
  };

  static const Map<String, double> _neutralKeywords = {
    'stable': 0.0, 'steady': 0.0, 'maintain': 0.0, 'hold': 0.0,
    'unchanged': 0.0, 'flat': 0.0, 'neutral': 0.0, 'sideways': 0.0,
    'consolidate': 0.0, 'range': 0.0, 'wait': 0.0, 'watch': 0.0,
  };

  // Cache for sentiment results
  final Map<String, SentimentResult> _sentimentCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration cacheExpiry = Duration(hours: 1);

  Future<SentimentResult> analyzeSentiment(String text) async {
    if (text.trim().isEmpty) {
      return SentimentResult(
        type: SentimentType.neutral,
        score: 0.0,
        confidence: 0.0,
      );
    }

    // Check cache first
    String cacheKey = _generateCacheKey(text);
    if (_isValidCache(cacheKey)) {
      return _sentimentCache[cacheKey]!;
    }

    SentimentResult result;

    try {
      // Try to use external API first (if available)
      result = await _analyzeWithExternalAPI(text);
    } catch (e) {
      print('External sentiment API failed, using local analysis: $e');
      // Fallback to local keyword-based analysis
      result = _analyzeWithKeywords(text);
    }

    // Cache the result
    _sentimentCache[cacheKey] = result;
    _cacheTimestamps[cacheKey] = DateTime.now();

    return result;
  }

  Future<SentimentResult> _analyzeWithExternalAPI(String text) async {
    // This would integrate with a real sentiment analysis API
    // For now, throwing an exception to fallback to keyword analysis
    throw UnimplementedError('External API not configured');
    
    /*
    // Example implementation with Google Cloud Natural Language API
    try {
      final response = await _dio.post(
        'https://language.googleapis.com/v1/documents:analyzeSentiment',
        queryParameters: {'key': sentimentApiKey},
        data: {
          'document': {
            'type': 'PLAIN_TEXT',
            'content': text,
          },
          'encodingType': 'UTF8',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        double score = data['documentSentiment']['score'].toDouble();
        double magnitude = data['documentSentiment']['magnitude'].toDouble();
        
        SentimentType type = SentimentType.neutral;
        if (score > 0.1) {
          type = SentimentType.bullish;
        } else if (score < -0.1) {
          type = SentimentType.bearish;
        }

        return SentimentResult(
          type: type,
          score: score,
          confidence: magnitude,
        );
      }
      
      throw Exception('API request failed');
    } catch (e) {
      throw Exception('Sentiment API error: $e');
    }
    */
  }

  SentimentResult _analyzeWithKeywords(String text) {
    String cleanText = text.toLowerCase().trim();
    List<String> words = cleanText
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();

    double totalScore = 0.0;
    int matchedWords = 0;
    Map<String, double> breakdown = {
      'bullish': 0.0,
      'bearish': 0.0,
      'neutral': 0.0,
    };

    // Check for bullish keywords
    for (String word in words) {
      if (_bullishKeywords.containsKey(word)) {
        double score = _bullishKeywords[word]!;
        totalScore += score;
        breakdown['bullish'] = breakdown['bullish']! + score;
        matchedWords++;
      }
    }

    // Check for bearish keywords
    for (String word in words) {
      if (_bearishKeywords.containsKey(word)) {
        double score = _bearishKeywords[word]!;
        totalScore += score;
        breakdown['bearish'] = breakdown['bearish']! + score.abs();
        matchedWords++;
      }
    }

    // Check for neutral keywords
    for (String word in words) {
      if (_neutralKeywords.containsKey(word)) {
        breakdown['neutral'] = breakdown['neutral']! + 0.1;
        matchedWords++;
      }
    }

    // Calculate average score and confidence
    double averageScore = matchedWords > 0 ? totalScore / matchedWords : 0.0;
    double confidence = min(matchedWords.toDouble() / words.length, 1.0);
    
    // Adjust confidence based on text length
    if (words.length < 5) {
      confidence *= 0.5; // Lower confidence for very short text
    }

    // Apply contextual adjustments
    averageScore = _applyContextualAdjustments(cleanText, averageScore);

    // Determine sentiment type
    SentimentType type = SentimentType.neutral;
    if (averageScore > 0.1) {
      type = SentimentType.bullish;
    } else if (averageScore < -0.1) {
      type = SentimentType.bearish;
    }

    // Normalize breakdown values
    double totalBreakdown = breakdown.values.fold(0.0, (sum, value) => sum + value);
    if (totalBreakdown > 0) {
      breakdown.updateAll((key, value) => value / totalBreakdown);
    }

    return SentimentResult(
      type: type,
      score: averageScore.clamp(-1.0, 1.0),
      confidence: confidence,
      breakdown: breakdown,
    );
  }

  double _applyContextualAdjustments(String text, double score) {
    // Look for negations that might reverse sentiment
    List<String> negations = ['not', 'no', 'never', 'don\'t', 'doesn\'t', 'won\'t', 'can\'t'];
    
    for (String negation in negations) {
      if (text.contains(negation)) {
        // Reverse and dampen the sentiment if negation is found
        score *= -0.7;
        break;
      }
    }

    // Look for uncertainty words that reduce confidence
    List<String> uncertaintyWords = ['maybe', 'might', 'could', 'possibly', 'perhaps', 'uncertain'];
    
    for (String word in uncertaintyWords) {
      if (text.contains(word)) {
        // Reduce the magnitude of sentiment
        score *= 0.6;
        break;
      }
    }

    // Look for time-based qualifiers
    if (text.contains('expected') || text.contains('forecast') || text.contains('projected')) {
      // Future-oriented sentiment is less certain
      score *= 0.8;
    }

    return score;
  }

  Future<List<SentimentResult>> analyzeBatchSentiment(List<String> texts) async {
    List<Future<SentimentResult>> futures = texts
        .map((text) => analyzeSentiment(text))
        .toList();
    
    return await Future.wait(futures);
  }

  Future<SentimentResult> analyzeStockSentiment(
    String symbol,
    List<String> texts,
  ) async {
    if (texts.isEmpty) {
      return SentimentResult(
        type: SentimentType.neutral,
        score: 0.0,
        confidence: 0.0,
      );
    }

    List<SentimentResult> results = await analyzeBatchSentiment(texts);
    
    // Calculate weighted average based on confidence and recency
    double totalWeightedScore = 0.0;
    double totalWeight = 0.0;
    
    Map<SentimentType, int> typeCount = {
      SentimentType.bullish: 0,
      SentimentType.bearish: 0,
      SentimentType.neutral: 0,
    };

    for (SentimentResult result in results) {
      double weight = result.confidence;
      totalWeightedScore += result.score * weight;
      totalWeight += weight;
      typeCount[result.type] = typeCount[result.type]! + 1;
    }

    double averageScore = totalWeight > 0 ? totalWeightedScore / totalWeight : 0.0;
    double averageConfidence = results.fold(0.0, (sum, result) => sum + result.confidence) / results.length;

    // Determine overall sentiment type based on majority and score
    SentimentType overallType = SentimentType.neutral;
    if (averageScore > 0.1) {
      overallType = SentimentType.bullish;
    } else if (averageScore < -0.1) {
      overallType = SentimentType.bearish;
    }

    // Create breakdown
    Map<String, double> breakdown = {
      'bullish': typeCount[SentimentType.bullish]!.toDouble() / results.length,
      'bearish': typeCount[SentimentType.bearish]!.toDouble() / results.length,
      'neutral': typeCount[SentimentType.neutral]!.toDouble() / results.length,
    };

    return SentimentResult(
      type: overallType,
      score: averageScore.clamp(-1.0, 1.0),
      confidence: averageConfidence,
      breakdown: breakdown,
    );
  }

  String getSentimentEmoji(SentimentType sentiment) {
    switch (sentiment) {
      case SentimentType.bullish:
        return '😊';
      case SentimentType.bearish:
        return '😡';
      case SentimentType.neutral:
        return '😐';
    }
  }

  String getSentimentText(SentimentType sentiment) {
    switch (sentiment) {
      case SentimentType.bullish:
        return 'Bullish';
      case SentimentType.bearish:
        return 'Bearish';
      case SentimentType.neutral:
        return 'Neutral';
    }
  }

  Color getSentimentColor(SentimentType sentiment) {
    switch (sentiment) {
      case SentimentType.bullish:
        return const Color(0xFF4CAF50); // Green
      case SentimentType.bearish:
        return const Color(0xFFF44336); // Red
      case SentimentType.neutral:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  String _generateCacheKey(String text) {
    return text.hashCode.toString();
  }

  bool _isValidCache(String key) {
    if (!_sentimentCache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }
    
    DateTime timestamp = _cacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) < cacheExpiry;
  }

  void clearCache() {
    _sentimentCache.clear();
    _cacheTimestamps.clear();
  }

  // Add new keywords dynamically (for learning/adaptation)
  void addBullishKeyword(String keyword, double weight) {
    // This would update the keyword dictionary
    // In a production app, you might want to store this in a database
  }

  void addBearishKeyword(String keyword, double weight) {
    // This would update the keyword dictionary
    // In a production app, you might want to store this in a database
  }

  // Get sentiment statistics for analysis
  Map<String, dynamic> getSentimentStats() {
    return {
      'bullishKeywords': _bullishKeywords.length,
      'bearishKeywords': _bearishKeywords.length,
      'neutralKeywords': _neutralKeywords.length,
      'cacheSize': _sentimentCache.length,
      'cacheHitRate': _sentimentCache.isNotEmpty ? 0.8 : 0.0, // Placeholder
    };
  }
}
