import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:invest_mate/models/news_model.dart';
import 'package:invest_mate/services/firebase/firebase_service.dart';
import 'package:invest_mate/services/sentiment/sentiment_service.dart';
import 'package:invest_mate/services/alpha_vantage_service.dart';

class NewsService {
  static final NewsService _instance = NewsService._internal();
  factory NewsService() => _instance;
  NewsService._internal();

  final Dio _dio = Dio();
  final FirebaseService _firebase = FirebaseService();
  final SentimentService _sentimentService = SentimentService();
  final AlphaVantageService _alphaVantage = AlphaVantageService();

  // News API configurations
  static const String newsApiKey = 'f944b9fcf341485cb11652accf5689cf';
  static const String newsApiBaseUrl = 'https://newsapi.org/v2';
  static const String moneycontrolUrl = 'https://www.moneycontrol.com';
  static const String nseAnnouncementsUrl = 'https://www.nseindia.com';

  // Cache configuration
  final Map<String, List<NewsModel>> _newsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration cacheExpiry = Duration(minutes: 30);

  Future<List<NewsModel>> getMarketNews({
    int limit = 20,
    bool useCache = true,
  }) async {
    const String cacheKey = 'market_news';
    
    // Check cache first
    if (useCache && _isValidCache(cacheKey)) {
      return _newsCache[cacheKey] ?? [];
    }

    try {
      List<NewsModel> news = [];
      
      // Fetch from multiple sources including Alpha Vantage
      List<Future<List<NewsModel>>> futures = [
        _fetchFromNewsAPI('business', limit: limit ~/ 3),
        _fetchFromMoneyControl(limit: limit ~/ 3),
        _alphaVantage.getNewsAndSentiments(limit: limit ~/ 3),
      ];

      List<List<NewsModel>> results = await Future.wait(futures);
      
      for (List<NewsModel> result in results) {
        news.addAll(result);
      }

      // Remove duplicates and sort by date
      news = _removeDuplicates(news);
      news.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      
      if (news.length > limit) {
        news = news.take(limit).toList();
      }

      // Process sentiment for news
      news = await _processSentiment(news);

      // Cache the results
      _newsCache[cacheKey] = news;
      _cacheTimestamps[cacheKey] = DateTime.now();

      // Cache to Firebase (background operation)
      _firebase.cacheNews(news).catchError((error) {
        print('Error caching news to Firebase: $error');
      });

      return news;
    } catch (e) {
      print('Error fetching market news: $e');
      
      // Try to get cached data from Firebase
      try {
        return await _firebase.getCachedNews(limit: limit);
      } catch (firebaseError) {
        print('Error getting cached news from Firebase: $firebaseError');
        return [];
      }
    }
  }

  Future<List<NewsModel>> getStockNews(
    String symbol, {
    int limit = 10,
    bool useCache = true,
  }) async {
    final String cacheKey = 'stock_news_$symbol';
    
    // Check cache first
    if (useCache && _isValidCache(cacheKey)) {
      return _newsCache[cacheKey] ?? [];
    }

    try {
      List<NewsModel> news = [];
      
      // Extract company name from symbol for better search
      String searchQuery = _getSearchQueryFromSymbol(symbol);
      
      // Fetch stock-specific news including Alpha Vantage
      List<Future<List<NewsModel>>> futures = [
        _fetchFromNewsAPI('business', query: searchQuery, limit: limit ~/ 2),
        _alphaVantage.getStockNews(symbol, limit: limit ~/ 2),
        _fetchStockSpecificNews(symbol, limit: limit ~/ 4),
      ];

      List<List<NewsModel>> results = await Future.wait(futures);
      
      for (List<NewsModel> result in results) {
        news.addAll(result);
      }

      // Filter news relevant to the stock
      news = _filterRelevantNews(news, symbol);
      
      // Remove duplicates and sort by date
      news = _removeDuplicates(news);
      news.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      
      if (news.length > limit) {
        news = news.take(limit).toList();
      }

      // Process sentiment for news
      news = await _processSentiment(news);

      // Update news with symbol association
      news = news.map((item) {
        if (!item.symbols.contains(symbol)) {
          return item.copyWith(symbols: [...item.symbols, symbol]);
        }
        return item;
      }).toList();

      // Cache the results
      _newsCache[cacheKey] = news;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return news;
    } catch (e) {
      print('Error fetching stock news for $symbol: $e');
      
      // Try to get cached data from Firebase
      try {
        return await _firebase.getCachedNews(symbols: [symbol], limit: limit);
      } catch (firebaseError) {
        print('Error getting cached stock news from Firebase: $firebaseError');
        return [];
      }
    }
  }

