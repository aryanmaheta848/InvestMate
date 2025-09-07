import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invest_mate/models/stock_model.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/services/alpha_vantage_service.dart';

class StockService {
  static final StockService _instance = StockService._internal();
  factory StockService() => _instance;
  StockService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AlphaVantageService _alphaVantage = AlphaVantageService();
  final Map<String, StockModel> _cache = {};
  final Duration _cacheExpiry = const Duration(minutes: 5);
  final Map<String, DateTime> _cacheTimestamps = {};

  // Get stock data by symbol
  Future<StockModel?> getStock(String symbol) async {
    try {
      // Check cache first
      if (_isValidCached(symbol)) {
        return _cache[symbol];
      }

      // Primary: Fetch from Alpha Vantage API
      StockModel? stockData = await _alphaVantage.getQuote(symbol);
      
      if (stockData != null) {
        _cache[symbol] = stockData;
        _cacheTimestamps[symbol] = DateTime.now();
        
        // Save to Firestore
        await _saveStockToFirestore(stockData);
        return stockData;
      }

      // Fallback 1: Try Yahoo Finance
      stockData = await _fetchFromYahooFinance(symbol);
      if (stockData != null) {
        _cache[symbol] = stockData;
        _cacheTimestamps[symbol] = DateTime.now();
        
        await _saveStockToFirestore(stockData);
        return stockData;
      }

      // Fallback 2: Get cached data from Firestore
      return await _getStockFromFirestore(symbol);
    } catch (e) {
      print('Error getting stock data for $symbol: $e');
      
      // Return cached data if available
      if (_cache.containsKey(symbol)) {
        return _cache[symbol];
      }
      
      // Final fallback to Firestore
      return await _getStockFromFirestore(symbol);
    }
  }

  // Get multiple stocks at once
  Future<List<StockModel>> getStocks(List<String> symbols) async {
    final List<Future<StockModel?>> futures = symbols.map((symbol) => getStock(symbol)).toList();
    final results = await Future.wait(futures);
    return results.whereType<StockModel>().toList();
  }

  // Search stocks by query
  Future<List<StockModel>> searchStocks(String query) async {
    try {
      // Search in popular stocks first
      final popularMatches = AppConstants.popularStocks
          .where((symbol) => symbol.toLowerCase().contains(query.toLowerCase()))
          .take(10)
          .toList();

      if (popularMatches.isNotEmpty) {
        return await getStocks(popularMatches);
      }

      // If no matches in popular stocks, search Firestore
      final querySnapshot = await _firestore
          .collection('stocks')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '$query\uf8ff')
          .limit(10)
          .get();

      return querySnapshot.docs
          .map((doc) => StockModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error searching stocks: $e');
      return [];
    }
  }

  // Get trending stocks
  Future<List<StockModel>> getTrendingStocks() async {
    try {
      // Get top 10 popular stocks
      final trendingSymbols = AppConstants.popularStocks.take(10).toList();
      return await getStocks(trendingSymbols);
    } catch (e) {
      print('Error getting trending stocks: $e');
      return [];
    }
  }

  // Get market indices (NIFTY 50, etc.)
  Future<List<StockModel>> getMarketIndices() async {
    try {
      const indices = [
        '^NSEI', // NIFTY 50
        '^NSEBANK', // BANK NIFTY
        '^CNX500', // NIFTY 500
      ];
      
      return await getStocks(indices);
    } catch (e) {
      print('Error getting market indices: $e');
      return [];
    }
  }

