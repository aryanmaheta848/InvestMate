import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'package:invest_mate/models/stock_model.dart';
import 'package:invest_mate/constants/app_constants.dart';

class RealtimeStockService {
  static final RealtimeStockService _instance = RealtimeStockService._internal();
  factory RealtimeStockService() => _instance;
  RealtimeStockService._internal();

  final Map<String, StreamController<StockModel>> _streamControllers = {};
  final Map<String, Timer> _timers = {};
  final Map<String, StockModel> _lastKnownPrices = {};
  final Duration _updateInterval = const Duration(seconds: 5); // More frequent updates
  final Duration _fastUpdateInterval = const Duration(seconds: 2); // For active stocks

  // WebSocket connection for real-time data (if available)
  WebSocketChannel? _webSocketChannel;
  bool _isWebSocketConnected = false;
  final Set<String> _subscribedSymbols = {};

  // Stream for real-time stock updates
  Stream<StockModel> getStockStream(String symbol) {
    if (!_streamControllers.containsKey(symbol)) {
      _streamControllers[symbol] = StreamController<StockModel>.broadcast();
      _startRealTimeUpdates(symbol);
    }
    return _streamControllers[symbol]!.stream;
  }

  // Start real-time updates for a stock
  void _startRealTimeUpdates(String symbol) {
    // Stop existing timer if any
    _timers[symbol]?.cancel();

    // Start with fast updates for better real-time feel
    _timers[symbol] = Timer.periodic(_fastUpdateInterval, (timer) {
      _updateStockPrice(symbol);
    });

    // Initial fetch
    _updateStockPrice(symbol);
  }

  // Update stock price
  Future<void> _updateStockPrice(String symbol) async {
    try {
      final stock = await _fetchRealTimeStock(symbol);
      if (stock != null) {
        _lastKnownPrices[symbol] = stock;
        _streamControllers[symbol]?.add(stock);
      }
    } catch (e) {
      print('Error updating stock price for $symbol: $e');
    }
  }

  // Fetch real-time stock data
  Future<StockModel?> _fetchRealTimeStock(String symbol) async {
    try {
      // Try multiple sources for better real-time data
      
      // 1. Try Alpha Vantage real-time quote
      final alphaVantageData = await _fetchFromAlphaVantage(symbol);
      if (alphaVantageData != null) return alphaVantageData;

      // 2. Try Yahoo Finance real-time
      final yahooData = await _fetchFromYahooFinance(symbol);
      if (yahooData != null) return yahooData;

      // 3. Try IEX Cloud (if available)
      final iexData = await _fetchFromIEXCloud(symbol);
      if (iexData != null) return iexData;

      return null;
    } catch (e) {
      print('Error fetching real-time stock data: $e');
      return null;
    }
  }

  // Fetch from Alpha Vantage
  Future<StockModel?> _fetchFromAlphaVantage(String symbol) async {
    try {
      final url = '${AppConstants.alphaVantageBaseUrl}?function=GLOBAL_QUOTE&symbol=$symbol&apikey=${AppConstants.alphaVantageQuoteKey}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Global Quote'] != null) {
          return StockModel.fromAlphaVantage(data);
        }
      }
      return null;
    } catch (e) {
      print('Alpha Vantage error: $e');
      return null;
    }
  }

  // Fetch from Yahoo Finance
  Future<StockModel?> _fetchFromYahooFinance(String symbol) async {
    try {
      final url = '${AppConstants.yahooFinanceUrl}/$symbol?interval=1m&range=1d';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StockModel.fromYahooFinance(data);
      }
      return null;
    } catch (e) {
      print('Yahoo Finance error: $e');
      return null;
    }
  }

  // Fetch from IEX Cloud (alternative real-time source)
  Future<StockModel?> _fetchFromIEXCloud(String symbol) async {
    try {
      // Note: You would need to add IEX Cloud API key to constants
      // For now, this is a placeholder for future implementation
      return null;
    } catch (e) {
      print('IEX Cloud error: $e');
      return null;
    }
  }

  // Subscribe to multiple stocks
  void subscribeToStocks(List<String> symbols) {
    for (final symbol in symbols) {
      if (!_subscribedSymbols.contains(symbol)) {
        _subscribedSymbols.add(symbol);
        getStockStream(symbol); // This will start the stream
      }
    }
  }

  // Unsubscribe from a stock
  void unsubscribeFromStock(String symbol) {
    _timers[symbol]?.cancel();
    _timers.remove(symbol);
    _streamControllers[symbol]?.close();
    _streamControllers.remove(symbol);
    _subscribedSymbols.remove(symbol);
  }

  // Unsubscribe from all stocks
  void unsubscribeFromAllStocks() {
    for (final symbol in _subscribedSymbols.toList()) {
      unsubscribeFromStock(symbol);
    }
  }

  // Get last known price
  StockModel? getLastKnownPrice(String symbol) {
    return _lastKnownPrices[symbol];
  }

  // Check if stock is being tracked
  bool isTracking(String symbol) {
    return _subscribedSymbols.contains(symbol);
  }

  // Get all tracked symbols
  Set<String> get trackedSymbols => _subscribedSymbols;

  // Dispose all resources
  void dispose() {
    unsubscribeFromAllStocks();
    _webSocketChannel?.sink.close();
  }

  // Market hours check for more frequent updates during market hours
  bool _isMarketHours() {
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

  // Get appropriate update interval based on market hours
  Duration getUpdateInterval() {
    return _isMarketHours() ? _fastUpdateInterval : _updateInterval;
  }
}

// Real-time stock data model for streaming
class RealtimeStockData {
  final String symbol;
  final double price;
  final double change;
  final double changePercent;
  final int volume;
  final DateTime timestamp;
  final double high;
  final double low;
  final double open;

  RealtimeStockData({
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.volume,
    required this.timestamp,
    required this.high,
    required this.low,
    required this.open,
  });

  factory RealtimeStockData.fromJson(Map<String, dynamic> json) {
    return RealtimeStockData(
      symbol: json['symbol'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      change: (json['change'] ?? 0.0).toDouble(),
      changePercent: (json['changePercent'] ?? 0.0).toDouble(),
      volume: json['volume'] ?? 0,
      timestamp: DateTime.now(),
      high: (json['high'] ?? 0.0).toDouble(),
      low: (json['low'] ?? 0.0).toDouble(),
      open: (json['open'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'price': price,
      'change': change,
      'changePercent': changePercent,
      'volume': volume,
      'timestamp': timestamp.toIso8601String(),
      'high': high,
      'low': low,
      'open': open,
    };
  }
}