  Future<List<NewsModel>> searchNews(
    String query, {
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<NewsModel> news = await _fetchFromNewsAPI(
        'everything',
        query: query,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );

      // Process sentiment for news
      news = await _processSentiment(news);

      return news;
    } catch (e) {
      print('Error searching news: $e');
      return [];
    }
  }

  Future<List<NewsModel>> _fetchFromNewsAPI(
    String endpoint, {
    String? query,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Map<String, dynamic> params = {
        'apiKey': newsApiKey,
        'pageSize': limit,
        'language': 'en',
      };

      if (endpoint == 'business') {
        params['category'] = 'business';
        params['country'] = 'in'; // Focus on Indian market
      }

      if (query != null) {
        params['q'] = query;
      }

      if (startDate != null) {
        params['from'] = startDate.toIso8601String();
      }

      if (endDate != null) {
        params['to'] = endDate.toIso8601String();
      }

      final response = await _dio.get(
        '$newsApiBaseUrl/${endpoint == 'business' ? 'top-headlines' : 'everything'}',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        List<dynamic> articles = response.data['articles'] ?? [];
        return articles
            .map((article) => NewsModel.fromNewsAPI(article))
            .where((news) => news.title.isNotEmpty && news.url.isNotEmpty)
            .toList();
      }

      return [];
    } catch (e) {
      print('Error fetching from NewsAPI: $e');
      return [];
    }
  }

  Future<List<NewsModel>> _fetchFromMoneyControl({int limit = 10}) async {
    try {
      // This would be a web scraping implementation
      // For production, you'd want to use their official API if available
      
      final response = await _dio.get(
        '$moneycontrolUrl/news/business',
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );

      if (response.statusCode == 200) {
        return _parseMoneyControlNews(response.data, limit);
      }

      return [];
    } catch (e) {
      print('Error fetching from MoneyControl: $e');
      return [];
    }
  }

  Future<List<NewsModel>> _fetchStockSpecificNews(String symbol, {int limit = 10}) async {
    try {
      // This would implement fetching from NSE announcements, company-specific sources
      // For now, returning empty list as it requires specific API access
      
      List<NewsModel> news = [];
      
      // You could implement:
      // - NSE corporate announcements
      // - Company press releases
      // - Regulatory filings
      // - Earnings announcements
      
      return news;
    } catch (e) {
      print('Error fetching stock-specific news for $symbol: $e');
      return [];
    }
  }

  List<NewsModel> _parseMoneyControlNews(String html, int limit) {
    try {
      Document document = html_parser.parse(html);
      List<NewsModel> news = [];

      // This would parse the HTML structure of MoneyControl
      // Implementation would depend on their actual HTML structure
      
      var newsElements = document.querySelectorAll('.news-item'); // Example selector
      
      for (var element in newsElements.take(limit)) {
        try {
          String? title = element.querySelector('.title')?.text;
          String? description = element.querySelector('.description')?.text;
          String? url = element.querySelector('a')?.attributes['href'];
          String? imageUrl = element.querySelector('img')?.attributes['src'];
          
          if (title != null && url != null) {
            news.add(NewsModel(
              id: url.hashCode.toString(),
              title: title,
              description: description ?? '',
              source: 'MoneyControl',
              url: url.startsWith('http') ? url : '$moneycontrolUrl$url',
              imageUrl: imageUrl,
              publishedAt: DateTime.now(), // You'd parse the actual date
            ));
          }
        } catch (e) {
          // Skip this news item if parsing fails
          continue;
        }
      }

      return news;
    } catch (e) {
      print('Error parsing MoneyControl news: $e');
      return [];
    }
  }

