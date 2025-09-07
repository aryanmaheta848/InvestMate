import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:invest_mate/models/stock_model.dart';
import 'package:invest_mate/services/stock_service.dart';
import 'package:invest_mate/services/realtime_stock_service.dart';

class StockProvider extends ChangeNotifier {
  final StockService _stockService = StockService();
  final RealtimeStockService _realtimeService = RealtimeStockService();

  List<StockModel> _watchlistStocks = [];
  List<StockModel> _trendingStocks = [];
  List<StockModel> _searchResults = [];
  Map<String, List<OHLCVData>> _chartData = {};
  
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isRealtimeEnabled = true;
  String? _errorMessage;
  
  // Stream subscriptions for real-time updates
  final Map<String, StreamSubscription> _streamSubscriptions = {};

  // Getters
  List<StockModel> get watchlistStocks => _watchlistStocks;
  List<StockModel> get trendingStocks => _trendingStocks;
  List<StockModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isRealtimeEnabled => _isRealtimeEnabled;
  String? get errorMessage => _errorMessage;

  // Get stock by symbol
  Future<StockModel?> getStock(String symbol) async {
    try {
      return await _stockService.getStock(symbol);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  // Load watchlist stocks
  Future<void> loadWatchlistStocks(List<String> symbols) async {
    if (symbols.isEmpty) {
      _watchlistStocks = [];
      notifyListeners();
      return;
    }

    try {
      _setLoading(true);
      _watchlistStocks = await _stockService.getWatchlistStocks(symbols);
      _clearError();
      
      // Start real-time updates for watchlist stocks
      if (_isRealtimeEnabled) {
        _startRealtimeUpdates(symbols);
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load trending stocks
  Future<void> loadTrendingStocks() async {
    try {
      _setLoading(true);
      _trendingStocks = await _stockService.getTrendingStocks();
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Search stocks
  Future<void> searchStocks(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _setSearching(true);
      _searchResults = await _stockService.searchStocks(query);
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setSearching(false);
    }
  }

  // Get historical data for chart
  Future<List<OHLCVData>> getHistoricalData(String symbol, String period) async {
    try {
      // Check cache first
      final cacheKey = '$symbol-$period';
      if (_chartData.containsKey(cacheKey)) {
        return _chartData[cacheKey]!;
      }

      final data = await _stockService.getHistoricalData(symbol, period);
      _chartData[cacheKey] = data;
      return data;
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  // Refresh single stock price
  Future<void> refreshStock(String symbol) async {
    try {
      final updatedStock = await _stockService.getStock(symbol);
      if (updatedStock != null) {
        // Update in watchlist if present
        final index = _watchlistStocks.indexWhere((s) => s.symbol == symbol);
        if (index != -1) {
          _watchlistStocks[index] = updatedStock;
          notifyListeners();
        }

        // Update in trending if present
        final trendingIndex = _trendingStocks.indexWhere((s) => s.symbol == symbol);
        if (trendingIndex != -1) {
          _trendingStocks[trendingIndex] = updatedStock;
          notifyListeners();
        }
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Refresh all watchlist stocks
  Future<void> refreshWatchlist(List<String> symbols) async {
    try {
      if (symbols.isNotEmpty) {
        await _stockService.refreshStockPrices(symbols);
        await loadWatchlistStocks(symbols);
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Get market status
  MarketStatus getMarketStatus() {
    return _stockService.getMarketStatus();
  }

  // Start real-time updates for symbols
  void _startRealtimeUpdates(List<String> symbols) {
    for (final symbol in symbols) {
      if (!_streamSubscriptions.containsKey(symbol)) {
        _streamSubscriptions[symbol] = _realtimeService
            .getStockStream(symbol)
            .listen(
              (updatedStock) => _updateStockInLists(updatedStock),
              onError: (error) => print('Real-time update error for $symbol: $error'),
            );
      }
    }
  }

  // Update stock in all relevant lists
  void _updateStockInLists(StockModel updatedStock) {
    bool updated = false;

    // Update in watchlist
    final watchlistIndex = _watchlistStocks.indexWhere((s) => s.symbol == updatedStock.symbol);
    if (watchlistIndex != -1) {
      _watchlistStocks[watchlistIndex] = updatedStock;
      updated = true;
    }

    // Update in trending stocks
    final trendingIndex = _trendingStocks.indexWhere((s) => s.symbol == updatedStock.symbol);
    if (trendingIndex != -1) {
      _trendingStocks[trendingIndex] = updatedStock;
      updated = true;
    }

    // Update in search results
    final searchIndex = _searchResults.indexWhere((s) => s.symbol == updatedStock.symbol);
    if (searchIndex != -1) {
      _searchResults[searchIndex] = updatedStock;
      updated = true;
    }

    if (updated) {
      notifyListeners();
    }
  }

  // Toggle real-time updates
  void toggleRealtimeUpdates() {
    _isRealtimeEnabled = !_isRealtimeEnabled;
    
    if (_isRealtimeEnabled) {
      // Start real-time updates for current watchlist
      final symbols = _watchlistStocks.map((s) => s.symbol).toList();
      _startRealtimeUpdates(symbols);
    } else {
      // Stop all real-time updates
      _stopAllRealtimeUpdates();
    }
    
    notifyListeners();
  }

  // Stop all real-time updates
  void _stopAllRealtimeUpdates() {
    for (final subscription in _streamSubscriptions.values) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();
    _realtimeService.unsubscribeFromAllStocks();
  }

  // Get real-time stock stream
  Stream<StockModel> getRealtimeStockStream(String symbol) {
    return _realtimeService.getStockStream(symbol);
  }

  // Get last known price
  StockModel? getLastKnownPrice(String symbol) {
    return _realtimeService.getLastKnownPrice(symbol);
  }

  // Check if stock is being tracked in real-time
  bool isStockTracked(String symbol) {
    return _realtimeService.isTracking(symbol);
  }

  // Dispose resources
  @override
  void dispose() {
    _stopAllRealtimeUpdates();
    _realtimeService.dispose();
    super.dispose();
  }

  // Check if market is open
  bool isMarketOpen() {
    return _stockService.isMarketOpen();
  }

  // Clear search results
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  // Clear chart cache
  void clearChartCache() {
    _chartData.clear();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set searching state
  void _setSearching(bool searching) {
    _isSearching = searching;
    notifyListeners();
  }

  // Set error
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error
  void _clearError() {
    _errorMessage = null;
    if (_errorMessage != null) {
      notifyListeners();
    }
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }
}
