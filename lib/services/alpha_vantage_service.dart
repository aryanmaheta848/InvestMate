import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:invest_mate/models/stock_model.dart';
import 'package:invest_mate/models/news_model.dart';
import 'package:invest_mate/constants/app_constants.dart';

class AlphaVantageService {
  static final AlphaVantageService _instance = AlphaVantageService._internal();
  factory AlphaVantageService() => _instance;
  AlphaVantageService._internal();

  // Cache for API responses
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheExpiry = const Duration(minutes: 1); // Short cache for real-time data

  /// Get real-time quote for a single stock
  Future<StockModel?> getQuote(String symbol) async {
    try {
      final cacheKey = 'quote_$symbol';
      
      // Check cache first
      if (_isValidCached(cacheKey)) {
        return _parseQuoteData(_cache[cacheKey], symbol);
      }

      final url = '${AppConstants.alphaVantageBaseUrl}'
          '?function=GLOBAL_QUOTE'
          '&symbol=$symbol'
          '&apikey=${AppConstants.alphaVantageQuoteKey}';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'TickerTracker/1.0'},
      ).timeout(AppDurations.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Cache the response
        _cache[cacheKey] = data;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return _parseQuoteData(data, symbol);
      }
      return null;
    } catch (e) {
      print('Error fetching quote for $symbol: $e');
      return null;
    }
  }

  /// Get historical daily data for charts
  Future<List<OHLCVData>> getDailyData(String symbol, {String outputSize = 'compact'}) async {
    try {
      final cacheKey = 'daily_${symbol}_$outputSize';
      
      // Check cache first (longer cache for daily data)
      if (_isValidCached(cacheKey, Duration(hours: 1))) {
        return _parseDailyData(_cache[cacheKey]);
      }

      final url = '${AppConstants.alphaVantageBaseUrl}'
          '?function=TIME_SERIES_DAILY'
          '&symbol=$symbol'
          '&outputsize=$outputSize'
          '&apikey=${AppConstants.alphaVantageDailyKey}';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'TickerTracker/1.0'},
      ).timeout(AppDurations.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Cache the response
        _cache[cacheKey] = data;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return _parseDailyData(data);
      }
      return [];
    } catch (e) {
      print('Error fetching daily data for $symbol: $e');
      return [];
    }
  }

  /// Get Simple Moving Average (SMA) data
  Future<Map<DateTime, double>> getSMA(String symbol, {
    int timePeriod = 20,
    String interval = 'daily',
    String seriesType = 'close',
  }) async {
    try {
      final cacheKey = 'sma_${symbol}_${timePeriod}_$interval';
      
      // Check cache first
      if (_isValidCached(cacheKey, Duration(hours: 1))) {
        return _parseSMAData(_cache[cacheKey]);
      }

      final url = '${AppConstants.alphaVantageBaseUrl}'
          '?function=SMA'
          '&symbol=$symbol'
          '&interval=$interval'
          '&time_period=$timePeriod'
          '&series_type=$seriesType'
          '&apikey=${AppConstants.alphaVantageSmaKey}';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'TickerTracker/1.0'},
      ).timeout(AppDurations.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Cache the response
        _cache[cacheKey] = data;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return _parseSMAData(data);
      }
      return {};
    } catch (e) {
      print('Error fetching SMA for $symbol: $e');
      return {};
    }
  }

  /// Get news and sentiment data
  Future<List<NewsModel>> getNewsAndSentiments({
    List<String>? topics,
    int limit = 50,
  }) async {
    try {
      final cacheKey = 'news_${topics?.join('_') ?? 'general'}_$limit';
      
      // Check cache first (15 minute cache for news)
      if (_isValidCached(cacheKey, Duration(minutes: 15))) {
        return _parseNewsData(_cache[cacheKey]);
      }

      String url = '${AppConstants.alphaVantageBaseUrl}'
          '?function=NEWS_SENTIMENT'
          '&limit=$limit'
          '&apikey=${AppConstants.alphaVantageNewsKey}';

      if (topics != null && topics.isNotEmpty) {
        url += '&topics=${topics.join(',')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'TickerTracker/1.0'},
      ).timeout(AppDurations.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Cache the response
        _cache[cacheKey] = data;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return _parseNewsData(data);
      }
      return [];
    } catch (e) {
      print('Error fetching news and sentiments: $e');
      return [];
    }
  }

  /// Get stock-specific news
  Future<List<NewsModel>> getStockNews(String symbol, {int limit = 20}) async {
    try {
      final cacheKey = 'stock_news_${symbol}_$limit';
      
      // Check cache first
      if (_isValidCached(cacheKey, Duration(minutes: 15))) {
        return _parseNewsData(_cache[cacheKey]);
      }

      final url = '${AppConstants.alphaVantageBaseUrl}'
          '?function=NEWS_SENTIMENT'
          '&tickers=$symbol'
          '&limit=$limit'
          '&apikey=${AppConstants.alphaVantageNewsKey}';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'TickerTracker/1.0'},
      ).timeout(AppDurations.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Cache the response
        _cache[cacheKey] = data;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return _parseNewsData(data);
      }
      return [];
    } catch (e) {
      print('Error fetching news for $symbol: $e');
      return [];
    }
  }

  /// Parse quote data from Alpha Vantage response
  StockModel? _parseQuoteData(Map<String, dynamic> data, String symbol) {
    try {
      final quote = data['Global Quote'];
      if (quote == null) return null;

      return StockModel(
        symbol: quote['01. symbol'] ?? symbol,
        name: _getCompanyName(symbol),
        currentPrice: double.tryParse(quote['05. price'] ?? '0') ?? 0.0,
        dayHigh: double.tryParse(quote['03. high'] ?? '0') ?? 0.0,
        dayLow: double.tryParse(quote['04. low'] ?? '0') ?? 0.0,
        open: double.tryParse(quote['02. open'] ?? '0') ?? 0.0,
        previousClose: double.tryParse(quote['08. previous close'] ?? '0') ?? 0.0,
        volume: int.tryParse(quote['06. volume'] ?? '0') ?? 0,
        lastUpdated: DateTime.now(),
        marketCap: 0, // Not available in quote endpoint
      );
    } catch (e) {
      print('Error parsing quote data: $e');
      return null;
    }
  }

  /// Parse daily time series data
  List<OHLCVData> _parseDailyData(Map<String, dynamic> data) {
    try {
      final timeSeries = data['Time Series (Daily)'] as Map<String, dynamic>?;
      if (timeSeries == null) return [];

      List<OHLCVData> ohlcvData = [];
      
      for (var entry in timeSeries.entries) {
        try {
          final date = entry.key;
          final values = entry.value;
          final ohlcv = OHLCVData(
            timestamp: DateTime.parse(date),
            open: double.parse(values['1. open']),
            high: double.parse(values['2. high']),
            low: double.parse(values['3. low']),
            close: double.parse(values['4. close']),
            volume: int.parse(values['5. volume']),
          );
          ohlcvData.add(ohlcv);
        } catch (e) {
          // Skip invalid data points
          continue;
        }
      }

      // Sort by date (newest first)
      ohlcvData.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return ohlcvData;
    } catch (e) {
      print('Error parsing daily data: $e');
      return [];
    }
  }

  /// Parse SMA technical indicator data
  Map<DateTime, double> _parseSMAData(Map<String, dynamic> data) {
    try {
      final technicalAnalysis = data['Technical Analysis: SMA'] as Map<String, dynamic>?;
      if (technicalAnalysis == null) return {};

      Map<DateTime, double> smaData = {};
      
      for (var entry in technicalAnalysis.entries) {
        try {
          final date = entry.key;
          final values = entry.value;
          smaData[DateTime.parse(date)] = double.parse(values['SMA']);
        } catch (e) {
          // Skip invalid data points
          continue;
        }
      }

      return smaData;
    } catch (e) {
      print('Error parsing SMA data: $e');
      return {};
    }
  }

  /// Parse news and sentiment data
  List<NewsModel> _parseNewsData(Map<String, dynamic> data) {
    try {
      final feed = data['feed'] as List<dynamic>?;
      if (feed == null) return [];

      List<NewsModel> newsItems = [];

      for (var item in feed) {
        try {
          // Parse sentiment scores
          final overallSentiment = item['overall_sentiment_score'] ?? 0.0;
          SentimentType sentimentType = SentimentType.neutral;
          
          if (overallSentiment > 0.15) {
            sentimentType = SentimentType.bullish;
          } else if (overallSentiment < -0.15) {
            sentimentType = SentimentType.bearish;
          }

          // Extract ticker symbols
          final tickerSentiment = item['ticker_sentiment'] as List<dynamic>? ?? [];
          List<String> symbols = tickerSentiment
              .map((ticker) => ticker['ticker'].toString())
              .toList();

          final newsItem = NewsModel(
            id: item['url'].hashCode.toString(),
            title: item['title'] ?? '',
            description: item['summary'] ?? '',
            content: item['summary'] ?? '',
            source: item['source'] ?? 'Alpha Vantage',
            author: item['authors']?.isNotEmpty == true ? item['authors'][0] : null,
            url: item['url'] ?? '',
            imageUrl: item['banner_image'],
            publishedAt: DateTime.tryParse(item['time_published'] ?? '') ?? DateTime.now(),
            sentiment: sentimentType,
            sentimentScore: overallSentiment?.toDouble() ?? 0.0,
            symbols: symbols,
          );

          newsItems.add(newsItem);
        } catch (e) {
          // Skip invalid news items
          continue;
        }
      }

      return newsItems;
    } catch (e) {
      print('Error parsing news data: $e');
      return [];
    }
  }

  /// Helper method to parse percentage strings
  double _parsePercentage(String percentageStr) {
    try {
      return double.parse(percentageStr.replaceAll('%', ''));
    } catch (e) {
      return 0.0;
    }
  }

  /// Get company name from symbol (simplified mapping)
  String _getCompanyName(String symbol) {
    final Map<String, String> symbolToName = {
      'RELIANCE.NS': 'Reliance Industries',
      'TCS.NS': 'Tata Consultancy Services',
      'HDFCBANK.NS': 'HDFC Bank',
      'INFY.NS': 'Infosys',
      'HINDUNILVR.NS': 'Hindustan Unilever',
      'ICICIBANK.NS': 'ICICI Bank',
      'KOTAKBANK.NS': 'Kotak Mahindra Bank',
      'BHARTIARTL.NS': 'Bharti Airtel',
      'ITC.NS': 'ITC Limited',
      'SBIN.NS': 'State Bank of India',
    };
    
    return symbolToName[symbol] ?? symbol.replaceAll('.NS', '');
  }

  /// Check if cached data is still valid
  bool _isValidCached(String key, [Duration? customExpiry]) {
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }
    
    final cacheTime = _cacheTimestamps[key]!;
    final expiry = customExpiry ?? _cacheExpiry;
    return DateTime.now().difference(cacheTime) < expiry;
  }

  /// Clear all cached data
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Get cache statistics for debugging
  Map<String, int> getCacheStats() {
    return {
      'total_cached_items': _cache.length,
      'quote_items': _cache.keys.where((k) => k.startsWith('quote_')).length,
      'daily_items': _cache.keys.where((k) => k.startsWith('daily_')).length,
      'sma_items': _cache.keys.where((k) => k.startsWith('sma_')).length,
      'news_items': _cache.keys.where((k) => k.startsWith('news_')).length,
    };
  }
}