  // Get historical data for charts
  Future<List<OHLCVData>> getHistoricalData(
    String symbol,
    String period, // 1d, 5d, 1mo, 3mo, 6mo, 1y, 2y, 5y, 10y, ytd, max
  ) async {
    try {
      // Primary: Try Alpha Vantage for daily data
      List<OHLCVData> ohlcvData = await _alphaVantage.getDailyData(
        symbol,
        outputSize: _getAlphaVantageOutputSize(period),
      );
      
      if (ohlcvData.isNotEmpty) {
        // Filter data based on period if needed
        return _filterDataByPeriod(ohlcvData, period);
      }

      // Fallback: Use Yahoo Finance
      final url = '${AppConstants.yahooFinanceUrl}/$symbol?period1=0&period2=9999999999&interval=1d&range=$period';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(AppDurations.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['chart']['result'][0];
        
        final timestamps = List<int>.from(result['timestamp']);
        final quotes = result['indicators']['quote'][0];
        final opens = List<double>.from(quotes['open'].where((x) => x != null));
        final highs = List<double>.from(quotes['high'].where((x) => x != null));
        final lows = List<double>.from(quotes['low'].where((x) => x != null));
        final closes = List<double>.from(quotes['close'].where((x) => x != null));
        final volumes = List<int>.from(quotes['volume'].where((x) => x != null));

        final List<OHLCVData> yahooData = [];
        for (int i = 0; i < timestamps.length; i++) {
          if (i < opens.length && i < highs.length && i < lows.length && 
              i < closes.length && i < volumes.length) {
            yahooData.add(OHLCVData(
              timestamp: DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000),
              open: opens[i],
              high: highs[i],
              low: lows[i],
              close: closes[i],
              volume: volumes[i],
            ));
          }
        }
        
        return yahooData;
      }
      return [];
    } catch (e) {
      print('Error getting historical data for $symbol: $e');
      return [];
    }
  }

  // Fetch stock data from Yahoo Finance API
  Future<StockModel?> _fetchFromYahooFinance(String symbol) async {
    try {
      final url = '${AppConstants.yahooFinanceUrl}/$symbol';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(AppDurations.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StockModel.fromYahooFinance(data);
      }
      return null;
    } catch (e) {
      print('Error fetching from Yahoo Finance: $e');
      return null;
    }
  }

  // Get stock from Firestore cache
  Future<StockModel?> _getStockFromFirestore(String symbol) async {
    try {
      final doc = await _firestore.collection('stocks').doc(symbol).get();
      if (doc.exists) {
        return StockModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting stock from Firestore: $e');
      return null;
    }
  }

  // Save stock data to Firestore
  Future<void> _saveStockToFirestore(StockModel stock) async {
    try {
      await _firestore.collection('stocks').doc(stock.symbol).set(
        stock.toFirestore(),
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Error saving stock to Firestore: $e');
    }
  }

  // Check if cached data is still valid
  bool _isValidCached(String symbol) {
    if (!_cache.containsKey(symbol) || !_cacheTimestamps.containsKey(symbol)) {
      return false;
    }
    
    final cacheTime = _cacheTimestamps[symbol]!;
    return DateTime.now().difference(cacheTime) < _cacheExpiry;
  }

  // Clear cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  // Get watchlist stocks for user
  Future<List<StockModel>> getWatchlistStocks(List<String> symbols) async {
    try {
      return await getStocks(symbols);
    } catch (e) {
      print('Error getting watchlist stocks: $e');
      return [];
    }
  }

  // Add stock to user watchlist
  Future<void> addToWatchlist(String userId, String symbol) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'watchlist': FieldValue.arrayUnion([symbol]),
      });
    } catch (e) {
      print('Error adding to watchlist: $e');
      throw Exception('Failed to add to watchlist');
    }
  }

  // Remove stock from user watchlist
  Future<void> removeFromWatchlist(String userId, String symbol) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'watchlist': FieldValue.arrayRemove([symbol]),
      });
    } catch (e) {
      print('Error removing from watchlist: $e');
      throw Exception('Failed to remove from watchlist');
    }
  }

  // Get stock price updates stream
  Stream<StockModel> getStockPriceStream(String symbol) async* {
    while (true) {
      try {
        final stock = await getStock(symbol);
        if (stock != null) {
          yield stock;
        }
        await Future.delayed(AppDurations.refreshInterval);
      } catch (e) {
        print('Error in stock price stream: $e');
        await Future.delayed(AppDurations.refreshInterval);
      }
    }
  }

  // Update multiple stock prices (for background refresh)
  Future<void> refreshStockPrices(List<String> symbols) async {
    try {
      // Batch update popular stocks
      final futures = symbols.map((symbol) => getStock(symbol)).toList();
      await Future.wait(futures);
    } catch (e) {
      print('Error refreshing stock prices: $e');
    }
  }

  // Get sector performance
  Future<Map<String, double>> getSectorPerformance() async {
    try {
      // This would typically come from a dedicated API
      // For now, return mock data
      return {
        'Technology': 2.5,
        'Banking': -1.2,
        'Healthcare': 1.8,
        'Energy': -0.5,
        'Consumer': 0.9,
        'Industrials': 1.4,
      };
    } catch (e) {
      print('Error getting sector performance: $e');
      return {};
    }
  }

  // Check if market is open
  bool isMarketOpen() {
    final now = DateTime.now();
    final indianTime = now.add(const Duration(hours: 5, minutes: 30));
    
    // NSE trading hours: 9:15 AM to 3:30 PM IST, Monday to Friday
    if (indianTime.weekday > 5) return false; // Weekend
    
    final hour = indianTime.hour;
    final minute = indianTime.minute;
    
    // Market opens at 9:15 AM
    if (hour < 9 || (hour == 9 && minute < 15)) return false;
    
    // Market closes at 3:30 PM
    if (hour > 15 || (hour == 15 && minute > 30)) return false;
    
    return true;
  }

  // Get market status
  MarketStatus getMarketStatus() {
    final now = DateTime.now();
    final indianTime = now.add(const Duration(hours: 5, minutes: 30));
    
    if (indianTime.weekday > 5) return MarketStatus.closed; // Weekend
    
    final hour = indianTime.hour;
    final minute = indianTime.minute;
    
    // Pre-market: 9:00 AM to 9:15 AM
    if (hour == 9 && minute < 15) return MarketStatus.preMarket;
    
    // Market hours: 9:15 AM to 3:30 PM
    if ((hour > 9 || (hour == 9 && minute >= 15)) && 
        (hour < 15 || (hour == 15 && minute <= 30))) {
      return MarketStatus.open;
    }
    
    // Post-market: 3:30 PM to 4:00 PM
    if (hour == 15 && minute > 30) return MarketStatus.postMarket;
    if (hour == 16) return MarketStatus.postMarket;
    
    return MarketStatus.closed;
  }

  // Helper methods for Alpha Vantage integration

  /// Convert period to Alpha Vantage output size
  String _getAlphaVantageOutputSize(String period) {
    // Alpha Vantage compact gives last 100 data points
    // Alpha Vantage full gives up to 20 years of data
    switch (period) {
      case '1d':
      case '5d':
      case '1mo':
      case '3mo':
        return 'compact'; // Last 100 days
      case '6mo':
      case '1y':
      case '2y':
      case '5y':
      case '10y':
      case 'ytd':
      case 'max':
        return 'full'; // Full historical data
      default:
        return 'compact';
    }
  }

  /// Filter historical data based on requested period
  List<OHLCVData> _filterDataByPeriod(List<OHLCVData> data, String period) {
    if (data.isEmpty) return data;

    final now = DateTime.now();
    DateTime cutoffDate;

    switch (period) {
      case '1d':
        cutoffDate = now.subtract(const Duration(days: 1));
        break;
      case '5d':
        cutoffDate = now.subtract(const Duration(days: 5));
        break;
      case '1mo':
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
      case '3mo':
        cutoffDate = now.subtract(const Duration(days: 90));
        break;
      case '6mo':
        cutoffDate = now.subtract(const Duration(days: 180));
        break;
      case '1y':
        cutoffDate = now.subtract(const Duration(days: 365));
        break;
      case '2y':
        cutoffDate = now.subtract(const Duration(days: 730));
        break;
      case '5y':
        cutoffDate = now.subtract(const Duration(days: 1825));
        break;
      case 'ytd':
        cutoffDate = DateTime(now.year, 1, 1);
        break;
      case '10y':
      case 'max':
      default:
        return data; // Return all data
    }

    return data.where((item) => item.timestamp.isAfter(cutoffDate)).toList();
  }

  /// Get Simple Moving Average data for technical analysis
  Future<Map<DateTime, double>> getMovingAverage(
    String symbol, {
    int period = 20,
    String interval = 'daily',
  }) async {
    try {
      return await _alphaVantage.getSMA(
        symbol,
        timePeriod: period,
        interval: interval,
      );
    } catch (e) {
      print('Error getting moving average for $symbol: $e');
      return {};
    }
  }

  /// Check if Alpha Vantage services are available
  Future<bool> checkAlphaVantageStatus() async {
    try {
      // Test with a known symbol
      final testData = await _alphaVantage.getQuote('RELIANCE.NS');
      return testData != null;
    } catch (e) {
      return false;
    }
  }

  /// Get API usage statistics
  Map<String, dynamic> getApiUsageStats() {
    return {
      'cache_stats': _alphaVantage.getCacheStats(),
      'local_cache_size': _cache.length,
      'cache_timestamps': _cacheTimestamps.length,
    };
  }
}