  List<NewsModel> _removeDuplicates(List<NewsModel> news) {
    Map<String, NewsModel> unique = {};
    
    for (NewsModel item in news) {
      String key = item.title.toLowerCase().trim();
      if (!unique.containsKey(key) || 
          unique[key]!.publishedAt.isBefore(item.publishedAt)) {
        unique[key] = item;
      }
    }
    
    return unique.values.toList();
  }

  List<NewsModel> _filterRelevantNews(List<NewsModel> news, String symbol) {
    String companyName = _getCompanyName(symbol);
    String searchTerms = _getSearchTerms(symbol);
    
    return news.where((item) {
      String content = '${item.title} ${item.description} ${item.content}'.toLowerCase();
      return content.contains(symbol.toLowerCase()) ||
             content.contains(companyName.toLowerCase()) ||
             _containsSearchTerms(content, searchTerms);
    }).toList();
  }

  String _getSearchQueryFromSymbol(String symbol) {
    // Convert symbol to company name for better search results
    Map<String, String> symbolToName = {
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
      // Add more mappings as needed
    };
    
    return symbolToName[symbol] ?? symbol.replaceAll('.NS', '');
  }

  String _getCompanyName(String symbol) {
    return _getSearchQueryFromSymbol(symbol);
  }

  String _getSearchTerms(String symbol) {
    // Additional search terms that might be relevant
    Map<String, String> symbolToTerms = {
      'RELIANCE.NS': 'RIL Jio Retail Petroleum',
      'TCS.NS': 'TCS IT Services',
      'HDFCBANK.NS': 'HDFC Banking',
      'INFY.NS': 'Infosys IT Technology',
      // Add more mappings as needed
    };
    
    return symbolToTerms[symbol] ?? '';
  }

  bool _containsSearchTerms(String content, String searchTerms) {
    if (searchTerms.isEmpty) return false;
    
    List<String> terms = searchTerms.toLowerCase().split(' ');
    return terms.any((term) => content.contains(term));
  }

  Future<List<NewsModel>> _processSentiment(List<NewsModel> news) async {
    List<NewsModel> processedNews = [];
    
    for (NewsModel item in news) {
      try {
        SentimentResult sentiment = await _sentimentService.analyzeSentiment(
          '${item.title} ${item.description}',
        );
        
        processedNews.add(item.copyWith(
          sentiment: sentiment.type,
          sentimentScore: sentiment.score,
        ));
      } catch (e) {
        // If sentiment analysis fails, keep original news item
        processedNews.add(item);
      }
    }
    
    return processedNews;
  }

  bool _isValidCache(String key) {
    if (!_newsCache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }
    
    DateTime timestamp = _cacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) < cacheExpiry;
  }

  void clearCache() {
    _newsCache.clear();
    _cacheTimestamps.clear();
  }

  void clearCacheForKey(String key) {
    _newsCache.remove(key);
    _cacheTimestamps.remove(key);
  }

  // Get trending topics from news
  List<String> getTrendingTopics(List<NewsModel> news) {
    Map<String, int> topicCount = {};
    
    for (NewsModel item in news) {
      List<String> words = '${item.title} ${item.description}'
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .split(' ');
      
      for (String word in words) {
        if (word.length > 4) { // Only consider words longer than 4 characters
          topicCount[word] = (topicCount[word] ?? 0) + 1;
        }
      }
    }
    
    var sortedTopics = topicCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedTopics
        .take(10)
        .map((entry) => entry.key)
        .toList();
  }

  // Get news summary for multiple stocks
  Future<Map<String, List<NewsModel>>> getMultipleStocksNews(
    List<String> symbols, {
    int limitPerStock = 5,
  }) async {
    Map<String, List<NewsModel>> result = {};
    
    List<Future<void>> futures = symbols.map((symbol) async {
      result[symbol] = await getStockNews(symbol, limit: limitPerStock);
    }).toList();
    
    await Future.wait(futures);
    
    return result;
  }
}
